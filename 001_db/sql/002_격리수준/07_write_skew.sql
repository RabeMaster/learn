-- ============================================================
-- Write Skew - REPEATABLE READ가 못 막고 SERIALIZABLE이 막는 것
--
-- 앞의 이상현상 네 가지는 전부 "같은 행"을 두고 다투는 이야기였습니다.
-- Write Skew는 두 세션이 서로 "다른 행"을 고치는데도 전체 규칙이 깨지는 경우입니다.
--
-- 상황: 당직자는 항상 최소 한 명이 남아 있어야 합니다.
--       지금 유리와 훈이 둘 다 당직 중입니다.
--       두 사람이 동시에 "나 말고 한 명 더 있네" 확인하고 퇴근 신청을 합니다.
--
-- 서로 다른 행을 고치기 때문에 잠금 충돌도, 대기도 없습니다.
-- 그런데 결과는 당직자 0명이 됩니다.
-- ============================================================
-- 이 시나리오는 accounts 가 아니라 doctors 테이블을 씁니다.
-- 00_setup.sql 을 실행했다면 이미 만들어져 있습니다.
-- ------------------------------------------------------------
-- 1부. REPEATABLE READ 로 돌려봅니다. 규칙이 깨집니다.
--
-- 본문은 PostgreSQL 16 기준입니다.
-- MySQL 8.0에서는 [MySQL] 주석이 붙은 자리만 그 줄로 바꿔 쓰시면 됩니다.
-- ------------------------------------------------------------


-- [S1] 1  (유리)
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- [MySQL] 문법이 다릅니다. 자리는 그대로 BEGIN 앞입니다.
--   SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN;
SELECT count(*) FROM doctors WHERE on_call = true;
-- 2. 나 말고 한 명 더 있으니 퇴근해도 되겠다.


-- [S2] 2  (훈이)
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- [MySQL] SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN;
SELECT count(*) FROM doctors WHERE on_call = true;
-- 2. 나 말고 한 명 더 있으니 퇴근해도 되겠다.


-- [S1] 3
UPDATE doctors SET on_call = false WHERE id = 1;
COMMIT;


-- [S2] 4
UPDATE doctors SET on_call = false WHERE id = 2;
COMMIT;
-- 대기도 없고 에러도 없습니다. 서로 다른 행을 고쳤기 때문입니다.


-- [S1] 5
SELECT count(*) FROM doctors WHERE on_call = true;
-- 0. 당직자가 아무도 안 남았습니다. 규칙이 조용히 깨졌습니다.


-- ------------------------------------------------------------
-- 2부. 똑같은 순서를 SERIALIZABLE 로 돌려봅니다.
--   위 [S1] 1, [S2] 2 의 SET 줄만 이렇게 바꾸면 됩니다.
--
--     SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL SERIALIZABLE;
--     [MySQL] SET SESSION TRANSACTION ISOLATION LEVEL SERIALIZABLE;
--
--   시작 전에 테이블을 되돌립니다.
--     UPDATE doctors SET on_call = true;
--
--   [S2] 4번의 COMMIT에서 이 에러가 납니다.
--
--     ERROR:  could not serialize access due to
--             read/write dependencies among transactions
--     DETAIL:  Reason code: Canceled on identification as a pivot,
--              during commit attempt.
--     HINT:  The transaction might succeed if retried.
--
--   훈이의 퇴근 신청이 취소되고 당직자는 1명으로 남습니다.
--
-- 앞의 Lost Update 때 나온 에러와 문구가 다르다는 점을 봐 두시면 좋습니다.
--   같은 행을 동시에 고칠 때   -> could not serialize access due to concurrent update
--   읽기와 쓰기가 얽혔을 때     -> could not serialize access due to read/write
--                                dependencies among transactions
--
-- 끝내고 나서
--   1번에서 건 격리 수준은 세션에 그대로 남아 있습니다.
--   두 세션 다 되돌려 주세요.
--     RESET ALL;                                    -- PostgreSQL
--     SET SESSION transaction_isolation = DEFAULT;  -- MySQL
-- ------------------------------------------------------------
