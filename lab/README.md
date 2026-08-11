# lab

이 저장소의 글들이 함께 쓰는 **실습 환경**입니다.  
컨테이너를 띄우는 방법만 여기 있고, 실제로 실행할 SQL은 각 주제 폴더에 있습니다.

```
lab/                       <- 지금 여기. 컨테이너를 띄우고 내립니다
001_db/sql/002_격리수준/    <- 실행할 SQL은 글 옆에 있습니다
```

주제가 달라져도 컨테이너는 하나를 같이 씁니다.  
포트와 컨테이너 이름은 한 대에 하나뿐이라, 주제마다 따로 띄우면 서로 충돌하기 때문입니다.

## 시작하기 전에

이 실습은 **저장소를 clone한 상태**를 전제로 합니다.  
`docker-compose.yml`이 저장소 안에 있고, 저장소 폴더째로 컨테이너 안 `/repo`에 들어가기 때문입니다.

```bash
git clone https://github.com/RabeMaster/learn.git
cd learn/lab
```

clone하지 않고 컨테이너만 따로 띄워도 실습은 됩니다.  
다만 그때는 `/repo`가 없으니, 아래 3번의 `\i /repo/...` 대신 SQL을 직접 복사해서 붙여넣으셔야 합니다.

## 계정

로컬 실습 전용입니다.  
**절대로 실제로 쓰는 비밀번호를 여기에 넣지 말 것!!!**

| | 값 |
| --- | --- |
| 아이디 | `ravenid` |
| 비밀번호 | `ravenpw` |
| DB 이름 | `labdb` |

## 1. 필요한 것만 띄우기

모든 서비스에 프로필이 걸려 있습니다.  
그래서 그냥 `up` 하면 `no service selected`가 뜨고 **아무것도 뜨지 않습니다.**  
필요한 것을 골라서 띄웁니다.

```bash
docker compose --profile db up -d      # PostgreSQL + MySQL
docker compose --profile pg up -d      # PostgreSQL만
docker compose --profile mysql up -d   # MySQL만
docker compose --profile redis up -d   # Redis만
```

두 개를 같이 쓰려면 프로필을 이어서 줍니다.

```bash
docker compose --profile pg --profile redis up -d
```

다 떴는지 확인합니다. `ps`는 프로필 없이도 보입니다.

```bash
docker compose ps
```

`STATUS`가 `healthy`가 되면 준비가 끝난 것입니다.

## 2. 세션 열기

이상현상이나 동시성 실습은 **트랜잭션 두 개가 서로 끼어들어야** 재현됩니다.  
그래서 **터미널 창을 두 개** 열고 각각 접속합니다. 이 두 창이 시나리오 파일의 `[S1]`, `[S2]`가 됩니다.

```bash
docker exec -it lab-pg psql -U ravenid -d labdb
docker exec -it lab-mysql mysql -u ravenid -pravenpw labdb
```

빠져나올 때는 psql은 `\q`, mysql은 `exit`입니다.

## 3. SQL 파일 실행하기

저장소 전체가 컨테이너 안 `/repo`에 읽기 전용으로 들어가 있습니다.  
그래서 **접속한 세션 안에서 바로** 파일을 실행할 수 있습니다.

psql에서는 `\i`를 씁니다.

```
\i /repo/001_db/sql/002_격리수준/00_setup.sql
```

mysql에서는 `source`를 씁니다.

```
source /repo/001_db/sql/002_격리수준/00_setup.sql
```

경로 규칙은 간단합니다. 저장소 루트가 `/repo`이니, 저장소 안에서의 경로를 그대로 뒤에 붙이면 됩니다.

> **왜 이 방식인가**
>
> `psql ... < 파일.sql` 같은 셸 리다이렉션을 쓰면 **윈도우 PowerShell에서 동작하지 않습니다.**  
> PowerShell은 `<` 입력 리다이렉션을 지원하지 않기 때문입니다.  
> 반면 위 방식은 세션 안에서 실행하는 것이라 셸을 거치지 않습니다.  
> 그래서 **맥, 리눅스, 윈도우 어디서든 명령이 똑같습니다.**

## 4. 내릴 때

```bash
docker compose --profile "*" down
```

`--profile "*"`을 빼먹으면 **컨테이너가 안 내려갑니다.**  
프로필이 걸린 서비스는 프로필을 지정해야 `down`의 대상이 되기 때문입니다.  
`ps`에는 보이는데 `down`이 조용히 통과한다면 이것 때문입니다.

컨테이너를 지우면 데이터도 같이 사라집니다.  
볼륨을 붙이지 않았기 때문인데, 실습용이라 오히려 이쪽이 편합니다.  
다시 띄우고 `00_setup.sql`만 실행하면 처음 상태가 됩니다.

## 새 실습을 추가할 때

1. 주제 폴더 안에 `sql/<글 번호>_<주제>/` 폴더를 만듭니다. 예를 들면 `002_api/sql/003_재시도/`입니다.
2. 그 안에 `00_setup.sql`을 두고 **그 글에 필요한 테이블을 전부** 넣습니다. `DROP TABLE IF EXISTS`로 시작하면 앞 실습이 남아 있어도 깨끗하게 다시 만들어집니다.
3. 다른 글과 테이블이 겹쳐도 각자 갖습니다. **폴더 하나만 보면 그 글 실습이 완결되는 편**이 낫습니다.
4. 시나리오 파일은 `01_`부터 번호를 붙이고, 각 블록에 `[S1]`, `[S2]`와 실행 순서를 주석으로 적습니다.
5. 그 폴더에 `README.md`를 두고 시나리오 목록과 **어떤 프로필로 띄우면 되는지**를 적습니다.

**새로운 종류의 서버가 필요해지면** `docker-compose.yml`을 새로 만들지 말고 여기에 서비스를 추가하고 프로필을 겁니다.  
파일이 늘어나면 이미지 버전 하나 올릴 때 여러 곳을 고쳐야 하고, 포트도 서로 부딪힙니다.

## 잘 안 될 때

**포트가 이미 쓰이고 있다는 에러**

로컬에 PostgreSQL이나 MySQL을 이미 깔아 두셨다면 포트가 겹칩니다.  
`docker-compose.yml`의 `ports`에서 **왼쪽** 숫자만 바꾸시면 됩니다.

```yaml
ports:
  - "15432:5432"
```

컨테이너 안으로 들어가서 실습하는 방식이라 왼쪽 숫자를 바꿔도 지장이 없습니다.

**Git Bash에서 경로가 이상하게 바뀔 때**

윈도우 Git Bash는 명령에 들어간 `/repo` 같은 경로를 윈도우 경로로 멋대로 바꿉니다.  `cannot access 'C:/Program Files/Git/repo'` 같은 에러가 그것입니다.  
해결 방법은 앞에 이걸 붙이면 됩니다.

```bash
MSYS_NO_PATHCONV=1 docker exec lab-pg ls /repo
```

세션에 접속한 뒤 `\i`나 `source`로 실행하면 이 문제 자체가 없습니다.

**윈도우에서 한글이 깨질 때**

PowerShell 기본 창은 UTF-8이 아니라서 한글 데이터가 깨져 보일 수 있습니다.  
접속 전에 한 번 실행하시면 됩니다.

```powershell
chcp 65001
```

Windows Terminal이나 VS Code 터미널을 쓰면 대체로 그냥 됩니다.

**MySQL 접속할 때 비밀번호 경고가 뜬다**

`Using a password on the command line interface can be insecure` 경고는 명령줄에 비밀번호를 그대로 적어서 나오는 것입니다.  
실습용이니 무시하셔도 됩니다.
