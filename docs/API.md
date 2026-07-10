# Memory Pager — API 명세

> 근거: [SPEC.md](SPEC.md) · [ERD.md](ERD.md) · [STACK.md](STACK.md)
> 버전 v0.1 (2026-07-10)
>
> **이 문서가 앱과 서버의 계약이다.** 앱 담당은 이걸 보고 목 서버로 개발하고, 서버 담당은 이걸 구현한다. 여기에 없는 필드는 없는 것이다. 바꾸려면 이 문서를 먼저 고친다.

**표기.** ⭐ = 과제 옵션을 증명하는 엔드포인트. 🔒 = 인증 필요. P2 = 잘라낼 수 있는 것.

---

## 0. 공통 규약

| 항목 | 규약 |
|---|---|
| Base URL | `https://<tunnel-domain>/v1` |
| 인증 | `Authorization: Bearer <token>` — `/auth/register`와 `/health` 제외 전부 필요 |
| 시각 | UTC, ISO 8601 (`2026-07-10T14:03:00Z`). 앱이 로컬 타임존으로 변환한다 |
| 날짜 | `YYYY-MM-DD` |
| 월 | `YYYY-MM` |
| 색상 | `#` 없는 6자리 hex 대문자 (`FF5A5F`) |
| ID | 64비트 정수. JSON에서는 **문자열로 직렬화한다** (JS의 `Number` 정밀도 문제) |
| 페이지네이션 | 커서 방식. `?before=<id>&limit=30`. 응답에 `next_before`. **더 없으면(빈 목록 포함) `{"items": [], "next_before": null}`** |
| 단건 조회 | 없으면 `404 not_found`. 모든 조회 엔드포인트에 일관 적용 |
| 미디어 | `photo_url` 등은 `/media/`로 시작하는 상대 경로. 앱이 base URL을 붙인다 |

**보안은 이 프로젝트의 비목표다**([SPEC.md](SPEC.md) 1.2절). 토큰은 설치 시 발급한 익명 토큰이고, 만료도 갱신도 없다. rate limit도 없다.

### 에러 형식

```json
{ "error": { "code": "group_full", "message": "그룹 정원은 2명입니다" } }
```

| 상태 | `code` | 언제 |
|---|---|---|
| 400 | `invalid_request` | 필드 누락·형식 오류 |
| 401 | `unauthorized` | 토큰 없음·불일치 |
| 403 | `forbidden` | 내 그룹이 아닌 리소스 |
| 404 | `not_found` | 애초에 없는 id |
| 409 | `group_full` | 그룹 정원 2명 초과 |
| 409 | `already_member` | 이미 **그** 그룹의 멤버 |
| 409 | `already_in_group` | 이미 **다른** 그룹에 속해 있음. 유저는 그룹 하나에만 속한다 |
| 410 | `doodle_expired` | 있었지만 사라지기 모드로 삭제됨 (`deleted_at IS NOT NULL`) |
| 422 | `unprocessable` | 값은 맞지만 처리 불가 (예: `content_type=photo`인데 파일 없음) |

> **404와 410을 갈라 쓴다.** soft delete라 만료된 낙서도 행은 남아 있다. 앱이 "사라졌다"와 "잘못된 링크"를 구분해 보여줄 수 있어야 한다.

---

## 1. 헬스 · 디바이스

### `GET /health`

인증 불필요. Day 1 관통 확인용.

```json
{ "status": "ok", "db": "ok", "gpu": "ok", "time": "2026-07-10T14:03:00Z" }
```

`gpu`는 GPU 서버 두 포트(vLLM, sd-worker)의 헬스를 합친 값이다. `"down"`이어도 앱은 정상 동작해야 한다.

### `POST /devices` 🔒

FCM 토큰 등록. 앱 시작 시, 토큰이 바뀔 때마다 호출한다.

```json
{ "fcm_token": "cXY...", "app_version": "1.0.0" }
```
→ `204 No Content`. 같은 토큰이면 `last_active_at`만 갱신한다.

---

## 2. 인증 · 온보딩

### `POST /auth/register`

인증 불필요. 앱 최초 실행 시 딱 한 번. `users` 1행 + `auth_identities(provider='device')` 1행을 만든다.

```json
{ "display_name": "종화", "device_uid": "<앱이 생성한 UUID>" }
```
```json
{
  "token": "mp_...",
  "user": { "id": "1", "display_name": "종화" }
}
```

> 같은 `device_uid`로 다시 부르면 기존 유저의 토큰을 그대로 돌려준다(재설치 복구는 안 된다 — `device_uid`가 새로 생기기 때문). 소셜 로그인을 나중에 붙이면 같은 `user_id`에 `provider='kakao'` 행을 더한다. [SPEC.md](SPEC.md) 6.6절.

### `GET /me` 🔒

```json
{
  "user": { "id": "1", "display_name": "종화" },
  "group": { "id": "7", "name": "우리집" }
}
```
그룹이 없으면 `"group": null`. 앱은 이 값으로 온보딩을 계속할지 홈으로 갈지 정한다.

### `PATCH /me` 🔒 — ON-1, ST-1

```json
{ "display_name": "종화" }
```

---

## 3. 그룹

정원은 **2명**이다. DB가 트리거로 막고, 서버는 가입 트랜잭션에서 `groups` 행을 `FOR UPDATE`로 잠근다.

### `POST /groups` 🔒 — ON-2

그룹을 만들고 초대 코드를 발급한다. **부수 효과가 둘 있다.** `pets` 1행과 `style_models(kind='default', version=0, status='ready')` 1행이 함께 생긴다. 기본 그림체가 있어야 가입 첫날부터 일기가 그려진다.

이미 어떤 그룹의 멤버면 `409 already_in_group`. **유저는 그룹 하나에만 속한다** — `group_members`의 `UNIQUE(user_id)`가 선언적으로 막고, 서버도 생성 전에 확인한다. 이 불변식이 깨지면 `GET /me`가 어느 그룹을 돌려줄지, 소켓이 어느 룸에 조인할지 결정할 수 없게 된다.

```json
{ "name": "우리집", "pet_name": "삐삐" }
```
```json
{
  "group": {
    "id": "7", "name": "우리집", "invite_code": "K3M9QX2A",
    "background_color": "FFFFFF", "member_count": 1,
    "members": [ { "user_id": "1", "display_name": "종화", "nickname": null, "role": "owner" } ]
  },
  "pet": { "id": "3", "name": "삐삐", "level": 1, "exp": 0, "coins": 0 }
}
```

### `POST /groups/join` 🔒 — ON-3

```json
{ "invite_code": "K3M9QX2A" }
```
→ `200` + 위와 같은 그룹 객체. 정원 초과면 `409 group_full`, 이미 그 그룹 멤버면 `409 already_member`, **이미 다른 그룹에 속해 있으면 `409 already_in_group`.**

### `GET /groups/{group_id}` 🔒

### `PATCH /groups/{group_id}` 🔒 — GR-1, GR-2, ST-1

```json
{ "name": "우리집", "background_color": "FFE4E1" }
```

### `PATCH /groups/{group_id}/members/{user_id}` 🔒 — ON-4, ST-1

상대에게 별명을 지어준다.

```json
{ "nickname": "곰돌이" }
```

> 2인 그룹이라 "내가 상대에게 지어준 별명"과 "그룹 내 이 사람의 별명"이 같은 값이다. 그래서 `group_members.nickname` 한 컬럼으로 족하다. 자기 자신에게는 지을 수 없다 → `400`.

---

## 4. 낙서 ⭐

### `POST /doodles` 🔒 — SD-5, SD-6, RV-1

`multipart/form-data`. 답장(RV-1)도 같은 엔드포인트에 `parent_id`를 실어 보낸다.

| 필드 | 타입 | 필수 | 설명 |
|---|---|---|---|
| `mode` | `normal` \| `ephemeral` | ✅ | SD-5 / SD-6 |
| `content_type` | `photo` \| `drawing` \| `text` | ✅ | 앱이 판정해 보낸다. 서버는 재계산하지 않는다 |
| `parent_id` | string | | 답장 대상 |
| `text_body` | string | | |
| `photo` | file (jpeg/png) | | |
| `drawing` | file (png, 투명 배경) | | 사진 위에 얹는 손그림 레이어 |
| `stroke_data` | string (JSON) | | 아래 스키마 |

`content_type`에 따라 필수 파일이 다르다. `photo`면 `photo`, `drawing`이면 `drawing`+`stroke_data`, `text`면 `text_body`. 안 맞으면 `422 unprocessable`.

**`stroke_data` 스키마**

```json
{
  "canvas": { "w": 1080, "h": 1080 },
  "duration_ms": 12480,
  "strokes": [
    {
      "pen": "marker",
      "color": "FF5A5F",
      "width": 6,
      "points": [ [120, 340, 0], [124, 351, 16], [131, 366, 33] ]
    }
  ]
}
```

`points`의 세 번째 값은 **획 시작 시점부터의 경과 밀리초**다. Flutter의 `DragUpdateDetails.sourceTimeStamp`로 얻는다. `onPanEnd`에는 `sourceTimeStamp`가 없으므로 마지막 update 값을 재사용한다.

> **왜 타임스탬프를 받는가.** "이번 달 최고의 낙서"(MR-3)가 쓸 수 있는 견고한 행동 신호가 답장 수 하나뿐이다. 그리기 소요 시간이 그보다 나은 대리 지표가 된다. [SPEC.md](SPEC.md) 7절 ⑤.
>
> 수만 포인트로 커지면 `.json.gz`로 디스크에 빼고 DB엔 경로만 저장한다. 보통은 256KB 미만이라 JSON 컬럼으로 충분하다.

**응답** `201`

```json
{
  "id": "812", "group_id": "7", "sender_id": "1", "parent_id": null,
  "mode": "normal", "content_type": "drawing",
  "photo_url": "/media/g7/812_photo.jpg",
  "drawing_url": "/media/g7/812_draw.png",
  "thumb_url": "/media/g7/812_thumb.jpg",
  "text_body": null,
  "reply_count": 0,
  "viewed_by_me": true,
  "expires_at": null,
  "created_at": "2026-07-10T14:03:00Z"
}
```

전송 직후 룸에 `doodle:new`가 브로드캐스트되고, 상대에게 FCM `doodle_received`가 나간다(SD-8).

> **계산 필드에 주의.** `reply_count`(`parent_id`로 세는 값), `viewed_by_me`(`doodle_receipts` 조인), `thumb_url`은 **DB 컬럼이 아니다.** 서버가 조립해서 내려준다. `doodles` 테이블에는 없다([ERD.md](ERD.md)).

> **`thumb_url`은 유형별로 다르게 만들고, 절대 `null`이 되지 않는다.**
>
> | `content_type` | 썸네일 원본 |
> |---|---|
> | `photo` | `photo_url`의 축소본 |
> | `drawing` | `drawing_url`. 사진 위 레이어면 합성 렌더본 |
> | `text` | 서버가 `text_body`를 렌더한 미리보기 이미지 |
>
> 이걸 못 박아두지 않으면 **손그림과 텍스트 낙서에서 위젯이 빈칸이 된다.** 순수 손그림은 `photo_url`이 `NULL`이고, 텍스트 낙서는 유도할 원본 이미지 자체가 없다. 무거운 리사이즈는 앱 VM(RAM 4GB)에서 하지 않는다 — 13절 참조.

### `GET /groups/{group_id}/doodles` 🔒 — RV-2, RV-3, RV-4

사진첩. 최신순.

| 쿼리 | 설명 |
|---|---|
| `before` | 커서 (이 id보다 오래된 것) |
| `limit` | 기본 30, 최대 100 |
| `content_type` | 유형 필터 (RV-3) |
| `date` | `YYYY-MM-DD` 하루치 |

```json
{ "items": [ /* 낙서 객체 */ ], "next_before": "780" }
```

**사라지기 모드로 삭제된 낙서는 목록에 나오지 않는다.** 아직 확인 전인 `ephemeral` 낙서는 나온다.

### `GET /doodles/{doodle_id}` 🔒 — RV-4

이미 만료됐으면 `410 doodle_expired`.

### `POST /doodles/{doodle_id}/view` 🔒 ⭐ — SD-6

**사라지기 모드의 방아쇠.** 수신자가 뷰어에서 낙서를 연 순간 호출한다.

- `doodle_receipts`에 최초 확인 시각(`viewed_at`)을 기록한다. `UNIQUE(doodle_id, user_id)`가 중복을 막으므로 **몇 번 불러도 안전하다**(멱등).
- `mode='ephemeral'`이고, **보낸 사람이 내가 아니고, 이번이 최초 확인이면**(receipt가 새로 삽입된 경우) `expires_at = viewed_at + 5s`를 세팅하고 5초 타이머를 건다.
- **이미 확인한 낙서를 다시 열면 저장된 `expires_at`을 그대로 돌려주고 타이머를 재무장하지 않는다.**
- 5초 뒤 서버가 `deleted_at`을 채우고 미디어 파일을 실제로 지운 다음 `doodle:expired`를 룸에 쏜다.

```json
{ "expires_at": "2026-07-10T14:03:05Z" }
```
`normal`이면 `{"expires_at": null}`.

> **최초 확인 게이트가 없으면 낙서가 영영 사라지지 않는다.** 뷰어를 닫았다 다시 열 때마다 `expires_at`이 갱신되고 타이머가 재무장되기 때문이다. receipt는 멱등인데 만료는 멱등이 아닌, 놓치기 쉬운 구멍이다. 기준 시각도 `now`가 아니라 **`viewed_at`** 이다 — [ERD.md](ERD.md), [STACK.md](STACK.md) 6절, `schema.sql`이 모두 그렇게 적혀 있다.

> 타이머는 프로세스 인메모리다. 서버가 죽으면 기동 시 부팅 스윕이 `expires_at`을 훑어 정리한다. 그래서 uvicorn을 **단일 프로세스**로 돌린다. [STACK.md](STACK.md) 6절.

### `POST /groups/{group_id}/pokes` 🔒 ⭐ — SD-7

```json
{ "to_user_id": "2" }
```
→ `204`. 룸에 `poke` 이벤트 + FCM `poke`.

---

## 5. 펫 ⭐

### `GET /groups/{group_id}/pet` 🔒

앱의 첫 화면(홈)이 이걸로 그려진다.

```json
{
  "id": "3", "name": "삐삐", "level": 4, "exp": 320, "coins": 150,
  "is_public": true,
  "current_activity": { "activity": "sleeping", "started_at": "2026-07-10T13:40:00Z" },
  "equipped_items": [ { "item_id": "12", "category": "hat", "asset_url": "/media/items/hat_12.png" } ]
}
```

`current_activity`는 `ended_at IS NULL`인 행이다. 없으면 `null`(펫이 아직 첫 활동을 못 받은 상태).

### `POST /pets/{pet_id}/pat` 🔒 ⭐ — PT-1

쓰다듬기. **LLM을 부르지 않는다.** 현재 활동 행의 `utterance`를 그대로 돌려준다.

```json
{
  "activity": "sleeping",
  "utterance": "방금 밥 먹고 졸려… 그림 잘 봤어!",
  "exp_gained": 1
}
```

> 사용자가 연타할 수 있는 인터랙션이라 매 탭마다 추론을 돌리면 GPU가 버티지 못한다. `pet_activities` 테이블 자체가 캐시다. 활동이 바뀔 때만 새 대사가 생긴다.
>
> 활동이 없으면 `503 gpu_unavailable`이 아니라 **기본 대사를 돌려준다.** GPU가 죽어도 펫은 말을 해야 한다.

### `GET /pets/{pet_id}/diaries` 🔒 — PT-6a

일기장. 최신순.

```json
{
  "items": [
    {
      "id": "45", "entry_date": "2026-07-09",
      "image_url": "/media/g7/diary_45.png",
      "caption": "오늘은 낮잠을 오래 잤다. 둘이 보내준 그림이 좋았다.",
      "style": { "kind": "learned", "version": 1 },
      "activities": ["eating", "sleeping", "playing"]
    }
  ],
  "next_before": "30"
}
```

`style.kind`가 `default`에서 `learned`로 바뀌는 날이 **"펫이 우리 그림체를 배운 날"** 이다. 앱은 그 경계를 시각적으로 표시하면 좋다.

**일기는 자정 배치로 생긴다.** 가입 첫날 첫 자정 이전에는 일기장이 비어 있고, 그때 `{"items": [], "next_before": null}`이 내려간다. 앱은 이 상태를 정상으로 그려야 한다 — 에러가 아니다.

### `GET /pets/{pet_id}/diaries/{entry_date}` 🔒

`entry_date`는 `YYYY-MM-DD`. 그날의 일기 객체 하나를 돌려준다(위 목록의 `items[]` 원소와 같은 모양).

그날 일기가 없으면 `404 not_found`. 자정 배치가 아직 안 돌았거나, GPU 서버가 죽어 그날 일기를 만들지 못한 경우다. `pet_diaries`는 `image_url`·`caption`이 `NOT NULL`이라 **부분 저장이 불가능하다.** "그날 일기 없음"이 정상 동작이다.

---

## 6. 월간 레포트 — MR-1 ~ MR-4

### `GET /groups/{group_id}/reports` 🔒

`{ "items": [ { "report_month": "2026-06", "generated_at": "..." } ] }`

### `GET /groups/{group_id}/reports/{YYYY-MM}` 🔒

```json
{
  "report_month": "2026-06",
  "photo_count": 21, "drawing_count": 34, "text_count": 5, "poke_count": 12,
  "dominant_type": "drawing",
  "pet_level_start": 2, "pet_level_end": 4,
  "best_doodle": {
    "id": "704",
    "rule": "most_replies",
    "content_type": "drawing",
    "photo_url": null,
    "drawing_url": "/media/g7/704_draw.png",
    "thumb_url": "/media/g7/704_thumb.jpg",
    "text_body": null,
    "created_at": "2026-06-14T21:11:00Z"
  }
}
```

`rule`은 `most_replies` → `most_strokes` → `latest` 순으로 결정된다([SPEC.md](SPEC.md) 6.5절). 나중에 vision을 도입하면 값이 늘어나므로, 앱은 **모르는 값을 만나도 죽지 않아야 한다.**

> **선정은 답장 수 기준이라 유형을 가리지 않는다.** 최고의 낙서가 `photo`일 수도 `text`일 수도 있다. 승자가 `photo`면 `photo_url`·`thumb_url`이, `drawing`이면 `drawing_url`·`thumb_url`이, `text`면 `text_body`·`thumb_url`이 채워지고 나머지는 `null`이다. **앱은 `content_type`으로 분기해 렌더한다.** `drawing_url` 하나만 내려주면 사진이나 텍스트가 뽑힌 달에 빈 화면이 뜬다.

레포트가 없으면 `404 not_found`.

### `POST /groups/{group_id}/reports/{YYYY-MM}/generate` 🔒

**데모용 수동 트리거.** MR-3는 월 1회 배치라 7일 안에 자연 실행이 한 번도 일어나지 않는다. 시연 때 손으로 띄운다. 이미 있으면 덮어쓴다.

---

## 7. 위젯 — RV-5

### `GET /widget/{group_id}` 🔒

홈 화면 위젯 전용. **가볍게 유지한다.** 위젯은 배터리 제약 아래서 돈다.

```json
{
  "doodle_id": "812",
  "content_type": "drawing",
  "thumb_url": "/media/g7/812_thumb.jpg",
  "sender_nickname": "곰돌이",
  "created_at": "2026-07-10T14:03:00Z",
  "is_ephemeral": false
}
```

`content_type`이 있어야 위젯이 유형별로 다르게 그릴 수 있다. `thumb_url`은 세 유형 모두에서 채워진다(4절).

낙서가 하나도 없으면 `{"doodle_id": null}`을 돌려준다. 위젯은 빈 상태를 그린다.

`is_ephemeral`이 `true`면 위젯은 **썸네일을 보여주지 않는다.** 위젯에 띄우는 순간 "확인"으로 볼 수 없기 때문이다. 자물쇠 아이콘만 띄우고 탭하면 앱 뷰어로 들어가 거기서 `POST /doodles/{id}/view`가 나간다.

위젯 탭 → **낙서 사진첩**으로 진입한다([SPEC.md](SPEC.md) 2절).

---

## 8. P2 — 잘라낼 수 있는 것

### 다른 그룹 펫 구경하기 (EX-1 ~ EX-3)

| Method | Endpoint | 설명 |
|---|---|---|
| `GET` | `/pets/explore?before=&limit=` | 공개 펫 목록. 옆으로 넘기기 (EX-3) |
| `GET` | `/pets/by-code/{invite_code}` | 코드로 찾아가기 (EX-2) |
| `POST` | `/pets/{pet_id}/like` | 좋아요 (EX-1). 멱등 |
| `DELETE` | `/pets/{pet_id}/like` | 취소 |

### 스토어 (PT-2 ~ PT-4)

| Method | Endpoint | 설명 |
|---|---|---|
| `GET` | `/items?category=` | 카탈로그 |
| `POST` | `/pets/{pet_id}/items` | `{"item_id":"12"}` 구매. 코인 부족 시 `422` |
| `PATCH` | `/pets/{pet_id}/items/{item_id}` | `{"is_equipped":true,"pos_x":40,"pos_y":12}` |

---

## 9. 실시간 — Socket.IO ⭐

**네임스페이스** `/rt` · **룸** `group:{group_id}` · **transport** WebSocket 전용

연결 시 `auth: { token: "mp_..." }`를 보낸다. 서버가 토큰으로 유저를 찾아 그 사람의 그룹 룸에 자동 조인시킨다.

Flutter는 `setTransports(['websocket'])`를 **반드시 명시한다.** 네이티브 dart:io는 polling을 지원하지 않는다.

### 서버 → 클라이언트

| 이벤트 | 페이로드 | 기능 |
|---|---|---|
| `doodle:new` | `{doodle_id, sender_id, mode, content_type, created_at}` — **`thumb_url`은 `mode=normal`일 때만 포함** | SD-5, SD-6 |
| `doodle:expired` | `{doodle_id}` | SD-6 |
| `poke` | `{from_user_id, at}` | SD-7 |
| `pet:activity` | `{pet_id, activity, utterance}` | PT-1 — 활동이 바뀔 때 |
| `pet:levelup` | `{pet_id, level}` | |
| `diary:new` | `{diary_id, entry_date, style_kind}` | PT-6a — 자정 배치 후 |

> **사라지기 모드는 썸네일을 싣지 않는다.** `mode=ephemeral`인 `doodle:new`에 `thumb_url`을 넣으면, 소켓이 붙어 있는 수신자가 **뷰어를 열기도 전에 내용을 받아 캐시한다.** 그러면 `doodle_receipts`가 찍히지 않아 타이머가 걸리지 않고, 미디어 파일이 영영 지워지지 않으며, 확인 집계에서도 빠진다. 위젯(7절)과 FCM(10절)은 이미 이 불변식을 지킨다. **소켓만 예외일 이유가 없다.**
>
> 수신자는 반드시 `POST /doodles/{id}/view`(또는 `doodle:viewed`)를 거쳐야 내용을 본다.

### 클라이언트 → 서버

| 이벤트 | 페이로드 | 비고 |
|---|---|---|
| `doodle:viewed` | `{doodle_id}` | `POST /doodles/{id}/view`와 **동등하다.** 소켓이 붙어 있으면 이쪽이 왕복이 짧다 |
| `poke:send` | `{to_user_id}` | `POST .../pokes`와 동등 |

> 두 경로를 다 두는 이유는 앱이 백그라운드에서 깨어났을 때 소켓이 아직 안 붙어 있을 수 있기 때문이다. REST가 항상 되는 길이고 소켓은 빠른 길이다. **서버는 둘을 같은 함수로 처리한다.**

### 하트비트 · 재연결

Socket.IO 기본 `pingInterval` 25초가 Cloudflare Tunnel의 유휴 종료를 막는다. Tunnel의 실제 유휴 타임아웃은 보고가 20~100초로 갈리므로 **데모 전에 실측한다**([STACK.md](STACK.md) 9절).

재연결 시 앱은 `GET /groups/{id}/doodles?limit=30`을 다시 불러 놓친 이벤트를 메운다. 소켓 이벤트는 유실될 수 있고, **REST가 진실의 원본이다.**

---

## 10. FCM — 푸시

전부 **data-only 메시지**다. notification 페이로드를 쓰지 않는다(위젯을 갱신해야 하므로).

| `type` | 추가 필드 | 기능 |
|---|---|---|
| `doodle_received` | `doodle_id`, `sender_nickname`, `is_ephemeral` | SD-8 |
| `poke` | `from_nickname` | SD-7 |
| `monthly_report` | `report_month` | MR-1 → 탭하면 **월간 레포트 뷰어** |
| `widget_refresh` | — | 위젯만 갱신 |

> **백그라운드 위젯 갱신은 보장되지 않는다.** Doze와 제조사 배터리 최적화에 좌우된다. 열화 설계로 간다 — 앱 열기 갱신 + `workmanager` 주기 폴링 + 위젯 탭 콜백. 실제 지연은 데모 기기에서 잰다.

---

## 11. 내부 API — 앱 VM → GPU 서버

**인터넷에 노출하지 않는다. 인증도 없다**(내부망, 보안 비목표).

두 서버가 서로 보인다는 전제다. `curl`로 확인하지 못하면 **GPU 서버가 앱 VM의 잡 큐를 폴링하는 아웃바운드 전용 구조**로 바꾼다([SPEC.md](SPEC.md) 7절 ⑧). 그 경우 아래 요청/응답 스키마는 그대로 두고 전송 방식만 바뀐다.

### 11-1. vLLM (`:8100`) — OpenAI 호환

`POST /v1/chat/completions`로 펫 활동과 일기 캡션을 만든다. **응답을 JSON 스키마로 강제한다** — `activity`가 자유 문자열이면 SD 프롬프트를 조립할 수 없다.

```json
{
  "activity": "sleeping",
  "utterance": "방금 밥 먹고 졸려… 그림 잘 봤어!"
}
```

`activity`는 `eating | sleeping | walking | playing | drawing | waiting` 여섯 개뿐이다.

> ⚠️ **구조화 출력의 정확한 파라미터 이름은 확인이 필요하다.** vLLM 0.24.0에서 `guided_json`인지 `response_format: {type: "json_schema"}`인지 실제로 띄워 보고 확정한다.

관리용 엔드포인트 (`VLLM_SERVER_DEV_MODE=1` 필요):

| Method | Path | 용도 |
|---|---|---|
| `POST` | `/sleep?level=1` | 가중치를 CPU RAM에 오프로드하고 GPU를 비운다 |
| `POST` | `/wake_up` | 3~6초 만에 복귀 |
| `GET` | `/is_sleeping` | 상태 확인 |

### 11-2. sd-worker (`:8200`) — 직접 만든 FastAPI

| Method | Path | 설명 |
|---|---|---|
| `GET` | `/health` | |
| `POST` | `/generate/diary` | 일기 그림 1장 생성 |
| `POST` | `/train/lora` | P2. LoRA 학습 잡 시작 |
| `GET` | `/train/lora/{job_id}` | P2. 상태 조회 |

**`POST /generate/diary`**

```json
{
  "group_id": "7",
  "entry_date": "2026-07-09",
  "activities": ["eating", "sleeping", "playing"],
  "caption": "오늘은 낮잠을 오래 잤다.",
  "style": { "kind": "default", "weights_path": null }
}
```
→ `200`, `image/png` 바이트를 그대로 돌려준다. **앱 VM이 받아서 저장한다.**

> **동기 호출로 간다.** 생성이 10~30초 걸리므로 `httpx` 타임아웃을 넉넉히 잡는다. 자정 배치라 지연이 문제되지 않는다. 만약 타임아웃을 넘기면 잡 큐 + 콜백으로 바꾼다.
>
> sd-worker는 SD를 올리기 전에 vLLM에 `POST /sleep`을 보낼 필요가 **없다.** 상주 LLM(8GB) + SD 추론(4~6GB) = 12~14GB로 20GB에 들어간다([STACK.md](STACK.md) 2절). LoRA 학습(`/train/lora`)만 sleep이 필요하다.

---

## 12. 기능 커버리지

기능정의서의 모든 항목이 어디로 가는지. **빠진 게 있으면 이 표에서 드러난다.**

| ID | 기능 | 어디서 |
|---|---|---|
| ON-1 | 내 이름 작성하기 | `POST /auth/register`, `PATCH /me` |
| ON-2 | 그룹 만들기 | `POST /groups` |
| ON-3 | 그룹 가입 | `POST /groups/join` |
| ON-4 | 별명 지어주기 | `PATCH /groups/{id}/members/{uid}` |
| GR-1 | 그룹 이름 변경 | `PATCH /groups/{id}` |
| GR-2 | 배경 색상 변경 | `PATCH /groups/{id}` |
| ST-1 | 설정 화면 | `PATCH /me`, `PATCH /groups/{id}`, `PATCH .../members/{uid}` |
| SD-1 | 펜 선택 | **클라이언트 전용.** `stroke_data.strokes[].pen`으로 전달 |
| SD-2 | 색깔 선택 | **클라이언트 전용.** `stroke_data.strokes[].color` |
| SD-3 | 사진 찍기 | **클라이언트 전용.** `POST /doodles`의 `photo` 파일 |
| SD-4 | 사진 선택 | **클라이언트 전용.** 위와 같음 |
| SD-5 | 일반 모드 | `POST /doodles` (`mode=normal`) |
| SD-6 | 사라지기 모드 ⭐ | `POST /doodles` (`mode=ephemeral`) + `POST /doodles/{id}/view` + `doodle:expired` |
| SD-7 | 찌르기 ⭐ | `POST /groups/{id}/pokes` 또는 `poke:send` |
| SD-8 | 낙서 수신 푸시 ⭐ | FCM `doodle_received` |
| RV-1 | 답장 보내기 | `POST /doodles` (`parent_id`) |
| RV-2 | 사진첩 날짜 정렬 | `GET /groups/{id}/doodles` |
| RV-3 | 낙서 유형 표시 | 응답의 `content_type`, `?content_type=` 필터 |
| RV-4 | 앱 뷰어 | `GET /groups/{id}/doodles`, `GET /doodles/{id}` |
| RV-5 | 위젯 뷰어 ⭐ | `GET /widget/{group_id}` |
| PT-1 | 쓰다듬기 ⭐ | `POST /pets/{id}/pat` + `pet:activity` |
| PT-2 | 펫 커스텀 (P2) | `PATCH /pets/{id}/items/{item_id}` |
| PT-3 | 펫 집 꾸미기 (P2) | 위와 같음 (`pos_x`, `pos_y`) |
| PT-4 | 펫 스토어 (P2) | `GET /items`, `POST /pets/{id}/items` |
| PT-5 | 그림체 학습 (P2) | 내부 `POST /train/lora` |
| PT-6a | 그림 일기 (기본 그림체) ⭐ | `GET /pets/{id}/diaries` + 내부 `POST /generate/diary` |
| PT-6b | 그림체 전환 (P2) | 응답의 `style.kind` |
| EX-1 | 좋아요 (P2) | `POST /pets/{id}/like` |
| EX-2 | 찾아가기 (P2) | `GET /pets/by-code/{code}` |
| EX-3 | 옆으로 넘기기 (P2) | `GET /pets/explore` |
| MR-1 | 월간 알람 | FCM `monthly_report` |
| MR-2 | 펫 성장 표시 | `GET .../reports/{YYYY-MM}` |
| MR-3 | 이번 달 최고의 낙서 | 위와 같음 (`best_doodle`) |
| MR-4 | 낙서 유형 분포 | 위와 같음 (`*_count`, `dominant_type`) |

**36행 전부 매핑됐다.** SD-1~4는 서버가 관여하지 않는 클라이언트 전용 기능이다.

---

## 13. 미확정

- **구조화 출력 파라미터** — vLLM 0.24.0의 정확한 필드명(11-1절)
- **`exp` 증가 규칙** — 낙서 전송·답장·찌르기·쓰다듬기가 각각 몇 exp인지, 레벨업 곡선. 게임 밸런스라 코드보다 먼저 정할 필요는 없다
- **코인 획득 규칙** — 스토어의 전제인데 획득 경로가 정의되지 않았다([BACKLOG.md](BACKLOG.md) A절)
- **펫 활동 생성 주기** — 하루 몇 번인지. 3~5회로 시작해 보고 조정
- **썸네일 생성 위치** — 앱 VM은 RAM이 4GB뿐이다. 앱이 업로드 시 함께 올리는 편이 나을 수 있다
- **텍스트 낙서의 썸네일 원본** — `photo_url`도 `drawing_url`도 없어 유도할 이미지가 아예 없다. 서버가 텍스트를 렌더한 미리보기를 만들지, 아니면 위젯이 텍스트를 직접 그릴지(그러려면 위젯 응답에 `text_body`가 필요) 정해야 한다
- **`stroke_data` 임계 초과 시의 응답 형태** — `.json.gz`로 빼면 경로만 남는데, 그때 응답 필드가 어떻게 달라지는지 아직 안 정했다. P2 최적화라 미룬다

---

## 14. 이 문서의 검토 이력

**2026-07-10, 적대적 검토 1차.** 커버리지·스키마 정합·상태 전이·앱 통합 네 렌즈로 29건이 지적됐고, 각 지적을 별도 검증자가 파일을 다시 읽어 반증한 결과 8건이 살아남았다. 그중 6건을 이 문서와 `schema.sql`에 반영했다.

가장 심각했던 것은 **소켓 `doodle:new`가 사라지기 낙서의 썸네일을 무조건 실어 SD-6를 무력화하던 것**이다. 위젯과 FCM은 "확인 전 노출 금지" 불변식을 지키는데 소켓만 깨고 있었다. 세 채널을 나란히 놓고 봐야 드러나는 종류의 결함이라, 단위 테스트로는 잡히지 않았을 것이다.

기각된 지적 중 반복되기 쉬운 것들: `viewed_by_me`가 발신자에게 `true`인 것은 모순이 아니다(발신자 규칙은 문서에 없다). 커버리지 표가 조회 엔드포인트를 안 담은 것은 전방 매핑이라 정상이다. `is_public` 토글 부재는 EX-1~3이 전부 P2라 문제가 아니다. `POST /doodles`에 멱등키가 없는 것은 create가 본질적으로 비멱등이기 때문이다.
