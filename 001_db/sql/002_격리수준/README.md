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
| `03_phantom_read.sql` | Phantom Read, PostgreSQL의 `REPEATABLE READ`가 이것도 막는다는 것 | `accounts` |
| `04_lost_update.sql` | Lost Update, 출금 7만 원이 증발하는 과정 | `accounts` |
| `05_lost_update_repeatable_read.sql` | 격리 수준을 올리면 잔액이 맞는 게 아니라 에러가 난다는 것 | `accounts` |
| `06_single_statement.sql` | 한 문장으로 쓰면 기본 격리 수준에서도 안 틀린다는 것 | `accounts` |
| `07_write_skew.sql` | `REPEATABLE READ`가 못 막고 `SERIALIZABLE`만 막는 경우 | `doctors` |

`01`부터 순서대로 돌리면 글의 흐름과 맞습니다.

파일을 통째로 실행하는 게 아닙니다. 주석의 `[S1]`, `[S2]` 표시를 보고 **번호 순서대로 한 블록씩 복사해서 붙여넣습니다.** 한 세션이 `COMMIT`하기 전에 다른 세션이 읽어야 재현되는 것들이라, 순서가 바뀌면 아무 일도 일어나지 않습니다.

## 확인되는 것

두 DB를 같이 돌려보면 이런 차이가 나옵니다.

| | PostgreSQL 16 | MySQL 8.0 |
| --- | --- | --- |
| `READ UNCOMMITTED`에서 커밋 안 된 값 읽기 | `100000` (안 읽힘) | `0` (읽힘) |
| `REPEATABLE READ`에서 Phantom Read | 막음 | 막음 |
| `REPEATABLE READ`에서 Lost Update | 에러를 던짐 | 에러 없이 덮어씀 |
| `balance = balance - 70000` 동시 실행 | `-20000` (정확) | `-20000` (정확) |
