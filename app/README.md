# Memory Pager — Flutter 앱 (Android)

커플 전용 폐쇄형 낙서·펫 앱의 클라이언트. 설계 근거는 [`../docs/SPEC.md`](../docs/SPEC.md) ·
[`../docs/ERD.md`](../docs/ERD.md) · [`../docs/API.md`](../docs/API.md)(앱↔서버 계약).
디자인은 `design_lab/`의 20종 탐색에서 고른 **Cold Press**(쿨 스톤 · 0.5px 키라인 · 슬레이트 잉크 · 유칼립투스 액센트).

## 실행

```bash
cd app
flutter pub get
flutter run                 # 연결된 안드로이드 기기
flutter run -d chrome       # 개발·QA용 웹
flutter test                # 동작 검증 (10 tests)
```

QA 딥링크(웹): `?route=<home|album|comm|draw|viewer|diary|report|store|house|explore|settings|widget|onboarding>` · `?tab=<pet|album|comm>`

## 구조

```
lib/
 core/
  models.dart          ERD/API 미러 도메인 모델 + enum (모르는 값은 안전 폴백)
  api/
   repository.dart     추상 인터페이스 (API.md 엔드포인트 1:1)
   mock_repository.dart ★ 인메모리 백엔드 — 서버 없이 실제 동작(결정론적 clock)
   rest_repository.dart 실서버 연결용 (백엔드 라우터 준비되면 교체)
  realtime.dart        Socket.IO /rt 추상 + MockRealtime(라이브 파트너·펫 시뮬) + SocketRealtime
  app_state.dart       ChangeNotifier — 세션·앨범·펫·실시간·배너. 전역 `appState`
 ui/
  theme.dart           Cold Press 팔레트/타입
  components.dart      Cp* 재사용 위젯 (CpMatted 시그니처, CpDoodlePainter 등)
  screens/             15개 화면 (P0~P2)
 app.dart / main.dart  셸·라우팅·엔트리
```

## 상태: 계약대로 P0~P2 전부 구현

| 우선순위 | 기능 | 상태 |
|---|---|---|
| P0 | 온보딩(이름·그룹생성/가입·초대코드·별명) | ✅ |
| P0 | 펫 홈(첫 화면) · 쓰다듬기 | ✅ |
| P0 | 낙서 그리기·보내기(실캔버스 + stroke_data 타임스탬프) | ✅ |
| P0 | 사진첩(날짜/유형) · 뷰어(이전/다음) · 답장 | ✅ |
| P1 | 사라지기 모드(확인→5초→삭제, 410) | ✅ |
| P1 | 찌르기 · 실시간 수신(doodle:new/poke/pet:activity) | ✅ (Mock 시뮬) |
| P1 | 홈위젯 뷰어(ephemeral 자물쇠) | ✅ (인앱 미리보기) |
| P1 | 펫 그림일기(기본→학습 그림체 경계 표시) | ✅ |
| P1 | 월간 레포트(성장·유형분포·최고의 낙서 + rule) | ✅ |
| P2 | 스토어·커스텀·집 꾸미기(pos_x/y) | ✅ |
| P2 | 다른 그룹 펫(넘기기·좋아요·코드로 찾기) | ✅ |
| P2 | 설정·배경색·그림체 전환 표시 | ✅ |

동작 검증: `test/mock_flow_test.dart` — 전송→앨범, 답장 카운트, **사라지기 5초 만료→410**,
쓰다듬기 대사, 레포트 집계, 구매 코인/422, 위젯 ephemeral 숨김, 온보딩까지 10 tests 통과.

## 계약 준수 포인트 (API.md)

- ID는 문자열, 색은 `#` 없는 6-hex 대문자, 시각 UTC ISO8601, 날짜 `YYYY-MM-DD`.
- `content_type`은 **앱이 판정**해 전송(서버 재계산 안 함). 그리기>사진>텍스트 순.
- `stroke_data.points = [x, y, t]` — `t`는 획 시작부터의 ms(웹에서 `sourceTimeStamp`가 null이라 Stopwatch로 측정).
- **404(없음) vs 410(사라짐)** 구분 표시. 모르는 enum/`best_doodle_rule`도 안 죽음.
- REST가 진실의 원본, Socket.IO는 빠른 길(`setTransports(['websocket'])`). 재연결 시 목록 재로드로 보정.

## 아직 붙이지 않은 것 (백엔드/Firebase 준비 후)

- **실서버 연결** — 현재는 `MockRepository`. 백엔드 라우터/Socket.IO 서버가 나오면 `RestRepository` + `SocketRealtime`로 교체(인터페이스 동일).
- **FCM 푸시**(SD-8·MR-1) — data-only 메시지. `firebase_messaging` + `google-services.json` 필요. `android/`에 설정 예정.
- **네이티브 홈 화면 위젯**(RV-5) — 안드로이드 AppWidget(Kotlin) + `home_widget` 플러그인. 현재는 계약(`GET /widget`)과 규칙을 **인앱 미리보기**로 구현. `android/app/src/main/kotlin`에 위젯 추가 예정.
- **카메라/갤러리** — `image_picker` 배선 완료. 실기기에서 권한 설정 필요(웹에선 파일 선택으로 동작).
