# GPU 서버 systemd 유닛

GPU 서버(`192.168.0.20`, Ubuntu 22.04)에서 두 추론 서버를 상주시키는 유닛이다.
설치 절차 전체는 [docs/SETUP.md](../../docs/SETUP.md) ② 참조. 여기 파일은 **실배포와 동일**하다.

| 유닛 | 포트 | venv | 역할 |
|---|---|---|---|
| `mp-vllm.service` | 8100 | `~/envs/vllm` | EXAONE 3.5 7.8B AWQ (OpenAI 호환) |
| `mp-sd.service`   | 8200 | `~/envs/sd`   | Stable Diffusion 1.5 그림일기 워커 |

```bash
cp gpu/systemd/mp-vllm.service gpu/systemd/mp-sd.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now mp-vllm mp-sd     # 첫 부팅은 모델 다운로드로 오래 걸린다
```

확인:

```bash
curl -s localhost:8100/v1/models                 # EXAONE 모델 노출
curl -s localhost:8100/is_sleeping               # {"is_sleeping":false} (404 면 DEV_MODE 미적용)
curl -s localhost:8200/health                    # {"status":"ok",...} (loading 이면 아직 모델 로드 중)
nvidia-smi --query-gpu=memory.used --format=csv,noheader   # 합 ~17GB (vLLM ~9.8 + SD ~7)
```

앱 VM 은 이 두 서버를 `.env` 의 `GPU_LLM_URL`/`GPU_SD_URL` 로 직접 HTTP 호출한다.
`GET /v1/health` 의 `"gpu":"ok"` 가 둘 다 200 임을 보증한다.
