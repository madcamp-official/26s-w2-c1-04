# Memory Pager — 프론트 연결 가이드 (Flutter)

> 이 문서는 **"어떻게 붙이는가"**를 담는다. 필드·엔드포인트의 **원본 계약은 [API.md](API.md)** 이고, 여기에 없는 필드는 없는 것이다.
> 서버는 지금 **라이브**다. 아래 값만 넣으면 바로 붙는다.

> **현황(2026-07-13):** 프론트가 **`front-remake` 브랜치(worktree `mp-design`)로 0부터 재구축**됐고, 현재는 **mock 우선**(`lib/mock.dart` 전역 싱글턴)으로 구동된다 — 실서버 미연결 상태. 따라서 이 문서의 REST/Socket 계약·핸드셰이크·주의점은 **"mock → 실물 교체 시" 그대로 적용**하면 된다(계약 자체는 안 바뀜). 구 앱(`jonghklee` 브랜치)의 `RestRepository`/`SocketRealtime` 는 배선 참고자료로만 본다. 아래 계약(엔드포인트·이벤트·에러) 본문은 그대로 유효.

---

## 0. TL;DR — 이 세 개만 넣으면 된다

| 용도 | 값 |
|---|---|
| REST base | `https://anjonghwa.madcamp-kaist.org/v1` |
| Socket.IO | host `https://anjonghwa.madcamp-kaist.org`, path `/socket.io`, **namespace `/rt`**, transport **`websocket` 고정** |
| 미디어 | 응답의 `/media/...` 상대경로 앞에 `https://anjonghwa.madcamp-kaist.org` 를 붙인다 |

- 인증: `POST /v1/auth/register` 로 받은 `token` 을 이후 모든 요청에 `Authorization: Bearer <token>`.
- 시각은 전부 **UTC ISO8601**(`...Z`), 앱에서 로컬로 변환. **ID는 문자열**(64bit 정밀도).
- CORS `*` 라 웹/모바일 다 됨. TLS·도메인은 서버가 처리(앱은 평문 걱정 없음).

---

## 1. 붙기 전에 30초 스모크 (터미널)

```bash
# 1) 살아있나
curl -s https://anjonghwa.madcamp-kaist.org/v1/health
# {"status":"ok","db":"ok","gpu":"ok","time":"..."}

# 2) 가입 → 토큰
curl -s -X POST https://anjonghwa.madcamp-kaist.org/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"display_name":"테스트","device_uid":"flutter-dev-0001"}'
# {"token":"mp_...","user":{"id":"...","display_name":"테스트"}}

# 3) 토큰으로 내 정보
curl -s https://anjonghwa.madcamp-kaist.org/v1/me -H "Authorization: Bearer <위 token>"
# {"user":{...},"group":null}
```

`gpu:"ok"` 면 펫 대사(LLM)·그림 일기(SD)까지 실동작. `"down"` 이어도 앱은 정상(스텁으로 열화).

---

## 2. Flutter 의존성

```yaml
# pubspec.yaml
dependencies:
  dio: ^5.7.0                 # REST (http 패키지 써도 됨)
  socket_io_client: ^3.1.0    # 실시간
  flutter_secure_storage: ^9.2.2   # 토큰 저장 (선택)
```

---

## 3. 인증 · 온보딩 흐름

앱 최초 실행 → **한 번** `register` → 토큰 저장. 이후엔 저장한 토큰만 쓴다.

```dart
class Api {
  static const base = 'https://anjonghwa.madcamp-kaist.org/v1';
  static const host = 'https://anjonghwa.madcamp-kaist.org';
  final Dio dio;
  String? token;

  Api() : dio = Dio(BaseOptions(baseUrl: base)) {
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (token != null) o.headers['Authorization'] = 'Bearer $token';
      h.next(o);
    }));
  }

  // 앱 첫 실행 딱 한 번. device_uid 는 앱이 만든 UUID (8자 이상!), 기기에 영구 저장.
  Future<void> register(String name, String deviceUid) async {
    final r = await dio.post('/auth/register',
        data: {'display_name': name, 'device_uid': deviceUid});
    token = r.data['token'];               // 저장(secure storage)
  }

  Future<Map?> me() async => (await dio.get('/me')).data['group']; // null 이면 온보딩
}
```

**온보딩 분기:** `register` → `GET /me` → `group == null` 이면 **그룹 생성** 또는 **초대코드로 참여**, 있으면 홈으로.

```dart
// 그룹 생성 (펫 + 기본 그림체가 같이 생김)
final g = await dio.post('/groups', data: {'name': '우리집', 'pet_name': '삐삐'});
final gid = g.data['group']['id'];
final inviteCode = g.data['group']['invite_code'];   // 상대에게 공유

// 초대코드로 참여
await dio.post('/groups/join', data: {'invite_code': 'K3M9QX2A'});
```

> **한 유저는 그룹 하나에만 속한다.** 이미 다른 그룹이면 `409 already_in_group`, 정원(2명) 초과면 `409 group_full`, 이미 그 그룹이면 `409 already_member`.

---

## 4. Socket.IO 연결 — ⭐ 실시간 (과제 주 옵션)

**반드시 `websocket` 트랜스포트 고정.** Cloudflare 터널은 WS만 확실히 통과하고, dart:io 는 polling 을 못 한다.

```dart
import 'package:socket_io_client/socket_io_client.dart' as IO;

IO.Socket connectRealtime(String token) {
  final socket = IO.io(
    '${Api.host}/rt',                        // 네임스페이스 /rt 를 URL 에 붙인다
    IO.OptionBuilder()
      .setTransports(['websocket'])          // 필수
      .setPath('/socket.io')                 // 엔진 경로 (기본값)
      .setAuth({'token': token})             // ← 여기로 토큰 전달 (헤더 아님)
      .enableForceNew()
      .build(),
  );

  socket.onConnect((_) => print('rt 연결됨'));
  socket.onConnectError((e) => print('rt 연결 실패: $e'));  // 토큰 틀리면 연결 거부

  // 서버 → 클라이언트 이벤트 (전부 group 룸으로 브로드캐스트)
  socket.on('doodle:new',     (d) { /* 새 낙서 도착 → 사진첩·위젯 갱신 */ });
  socket.on('doodle:expired', (d) { /* {doodle_id} 사라짐 → 뷰어 닫기 */ });
  socket.on('poke',           (d) { /* {from_user_id, at} 찌르기 */ });
  socket.on('pet:activity',   (d) { /* {pet_id, activity, utterance} 활동 바뀜 */ });
  socket.on('pet:levelup',    (d) { /* {pet_id, level} 레벨업 */ });
  socket.on('diary:new',      (d) { /* {diary_id, entry_date, style_kind} 새 일기 */ });

  socket.connect();
  return socket;
}
```

> **그룹 가입 전에 연결하면** 룸에 못 들어간다(연결은 되지만 이벤트를 못 받음). **그룹 생성/참여 직후 소켓을 재연결**하면 서버가 `group:{id}` 룸에 자동 조인시킨다.

### 클라이언트 → 서버 이벤트 (ack 로 결과 받음)

REST 와 **동등**하다. 빠른 길일 뿐이고, 안 되면 REST 로 폴백하면 된다. dart 클라이언트의 ack 는
**콜백**으로 온다(`await` 아님).

```dart
// 사라지기 낙서 확인 (REST POST /doodles/{id}/view 와 같은 일)
socket.emitWithAck('doodle:viewed', {'doodle_id': '812'}, ack: (resp) {
  if (resp['error'] != null) { /* {code,message} */ }
  else { final expiresAt = resp['expires_at']; /* 카운트다운 시작 */ }
});

// 찌르기 (REST POST /groups/{gid}/pokes 와 같은 일)
socket.emitWithAck('poke:send', {'to_user_id': '2'}, ack: (resp) {
  if (resp['error'] != null) { /* 실패 처리 */ }
});
```

ack 는 **성공이든 실패든 항상 객체**로 온다. `resp['error'] != null` 로 분기.
async/await 로 쓰고 싶으면 `Completer` 로 감싼다:

```dart
Future<Map> emitAck(IO.Socket s, String ev, dynamic data) {
  final c = Completer<Map>();
  s.emitWithAck(ev, data, ack: (r) => c.complete(Map<String, dynamic>.from(r)));
  return c.future;
}
```

---

## 5. 낙서 보내기 — multipart

`content_type` 별로 실어야 할 게 다르다. 답장도 같은 엔드포인트에 `parent_id`.

```dart
// 손그림
final form = FormData.fromMap({
  'mode': 'normal',                    // 또는 'ephemeral' (사라지기)
  'content_type': 'drawing',
  'stroke_data': jsonEncode(strokeJson),   // JSON "문자열" 로
  'drawing': await MultipartFile.fromFile(pngPath, filename: 'd.png'),
  // 'parent_id': '812',               // 답장이면
});
final r = await dio.post('/doodles', data: form);  // 201 + 낙서 객체
```

| content_type | 필수 필드 |
|---|---|
| `photo` | `photo` (파일) |
| `drawing` | `drawing` (파일) + `stroke_data` (JSON 문자열) |
| `text` | `text_body` |

`stroke_data` 스키마와 `points` 의 타임스탬프 규칙은 [API.md](API.md) 4절 참조(`DragUpdateDetails.sourceTimeStamp`).

보내면 상대 룸에 `doodle:new` 가 즉시 브로드캐스트된다.

---

## 6. 사라지기 모드 (SD-6) — ⭐ 흐름 주의

받는 사람 기준:

1. 사진첩/뷰어에서 아직 안 연 `ephemeral` 낙서는 **내용 필드가 전부 `null`**(`photo_url`·`drawing_url`·`thumb_url`·`text_body`). 메타데이터만 온다.
2. 뷰어를 **연 순간** `POST /doodles/{id}/view` (또는 소켓 `doodle:viewed`) 호출 → `{"expires_at":"...Z"}` 수신.
3. 그 시각까지 카운트다운 UI 를 그린다(TTL 5초). **`expires_at` 기준으로 그릴 것**(now 아님).
4. 5초 뒤 서버가 실제 삭제하고 룸에 `doodle:expired {doodle_id}` 를 쏜다 → 뷰어 닫기.

> 재열람해도 `expires_at` 은 **처음 값 그대로**(타이머 재무장 안 함). `view` 는 몇 번 불러도 안전(멱등). 보낸 사람에겐 처음부터 내용이 보이고 만료도 안 걸린다.

---

## 7. 첫 화면들에 필요한 조회

```dart
// 홈 = 펫 (PT-1)
final pet = await dio.get('/groups/$gid/pet');
// {id,name,level,exp,coins,current_activity:{activity,started_at}|null, equipped_items:[...]}

// 쓰다듬기 — LLM 안 부름, 현재 활동 대사 즉답 (연타 안전)
final pat = await dio.post('/pets/$petId/pat');
// {activity, utterance, exp_gained}

// 사진첩 (커서 페이지네이션)
final list = await dio.get('/groups/$gid/doodles',
    queryParameters: {'limit': 30, if (cursor != null) 'before': cursor});
// {items:[...], next_before:"780"|null}

// 그림 일기장 / 단건
await dio.get('/pets/$petId/diaries');            // {items:[...], next_before}
await dio.get('/pets/$petId/diaries/2026-07-11'); // 없으면 404 (정상)

// 위젯용 (홈스크린 위젯, 가볍게)
await dio.get('/widget/$gid');   // {doodle_id|null, content_type, thumb_url, sender_nickname, ...}

// 월간 레포트 (월간 알람 → 이 뷰어)
await dio.get('/groups/$gid/reports');            // {items:[{report_month, generated_at}]}
await dio.get('/groups/$gid/reports/2026-06');    // 집계 + 최고의 낙서
```

전체 필드는 [API.md](API.md) 5·6·7절.

---

## 8. 미디어 URL

응답의 이미지 경로는 **상대경로**(`/media/g7/812_thumb.jpg`). 앱에서 호스트를 붙인다.

```dart
String mediaUrl(String? path) =>
    path == null ? '' : 'https://anjonghwa.madcamp-kaist.org$path';

Image.network(mediaUrl(doodle['thumb_url']));
```

`thumb_url` 은 사진·손그림·텍스트 **세 유형 모두**에서 채워진다(안 연 사라지기 낙서만 `null`).

---

## 9. 에러 처리

모든 에러는 같은 봉투다.

```json
{ "error": { "code": "group_full", "message": "그룹 정원은 2명입니다" } }
```

| status | code | 언제 | 앱 처리 |
|---|---|---|---|
| 400 | `invalid_request` | 필드 누락/형식 | 입력 검증 |
| 401 | `unauthorized` | 토큰 없음/불일치 | 재가입 or 재로그인 |
| 403 | `forbidden` | 내 그룹 아님 | 접근 차단 |
| 404 | `not_found` | 없는 id | "없음" 표시 |
| 409 | `group_full` / `already_member` / `already_in_group` | 그룹 정원·중복 | 온보딩 분기 |
| 410 | `doodle_expired` | 사라진 낙서 | **"사라졌어요"** (404 와 구분!) |
| 413 | `payload_too_large` | 이미지/stroke 초과 | 압축 후 재시도 |
| 422 | `unprocessable` | 값은 맞지만 처리 불가 | 필수 파일 확인 |

```dart
try {
  await dio.post(...);
} on DioException catch (e) {
  final code = e.response?.data?['error']?['code'];
  if (code == 'doodle_expired') showGone();   // 410 ≠ 404
}
```

---

## 10. 붙일 때 체크리스트

- [ ] `device_uid` **8자 이상** (짧으면 422). 기기에 영구 저장, 재설치 전까지 고정.
- [ ] 소켓 **`setTransports(['websocket'])`** 필수.
- [ ] 소켓 토큰은 **`setAuth({'token': ...})`** 로 (헤더 아님).
- [ ] **그룹 가입 직후 소켓 재연결** (룸 조인).
- [ ] ID 는 전부 **문자열**로 다룰 것 (JSON 이 문자열로 내려줌).
- [ ] 미디어 경로에 **호스트 prefix**.
- [ ] 사라지기: `expires_at` 기준 카운트다운, `doodle:expired` 로 닫기.
- [ ] 410 과 404 를 **다르게** 보여줄 것.

---

## 11. 아직 안 되는 것 — FCM 백그라운드 푸시

- `POST /devices {fcm_token, app_version}` 엔드포인트는 **지금 호출해도 됨**(토큰만 저장, 안전).
- 다만 서버에 **Firebase 프로젝트가 아직 없어 실제 푸시는 안 나간다.** 즉:
  - 앱이 **포그라운드면** 위 Socket.IO 이벤트로 낙서 수신·찌르기·만료를 **전부 실시간 수신** → 개발·시연 지장 없음.
  - **백그라운드 푸시(낙서 알림·월간 알람)만** Firebase 붙기 전까지 안 옴.
- Firebase 연결되면 앱 코드 수정 없이 켜진다(서버측 `notifications.py` 완성돼 있음).

---

## 12. 막히면

- 계약 상세는 [API.md](API.md), 서버 동작 근거는 [SPEC.md](SPEC.md).
- 응답이 이 문서와 다르면 **서버 쪽 버그**일 수 있으니 바로 서버 담당(안종화)에게. 계약(API.md)을 먼저 고치고 맞춘다.
