# 26s-w2-c1-04

## 공통과제 II : 협업형 실전 산출물 제작 (2인 1팀)

**목적:** 실시간 인터랙션, LLM Wrapper, Cross-Platform 중 하나의 옵션을 선택해 구현하며, 선택한 기술을 실제로 동작하는 형태의 산출물로 완성한다.

**선택 옵션:**

| 옵션 | 설명 |
|---|---|
| 실시간 인터랙션 | 사용자 간 상태 변화, 실시간 데이터 흐름, 스트리밍 응답 등 실시간성이 드러나는 기능을 구현 |
| LLM Wrapper | LLM API를 활용하여 AI 기능이 포함된 산출물을 구현 |
| Cross-Platform | 하나의 산출물을 여러 실행 환경에서 사용할 수 있도록 구현* |

> *데스크톱 앱 ↔ 모바일 앱; 혹은 다른 폼팩터에서의 앱; 웹만/웹 기반 프레임워크(Electron, Tauri 등) 대신 다른 프레임워크를 시도해보는 것을 적극 권장

**결과물:** 선택한 옵션이 적용된 작동 가능한 산출물, 실행 가능한 코드, 시연 자료 및 관련 문서

---

## 프로젝트 현황(2026-07-13)

**한 줄 소개:** 두 사람만의 커플 낙서 호출기 — 낙서·사진·짧은 글을 주고받고, 그 활동이 펫의 대사와 그림 일기로 쌓인다.

**아키텍처 상태**

| 레이어 | 상태 | 비고 |
|---|---|---|
| 백엔드 (FastAPI + Socket.IO `/rt` + MySQL 8) | **라이브** | `https://anjonghwa.madcamp-kaist.org/v1` (Cloudflare Tunnel, 앱 VM `memory-pager.service`). 라우터 전부 완성(auth/groups/devices/doodles/pokes/widget/pets/reports), 통합 테스트 198+ 그린, 하드닝(입력검증·동시성·DATETIME(6)) 완료 |
| GPU 서버 (vLLM + SD 1.5) | **라이브** | vLLM EXAONE 3.5 7.8B AWQ(`:8100`) + SD 1.5(`:8200`), systemd `mp-vllm`/`mp-sd`, health `"gpu":"ok"`. 펫 대사·그림 일기 실추론 확인. vLLM 부팅에 `--trust-remote-code` + `VLLM_USE_FLASHINFER_SAMPLER=0` 필수. LoRA 그림체는 **구현·E2E 검증 완료**(3090·200step 46s, `/train/style`→learned 렌더) |
| 프론트엔드 (Flutter, Android) | **디자인 기반 재구축·Mock** | Claude 디자인 시안(16캔버스 하이파이)을 유일 원본으로 `front-remake` 브랜치에서 0부터 재작성. Flutter 3.44.6/Dart 3.12.2, 폰트 Pretendard+Gaegu 번들, 팔레트 코랄 `#E8566B`·잉크 `#3A2E2E`. 인앱 14화면 + shell 탭바. 현재 `lib/mock.dart` 전역 싱글턴으로 Mock 구동, **실서버 미연결**. `flutter analyze` 0, 웹 빌드 성공, 골든 15 + 시나리오 8 테스트 통과 |
| FCM 푸시 | 코드 완성·무동작 | Firebase 프로젝트 부재로 `NullPushClient` |

**브랜치**

| 브랜치 | 내용 |
|---|---|
| `anjonghwa` | 서버 · GPU · 문서 |
| `front-remake` | 디자인 시안 기반 새 프론트(worktree `mp-design`) — 현재 개발 중심 |
| `jonghklee` | 구 프론트(Flutter mock + RestRepository) — 배제 |

**실행법**

- 백엔드·GPU: 이미 배포·라이브 상태(위 URL). 로컬 재현은 [backend/README.md](backend/README.md) 참고.
- 앱: `cd app && flutter run` (현재 Mock 데이터로 단독 구동). 앱 상세는 [app/README.md](app/README.md).

**디자인 갭(백엔드 추가 필요)**

- **오늘의 질문** — 매일 커플에게 같은 질문, 각자 답변(디자인 신규 기능, 백엔드에 없음)
- D-day용 그룹 `created_at` 노출
- 앨범 AI 큐레이션("모리가 모아줬어요")
- 낙서 속 단어 검색
- `groups/join` 응답을 `{group, pet}`로 래핑
- (디자인 4h 홈 위젯·4i 푸시 알림은 OS 네이티브(AppWidget/FCM)라 인앱 화면 아님)

**남은 큰 스텝:** ① 재구축 프론트를 실서버(REST + Socket.IO)에 연결(Mock→실물 교체) ② 백엔드 디자인 갭 엔드포인트 ③ FCM(Firebase) ④ 네이티브 홈 위젯 ⑤ LoRA 그림체 학습(P2)

---

## 팀원

| 이름 | 학교 | GitHub | 역할 |
|---|---|---|---|
| 이종혁 | DGIST |  | 앱 (Flutter, 캔버스, 홈 위젯, FCM) |
| 안종화 | KAIST |  | 서버 · GPU (FastAPI, Socket.IO, MySQL, vLLM, SD) |

---

## 선택 옵션

- [x] 실시간 인터랙션 — **주 옵션.** 찌르기, 사라지기 모드(확인 후 5초 삭제), 홈 화면 위젯 즉시 갱신
- [x] LLM Wrapper — 부 옵션. 펫의 하루 활동·대사 생성, 그림 일기 캡션 (자체 GPU 서버에 서빙)
- [ ] Cross-Platform — 제외. 갤럭시(Android) 단일 타깃

---

## 기획안

- **산출물 주제:** Memory Pager — 두 사람이 낙서·사진·짧은 글과 함께 펫을 키우는 폐쇄형 커플 공간
- **제작 목적:** 앱을 열어 둔 상태와 백그라운드 모두에서 가벼운 소통이 이어지고, 그룹 활동이 펫의 말과 그림 일기로 축적되는 경험 구현
- **선택 옵션:** 실시간 인터랙션(주 옵션) + LLM Wrapper(부 옵션)
- **핵심 구현 요소:**
  - Socket.IO 룸 기반 낙서·찌르기와 확인 후 5초 만료
  - FCM data-only 푸시와 Android 홈 위젯 갱신 계약
  - 자체 GPU의 한국어 LLM 대사·캡션과 SD 1.5 그림 일기
- **사용 / 시연 시나리오:** 두 사용자가 초대 코드로 매칭 → 일반/사라지기 낙서 왕복 → 찌르기·쓰다듬기 → 펫 성장·그림 일기·월간 레포트 확인
- **팀원별 역할:** 이종혁 — Flutter/Android, 안종화 — FastAPI/MySQL/Socket.IO/GPU

### 개발 일정

> 상세 계획과 완료 기준은 [docs/PLAN.md](docs/PLAN.md)

| 날짜 | 목표 |
|---|---|
| Day 1 | 관통(앱 → Tunnel → FastAPI → MySQL) + 두 서버 환경 구성 |
| Day 2 | 온보딩·그룹 (P0). 정원 2명 강제 |
| Day 3 | 낙서 왕복 (P0). 캔버스·사진첩·앱 뷰어 |
| Day 4 | **실시간 증명** — 사라지기 모드, 찌르기, 홈 위젯, 푸시 |
| Day 5 | **LLM 증명** — 펫 활동·대사, 그림 일기 |
| Day 6 | 월간 레포트 + QA |
| Day 7 | 데모·문서·버퍼 |

---

## 구현 명세서

| 구현 요소 | 설명 | 우선순위 |
|---|---|---|
| 2인 그룹·낙서 | 초대 코드, 정원 강제, 사진/손그림/텍스트, 답장·사진첩 | 필수 |
| 실시간 소통 | Socket.IO, 찌르기, 5초 만료, FCM, 위젯 계약 | 필수 |
| AI 펫 | 활동·대사 캐시, 쓰다듬기, SD 1.5 그림 일기 | 필수 |
| 월간 레포트 | 유형 분포, 성장, 규칙 기반 최고의 낙서 | 선택 |
| LoRA 그림체 | 사용자 손그림 화풍 학습(`/train/style`→learned 일기) | **구현·E2E 검증** |
| 스토어·탐색 | 펫 꾸미기, 다른 그룹 탐색 | P2 (세션 로컬/정적 목업) |

---

## 아키텍처

Android 앱은 Cloudflare Tunnel을 통해 앱 VM의 FastAPI REST·Socket.IO에 연결한다. 앱 VM은 MySQL과 미디어 파일을 소유하고, 사설망으로 GPU VM의 vLLM(`:8100`)과 SD worker(`:8200`)를 호출한다. 상세 구조는 [docs/SPEC.md](docs/SPEC.md), API 계약은 [docs/API.md](docs/API.md), 배포 절차는 [docs/SETUP.md](docs/SETUP.md)를 따른다.

---

## 설계 문서

> 프로젝트 성격에 따라 필요한 항목만 작성

### 화면 / 인터페이스 설계

<!-- Figma 링크, 화면 이미지, CLI 사용 예시, 앱 화면 등 -->

### 데이터 구조

<!-- DB 스키마, JSON 구조, 파일 저장 방식 등 -->

### API / 외부 서비스 연동

| Method / 방식 | Endpoint / 서비스 | 설명 | 요청 | 응답 | 비고 |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

---

## 산출물 및 실행 방법

- **산출물 설명:** Android 앱 + FastAPI 실시간 백엔드 + MySQL + 자체 GPU 추론 worker
- **실행 환경:** Ubuntu 22.04 앱 VM, Ubuntu 22.04 RTX 3090 GPU VM, Android(Galaxy)
- **실행 방법:** 아래 백엔드 실행 또는 [backend/README.md](backend/README.md) 참고
- **시연 영상 / 이미지:** (선택)

### 실행 방법

```bash
# 앱 VM 백엔드
python3 -m venv ~/envs/api
source ~/envs/api/bin/activate
pip install -r backend/requirements.txt
cp backend/.env.example backend/.env
cd backend
uvicorn app.main:asgi --host 0.0.0.0 --port 8000

# 선택: 두 사용자 통합 데모
cd ..
python -m http.server 4173 --directory demo
```

### 기술 구성

| 분류 | 사용 기술 |
|---|---|
| 핵심 기술 | FastAPI, Socket.IO, Flutter, FCM, vLLM, Stable Diffusion 1.5 |
| 실행 환경 | Android, Ubuntu 22.04 앱 VM, RTX 3090 GPU VM |
| 데이터 저장 | MySQL 8, 앱 VM 파일시스템 미디어 |
| 외부 API / 서비스 | Cloudflare Tunnel, Firebase Cloud Messaging |
| 기타 | APScheduler, SQLAlchemy async, Pillow |

---

## 회고 문서

> [KPT 방법론 참고](https://velog.io/@habwa/%EB%8B%A8%EA%B8%B0-%ED%94%84%EB%A1%9C%EC%A0%9D%ED%8A%B8-%ED%9A%8C%EA%B3%A0-KPT-%EB%B0%A9%EB%B2%95%EB%A1%A0)

### Keep — 잘 된 점, 다음에도 유지할 것

-
-
-

### Problem — 아쉬웠던 점, 개선이 필요한 것

-
-
-

### Try — 다음번에 시도해볼 것

-
-
-

### 팀원별 소감

**이종혁:**

> 

**안종화:**

> 

---

## 참고 자료

### 실시간 인터랙션

**WebSocket**
- https://developer.mozilla.org/en-US/docs/Web/API/WebSockets_API
- https://techblog.woowahan.com/5268/
- https://tech.kakao.com/posts/391
- https://daleseo.com/websocket/
- https://kakaoentertainment-tech.tistory.com/110

**Socket.IO**
- https://socket.io/docs/v4/
- https://inpa.tistory.com/entry/SOCKET-%F0%9F%93%9A-Namespace-Room-%EA%B8%B0%EB%8A%A5
- https://adjh54.tistory.com/549
- https://fred16157.github.io/node.js/nodejs-socketio-communication-room-and-namespace/

**SSE (Server-Sent Events)**
- https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events
- https://developer.mozilla.org/ko/docs/Web/API/Server-sent_events/Using_server-sent_events
- https://api7.ai/ko/blog/what-is-sse

**TCP / UDP Socket**
- https://docs.python.org/3/library/socket.html
- https://inpa.tistory.com/entry/NW-%F0%9F%8C%90-%EC%95%84%EC%A7%81%EB%8F%84-%EB%AA%A8%ED%98%B8%ED%95%9C-TCP-UDP-%EA%B0%9C%EB%85%90-%E2%9D%93-%EC%89%BD%EA%B2%8C-%EC%9D%B4%ED%95%B4%ED%95%98%EC%9E%90

**gRPC Streaming**
- https://grpc.io/docs/what-is-grpc/core-concepts/
- https://tech.ktcloud.com/entry/gRPC%EC%9D%98-%EB%82%B4%EB%B6%80-%EA%B5%AC%EC%A1%B0-%ED%8C%8C%ED%97%A4%EC%B9%98%EA%B8%B0-HTTP2-Protobuf-%EA%B7%B8%EB%A6%AC%EA%B3%A0-%EC%8A%A4%ED%8A%B8%EB%A6%AC%EB%B0%8D
- https://tech.ktcloud.com/entry/gRPC%EC%9D%98-%EB%82%B4%EB%B6%80-%EA%B5%AC%EC%A1%B0-%ED%8C%8C%ED%97%A4%EC%B9%98%EA%B8%B02-Channel-Stub
- https://inspirit941.tistory.com/371
- https://devocean.sk.com/blog/techBoardDetail.do?ID=167433

**WebRTC**
- https://developer.mozilla.org/en-US/docs/Web/API/WebRTC_API
- https://webrtc.org/getting-started/overview
- https://web.dev/articles/webrtc-basics?hl=ko
- https://devocean.sk.com/blog/techBoardDetail.do?ID=164885
- https://beomkey-nkb.github.io/%EA%B0%9C%EB%85%90%EC%A0%95%EB%A6%AC/webRTC%EC%A0%95%EB%A6%AC/
- https://gh402.tistory.com/45
- https://on.com2us.com/tech/webrtc-coturn-turn-stun-server-setup-guide/

**QUIC / WebTransport**
- https://developer.mozilla.org/en-US/docs/Web/API/WebTransport_API
- https://datatracker.ietf.org/doc/html/rfc9000
- https://news.hada.io/topic?id=13888

#### KCLOUD VM / Cloudflare Tunnel 환경별 주의사항

| 환경 | 사용 가능(권장) 기술 | 포트/조건 | 주의할 기술 |
|---|---|---|---|
| **로컬 / 일반 VM** | HTTP/REST, WebSocket, Socket.IO, SSE, TCP Socket, gRPC Streaming, WebRTC, QUIC/WebTransport 등 대부분 가능 | 직접 포트 개방 가능. 예: 3000, 5000, 8000, 8080, 9000 등. 외부 공개 시 방화벽/보안그룹/공인 IP 설정 필요 | WebRTC는 STUN/TURN 필요 가능. QUIC/WebTransport는 HTTP/3 · UDP 지원 필요 |
| **KCLOUD VM (VPN 내부)** | HTTP/REST, WebSocket, Socket.IO, SSE, WebRTC 시그널링 | 접속 기기 VPN 필요. 기본 허용 포트: **22, 80, 443**. 개발 포트(3000, 8000, 8080 등)는 직접 접근 제한 가능 | TCP Socket은 포트 제한 있음. gRPC는 HTTP/2 설정 필요. WebRTC 미디어·UDP·QUIC/WebTransport 비권장 |
| **KCLOUD VM + Tunnel** | HTTP/REST, WebSocket, Socket.IO, SSE, WebRTC 시그널링 | VM의 `localhost:<port>`를 도메인에 연결. `localPort`는 **1024~65535**. 예: 3000, 8000, 8080 가능 | 순수 TCP Socket, UDP, WebRTC 미디어/DataChannel, QUIC/WebTransport 불가. gRPC 보장 어려움 |
| **외부 서비스 + 우리 도메인** | HTTP/REST, WebSocket, Socket.IO, SSE, WebRTC 시그널링 | Vercel/Netlify/Railway/Render/AWS/GCP 등에 배포 후 CNAME/A 레코드 연결. 보통 외부는 **443** 사용 | WebSocket/gRPC/TCP/UDP는 플랫폼 지원 여부 확인 필요. 서버리스 플랫폼은 장시간 연결 제한 가능 |
| **서버 없이 외부 SaaS 사용** | Supabase Realtime, Firebase, Pusher/Ably, LLM API Streaming | 직접 포트 관리 불필요. 각 서비스 SDK/API 사용 | 커스텀 TCP/UDP 서버 구현 불가. WebRTC는 STUN/TURN 필요할 수 있음 |

### LLM Wrapper

- https://github.com/teddylee777/openai-api-kr
- https://github.com/teddylee777/langchain-kr
- https://devocean.sk.com/blog/techBoardDetail.do?ID=167407
- https://mastra.ai/docs

### Cross-Platform

- https://flutter.dev/
- https://reactnative.dev/
- https://docs.expo.dev/
- https://kotlinlang.org/multiplatform/
