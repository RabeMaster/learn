-- 시나리오를 하나 끝낼 때마다 실행해서 처음 상태로 되돌립니다.
-- 테이블을 다시 만들지는 않고 데이터만 되돌립니다.
-- 테이블 자체가 없다면 00_setup.sql 을 먼저 실행하시면 됩니다.
-- PostgreSQL, MySQL 둘 다 그대로 쓸 수 있습니다.

DELETE FROM accounts;
INSERT INTO accounts VALUES (1, '짱구', 100000), (2, '철수', 60000);

UPDATE doctors SET on_call = true;

SELECT * FROM accounts ORDER BY id;
