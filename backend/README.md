# Memory Pager — 백엔드

FastAPI + Socket.IO + MySQL 8. 설계 근거는 [../docs/SPEC.md](../docs/SPEC.md), [../docs/ERD.md](../docs/ERD.md).

## 현재 상태

| 파일 | 상태 |
|---|---|
| `schema.sql` | 작성 완료. **DDL의 원본이다.** |
| `app/models.py` | 작성 완료. SQLAlchemy 2.0. schema.sql과 1:1 대응 |
| `requirements.txt` | 미작성 — 환경 조사 결과 대기 중 |
| `app/db.py`, 라우터, Socket.IO 서버 | 미작성 |

## 검증한 것

- `app/models.py`가 임포트되고 `configure_mappers()`가 통과한다 (SQLAlchemy 2.0.51, Python 3.13).
- `schema.sql`이 MySQL 방언으로 파싱되며(16 테이블), 테이블·컬럼·ENUM 값이 모델과 정확히 일치한다.

## 검증하지 못한 것

- **DDL을 실제 MySQL 서버에 걸어보지 못했다.** 파서 통과가 실행 성공을 뜻하지는 않는다.
- **트리거 블록은 파서 검증에서 제외했다.** `DELIMITER`가 SQL이 아니라 `mysql` 클라이언트 명령이기 때문이다. 트리거는 서버에서 직접 확인해야 한다.

## Python 버전 — 함정

**Python 3.9 이상이 필요하다.** `app/models.py`는 `Mapped[list[X]]` 형태의 PEP 585 제네릭을 쓰는데, SQLAlchemy가 이 어노테이션을 런타임에 평가한다. Python 3.8에서는 `list[X]`가 구독 불가라 `NameError`로 터진다. 실제로 3.8.6에서 재현했다.

**Ubuntu 20.04의 기본 Python이 3.8이다.** 서버에 그대로 깔면 모델이 임포트조차 되지 않는다. 반드시 새 인터프리터를 올려야 한다. 어떤 경로로 올릴지(deadsnakes PPA / conda / uv)는 환경 조사 결과를 반영해 정한다.

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
