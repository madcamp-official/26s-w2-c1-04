# Memory Pager — 환경 구성과 고정 버전

> 근거: [SPEC.md](SPEC.md) · 조사·적대적 검증 결과 (2026-07-10)
>
> **검증 등급 표기**
> - ✅ **검증** — 적대적 검증을 통과했거나 2026-07-10에 공식 출처로 재확인
> - ⚠️ **미확인** — 신뢰할 근거를 확보하지 못함. 설치해 보고 고정할 것
> - 🔬 **실측 필요** — 숫자가 환경에 좌우됨. 반드시 직접 재야 함

---

## 1. 두 머신의 분담

| | ① 앱 VM | ② GPU 서버 |
|---|---|---|
| OS | Ubuntu **24.04** (기본 Python 3.12) | Ubuntu **20.04** (기본 Python 3.8) |
| 스펙 | 4 vCPU / **4GB RAM** / 100GB | 40 vCPU / 50GB RAM / 100GB / RTX 3090 **20GB** |
| 도는 것 | FastAPI, Socket.IO, MySQL 8, 미디어 서빙, 스케줄러 | vLLM(LLM 서빙), SD 1.5 추론·학습 |
| Python | **시스템 3.12로 충분.** venv만 만든다 | **3.8로는 아무것도 안 깔린다.** uv로 3.11 격리 설치 |

> **Python 3.8이 진짜 걸림돌이다. glibc는 아니다.** 20.04의 glibc 2.31은 현재 wheel 요건(`manylinux_2_28`, glibc ≥ 2.28)을 충족한다. 반면 최신 torch·vLLM·SQLAlchemy는 Python ≥ 3.10을, asyncmy·firebase-admin은 ≥ 3.9를 요구한다. 3.8에서는 **전부 설치 불가**다.
>
> **시스템 Python 3.8을 업그레이드하지 마라.** apt 유틸들이 3.8에 묶여 있어 OS가 깨진다. `uv`로 3.11을 따로 받아 쓴다.

---

## 2. VRAM 예산 (20GB) — 검증된 수치

| 워크로드 | 실제 VRAM | 등급 |
|---|---|---|
| 상주 LLM (EXAONE 3.5 7.8B AWQ), `--gpu-memory-utilization 0.4` | **약 8GB (상한이 물리적으로 고정됨)** | ✅ |
| 상주 LLM, 위 인자 **없이** (기본 0.9) | 약 18GB를 즉시 선점 | ✅ |
| SD 1.5 추론 (512px, fp16, 1장) | 4~6GB | ✅ |
| SD 1.5 **LoRA 학습** (512px, batch 1, 8-bit Adam) | **6~8GB** (저rank·텍스트인코더 미학습 시 4~6GB) | ✅ |
| SDXL LoRA 학습 (batch 1 + grad ckpt + AdamW8bit) | 13~15GB (피크) | ✅ |
| Qwen3-VL 4B AWQ (이미지 처리 총량) | **6~9GB** (가중치만 4.43GB) | ✅ / 🔬 |

### 동시 실행 판정

| 조합 | 합산 | 판정 |
|---|---|---|
| 상주 LLM + SD 1.5 **추론** | 12~14GB | ✅ **동시 가능** (헤드룸 ~6GB). 자정 일기 배치에 LLM을 안 내려도 된다 |
| 상주 LLM + SD 1.5 **LoRA 학습** | 14~16GB | ✅ **동시 가능** (헤드룸 4~6GB). 다만 안전하게 가려면 학습 동안 LLM을 sleep |
| 상주 LLM + Qwen3-VL 4B | 14~17GB | ⚠️ 가능하지만 **헤드룸이 얇다**(3~6GB). 큰 이미지면 실측 필요 |
| 셋 동시 | 20~23GB | ❌ **불가.** 반드시 시간대 분리 |
| 상주 LLM + **SDXL** LoRA 학습 | 21~23GB | ❌ **불가** |

**SDXL은 단독으로는 20GB에 들어간다.** 다만 상주 LLM과 절대 공존하지 못해 매번 sleep을 강제하고 헤드룸도 얇다. 일기 그림에 SDXL 품질이 꼭 필요한 게 아니므로 **SD 1.5를 쓴다.**

### 교대 방법 — 프로세스를 죽이지 않는다

vLLM **Sleep Mode**를 쓴다. ✅

```bash
# 기동 시
VLLM_SERVER_DEV_MODE=1 vllm serve LGAI-EXAONE/EXAONE-3.5-7.8B-Instruct-AWQ \
  --gpu-memory-utilization 0.4 --max-model-len 8192 --max-num-seqs 16 \
  --enable-sleep-mode --port 8100
```

- 무거운 배치 직전: `POST /sleep?level=1` — 가중치를 CPU RAM으로 오프로드하고 KV 캐시를 버려 GPU를 비운다
- 배치 후: `POST /wake_up` — 7B급 기준 3~6초
- 상태 확인: `GET /is_sleeping`
- **`VLLM_SERVER_DEV_MODE=1`이 없으면 sleep 엔드포인트가 404다.** 이 함정을 기억할 것

`--gpu-memory-utilization 0.4`가 상주 상한을 8GB로 못박고, sleep이 필요할 때 그 8GB마저 비운다. 이 둘이 단일 20GB에서 모든 워크로드를 공존시키는 축이다.

---

## 3. 고정 버전표

### 앱 VM — 백엔드

| 구성요소 | 버전 | 등급 | 비고 |
|---|---|---|---|
| Python | 3.10 이상 | ✅ | **스택 최저선이 3.10이다.** OS 템플릿은 `ubuntu-24-pw`(3.12)였으나 실제 VM은 22.04(3.10)일 수 있다 — `mysql --version`이 `0ubuntu0.22.04.x`면 22.04다. 둘 다 동작한다 |
| FastAPI | 0.139.0 | ✅ | 2026-07-01 최신 |
| uvicorn[standard] | 0.51.0 | ✅ | **`[standard]`가 아니면 WebSocket 업그레이드가 실패한다** |
| python-socketio | 5.16.3 | ✅ | Socket.IO v5 / Engine.IO v4 |
| SQLAlchemy[asyncio] | 2.0.51 | ✅ | 2.1은 아직 beta |
| asyncmy | 0.2.11 | ✅ | cp39~cp313 prebuilt wheel (무컴파일) |
| APScheduler | 3.11.3 | ✅ | 4.x는 alpha |
| firebase-admin | 7.5.0 | ✅ | FCM data-only 메시지 |
| MySQL | 8.0.x | ⚠️ | 20.04 apt는 검증됨. **24.04는 설치 후 `SELECT VERSION()`으로 확인할 것** |

### GPU 서버

| 구성요소 | 버전 | 등급 | 비고 |
|---|---|---|---|
| NVIDIA 드라이버 | 570 이상 | ✅ | CUDA 12.8 런타임 최소 570.26 |
| CUDA 툴킷 | **설치하지 않음** | ✅ | torch가 CUDA 런타임을 wheel에 번들 |
| Python | 3.11 (uv로 격리) | ✅ | 시스템 3.8은 건드리지 않는다 |
| vLLM | 0.24.0 | ✅ | `--enable-sleep-mode` 지원 |
| torch | vLLM env에서는 **핀하지 말 것** / SD env는 2.9.0 | ✅ / ⚠️ | vLLM이 호환 torch를 끌어온다 |
| diffusers | 0.39.0 | ✅ | 2026-07-03 최신 |
| transformers · accelerate · peft · bitsandbytes | 미정 | ⚠️ | pip 해석에 맡기고 테스트 후 고정 |

### 모델

| 용도 | 식별자 | 등급 |
|---|---|---|
| 상주 LLM | `LGAI-EXAONE/EXAONE-3.5-7.8B-Instruct-AWQ` | ✅ 한/영 네이티브, 32K 컨텍스트, 가중치 5.31GB |
| 일기 그림 | Stable Diffusion 1.5 | ✅ |
| (P2, 미도입) 최고의 낙서 | `cyankiwi/Qwen3-VL-4B-Instruct-AWQ-4bit` | ✅ 32개 언어 OCR |

> EXAONE 4.0·4.5가 나와 있으나 공개 사이즈가 32B급이라 4-bit로도 18~20GB다. **상주 + SD 공존이라는 이 프로젝트의 제약에는 3.5의 7.8B가 여전히 최적이다.** 신형 계열에 7~8B급 변형이 있는지는 채택 전 확인할 것.

### Flutter

| 구성요소 | 버전 | 등급 |
|---|---|---|
| Flutter SDK | 3.44.0 (stable) | ✅ 2026-05-29 |
| socket_io_client | 3.1.6 | ✅ **`setTransports(['websocket'])` 명시 필수** (dart:io는 polling 미지원) |
| home_widget | 0.9.3 | ✅ |
| Dart / camera / image_picker / workmanager | 미확인 | ⚠️ |

---

## 4. 설치 순서

### 앱 VM (Ubuntu 24.04)

1. swap 4~8GB 추가. **RAM이 4GB뿐이라 빌드 중 OOM-killer에 맞기 쉽다.**
2. `sudo apt install mysql-server` → `SELECT VERSION();`으로 8.0.x 확인 → DB·유저 생성 → `mysql < backend/schema.sql`
3. **트리거가 실제로 3번째 가입을 거부하는지 확인한다.** 파서 검증으로는 못 잡는다.
4. `python3 -m venv ~/envs/api` → `pip install -r backend/requirements.txt`
   - 24.04는 PEP 668로 시스템 pip 설치가 막혀 있다. 반드시 venv 안에서.
5. `innodb_buffer_pool_size`를 키우지 않는다. 기본값 근처로 둔다.
6. cloudflared 설치 → ingress에 `http://localhost:8000`만 등록하면 WebSocket이 자동 프록시된다

### GPU 서버 (Ubuntu 20.04)

1. `nvidia-smi`로 드라이버 확인. 570 미만이면 `sudo ubuntu-drivers autoinstall` 후 재부팅.
   **여기서 GPU가 안 잡히면 상위 스택 전부가 무의미하다. 이 단계부터 통과시킨다.**
2. **CUDA 툴킷은 설치하지 않는다.**
3. swap 8~16GB 추가. `HF_HOME`을 100GB 파티션(`/data/hf`)으로, `TMPDIR`도 큰 파티션으로 export한다.
   작은 `/tmp`가 pip 빌드·triton 캐시로 차서 실패하는 것을 막는다.
4. `uv` 설치 → venv 두 개를 3.11로 만든다. **vLLM과 SD는 torch 핀이 충돌하므로 분리한다.**
   `HF_HOME`은 공유해 같은 가중치를 두 번 받지 않게 한다.
   - `~/envs/vllm` ← `gpu/requirements-vllm.txt`
   - `~/envs/sd` ← `gpu/requirements-sd.txt`
5. vLLM 기동 후 `nvidia-smi`로 점유가 **약 8GB**인지 확인한다. 18GB가 잡히면 `--gpu-memory-utilization` 인자가 안 먹은 것이다.
6. GPU 작업은 FastAPI 이벤트루프와 **반드시 별도 프로세스**로 돌린다.

### Docker는 쓰지 않는다

glibc가 걸림돌이 아니고 Python 3.8은 uv로 2분이면 해결된다. 7일·2인에서 가장 비싼 자원은 팀의 시간인데, Docker의 GPU 공유·`/dev/shm` 64MB 함정·볼륨·8~15GB 이미지가 100GB 디스크를 잠식하는 문제를 새로 배우는 비용이 이득보다 크다.

**예외는 vLLM 하나.** 네이티브 설치가 끝내 막히면 공식 `vllm/vllm-openai` 컨테이너로 그 컴포넌트만 폴백하되 `--ipc=host`(또는 `--shm-size=8g`)를 반드시 붙인다.

---

## 5. FastAPI + Socket.IO 통합 — 네 가지 함정

1. **`uvicorn[standard]`로 설치한다.** 순정 uvicorn은 websockets 구현이 없어 Socket.IO의 WS 업그레이드가 실패한다.
2. **`socketio.ASGIApp(sio, other_asgi_app=fastapi_app)`로 감싸서 uvicorn에 넘긴다.** `app.mount()` 방식은 특정 FastAPI 버전에서 socket.io 엔드포인트가 404 나는 이력이 있다.
3. **CORS는 FastAPI 미들웨어가 아니라 `AsyncServer(cors_allowed_origins='*')`에 설정한다.** 아니면 핸드셰이크가 통과하지 못한다.
4. **Flutter는 `setTransports(['websocket'])`를 명시한다.** 네이티브 dart:io는 polling을 지원하지 않는다.

Cloudflare Tunnel의 유휴 종료는 Socket.IO 기본 하트비트(pingInterval 25초)가 막아 준다. 다만 Tunnel의 실제 유휴 타임아웃은 보고가 20~100초로 갈리므로 🔬 데모 전에 실측할 것.

---

## 6. 사라지기 모드 5초 만료 — 스케줄러 폴링이 아니다

5초짜리를 1초마다 스캔하면 최악 5초 지연에 매초 DB 부하가 얹힌다. **확인 시점에 정확한 만료 시각으로 지연 태스크 하나를 거는 이벤트 드리븐 타이머**가 맞다.

- 절대 시각 `doodles.expires_at`을 DB에 저장한다 (재시작 시 남은 시간 계산용)
- 최초 확인 시 `loop.call_later(ttl, ...)`로 타이머를 걸고 `doodle_id → TimerHandle`로 보관한다 (조기 삭제 시 취소 가능)
- 만료 콜백은 이벤트루프를 막으면 안 되므로 `create_task`로 비동기 DB 삭제 + 미디어 파일 삭제 + `doodle:expired` emit
- **부팅 스윕**으로 내구성을 보강한다. 서버가 죽으면 인메모리 타이머가 전부 사라지므로, 기동 시 `expires_at`이 지난 건 즉시 삭제·emit하고 안 지난 건 남은 시간으로 재스케줄한다

> **주의: 이 타이머는 프로세스 인메모리다.** uvicorn 워커를 여러 개로 늘리면 타이머가 공유되지 않는다. 단일 프로세스로 돌린다.

---

## 7. 갈림길 결정

| 갈림길 | 결정 | 이유 |
|---|---|---|
| vLLM vs Ollama | **vLLM** | Sleep Mode와 `--gpu-memory-utilization` 캡. 단일 20GB 교대의 핵심이며 Ollama에 동등한 것이 없다 |
| asyncmy vs aiomysql | **asyncmy** | Cython 성능 + prebuilt wheel(무컴파일). *"aiomysql은 죽었다"는 근거는 틀렸다 — 8절 참조* |
| Alembic | **미도입** | 7일간 스키마가 계속 흔들린다. `schema.sql` 하나로 DROP/CREATE 하는 게 빠르다 |
| Docker | **미사용** | 4절 참조. vLLM만 예외적 폴백 |
| SD 1.5 vs SDXL | **SD 1.5** | 상주 LLM과 공존 가능(14~16GB). SDXL은 매번 sleep 강제 |
| stroke_data 저장 | **MySQL JSON 컬럼** | 보통 수천 포인트(256KB 미만). 내부 값으로 쿼리할 일이 없어 인덱스도 불필요. 수만 포인트로 커지는 건만 `.json.gz`로 빼고 경로만 저장 |

---

## 8. 반증된 주장 — 정직하게

조사 과정에서 틀린 것으로 드러난 것들이다. 이 중 **①②는 이 레포의 이전 커밋에 잘못된 수치로 들어가 있었고, 이번에 고쳤다.**

1. **"SD 1.5 LoRA 학습은 8~12GB"** — 틀렸다. 그건 SDXL(UNet 2.6B) 수치다. SD 1.5의 UNet은 860M이라 실제로는 **6~8GB**다. 512px에서는 gradient checkpointing 없이도 학습되는 경우가 많고 절감폭도 15~20%에 그친다. **영향: "상주 LLM + LoRA 학습"이 '상한에 닿음'에서 '헤드룸 4~6GB로 동시 가능'으로 상향됐다.**

2. **"Qwen3-VL 4B AWQ 가중치는 3GB, 총 5~7GB"** — 틀렸다. AWQ는 비전 인코더·임베딩·lm_head를 고정밀로 유지하므로 4B가 3GB로 압축되지 않는다. 실측 `model.safetensors`가 **4.43GB**이고 이미지 처리 총량은 **6~9GB**다. **영향: 상주 LLM과의 공존 헤드룸이 생각보다 얇다.**

3. **"asyncmy만 유지보수되고 aiomysql은 죽었으며 SQLAlchemy 문서가 그렇게 명시한다"** — 틀렸다. SQLAlchemy 문서는 둘을 중립적으로 나열할 뿐이고, aiomysql은 2025-10에 0.3.x로 재활성화됐다. asyncmy 권장은 유지하되 근거를 성능·무컴파일 설치로 정정한다.

4. **"획별 타임스탬프는 `Listener` + `PointerEvent.timeStamp`로만 얻을 수 있다"** — 틀렸다. `DragStartDetails.sourceTimeStamp`와 `DragUpdateDetails.sourceTimeStamp`(둘 다 `Duration?`)가 원시 타임스탬프를 그대로 준다. 즉 `GestureDetector`의 `onPanStart`/`onPanUpdate`로도 된다. 다만 `DragEndDetails`에는 없어 종료 시각은 마지막 update 값을 재사용해야 한다.

5. **"20.04의 glibc가 vLLM 설치를 막는다"** — 반대로 틀렸다. glibc 2.31은 요건을 충족한다. 진짜 걸림돌은 Python 3.8이다.

---

## 9. 실측해야 아는 것 🔬

- **Qwen3-VL 4B의 이미지 처리 실측 VRAM.** 비전 토큰 수에 크게 좌우된다. 실제 낙서 해상도로 잰다
- **상주 LLM의 KV 캐시 실사용.** 8GB 캡이 상한은 보장하지만, 8K 컨텍스트가 KV를 얼마나 먹는지는 재봐야 안다
- **Sleep level 1 오프로드 시 CPU RAM 실사용.** GPU 서버 RAM 50GB에 여유가 실제로 남는지
- **torch ↔ vLLM 정확한 상호 핀.** vLLM 0.24.0이 요구하는 torch 버전, flash-attn 빌드 여부
- **SD 1.5 LoRA 학습을 diffusers 예제로 갈지 kohya_ss로 갈지.** kohya_ss가 3.11에서 도는지
- **Cloudflare Tunnel WS 유휴 타임아웃 실값** (20~100초로 보고가 갈림)
- **FCM data 메시지의 백그라운드 위젯 갱신 지연·유실률.** Doze와 제조사 배터리 최적화에 좌우된다.
  "실시간 보장" 대신 **앱 열기 갱신 + workmanager 주기 폴링 + 위젯 탭 콜백**으로 열화 설계하고, 실제 지연은 데모 기기에서 잰다
- **MySQL 8 버전.** 24.04 apt가 무엇을 주는지 (20.04는 검증됨)
