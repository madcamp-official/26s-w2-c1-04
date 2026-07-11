# Memory Pager — 서버 구축 순서

> 버전·근거는 [STACK.md](STACK.md). 이 문서는 **복사해서 붙이는 순서**만 담는다.
> 보안은 이 프로젝트의 비목표다([SPEC.md](SPEC.md) 1.2절). 비밀번호 강도를 신경쓰지 않는다.

| | ① 앱 VM | ② GPU 서버 |
|---|---|---|
| IP | 172.10.7.229 | 192.168.0.20 (사설망) |
| OS | Ubuntu **22.04** (Python 3.10) | Ubuntu **22.04** (Python 3.10) |
| 스펙 | 4 vCPU / **4GB RAM** / 100GB | 40 vCPU / 50GB RAM / 100GB / RTX 3090 **24GB** |
| 개방 포트 | 22 · 80 · 443 | (외부 노출 안 함) |
| 공개 주소 | **`https://anjonghwa.madcamp-kaist.org`** (Cloudflare Tunnel) | 없음 |
| 도는 것 | FastAPI, Socket.IO, MySQL 8, 미디어 | vLLM, SD 1.5 |

> **VM이 셋인데 하나(172.10.8.83)는 안 쓴다.** 원래 여기에 도메인이 붙어 다른 서비스를 내려주고 있었다. 터널을 앱 VM으로 옮기는 순서는 7-7.

---

# ① 앱 VM

## 0. 먼저 확인 — OS와 사용자

```bash
cat /etc/os-release | head -2     # Ubuntu 22.04.x 확인
python3 --version                 # 3.10.x
whoami
```

**앱 VM은 172.10.7.229, Ubuntu 22.04(Python 3.10)다.** 우리 스택 최저선이 3.10이라 시스템 Python으로 충분하다. 다만 RAM이 4GB뿐이니 시스템 Python을 건드리지 말고 venv를 쓴다.

아래는 `$HOME`을 기준으로 쓴다. root로 작업하면 `/root`, `ubuntu` 유저면 `/home/ubuntu`다.

```bash
export APP_HOME=$HOME/26s-w2-c1-04
export VENV=$HOME/envs/api
```

## 1. 저장소 clone

```bash
apt update && apt install -y git curl python3-venv python3-pip
cd $HOME
git clone -b anjonghwa https://github.com/madcamp-official/26s-w2-c1-04.git
cd $APP_HOME
```

저장소가 비공개면 GitHub 계정과 **Personal Access Token**을 물어본다(비밀번호가 아니다). 또는 `gh auth login`을 먼저 한다.

## 2. swap 추가 — DB 설치 전에 한다

**RAM이 4GB뿐이다.** `pip install` 도중 OOM-killer에 맞는 걸 막는다. 이미 잡혀 있는지 먼저 본다.

```bash
swapon --show          # 비어 있으면 아래를 실행
fallocate -l 4G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab
free -h                # Swap 4.0Gi 확인
```

## 3. MySQL

```bash
apt install -y mysql-server
mysql --version                       # 8.0.x
systemctl enable --now mysql
```

Ubuntu의 MySQL은 root가 `auth_socket`이라 비밀번호 없이 들어간다. 앱 전용 유저를 만든다.

```bash
mysql <<'SQL'
CREATE USER IF NOT EXISTS 'memory'@'localhost' IDENTIFIED BY 'pager';
GRANT ALL PRIVILEGES ON memory_pager.* TO 'memory'@'localhost';
FLUSH PRIVILEGES;
SQL
```

스키마를 적용한다. **`schema.sql`은 맨 앞에서 기존 테이블을 전부 DROP한다. 개발 초기 전용이다.**

```bash
cd $APP_HOME
mysql < backend/schema.sql
```

확인 — 16과 3이 나와야 한다.

```bash
mysql -u memory -ppager -N -e "
  SELECT COUNT(*) FROM information_schema.TABLES  WHERE TABLE_SCHEMA='memory_pager';
  SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='memory_pager';"
```

**트리거가 진짜로 막는지 본다.** 파서 검증으로는 못 잡는 부분이다.

```bash
MYSQL_USER=memory MYSQL_PW=pager bash backend/tests/test_schema_mysql.sh
# 17 passed, 0 failed
```

### 4GB RAM 튜닝

`innodb_buffer_pool_size`를 **키우지 마라.** 기본값(128MB) 근처가 맞다. 사용자가 둘뿐이라 캐시를 키워봐야 FastAPI가 쓸 메모리만 뺏는다.

```bash
sudo tee /etc/mysql/mysql.conf.d/zz-memory-pager.cnf >/dev/null <<'CNF'
[mysqld]
innodb_buffer_pool_size = 128M
max_connections         = 50
performance_schema      = OFF
CNF
sudo systemctl restart mysql
```

## 4. Python

**24.04는 PEP 668로 시스템 pip 설치를 막는다.** 22.04에는 그 제약이 없지만, 어느 쪽이든 venv 안에서 설치한다.

```bash
python3 --version                     # 3.10 이상이면 된다
python3 -m venv $VENV
source $VENV/bin/activate
pip install -U pip
pip install -r backend/requirements.txt
```

## 5. 설정

```bash
cp backend/.env.example backend/.env
sed -i "s#MEDIA_ROOT=./media#MEDIA_ROOT=$HOME/media#" backend/.env
```

GPU 서버가 아직 없으면 `GPU_ENABLED=false`로 둔다 — **스텁이 그럴듯한 값을 돌려주므로 앱 작업이 막히지 않는다.** 나중에 `true`로 바꾸고 `GPU_LLM_URL`·`GPU_SD_URL`에 사설 IP를 넣는다.

## 6. 실행

```bash
cd $APP_HOME/backend
uvicorn app.main:asgi --host 127.0.0.1 --port 8000
```

- `--workers`를 **주지 마라.** 사라지기 모드의 5초 타이머가 프로세스 인메모리다.
- `127.0.0.1`에 바인딩한다. 외부 노출은 Cloudflare Tunnel이 한다. 개방 포트가 22·80·443뿐이라 8000은 어차피 못 연다.

확인:

```bash
curl -s localhost:8000/v1/health
# {"status":"ok","db":"ok","gpu":"stub","time":"..."}
```

`db`가 `down`이면 `.env`의 `DATABASE_URL`이나 MySQL 유저 권한을 본다.

## 6-1. 라우터가 실제 DB 위에서 도는지 확인

```bash
pip install pymysql          # 테스트가 테이블을 비우는 데만 쓴다
export DATABASE_URL='mysql+asyncmy://memory:pager@127.0.0.1:3306/memory_pager?charset=utf8mb4'
python backend/tests/test_groups_integration.py    # 28 passed
python backend/tests/test_doodles_integration.py   # 31 passed
python backend/tests/test_pets_integration.py      # 33 passed
```

**레포 루트에서 돌린다.** `backend/` 안에서 `backend/tests/...`를 부르면 경로가 겹친다.

**테스트는 매번 테이블을 비운다. 개발용 DB 에만 돌릴 것.**

### systemd로 상주시키기

`$HOME`과 `$USER`를 실제 값으로 바꿔서 붙인다.

```bash
tee /etc/systemd/system/memory-pager.service >/dev/null <<UNIT
[Unit]
Description=Memory Pager API
After=network.target mysql.service

[Service]
User=$(whoami)
WorkingDirectory=$APP_HOME/backend
Environment="PATH=$VENV/bin"
ExecStart=$VENV/bin/uvicorn app.main:asgi --host 127.0.0.1 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now memory-pager
journalctl -u memory-pager -f
```

`<<UNIT`에 따옴표를 붙이지 않았다. 셸이 `$APP_HOME` 같은 변수를 먼저 풀어야 하기 때문이다.

## 7. Cloudflare Tunnel — 캠프 DNS 셀프서비스 API로

> **`cloudflared tunnel login`을 하지 마라.** 그건 본인 Cloudflare 계정으로 도메인을 소유할 때의 흐름이다. `madcamp-kaist.org`는 운영진 소유이고, 우리는 API로 **이미 만들어진 터널의 토큰**을 받는다. `tunnel create`, `route dns`, `config.yml` 전부 필요 없다. ingress는 API가 관리한다.

### 7-1. API 키를 셸에 둔다

**우리 도메인은 `anjonghwa.madcamp-kaist.org`다.**

```bash
export API_KEY="sk_dns_..."          # 셸에만. 절대 커밋하지 마라
export BASE_URL="https://dns.madcamp-kaist.org"
export SUB="anjonghwa"

curl -s -H "Authorization: Bearer $API_KEY" $BASE_URL/v1/me
```

> **DNS API 키를 레포에 넣지 마라.** 셸 환경변수나 gitignore된 `.env`에만 둔다. 실수로 커밋했거나 어딘가에 붙여넣었다면 운영진에게 폐기·재발급을 요청하는 편이 싸다.
>
> **쓰기 요청은 1분에 10회 제한**이다. 실패해도 연타하지 마라. 429가 나면 `Retry-After`만큼 기다린다.

### 7-2. cloudflared 설치 (VM당 딱 한 번)

```bash
uname -m                                  # x86_64 → amd64
curl -L --output cloudflared.deb \
  https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
dpkg -i cloudflared.deb
cloudflared --version
```

### 7-3. 터널 등록 → 설치 명령어 받기

```bash
curl -s -X POST -H "Authorization: Bearer $API_KEY" $BASE_URL/v1/tunnels
```

응답의 `installCommand`를 **그대로 복사해서 실행**한다. 토큰이 그 안에 들어 있다.

```bash
sudo cloudflared service install eyJhIjoi...
systemctl status cloudflared          # active (running) 이어야 한다
```

**`installCommand`는 이 POST 응답에서만 보여준다.** 나중에 다시 필요하면 `GET /v1/tunnels/token`.

### 7-4. 호스트네임을 8000번 포트에 연결

```bash
curl -s -X POST \
  -H "Authorization: Bearer $API_KEY" -H "Content-Type: application/json" \
  -d "{\"subdomain\": \"$SUB\", \"localPort\": 8000}" \
  $BASE_URL/v1/tunnels/hostnames
```

`name`을 생략하면 `@`, 즉 **서브도메인 자체**(`anjonghwa.madcamp-kaist.org`)가 `localhost:8000`으로 연결된다. 앱 하나뿐이니 이걸로 충분하다. 나중에 프론트를 따로 띄우려면 `"name": "api"`처럼 이름을 줘서 하나 더 만들면 된다.

**포트 제약이 우리 구성과 맞물린다.**

| 규칙 | 우리 상황 |
|---|---|
| `localPort`는 1024~65535 | 8000 ✅ |
| 3306(MySQL)·22(SSH) 등은 차단 | MySQL을 노출할 일이 없다 ✅ |
| 연결 대상은 항상 VM의 `127.0.0.1` | uvicorn을 `--host 127.0.0.1`로 띄운 이유다 ✅ |
| 프로토콜은 `http`만 | uvicorn이 평문 HTTP다. TLS는 Cloudflare가 붙인다 ✅ |

### 7-5. 확인

**서버가 떠 있어야 한다.** 터널만 붙여봐야 502다.

```bash
curl -s localhost:8000/v1/health                      # VM 안에서
curl -s https://$SUB.madcamp-kaist.org/v1/health      # 밖에서
```

안 되면 순서대로 본다.

1. `systemctl status cloudflared` — 연결됐나
2. `curl localhost:8000/v1/health` — 서버가 떠 있나
3. `curl -s -H "Authorization: Bearer $API_KEY" $BASE_URL/v1/tunnels` — 호스트네임이 등록됐나

### 7-6. Socket.IO는 그냥 통과한다

이 터널은 **HTTP ingress**다. WebSocket은 HTTP Upgrade로 시작하므로 그대로 지나간다. Socket.IO도 마찬가지다. 별도 설정이 없다.

앱은 `wss://anjonghwa.madcamp-kaist.org/socket.io/`에 붙고, 네임스페이스는 `/rt`다. Socket.IO 기본 하트비트(25초)가 유휴 종료를 막는다.

다만 **순수 TCP·UDP·WebRTC 미디어는 이 터널로 나가지 못한다.** 우리가 실시간 계층을 Socket.IO로 고른 이유가 이것이다([STACK.md](STACK.md), [SPEC.md](SPEC.md) 5.1절).

여기까지 초록불이면 **Day 1의 관통 절반이 끝난 것**이다. 나머지 절반은 폰에서 소켓이 붙는 것.

> **레코드 한도는 DNS 레코드와 터널 호스트네임을 합산한다.** `GET /v1/me`의 `recordLimit`으로 확인한다.

### 7-7. 터널을 다른 VM으로 옮기기

이미 다른 VM에 터널을 설치해 뒀다면(예: 이전에 1번 VM에서 다른 서비스를 띄웠던 경우), **터널은 계정당 하나**라 같은 터널을 두 곳에서 돌릴 수 없다. 앱 VM으로 옮긴다.

```bash
# 1) 지금 뭘 어디로 보내는지 본다
curl -s -H "Authorization: Bearer $API_KEY" $BASE_URL/v1/tunnels

# 2) 엉뚱한 데를 가리키는 호스트네임을 지운다 (위 응답의 hostnames[].id)
curl -s -X DELETE -H "Authorization: Bearer $API_KEY" \
  $BASE_URL/v1/tunnels/hostnames/<th_...>

# 3) 앱 VM 에서 설치 명령을 다시 받아 실행한다. 터널 자체는 그대로, 실행 위치만 옮긴다.
curl -s -H "Authorization: Bearer $API_KEY" $BASE_URL/v1/tunnels/token
#   → 나온 installCommand 를 앱 VM 에서 실행
cloudflared service install eyJhIjoi...

# 4) 8000 으로 호스트네임을 새로 건다 (7-4)
```

**이전 VM의 cloudflared 는 죽는다.** 같은 터널을 두 곳에서 못 돌리기 때문이다. 이전 VM을 안 쓴다면 문제없다.

---

# ② GPU 서버 (Ubuntu 22.04, `192.168.0.20`)

> **GPU 서버도 22.04(Python 3.10)로 확인됐다.** 초기 문서는 20.04를 가정했으나 실제는 22.04다. RTX 3090이 물리적으로 달려 있다(`lspci`에 `GA102 [GeForce RTX 3090]`). **Python 3.8 격리 절차가 필요 없어졌다.**

## 0. 두 서버 연결 — 확인됨

앱 VM(`172.10.7.229`)에서 `curl http://192.168.0.20:8100`이 200을 돌려준다. 같은 사설망이다. **앱 VM이 GPU를 직접 HTTP로 부른다.** `.env`에 `GPU_LLM_URL=http://192.168.0.20:8100`, `GPU_SD_URL=http://192.168.0.20:8200`.

## 1. 드라이버 — 여기서 막히면 위가 다 무의미하다

GPU 하드웨어와 드라이버 설치를 확인했다(2026-07-11). `nvidia-smi` 기준 Driver 595.71.05, CUDA 13.2, RTX 3090 24GB다. 아래 설치 절차는 VM을 다시 만들 때의 복구용으로 남긴다.

```bash
nvidia-smi                       # "command not found" 면 아래로
lspci | grep -i nvidia           # GA102 [GeForce RTX 3090] 확인
```

`ubuntu-drivers` 명령 자체가 없을 수 있으니 패키지부터 깐다.

```bash
apt update
apt install -y ubuntu-drivers-common
ubuntu-drivers devices           # 권장 드라이버 확인
ubuntu-drivers autoinstall
reboot
```

`ubuntu-drivers`가 계속 말썽이면 직접 지정한다 (22.04에 `nvidia-driver-570`이 있다):

```bash
apt install -y nvidia-driver-570
reboot
```

재부팅 후:

```bash
nvidia-smi                       # 드라이버 버전과 3090이 떠야 한다
```

**CUDA 툴킷은 설치하지 않는다.** torch가 CUDA 런타임을 wheel에 번들한다.

## 2. 시스템 준비

```bash
fallocate -l 16G /swapfile && chmod 600 /swapfile
mkswap /swapfile && swapon /swapfile
echo '/swapfile none swap sw 0 0' >> /etc/fstab

# 작은 /tmp 가 pip 빌드·triton 캐시로 차서 실패하는 것을 막는다
mkdir -p /data/hf /data/tmp
echo 'export HF_HOME=/data/hf'  >> ~/.bashrc
echo 'export TMPDIR=/data/tmp'  >> ~/.bashrc
source ~/.bashrc
```

## 3. venv 두 개 — 시스템 Python 3.10으로 충분

**22.04라 시스템 Python 3.10이 스택 최저선을 만족한다.** uv도 3.8 격리도 필요 없다. venv만 만든다.

```bash
apt install -y python3-venv python3-pip git
python3 -m venv ~/envs/vllm
python3 -m venv ~/envs/sd
```

**venv를 둘로 나누는 이유는 vLLM과 SD의 torch 핀이 충돌하기 때문이다.** `HF_HOME`은 공유해 같은 가중치를 두 번 받지 않게 한다.

레포를 클론하거나(requirements 파일 때문에) 필요한 파일만 받는다.

```bash
cd ~ && git clone -b anjonghwa https://github.com/madcamp-official/26s-w2-c1-04.git
```

## 4. vLLM

```bash
cd ~/26s-w2-c1-04
source ~/envs/vllm/bin/activate
pip install -r gpu/requirements-vllm.txt

# 두 값은 실측으로 확인됨(2026-07-11). 빼면 부팅이 크래시 루프에 빠진다.
VLLM_SERVER_DEV_MODE=1 VLLM_USE_FLASHINFER_SAMPLER=0 \
  vllm serve LGAI-EXAONE/EXAONE-3.5-7.8B-Instruct-AWQ \
  --trust-remote-code \
  --gpu-memory-utilization 0.4 \
  --max-model-len 8192 --max-num-seqs 16 \
  --enable-sleep-mode --port 8100
```

**`--trust-remote-code` 는 필수다.** EXAONE 3.5 는 커스텀 모델링 코드를 포함해서, 이게 없으면
`ModelConfig` 검증에서 `trust_remote_code=True` 를 요구하며 죽는다(pydantic ValidationError).

**`VLLM_USE_FLASHINFER_SAMPLER=0` 도 필수다.** FlashInfer 의 top-k/top-p 샘플러가 런타임에
CUDA 커널을 JIT 컴파일하려고 `nvcc`(CUDA 툴킷)를 찾는데, 여기엔 드라이버만 있고 툴킷은 없다
(`Could not find nvcc ... /usr/local/cuda`). 툴킷을 깔지 않는다(torch·SD 가 런타임을 번들). 대신
이 환경변수로 FlashInfer 샘플러를 꺼 vLLM 기본 PyTorch 샘플링 경로를 쓰게 한다.

`--gpu-memory-utilization`은 24GB의 비율이다. `0.4`면 약 9.8GB 상한. SD(~3GB)와 합쳐도 24GB에 든다.
(SD가 이미 떠 있으면 vLLM 가중치 로드까지 약 8.4GB 점유가 관찰된다.)

**두 가지를 반드시 확인한다.**

```bash
nvidia-smi                              # 점유가 약 8GB대 여야 한다
curl -s localhost:8100/is_sleeping      # 404 가 나오면 VLLM_SERVER_DEV_MODE 가 안 먹은 것
```

기본값(0.9)으로 뜨면 약 22GB를 선점해 SD가 못 올라온다. 반드시 `0.4`(또는 그 이하)가 들어갔는지 확인한다.

> **실제 배포는 systemd 로 돈다.** `mp-vllm.service`(EXAONE)와 `mp-sd.service`(SD 1.5)가 부팅 시 자동 기동된다. 앱 VM `.env` 는 `GPU_ENABLED=true`, `GPU_LLM_URL=http://192.168.0.20:8100`, `GPU_SD_URL=http://192.168.0.20:8200`, `LLM_MODEL=LGAI-EXAONE/EXAONE-3.5-7.8B-Instruct-AWQ`. GPU 사설 IP 는 `192.168.0.20`(앱 VM 은 같은 /24 의 `192.168.0.213`) — `10.x` 대가 아니다. 헬스는 `GET /v1/health` 의 `"gpu":"ok"` 로 확인(vLLM·SD 둘 다 200 이어야 ok).

## 5. Stable Diffusion 1.5

```bash
source ~/envs/sd/bin/activate
pip install -r gpu/requirements-sd.txt
uvicorn gpu.sd_worker:app --host 0.0.0.0 --port 8200
```

다른 셸에서 `curl http://127.0.0.1:8200/health`를 확인한다. 모델을 받지 않고 계약만 검사할 때는 `SD_STUB=true`로 실행한다. 실제 모드는 모델을 백그라운드에서 읽는 동안 `/health`가 503 `loading`, 완료 후 200 `ok`를 반환한다.

**SDXL은 쓰지 않는다.** 24GB에서 상주 LLM과 겨우 공존은 하나(합 21~23GB) 헤드룸이 없어 OOM 위험이 있다. SD 1.5는 추론 4~6GB, LoRA 학습 6~8GB라 여유 있게 LLM을 켠 채로 돌아간다.

무거운 배치(LoRA 학습) 직전에는 vLLM을 재운다:

```bash
curl -X POST localhost:8100/sleep?level=1   # GPU 를 비운다
# ... 학습 ...
curl -X POST localhost:8100/wake_up         # 3~6초
```

---

# 확인 체크리스트

| | 확인 방법 | 통과 기준 | 상태 |
|---|---|---|---|
| 두 서버 연결 | 앱 VM에서 `curl http://192.168.0.20:8100/` | 200 | ✅ 확인됨 |
| MySQL 스키마 | `bash backend/tests/test_schema_mysql.sh` | 17 passed | ✅ |
| 라우터 | `DATABASE_URL=... python backend/tests/test_groups_integration.py` | 28 passed | ✅ |
| API 로컬 | `curl localhost:8000/v1/health` | `db: ok` | ✅ |
| **API 외부** | 노트북에서 `curl.exe https://anjonghwa.madcamp-kaist.org/v1/health` | 우리 JSON | ✅ `gpu:ok` 포함 (2026-07-11) |
| GPU 드라이버 | `nvidia-smi` | 뜨면 OK (570+ 권장) | ✅ 595.71.05 / RTX 3090 24GB |
| vLLM 점유 | `nvidia-smi` | **약 8~10GB** (18GB면 실패) | ✅ ~9.8GB (SD 합 ~17GB) |
| vLLM sleep | `curl localhost:8100/is_sleeping` | 404 아님 | ✅ `is_sleeping:false` |
| GPU 실추론 E2E | 앱 VM에서 펫활동·캡션(LLM)+그림일기(SD) | 실제 출력 | ✅ EXAONE JSON + 512px PNG |

> **PowerShell에서는 `curl`이 `Invoke-WebRequest`의 별칭이다.** 진짜 curl은 `curl.exe`로 부른다. VM 안(리눅스 셸)에서는 그냥 `curl`이 맞다.
