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
| `app/realtime.py` | 작성 완료. Socket.IO 서버, ack 포함 |
| `app/main.py` | 작성 완료. `/v1/health` 동작 확인 |
| 라우터 (auth, groups, doodles, pets, reports) | 미작성 |

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

24.04는 PEP 668로 시스템 pip 설치를 막는다. **반드시 venv 안에서.**

```bash
python3 -m venv ~/envs/api
source ~/envs/api/bin/activate
pip install -r backend/requirements.txt
```

`uvicorn`은 반드시 `[standard]` 옵션으로 깔린다. 순정 uvicorn은 websockets 구현이 없어 Socket.IO의 WS 업그레이드가 실패한다. Socket.IO는 `app.mount()`가 아니라 `socketio.ASGIApp(sio, other_asgi_app=fastapi_app)`으로 감싼다. 함정 네 가지는 [STACK.md](../docs/STACK.md) 5절.

**uvicorn을 단일 프로세스로 돌린다.** 사라지기 모드의 5초 타이머가 프로세스 인메모리라 워커를 늘리면 공유되지 않는다.

## 검증한 것

- `app/models.py`가 임포트되고 `configure_mappers()`가 통과한다 (SQLAlchemy 2.0.51, Python 3.13).
- `schema.sql`이 MySQL 방언으로 파싱되며(16 테이블), 테이블·컬럼·ENUM 값이 모델과 정확히 일치한다.

## 검증하지 못한 것

- **DDL을 실제 MySQL 서버에 걸어보지 못했다.** 파서 통과가 실행 성공을 뜻하지는 않는다.
- **트리거 블록은 파서 검증에서 제외했다.** `DELIMITER`가 SQL이 아니라 `mysql` 클라이언트 명령이기 때문이다. 트리거는 서버에서 직접 확인해야 한다.

## 어디서 도는가

| | 앱 VM | GPU 서버 |
|---|---|---|
| OS | Ubuntu 24.04 (Python 3.12) | Ubuntu 20.04 (Python 3.8) |
| 스펙 | 4 vCPU / **4GB RAM** / 100GB | 40 vCPU / 50GB RAM / 100GB / RTX 3090 20GB |
| 이 디렉터리의 코드 | **여기서 돈다** | 돌지 않는다 |
| 그 밖에 | MySQL 8, 미디어 파일 | LLM 서빙, SD 추론·학습 |

**이 백엔드는 앱 VM에서만 돈다.** GPU 서버는 상태 없는 추론 워커이고, HTTP로만 부른다.

## Python 버전 — 함정

**Python 3.9 이상이 필요하다.** `app/models.py`는 `Mapped[list[X]]` 형태의 PEP 585 제네릭을 쓰는데, SQLAlchemy가 이 어노테이션을 런타임에 평가한다. Python 3.8에서는 `list[X]`가 구독 불가라 `NameError`로 터진다. 실제로 3.8.6에서 재현했고, 3.13에서 통과했다.

**앱 VM은 Ubuntu 24.04라 기본 Python이 3.12다. 문제없다.** Python 3.8 문제는 **GPU 서버(Ubuntu 20.04) 쪽에만** 있고, 거기서는 PyTorch와 추론 스택이 어차피 3.9 이상을 요구하므로 인터프리터를 올려야 한다.

## 앱 VM은 RAM이 4GB뿐이다

MySQL 8과 FastAPI가 같은 4GB를 나눠 쓴다. 사용자가 둘이라 트래픽은 문제가 아니지만, `innodb_buffer_pool_size`를 함부로 키우지 말고 이미지 리사이즈처럼 메모리가 튀는 작업은 GPU 서버로 넘긴다.

## 스키마 적용

```bash
mysql -u root -p < backend/schema.sql
```

`schema.sql`은 맨 앞에서 기존 테이블을 전부 `DROP`한다. **개발 초기 전용이다.**

## 설계상 알아둘 것

**`groups`는 MySQL 8의 예약어(`GROUPS`)다.** DDL에서 백틱으로 감쌌고, 모델에서는 `quoted_name("groups", True)`로 인용을 강제했다.

**그룹 정원 2명은 세 겹으로 막는다.** `groups.member_count`에 `CHECK`, `group_members`에 `BEFORE INSERT` 트리거, 그리고 애플리케이션이 가입 트랜잭션에서 `SELECT ... FOR UPDATE`로 `groups` 행을 잠근다. 초대 코드를 두 사람이 동시에 입력하는 경합이 실제로 나기 때문이다.

**`doodle_receipts`는 최초 확인만 기록한다.** `UNIQUE(doodle_id, user_id)`가 그것을 보장하며, 사라지기 모드의 5초 타이머를 여기서 건다. 부작용으로 체류 시간과 재조회 횟수가 남지 않아 "이번 달 최고의 낙서"가 쓸 수 있는 행동 신호는 답장 수 하나뿐이다.

**`pet_activities`가 곧 캐시다.** 쓰다듬기는 LLM을 부르지 않고 `ended_at IS NULL`인 현재 활동의 `utterance`를 그대로 돌려준다. 연타 가능한 인터랙션이라 매 탭마다 추론을 돌리면 GPU가 버티지 못한다.
