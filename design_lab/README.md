# design_lab — 디자인 탐색 아카이브

실제 앱을 만들기 전, "같은 앱을 완전히 다르게" 디자인해보고 방향을 고르기 위한 탐색 결과입니다.
이 폴더는 **독립 Flutter 패키지**(`memory_pager_design_lab`)라 루트 앱과 분리되어 있습니다.

## 무엇이 있나

- `lib/` — 21개 디자인 변형(레퍼런스 + 라운드1 10종 + calm 라운드 10종)을 폰 프레임 갤러리로 비교하는 앱
  - `designs/design_01..10_*` — 라운드1: 완전히 다른 10가지 방향(PAGER-9000·Frosted Locket·Clay Room·Riso Pulse·Washi·Felt&Fluff·Quiet Signal·Memory Bento·Mixtape·Darkroom)
  - `designs/design_11..20_*` — 라운드2: Quiet Signal 기반 calm·미니멀 10종(Cold Press·Foolscap·Manila·Quadrille·Dateline·Low Lamp·Folio·Pale Index·Vellum·Segment)
  - `main.dart` — 갤러리(좌: 디자인 리스트 / 상단: 화면 탭 / 폰 프레임). 딥링크 `?d=11&s=petHome&solo=1`
- `artifacts/` — 발행된 비교 룩북 2종(자체 포함 HTML)
- `tools/` — 룩북 재생성 스크립트(스크린샷 임베드)

## 선택 결과

**최종 선택: #11 Cold Press** (쿨 스톤 갤러리 매트 · 0.5px 키라인 파스파르투 · 슬레이트 잉크 · 유칼립투스 액센트).
실제 앱은 이 디자인 언어를 기반으로 루트 `lib/`에서 개발한다.

## 실행

```bash
cd design_lab
flutter create . --platforms web   # 플랫폼 스캐폴딩(최초 1회)
flutter run -d chrome
```

발행된 비교 룩북: 라운드1 / calm 라운드 (claude.ai artifacts — 대화 기록 참조).
