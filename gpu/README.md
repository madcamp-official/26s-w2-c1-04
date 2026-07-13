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

실제 모드는 기본적으로 `stable-diffusion-v1-5/stable-diffusion-v1-5`를 fp16으로 CUDA에 올린다. 환경변수 접두사는 `SD_`다: `SD_MODEL_ID`, `SD_DEVICE`, `SD_WIDTH`, `SD_HEIGHT`, `SD_INFERENCE_STEPS`, `SD_GUIDANCE_SCALE`, LoRA용 `SD_LORA_DIR`, `SD_LORA_STEPS`, `SD_LORA_RANK`, `SD_LORA_LR`.

**LoRA 화풍 학습(구현 완료):**
- `POST /train/style` — 손그림 여러 장(멀티파트 `files`) + `style_id` → SD 1.5 LoRA(UNet attention, rank8) 학습 → `SD_LORA_DIR/{style_id}/pytorch_lora_weights.safetensors` 저장. 300 step ~64s, 가중치 ~6.4MB. 생성 락으로 감싸 VRAM 경합 차단, 학습 후 임시 어댑터는 `finally` 로 제거.
- `POST /generate/diary` 의 `style.kind=learned`(+`weights_path`) — 해당 어댑터를 로드해 트리거 프롬프트로 렌더. `weights_path` 없는 learned 는 400(기본 화풍으로 위장하지 않음).
- `peft`·`bitsandbytes`·`python-multipart` 는 `requirements-sd.txt` 에 포함(신규 배포에서도 재현됨).
- BLIP 캡션(`POST /caption`)도 상주해 낙서→영어 서술을 제공한다.
