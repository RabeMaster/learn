-- ============================================================
-- 002 격리 수준과 이상현상 - 실습 준비
--
-- 이 글의 시나리오에 필요한 테이블을 전부 만듭니다.
-- PostgreSQL과 MySQL은 서로 다른 DB이므로 양쪽에 각각 한 번씩 실행합니다.
-- 아래 DDL은 두 DB에서 그대로 돌아갑니다.
-- ============================================================

-- 01 ~ 06 시나리오에서 씁니다.
DROP TABLE IF EXISTS accounts;
CREATE TABLE accounts (
    id      int PRIMARY KEY,
    owner   text NOT NULL,
    balance int  NOT NULL
);
INSERT INTO accounts VALUES (1, '짱구', 100000), (2, '철수', 60000);

-- 07 Write Skew 시나리오에서만 씁니다.
-- 당직자는 항상 최소 한 명이 남아 있어야 한다는 규칙을 검사하는 용도입니다.
DROP TABLE IF EXISTS doctors;
CREATE TABLE doctors (
    id      int  PRIMARY KEY,
    name    text NOT NULL,
    on_call boolean NOT NULL
);
INSERT INTO doctors VALUES (1, '유리', true), (2, '훈이', true);

SELECT * FROM accounts ORDER BY id;
SELECT * FROM doctors ORDER BY id;
