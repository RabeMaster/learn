-- ============================================================
-- 2. Non-Repeatable Read - 같은 행을 두 번 읽었는데 값이 달라지는 것
--
-- PostgreSQL 16 기본값인 READ COMMITTED에서 그대로 재현됩니다.
-- 격리 수준을 REPEATABLE READ로 올리면 사라집니다(맨 아래 참고).
-- ============================================================
-- 세션 두 개를 띄우고 [S1], [S2] 옆의 번호 순서대로 한 블록씩 실행합니다.
-- ------------------------------------------------------------


-- [S1] 1
BEGIN;
SELECT balance FROM accounts WHERE id = 1;
-- 100000


-- [S2] 2
BEGIN;
UPDATE accounts SET balance = 50000 WHERE id = 1;
COMMIT;
-- 세션 2는 잘못한 게 없습니다. 정상적으로 고치고 확정까지 마쳤습니다.


-- [S1] 3
SELECT balance FROM accounts WHERE id = 1;
-- 50000  <- 같은 트랜잭션 안인데 값이 바뀌었습니다
COMMIT;


-- ------------------------------------------------------------
-- 격리 수준을 올려서 다시 돌려보기
--   [S1] 1번의 BEGIN 앞에 이 줄을 넣으면 3번에서도 100000이 나옵니다.
--
--     SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL REPEATABLE READ;
--     [MySQL] SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
--
--   트랜잭션이 처음 뜬 스냅샷을 끝까지 들고 가기 때문입니다.
--   이 설정은 세션에 남으니 실습을 마치면 되돌려 주세요.
--     RESET ALL;                                    -- PostgreSQL
--     SET SESSION transaction_isolation = DEFAULT;  -- MySQL
--
-- MySQL 8.0에서 돌릴 때
--   MySQL은 기본값이 REPEATABLE READ라, 위 시나리오를 그냥 돌리면
--   3번에서 100000이 나옵니다. 재현하시려면 [S1] 1번 앞에 이 줄을 넣습니다.
--
--     SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- ------------------------------------------------------------
