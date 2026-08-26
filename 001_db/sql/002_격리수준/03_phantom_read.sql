-- ============================================================
-- 3. Phantom Read - 같은 조건으로 두 번 조회했는데 행의 개수가 달라지는 것
--
-- PostgreSQL 16 기본값인 READ COMMITTED에서 재현됩니다.
-- 중요한 부분은 맨 아래입니다. PostgreSQL의 REPEATABLE READ는
-- 표준 표와 달리 이 Phantom Read까지 막습니다.
-- ============================================================
-- 세션 두 개를 띄우고 [S1], [S2] 옆의 번호 순서대로 한 블록씩 실행합니다.
-- 끝나면 00_reset.sql 로 되돌립니다(유리 행이 남습니다).
-- ------------------------------------------------------------


-- [S1] 1
BEGIN;
SELECT count(*) FROM accounts WHERE balance >= 50000;
-- 2


-- [S2] 2
BEGIN;
INSERT INTO accounts VALUES (3, '유리', 80000);
COMMIT;
-- 세션 2는 잘못한 게 없습니다. 정상적으로 넣고 확정까지 마쳤습니다.


-- [S1] 3
SELECT count(*) FROM accounts WHERE balance >= 50000;
-- 3  <- 없던 행이 유령처럼 나타났습니다
COMMIT;


-- ------------------------------------------------------------
-- 이 글의 핵심. 격리 수준을 올려서 다시 돌려보기
--   00_reset.sql 로 되돌린 뒤, [S1] 1번의 BEGIN 앞에 이 줄을 넣습니다.
--
--     SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL REPEATABLE READ;
--     [MySQL] SET SESSION TRANSACTION ISOLATION LEVEL REPEATABLE READ;
--
--   이 설정은 세션에 남으니 실습을 마치면 되돌려 주세요.
--     RESET ALL;                                    -- PostgreSQL
--     SET SESSION transaction_isolation = DEFAULT;  -- MySQL
--
--   3번에서도 2가 나옵니다. Phantom Read가 막힙니다.
--   표준 표에는 "REPEATABLE READ에서 Phantom Read 허용"이라고 돼 있는데,
--   PostgreSQL은 표준보다 더 강하게 막습니다. 공식 문서가 직접 밝히고 있습니다.
--
--     "PostgreSQL's Repeatable Read implementation does not allow phantom reads."
--
-- MySQL 8.0에서 돌릴 때
--   기본값이 REPEATABLE READ라 그냥 돌리면 3번에서도 2가 나옵니다. 여기서도 막힙니다.
--   재현하시려면 [S1] 1번 앞에 READ COMMITTED로 내리는 줄을 넣습니다.
--
--     SET SESSION TRANSACTION ISOLATION LEVEL READ COMMITTED;
--
--   다만 MySQL이 막는 방식은 하나가 아닙니다. 읽는 방법에 따라 갈립니다.
--     - 위처럼 그냥 SELECT로 읽으면(non-locking) 스냅샷으로 막습니다.
--       "Consistent reads within the same transaction read the snapshot
--        established by the first read."
--     - SELECT ... FOR UPDATE 나 UPDATE, DELETE로 읽으면(locking read)
--       gap lock, next-key lock으로 남이 그 범위에 삽입하는 것 자체를 막습니다.
--       "InnoDB locks the index range scanned, using gap locks or next-key
--        locks to block insertions by other sessions into the gaps
--        covered by the range."
--
--   READ COMMITTED로 내리면 gap lock이 꺼져서 phantom이 생길 수 있다고
--   문서가 직접 적어두었습니다.
--       "Because gap locking is disabled, phantom row problems may occur."
--
--   PostgreSQL은 어느 쪽이든 스냅샷이 기준이고, 잠그는 대신
--   충돌이 나면 에러를 던져 재시도를 요구합니다.
-- ------------------------------------------------------------
