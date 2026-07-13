# Memory Pager — 앱 (Flutter)

커플용 낙서 호출기. **디자인 원본**은 `../썸원 스타일 앱 디자인/Memory Pager 디자인.dc.html`로, 이 앱은
그 하이파이 시안(16캔버스)을 픽셀 충실하게 옮긴 결과다. 계약은 [`../docs/API.md`](../docs/API.md).

## 현재 상태 (2026-07-13)

- **디자인 원본 기반 전면 재구축.** 이전 프론트를 배제하고 `front-remake` 브랜치에서 0부터 작성.
- **Flutter 3.44.6** (Dart 3.12.2). `flutter analyze` **이슈 0**, 웹 릴리즈 빌드 성공.
- **현재는 Mock 구동** — `lib/mock.dart`의 전역 싱글턴이 인메모리 백엔드다. 실서버(REST/Socket.IO)
  연결은 아직 안 붙였다(아래 "실서버 연결" 참조).
- 검증: 골든 15화면(실 폰트·사진 렌더) + 시나리오 8종 **모두 통과** (`flutter test`).

## 실행

```bash
flutter pub get
flutter run -d chrome            # 웹 (데모 보기 제일 빠름)
flutter run -d <android-device>  # 갤럭시
```

앱은 **온보딩 완료 상태**(mock.onboarded=true)로 홈에서 부팅한다. 설정의 "로그아웃 · 커플 연결 끊기"가
mock을 리셋하면 온보딩 플로우(이름→그룹→별명)가 열린다.

## 구조

```
lib/
  main.dart        진입점. onboarded면 AppShell, 아니면 온보딩.
  theme.dart       디자인 실측 토큰(팔레트 30여·radius) + sans()/hand() 텍스트 스타일
  pet.dart         펫 "모리" — 디자인 SVG 좌표를 CustomPainter로. 모자·볼·이웃 보라 변형
  mock.dart        전역 AppMock 싱글턴 — 디자인 샘플 세계(지우·나무늘보·모리·억새밭·떡볶이)
  shell.dart       하단 탭 4개 (디자인 2a: 아이콘 온리 + 활성 블러시 필)
  screens/         14개 화면 (아래)
assets/
  fonts/           Pretendard 4웨이트 + Gaegu 손글씨 (둘 다 OFL)
  photos/          디자인 fig_extract 사진 2장
test/
  golden_test.dart 14화면 골든 PNG (goldens/*.png) — 디자인 대비 육안 검증용
  scenario_test.dart 인터랙션 8종
```

## 화면 (디자인 id → 파일)

| 디자인 | 파일 | 핵심 |
|---|---|---|
| 1a·1b·4a | onboarding_name/group/nickname | 이름→그룹(초대코드)→별명 |
| 1c | home | roomColor 헤더·펫·낙서보내기/콕찌르기·**오늘의 질문**·새 낙서 |
| 1d·4c | draw_canvas | 실 프리핸드·지우개·컬러피커·굵기·사진토글·**사라지기 ∞↔5** |
| 4b | viewer | 받은 낙서. 사라지기면 **5초 카운트다운 후 소멸** |
| 1e·2d | album / calendar | 주간스트립·인물칩·타임라인 · 추억 달력 |
| 1f | report | 월간 레포트(성장·최고낙서·유형바·스탯) |
| 4f | diary | 그림 일기장(장면 페인터) |
| 1g·1h | pet_house / neighbor | 모리네 집(스토어·착용) · 이웃집(라일락) |
| 4g | settings | 이름/별명·배경색 4스와치·토글·로그아웃 |
| 4e | surprise | 펫 깜짝 낙서 팝업(쓰다듬기 5회) |

디자인 4h(홈위젯)·4i(푸시)는 OS 네이티브 레이어라 인앱 화면이 아니다 → 후속(Android AppWidget/FCM).

## 디자인 대비 규칙

- 색은 **theme.dart 토큰**만 쓴다(코랄 `coral`=E8566B·잉크 `ink`=3A2E2E·블러시·골드·라일락…).
- 본문은 `sans(size, w:)`(Pretendard), 손글씨(낙서·펫대사·일기·캡션)는 `hand(size)`(Gaegu).
- roomColor 4프리셋은 홈 헤더·펫 배경·설정 스와치가 공유한다.

## 실서버 연결 (아직 — 다음 스텝)

지금은 `mock`이 전부다. 실배포된 백엔드(`https://anjonghwa.madcamp-kaist.org/v1`, Socket.IO `/rt`)에
붙이려면 `mock`을 REST 리포지토리 + Socket.IO 클라이언트로 교체한다. 계약·핸드셰이크·주의점은
[`../docs/FRONTEND.md`](../docs/FRONTEND.md). 붙기 전 서버가 채워야 할 **디자인 갭**(오늘의 질문 API,
`created_at`/D-day, join `{group,pet}` 래핑 등)은 [`../docs/BACKLOG.md`](../docs/BACKLOG.md) 참조.
