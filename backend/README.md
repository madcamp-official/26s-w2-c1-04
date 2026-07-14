# Memory Pager — 백엔드

FastAPI + Socket.IO + MySQL 8. 설계 근거는 [../docs/SPEC.md](../docs/SPEC.md), [../docs/ERD.md](../docs/ERD.md).

## 현재 상태

| 파일 | 상태 |
|---|---|
| `schema.sql` | 작성 완료. **DDL의 원본이다.** |
| `app/models.py` | 작성 완료. SQLAlchemy 2.0. schema.sql과 1:1 대응 |
| `requirements.txt` | 작성 완료. 버전 근거는 [../docs/STACK.md](../docs/STACK.md) 3절 |
| `app/config.py` | 작성 완료. `.env` 로드 |
| `app/db.py` | 작성 완료. 엔진은 lifespan에서 지연 생성한다 |
| `app/ephemeral.py` | 작성 완료. 사라지기 모드 타이머. **테스트 7/7 통과** |
| `app/gpu.py` | 작성 완료. 스텁 ↔ 실물을 같은 인터페이스 뒤에 둠 |
| `app/notifications.py` | 작성 완료. FCM data-only 푸시 + 자격 증명 없는 개발 폴백 |
| `app/realtime.py` | 작성 완료. Socket.IO 서버, ack 포함 |
| `app/main.py` | 작성 완료. `/v1/health` 동작 확인 |
| `app/scheduler.py` | 작성 완료. 활동 갱신·자정 일기·**월간 레포트** 배치 |
| 라우터 `auth`·`groups`·`devices` | 작성 완료. 온보딩·그룹·기기 등록 |
| 라우터 `doodles`·`pokes`·`widget` | 작성 완료. 낙서·사라지기·찌르기·위젯 |
| 라우터 `pets` | 작성 완료. 쓰다듬기·그림 일기 |
| 라우터 `reports` | 작성 완료. 월간 레포트(MR-1~4). **테스트 45/45 통과** |
| `../gpu/sd_worker.py` | 작성 완료. SD 1.5 기본 그림체 일기 + 로컬 스텁 계약 |
| `../demo/` | 작성 완료. 두 사용자 REST·Socket.IO·5초 만료 검증 화면 |

## 실행

```bash
uvicorn app.main:asgi --host 0.0.0.0 --port 8000
```

**`--workers`를 주지 마라.** 사라지기 모드의 5초 타이머가 프로세스 인메모리다. 워커를 늘리면 타이머가 공유되지 않아 낙서가 사라지지 않는다.

DB와 GPU가 없어도 서버는 뜬다. `GET /v1/health`가 `{"db":"down","gpu":"stub"}`을 돌려준다. **앱 개발이 인프라에 막히지 않게 하려는 것이다.** `GPU_ENABLED=true`로 바꾸면 실제 추론을 부른다.

```bash
python tests/test_ephemeral.py   # 의존성 없이 돈다
```

## 설치

**반드시 venv 안에서.**

```bash
python3 -m venv ~/envs/api
source ~/envs/api/bin/activate
pip install -r backend/requirements.txt
```

`uvicorn`은 반드시 `[standard]` 옵션으로 깔린다. 순정 uvicorn은 websockets 구현이 없어 Socket.IO의 WS 업그레이드가 실패한다. Socket.IO는 `app.mount()`가 아니라 `socketio.ASGIApp(sio, other_asgi_app=fastapi_app)`으로 감싼다. 함정 네 가지는 [STACK.md](../docs/STACK.md) 5절.

**uvicorn을 단일 프로세스로 돌린다.** 사라지기 모드의 5초 타이머가 프로세스 인메모리라 워커를 늘리면 공유되지 않는다.

## 테스트

```bash
python tests/test_ephemeral.py    # 의존성 없이 돈다
python tests/test_security.py     # 의존성 없이 돈다
python tests/test_validation.py   # ID·월·KST 배치 날짜
python tests/test_gpu_clients.py  # vLLM 0.24·sd-worker HTTP 계약

# 실제 MySQL 이 필요하다. schema.sql 을 먼저 적용할 것.
bash tests/test_schema_mysql.sh                    # 트리거·CHECK·에러 우선순위
export DATABASE_URL='mysql+asyncmy://root:root@127.0.0.1:3306/memory_pager?charset=utf8mb4'
python tests/test_groups_integration.py            # 온보딩~정원 초과 전체 흐름 (28)
python tests/test_doodles_integration.py           # 낙서·사라지기·찌르기 (35)
python tests/test_pets_integration.py              # 펫·그림 일기·위젯 (33)
python tests/test_reports_integration.py           # 월간 레포트·최고의 낙서 (45)
python tests/test_questions_integration.py          # 오늘의 질문 E-1 (17)
python tests/test_hardening_integration.py         # FCM 대상·동시성·입력 경계 (28)

# 실행 중인 서버의 실제 WebSocket E2E (7)
E2E_BASE_URL=http://127.0.0.1:8000 python tests/test_realtime_e2e.py

# GPU 없이 sd-worker 요청/PNG 계약 (6)
SD_STUB=true python ../gpu/tests/test_sd_worker.py
```

**MySQL 8.0.40에서 실제로 확인했다.** `schema.sql`이 그대로 걸리고(17 테이블, 트리거 3개), 트리거가 3번째 가입을 거부하며, `UNIQUE(user_id)`가 유저의 두 번째 그룹 가입을 막고, `AFTER INSERT/DELETE`가 `member_count`를 유지한다. 라우터 통합 테스트 **161항목**(그룹 31 · 낙서 35 · 펫 33 · 레포트 45 · 질문 17)과 동시성·FCM·입력 경계 29항목이 통과한다. 실제 WebSocket E2E 7항목은 실행 중인 서버에 별도로 붙는다.

> **라이브 DB 마이그레이션(E-1).** `question_answers`는 새 테이블이라 배포 시 라이브 DB에 `CREATE TABLE`이 필요하다(`schema.sql`은 drop-recreate라 새 설치만 반영). SSH 복구되면 `mysql -uroot -proot memory_pager < ` 로 해당 CREATE 문만 적용한다. [[madcamp-infra-facts]]의 DATETIME(6) 마이그레이션 함정과 같은 부류다.

## 데모 프론트

백엔드를 `:8000`에 실행한 뒤 저장소 루트에서 다음을 실행한다.

```bash
python -m http.server 4173 --directory demo
```

브라우저에서 `http://127.0.0.1:4173`을 열고 **2인 데모 시작**을 누른다. 고유한 두 유저를 만들고 같은 그룹에 가입시킨 뒤 WebSocket 두 개를 연결한다. 일반·사라지기 메시지, 찌르기, 쓰다듬기, 월간 레포트를 실제 API로 확인할 수 있다.

### 실측으로 알아낸 것 — 에러 우선순위

**그룹이 꽉 찬 상태에서 기존 멤버가 재가입하면, `BEFORE INSERT` 트리거가 `UNIQUE`보다 먼저 터진다.** MySQL 에러가 `1062`(중복)가 아니라 `1644`(SIGNAL)로 온다. DB 에러만 보고 코드를 정하면 `already_member`가 `group_full`로 둔갑한다. 그래서 `groups.py`는 insert 전에 선검사를 해서 정확한 에러 코드를 고른다.

파서 검증으로는 이런 걸 절대 못 잡는다. `DELIMITER`가 SQL이 아니라 `mysql` 클라이언트 명령이라 트리거 블록은 애초에 파서를 타지도 않는다.

## 어디서 도는가

| | 앱 VM (172.10.7.229) | GPU 서버 (192.168.0.20) |
|---|---|---|
| OS | Ubuntu 22.04 (Python 3.10) | Ubuntu 22.04 (Python 3.10) |
| 스펙 | 4 vCPU / **4GB RAM** / 100GB | 40 vCPU / 50GB RAM / 100GB / RTX 3090 24GB |
| 이 디렉터리의 코드 | **여기서 돈다** | 돌지 않는다 |
| 그 밖에 | MySQL 8, 미디어 파일 | LLM 서빙, SD 추론·학습 |

**이 백엔드는 앱 VM에서만 돈다.** GPU 서버는 상태 없는 추론 워커이고, HTTP로만 부른다(사설망 `192.168.0.20`).

## Python 버전 — 함정

**Python 3.9 이상이 필요하다.** `app/models.py`는 `Mapped[list[X]]` 형태의 PEP 585 제네릭을 쓰는데, SQLAlchemy가 이 어노테이션을 런타임에 평가한다. Python 3.8에서는 `list[X]`가 구독 불가라 `NameError`로 터진다. 실제로 3.8.6에서 재현했고, 3.13에서 통과했다.

**두 VM 다 Ubuntu 22.04라 기본 Python이 3.10이다. 문제없다.** 스택 최저선이 3.10이라 시스템 Python으로 충분하고, 초기에 걱정했던 GPU 서버의 3.8 문제는 실제 OS가 22.04로 확인되면서 사라졌다.

## 앱 VM은 RAM이 4GB뿐이다

MySQL 8과 FastAPI가 같은 4GB를 나눠 쓴다. 사용자가 둘이라 트래픽은 문제가 아니지만, `innodb_buffer_pool_size`를 함부로 키우지 말고 이미지 리사이즈처럼 메모리가 튀는 작업은 GPU 서버로 넘긴다.

## 스키마 적용

```bash
# 대상 DB를 커맨드라인에서 지정한다(스키마가 DB명을 강제하지 않는다).
mysql -u root -p memory_pager < backend/schema.sql
# 격리 테스트: 임시 DB에만 적용(기본 memory_pager 를 건드리지 않는다)
mysql -u root -p mp_test < backend/schema.sql
```

`schema.sql`은 맨 앞에서 (선택된 DB의) 기존 테이블을 전부 `DROP`한다. **개발 초기 전용이다.**
DB명을 파일이 아니라 호출자가 고르므로, 격리 테스트가 기본 DB를 재생성하는 사고가 없다.

## 설계상 알아둘 것

**`groups`는 MySQL 8의 예약어(`GROUPS`)다.** DDL에서 백틱으로 감쌌고, 모델에서는 `quoted_name("groups", True)`로 인용을 강제했다.

**그룹 정원 2명은 세 겹으로 막는다.** `groups.member_count`에 `CHECK`, `group_members`에 `BEFORE INSERT` 트리거, 그리고 애플리케이션이 가입 트랜잭션에서 `SELECT ... FOR UPDATE`로 `groups` 행을 잠근다. 초대 코드를 두 사람이 동시에 입력하는 경합이 실제로 나기 때문이다.

**`doodle_receipts`는 최초 확인만 기록한다.** `UNIQUE(doodle_id, user_id)`가 그것을 보장하며, 사라지기 모드의 5초 타이머를 여기서 건다. 부작용으로 체류 시간과 재조회 횟수가 남지 않아 "이번 달 최고의 낙서"가 쓸 수 있는 행동 신호는 답장 수 하나뿐이다.

**`pet_activities`가 곧 캐시다.** 쓰다듬기는 LLM을 부르지 않고 `ended_at IS NULL`인 현재 활동의 `utterance`를 그대로 돌려준다. 연타 가능한 인터랙션이라 매 탭마다 추론을 돌리면 GPU가 버티지 못한다.
