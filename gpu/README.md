# Memory Pager GPU workers

LLM은 vLLM의 OpenAI 호환 서버(`:8100`), 그림 일기는 이 디렉터리의 SD worker(`:8200`)가 담당한다. 두 프로세스는 서로 다른 venv에서 실행한다.

```bash
python3 -m venv ~/envs/sd
source ~/envs/sd/bin/activate
pip install -r gpu/requirements-sd.txt
uvicorn gpu.sd_worker:app --host 0.0.0.0 --port 8200
```

모델 다운로드 없이 API 계약만 확인할 때는 스텁 모드를 쓴다.

```bash
SD_STUB=true uvicorn gpu.sd_worker:app --host 127.0.0.1 --port 8200
curl http://127.0.0.1:8200/health
```

실제 모드는 기본적으로 `stable-diffusion-v1-5/stable-diffusion-v1-5`를 fp16으로 CUDA에 올린다. 환경변수 접두사는 `SD_`다: `SD_MODEL_ID`, `SD_DEVICE`, `SD_WIDTH`, `SD_HEIGHT`, `SD_INFERENCE_STEPS`, `SD_GUIDANCE_SCALE`.

`style.kind=learned`는 PT-5/PT-6b(P2)이므로 현재 501을 반환한다. P1의 기본 그림체 일기는 완전히 동작하며, learned 요청을 기본 화풍으로 조용히 위장하지 않는다.
