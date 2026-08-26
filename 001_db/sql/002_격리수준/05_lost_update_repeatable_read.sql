-- ============================================================
-- 4-2. 격리 수준을 REPEATABLE READ로 올리면 어떻게 되나
--
-- 앞 시나리오와 똑같은데 두 세션 다 REPEATABLE READ로 올립니다.
-- 잔액이 알아서 맞아떨어지는 게 아니라, 에러가 납니다.
-- 애플리케이션에 재시도 코드가 없으면 격리 수준만 올려봐야 그냥 에러입니다.
--
-- 시작 전에 00_reset.sql 로 되돌립니다.
-- ============================================================
-- 세션 두 개를 띄우고 [S1], [S2] 옆의 번호 순서대로 한 블록씩 실행합니다.
--
-- 본문은 PostgreSQL 16 기준입니다.
-- MySQL 8.0에서는 [MySQL] 주석이 붙은 자리만 그 줄로 바꿔 쓰시면 됩니다.
-- ------------------------------------------------------------


-- [S1] 1  (ATM, 7만 원 출금)
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- [MySQL] 문법이 다릅니다. 자리는 그대로 BEGIN 앞입니다.
--   SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN;
SELECT balance FROM accounts WHERE id = 1;
-- 100000


-- [S2] 2  (휴대폰 앱, 5만 원 출금)
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL REPEATABLE READ;
-- [MySQL] SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
BEGIN;
SELECT balance FROM accounts WHERE id = 1;
-- 100000


-- [S1] 3
UPDATE accounts SET balance = 30000 WHERE id = 1;


-- [S2] 4
UPDATE accounts SET balance = 50000 WHERE id = 1;
-- 대기


-- [S1] 5
COMMIT;


-- [S2] 6
-- 5번 직후 세션 2의 대기가 풀리면서 이 에러가 뜹니다.
--
--   ERROR:  could not serialize access due to concurrent update
--
-- 이 트랜잭션은 이미 죽어서, 이후 명령은 전부 거부됩니다.
ROLLBACK;


-- [S1] 7
SELECT * FROM accounts WHERE id = 1;
-- balance = 30000
-- 앞 시나리오와 달리 덮어쓰기가 일어나지 않았습니다.
-- 대신 세션 2의 출금은 아예 실패했습니다.


-- ------------------------------------------------------------
-- 공식 문서가 시키는 것
--   "it should abort the current transaction and retry the whole transaction
--    from the beginning."
--   애플리케이션이 이 에러를 잡아서 트랜잭션을 처음부터 다시 돌려야 합니다.
--
-- MySQL 8.0에서 돌릴 때
--   이 에러가 나지 않습니다. 04번과 똑같이 50000으로 조용히 덮어써집니다.
--   같은 REPEATABLE READ라는 이름인데 속이 다릅니다.
--
-- 끝내고 나서
--   1번에서 건 격리 수준은 세션에 그대로 남아 있습니다.
--   다음 실습으로 넘어가기 전에 두 세션 다 되돌려 주세요.
--     RESET ALL;                                        -- PostgreSQL
--     SET SESSION transaction_isolation = DEFAULT;      -- MySQL
-- ------------------------------------------------------------
