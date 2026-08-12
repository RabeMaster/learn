-- ============================================================
-- 1. Dirty Read - 아직 COMMIT되지 않은 남의 데이터를 읽는 것
--
-- 결론을 먼저 적어두면 이렇습니다.
--
--                            PostgreSQL 16   MySQL 8.0
--   기본값 그대로                  100000      100000
--   READ UNCOMMITTED 로 내림       100000           0
--
-- 기본값에서는 양쪽 다 재현되지 않습니다. 두 DB의 기본 격리 수준이
-- 이미 Dirty Read를 막는 단계이기 때문입니다.
-- 제일 낮은 READ UNCOMMITTED 로 내렸을 때 비로소 결과가 갈립니다.
--
-- PostgreSQL에는 함정이 하나 있습니다. 격리 수준을 내리고
-- SHOW transaction_isolation 을 찍으면 read uncommitted 라고 그대로 나옵니다.
-- 설정 자체는 받아줍니다. 그런데 동작은 READ COMMITTED와 같습니다.
-- 표시값만 보고 판단하면 안 되고, 실제로 남의 미확정 데이터가 읽히는지를 봐야 합니다.
-- ============================================================
-- 세션 두 개를 띄우고 [S1], [S2] 옆의 번호 순서대로 한 블록씩 실행합니다.
--
-- 본문은 PostgreSQL 16 기준입니다.
-- MySQL 8.0에서는 [MySQL] 주석이 붙은 자리만 그 줄로 바꿔 쓰시면 됩니다.
-- ------------------------------------------------------------
-- 1부. 기본값 그대로 돌려봅니다. 양쪽 다 재현되지 않습니다.
-- ------------------------------------------------------------


-- [S2] 1
-- 시작하기 전에 지금 격리 수준부터 확인합니다.
-- 앞 실습에서 바꿔둔 값이 남아 있으면 결과가 달라집니다.
SHOW transaction_isolation;
-- read committed 가 나와야 합니다. 다르면 RESET ALL; 로 되돌립니다.
--
-- [MySQL] 확인 명령도, 기본값도 다릅니다.
--   SELECT @@transaction_isolation;   -- REPEATABLE-READ 가 나와야 합니다
--   되돌릴 때는  SET SESSION transaction_isolation = DEFAULT;


-- [S1] 2
BEGIN;
UPDATE accounts SET balance = 0 WHERE id = 1;
-- 아직 COMMIT하지 않았습니다. 이 0은 확정된 값이 아닙니다.


-- [S2] 3
SELECT balance FROM accounts WHERE id = 1;
-- 100000. PostgreSQL과 MySQL 둘 다 같습니다.
-- 기본 격리 수준이 이미 Dirty Read를 막고 있어서 남의 미확정 0을 못 봅니다.


-- [S1] 4
ROLLBACK;
-- 데이터가 원래대로 돌아왔으니 2부를 바로 이어서 하셔도 됩니다.


-- ------------------------------------------------------------
-- 2부. 격리 수준을 제일 낮은 READ UNCOMMITTED 로 내려봅니다.
--      여기서부터 두 DB가 갈립니다.
-- ------------------------------------------------------------


-- [S2] 5
SET SESSION CHARACTERISTICS AS TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SHOW transaction_isolation;
-- read uncommitted 라고 나옵니다. 요청은 그대로 받아들여졌습니다.
--
-- [MySQL] 위 두 줄 대신 이 두 줄을 씁니다. 문법이 아예 다릅니다.
--   SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
--   SELECT @@transaction_isolation;


-- [S1] 6
BEGIN;
UPDATE accounts SET balance = 0 WHERE id = 1;
-- 1부의 2번과 똑같습니다. 바뀐 것은 세션 2의 격리 수준뿐입니다.


-- [S2] 7
SELECT balance FROM accounts WHERE id = 1;
-- PostgreSQL 16 -> 100000. 제일 낮게 내렸는데도 여전히 못 봅니다.
-- MySQL 8.0     -> 0.      이게 진짜 Dirty Read입니다.


-- [S1] 8
ROLLBACK;
-- 방금 그 0은 존재한 적 없는 값이 되었습니다.


-- [S2] 9
SELECT balance FROM accounts WHERE id = 1;
-- 100000
-- MySQL에서 7번에 0을 보셨다면, 존재한 적 없는 값을 보고 판단했던 것입니다.


-- ------------------------------------------------------------
-- 왜 PostgreSQL은 내려도 재현되지 않나
--   PostgreSQL 16 문서가 직접 밝히고 있습니다.
--
--     "In PostgreSQL, you can request any of the four standard transaction
--      isolation levels, but internally only three distinct isolation levels
--      are implemented, i.e., PostgreSQL's Read Uncommitted mode behaves like
--      Read Committed. This is because it is the only sensible way to map the
--      standard isolation levels to PostgreSQL's multiversion concurrency
--      control architecture."
--
--   요청은 받아주되 실제로는 READ COMMITTED로 돌린다는 뜻입니다.
--   그래서 PostgreSQL의 격리 수준은 이름은 4개지만 실질은 3개입니다.
--
--   MySQL은 READ UNCOMMITTED가 실제로 동작합니다.
--   같은 SQL을 돌렸는데 결과가 갈리는 자리는 위 7번 한 곳뿐입니다.
-- ------------------------------------------------------------
