# 002 격리 수준과 이상현상 - 실습

글: [트랜잭션 격리 수준과 이상현상](../../002_격리수준과-이상현상.md)

## 준비

컨테이너 띄우는 법과 세션 여는 법은 [lab README](../../../lab/README.md)에 있습니다.  
이 글은 PostgreSQL과 MySQL을 둘 다 씁니다.

```bash
docker compose --profile db up -d
```

접속한 뒤, **두 DB에서 각각 한 번씩** 아래를 실행합니다.

psql에서는 이렇게 합니다.

```
\i /repo/001_db/sql/002_격리수준/00_setup.sql
```

mysql에서는 이렇게 합니다.

```
source /repo/001_db/sql/002_격리수준/00_setup.sql
```

`accounts`(짱구 10만, 철수 6만)와 `doctors`(유리, 훈이 둘 다 당직 중)가 만들어집니다.

## 시나리오

| 파일 | 보는 것 | 쓰는 테이블 |
| --- | --- | --- |
| `00_setup.sql` | 테이블 만들기. 제일 먼저 한 번 | - |
| `00_reset.sql` | 데이터만 처음 상태로. 시나리오 하나 끝날 때마다 | 둘 다 |
| `01_dirty_read.sql` | Dirty Read, 그리고 PostgreSQL에서 왜 재현되지 않는지 | `accounts` |
| `02_non_repeatable_read.sql` | Non-Repeatable Read | `accounts` |

`01`부터 순서대로 돌리면 글의 흐름과 맞습니다.

파일을 통째로 실행하는 게 아닙니다. 주석의 `[S1]`, `[S2]` 표시를 보고 **번호 순서대로 한 블록씩 복사해서 붙여넣습니다.** 한 세션이 `COMMIT`하기 전에 다른 세션이 읽어야 재현되는 것들이라, 순서가 바뀌면 아무 일도 일어나지 않습니다.

## 확인되는 것

두 DB를 같이 돌려보면 이런 차이가 나옵니다.

| | PostgreSQL 16 | MySQL 8.0 |
| --- | --- | --- |
| `READ UNCOMMITTED`에서 커밋 안 된 값 읽기 | `100000` (안 읽힘) | `0` (읽힘) |
