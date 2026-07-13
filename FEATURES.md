# Memory Pager — 구현 기능 전체 설명

> 커플(2인) 전용 폐쇄형 소셜 앱. 사진·손낙서를 삐삐(호출기) 감성으로 주고받고,
> 함께 키우는 펫이 둘의 낙서를 보고 **그림 일기**를 그려준다.
> Flutter(Android) + FastAPI + Socket.IO + MySQL + GPU(EXAONE LLM / Stable Diffusion).
>
> 상태 표기: ✅ 실서버 연결 완료 · 🟡 목데이터(백엔드 미연결/부분) · ⏳ 미구현/계획.
> 최종 갱신 2026-07-13.

---

## 0. 동작 모드 (Dual-mode)
앱은 하나의 코드베이스로 두 모드를 지원한다.
- **실서버 모드** ✅ — `--dart-define=API_BASE=https://anjonghwa.madcamp-kaist.org` 로 빌드하면
  부팅 시 기기 등록 → 실제 백엔드/실시간/펫 데이터로 동작. 완성품 APK가 이 모드.
- **데모(목) 모드** — `API_BASE` 없이 빌드하면 온보딩 완료 상태의 샘플 데이터로 바로 홈에서 시작.
  디자인 시연·골든 테스트용.
- 판별: `mock.real`(= `api != null`). 화면 코드는 모드에 무관하게 `mock` 을 읽는다.

## 1. 기기 · 계정 · 온보딩 ✅
- **기기별 device_uid 영속화** ✅ — 최초 실행 때 랜덤 uid 생성 후 `shared_preferences` 에 저장·재사용.
  → **한 기기 = 한 유저**. 두 폰이 각자 등록해 커플을 이룬다. (`main.dart _deviceUid()`)
- **자동 등록** ✅ — 부팅 시 `POST /v1/auth/register {device_uid, display_name}` → 토큰 발급 → `GET /v1/me`.
- **온보딩 흐름** ✅ — 이름 입력 → 그룹 **생성**(펫 이름 정하기) 또는 **참여**(초대 코드) → 별명 설정.
  - 그룹 없으면 온보딩, 있으면 바로 앱 홈으로(`_gate()`).
  - 모든 입력 **엔터 제출** 지원(U-3).

## 2. 홈 (삐삐 화면) ✅
- 펫 상태 카드: 이름·레벨·성장바·말풍선.
  - **활동 표정** ✅ — 서버 `pet.current_activity`(eating/sleeping/walking/playing/drawing/waiting)를
    말풍선에 반영. 실시간 `pet:activity` 이벤트로도 갱신.
  - **착용 모자** ✅ — 서버 `equipped_items` 의 hat 카테고리를 펫에 반영.
- **콕 찌르기(poke)** ✅ — `POST /v1/groups/{id}/pokes`. 상대에게 실시간 알림(`poke` 이벤트).
- **쓰다듬기(pat)** ✅ — `POST /v1/pets/{id}/pat` → 경험치 + 펫 대사(utterance). 5회 연속 → 서프라이즈.
- **오늘의 질문** ✅ — `GET/POST /v1/groups/{id}/question/today`. 답변 남기기(엔터 제출),
  상대 답변 여부 표시. 질문은 날짜 기반 풀에서 결정(프론트/백엔드 풀 동기화).
- 진입: 사진첩·달력·레포트·설정·서프라이즈·펫하우스·캔버스.

## 3. 낙서 그리기 (캔버스) ✅
- 펜 도구·색상 선택·사진 첨부 토글.
- **사라지는 낙서(ephemeral)** ✅ — 켜면 상대가 확인 후 일정 시간 뒤 소멸(디자인 5초 데모).
- **전송** ✅ — 스트로크를 PNG로 래스터화 + 스트로크 JSON 동봉 → `POST /v1/doodles`(그림) /
  텍스트 낙서 전송. 답장(replyTo)도 지원.
- 전송 즉시 상대에게 실시간 `doodle:new`.

## 4. 낙서 사진첩 (앨범) ✅
- 주간 스트립 + 인물 필터(모두/나/상대) + 낙서 타임라인.
- **격자 갤러리 토글** ✅ — 상단 겹사진 아이콘으로 타임라인 ↔ 3열 그리드 전환(U-2로 연결).
- **달력 뷰** ✅ — 월별 낙서 분포.
- 낙서 탭 → **뷰어**(원본·캡션·찌르기·답장).

## 5. 뷰어 ✅
- 낙서 원본 이미지(네트워크 or 로컬), 펫이 붙인 **캡션**(LLM 생성), 찌르기·답장 CTA.
- 확인 시 `POST /v1/doodles/{id}/view` → 사라지는 낙서 소멸 카운트 시작, 실시간 반영.

## 6. 펫 하우스 · 스토어 · 이웃
- **펫 하우스** ✅ — 펫 렌더(레벨에 따라 크기), 방 배경색, 진입 메뉴(일기·이웃).
- **스토어(모자 꾸미기)** 🟡 — 모자 6종. 착용은 되나 **코인 게이팅 미구현**(U-1 백로그: 보유/구매·부족 시 착용 불가).
- **이웃집** 🟡 — 다른 커플 펫 구경·좋아요(현재 목데이터, 공개 위젯 연동 예정).

## 7. 그림 일기장 ✅
- 펫이 둘의 낙서를 보고 그린 **그림 일기**(서버 생성 이미지 + 캡션).
- **실서버 로드** ✅ — `GET /v1/pets/{id}/diaries`. 원격이면 네트워크 이미지, 아니면 손그림 장면(데모).
- **빈 상태** ✅ — 신규 커플은 "아직 그린 일기가 없어요" 안내(GPU가 만들기 전이라 정상).

## 8. 월간 레포트 ✅
- 이 달의 사진/그림/텍스트 수, 콕 찌르기, 펫 레벨 변화 등 통계.
- **실서버 로드** ✅ — `GET /v1/groups/{id}/reports` → 최신 달 `reports/{month}` 카운트 매핑.
  없으면 0(신규 그룹). 생성은 `POST .../generate`.

## 9. 설정 ✅
- 별명·이름 편집(엔터 저장), 방 배경색, 초대 코드 복사, 알림 토글, 로그아웃·커플 연결 끊기.

## 10. 실시간 (Socket.IO `/rt`) ✅
- 인증 `{token}`, websocket. 수신 이벤트: `doodle:new` / `doodle:expired` / `poke` /
  `pet:activity` / `pet:levelup` / `diary:new`. 송신: 확인(view)·찌르기 ack.

## 11. GPU 지능 기능 (앱 VM ↔ GPU 서버 직접 HTTP) ✅ / ⏳
- **LLM(EXAONE 3.5 7.8B AWQ, vLLM :8100)** ✅
  - 낙서 **캡션** 생성(펫 1인칭·한국어 강제, 펫 이름 반영).
  - **펫 활동/대사**(activity ENUM 강제 스키마 + utterance).
- **Stable Diffusion 1.5 (:8200)** ✅ — 그림 일기 **이미지 생성**.
- **월간 레포트** ✅ — 집계 + (선택) LLM 요약.
- **LoRA 화풍 학습** ⏳ — 실현성 검증 완료(peak 6GB·200step 46s)이나 학습 잡 자체는 미구현
  (sd_worker `learned` → 501). 커플 그림체 개인화가 목표.

## 12. 빌드 · 배포 ✅
- **완성품 APK** ✅ — 로컬 Android SDK 없이 **GitHub Actions**(`.github/workflows/build-apk.yml`)로
  push마다 실서버 연결 release APK 아티팩트 생성.
- **공개 도메인** ✅ — `https://anjonghwa.madcamp-kaist.org`(Cloudflare Tunnel → 앱 VM FastAPI).
- **서버** ✅ — 앱 VM(systemd `memory-pager.service`) + GPU 서버(`mp-vllm`/`mp-sd`). VM 접속은 kcloudVPN.

## 13. 품질 · 검증 ✅
- 골든 테스트 15종 + 시나리오 테스트 8종(총 23) 그린.
- 백엔드 통합 테스트(questions·groups 등) 그린.
- 실서버 E2E: register→me→group→pet/diaries/reports/question 라이브 확인.

---

## 남은 일 (요약)
- **U-1 코인 게이팅**(스토어 보유/구매·부족 시 착용 불가) — 다음 스텝.
- 이웃집 실데이터(공개 위젯) 연동.
- LoRA 화풍 학습 잡 구현.
- 실기기(갤럭시) APK 설치 후 커플 2인 실사용 검증.
