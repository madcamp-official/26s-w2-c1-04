# Memory Pager — 서버 구축 순서

> 버전·근거는 [STACK.md](STACK.md). 이 문서는 **복사해서 붙이는 순서**만 담는다.
> 보안은 이 프로젝트의 비목표다([SPEC.md](SPEC.md) 1.2절). 비밀번호 강도를 신경쓰지 않는다.

| | ① 앱 VM | ② GPU 서버 |
|---|---|---|
| OS | Ubuntu **24.04** (Python 3.12) | Ubuntu **20.04** (Python 3.8) |
| 스펙 | 4 vCPU / **4GB RAM** / 100GB | 40 vCPU / 50GB RAM / 100GB / RTX 3090 **20GB** |
| 개방 포트 | 22 · 80 · 443 | (외부 노출 안 함) |
| 도는 것 | FastAPI, Socket.IO, MySQL 8, 미디어 | vLLM, SD 1.5 |

---

# ① 앱 VM

## 0. 먼저 확인 — OS와 사용자

```bash
cat /etc/os-release | head -2
python3 --version
whoami
```

**OS 템플릿은 `ubuntu-24-pw`였지만 실제로 22.04일 수 있다.** `mysql --version`이 `0ubuntu0.22.04.x`를 뱉으면 22.04다.

| | Ubuntu 22.04 | Ubuntu 24.04 |
|---|---|---|
| 기본 Python | 3.10 | 3.12 |
| 우리 스택 | ✅ 동작 (최저선이 3.10) | ✅ |
| PEP 668 (시스템 pip 차단) | 없음 | 있음 |

**22.04여도 그대로 간다.** `requirements.txt`의 최저 요구가 Python 3.10이라 딱 맞는다. 다만 여유가 없으니 시스템 Python을 건드리지 말고 venv를 쓴다.

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
```

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

## 7. Cloudflare Tunnel

```bash
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb -o cloudflared.deb
sudo dpkg -i cloudflared.deb
cloudflared tunnel login          # 브라우저에서 도메인 인증
cloudflared tunnel create memory-pager
cloudflared tunnel route dns memory-pager <서브도메인>.<도메인>
```

`~/.cloudflared/config.yml`:

```yaml
tunnel: memory-pager
credentials-file: /home/ubuntu/.cloudflared/<UUID>.json

ingress:
  - hostname: <서브도메인>.<도메인>
    service: http://localhost:8000
  - service: http_status:404
```

```bash
cloudflared tunnel run memory-pager
# 또는: sudo cloudflared service install
```

**WebSocket은 별도 설정이 필요 없다.** ingress에 `http://localhost:8000`만 등록하면 Tunnel이 자동으로 프록시한다. Socket.IO의 기본 하트비트(25초)가 유휴 종료를 막는다.

밖에서 확인:

```bash
curl -s https://<서브도메인>.<도메인>/v1/health
```

여기까지 초록불이면 **Day 1의 관통 절반이 끝난 것**이다. 나머지 절반은 폰에서 소켓이 붙는 것.

---

# ② GPU 서버 (Ubuntu 20.04) — 접속되면

## 0. 두 서버가 서로 보이는지부터 — 최우선

**이게 안 되면 Day 5를 통째로 날린다.** GPU 서버에서 아무 포트나 띄우고 앱 VM에서 부른다.

```bash
# GPU 서버에서
python3 -m http.server 8100

# 앱 VM에서
curl -m 5 http://<GPU_사설IP>:8100/
```

- **되면:** 앱 VM이 GPU 서버를 직접 HTTP로 부른다. `.env`의 `GPU_LLM_URL`·`GPU_SD_URL`에 사설 IP를 넣는다.
- **안 되면:** GPU 서버가 앱 VM의 잡 큐를 폴링하는 아웃바운드 전용 구조로 바꾼다. 구현이 하루 더 든다. 바로 알려달라.

## 1. 드라이버 — 여기서 막히면 위가 다 무의미하다

```bash
nvidia-smi
```

없거나 570 미만이면:

```bash
sudo ubuntu-drivers autoinstall
sudo reboot
```

**CUDA 툴킷은 설치하지 않는다.** torch가 CUDA 런타임을 wheel에 번들한다.

## 2. 시스템 준비

```bash
sudo fallocate -l 16G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# 작은 /tmp 가 pip 빌드·triton 캐시로 차서 실패하는 것을 막는다
sudo mkdir -p /data/hf /data/tmp && sudo chown -R $USER /data
echo 'export HF_HOME=/data/hf'  >> ~/.bashrc
echo 'export TMPDIR=/data/tmp'  >> ~/.bashrc
source ~/.bashrc
```

## 3. Python 3.11 — 시스템 3.8은 **절대 건드리지 않는다**

apt 유틸들이 3.8에 묶여 있어 업그레이드하면 OS가 깨진다. `uv`로 격리 설치한다.

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc

uv venv --python 3.11 ~/envs/vllm
uv venv --python 3.11 ~/envs/sd
```

**venv를 둘로 나누는 이유는 vLLM과 SD의 torch 핀이 충돌하기 때문이다.** `HF_HOME`은 공유해 같은 가중치를 두 번 받지 않게 한다.

## 4. vLLM

```bash
source ~/envs/vllm/bin/activate
pip install -r gpu/requirements-vllm.txt

VLLM_SERVER_DEV_MODE=1 vllm serve LGAI-EXAONE/EXAONE-3.5-7.8B-Instruct-AWQ \
  --gpu-memory-utilization 0.4 \
  --max-model-len 8192 --max-num-seqs 16 \
  --enable-sleep-mode --port 8100
```

**두 가지를 반드시 확인한다.**

```bash
nvidia-smi                              # 점유가 약 8GB 여야 한다
curl -s localhost:8100/is_sleeping      # 404 가 나오면 VLLM_SERVER_DEV_MODE 가 안 먹은 것
```

18GB가 잡히면 `--gpu-memory-utilization` 인자가 안 들어간 것이다. 그러면 SD가 못 올라온다.

## 5. Stable Diffusion 1.5

```bash
source ~/envs/sd/bin/activate
pip install -r gpu/requirements-sd.txt
```

**SDXL은 쓰지 않는다.** 단독 학습은 20GB에 들어가지만(피크 13~15GB) 상주 LLM과는 21~23GB로 공존하지 못한다. SD 1.5는 추론 4~6GB, LoRA 학습 6~8GB라 LLM을 켠 채로 돌아간다.

무거운 배치(LoRA 학습) 직전에는 vLLM을 재운다:

```bash
curl -X POST localhost:8100/sleep?level=1   # GPU 를 비운다
# ... 학습 ...
curl -X POST localhost:8100/wake_up         # 3~6초
```

---

# 확인 체크리스트

| | 확인 방법 | 통과 기준 |
|---|---|---|
| MySQL 스키마 | `bash backend/tests/test_schema_mysql.sh` | 17 passed |
| 라우터 | `DATABASE_URL=... python backend/tests/test_groups_integration.py` | 28 passed |
| API 로컬 | `curl localhost:8000/v1/health` | `db: ok` |
| API 외부 | `curl https://<도메인>/v1/health` | 같은 응답 |
| **두 서버 연결** | 앱 VM에서 `curl http://<GPU_IP>:8100/health` | 200 |
| GPU 드라이버 | `nvidia-smi` | 570 이상 |
| vLLM 점유 | `nvidia-smi` | **약 8GB** (18GB면 실패) |
| vLLM sleep | `curl localhost:8100/is_sleeping` | 404 아님 |
