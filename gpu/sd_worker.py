"""Stable Diffusion 1.5 일기 이미지 워커.

실행:
    uvicorn gpu.sd_worker:app --host 0.0.0.0 --port 8200

로컬 계약 검증:
    SD_STUB=true uvicorn gpu.sd_worker:app --port 8200
"""

from __future__ import annotations

import asyncio
import hashlib
import io
import logging
import os
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import date
from typing import Any, Literal

from fastapi import FastAPI, File, Form, HTTPException, Response, UploadFile
from PIL import Image, ImageDraw, ImageFont
from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict

logger = logging.getLogger(__name__)

Activity = Literal["eating", "sleeping", "walking", "playing", "drawing", "waiting"]


class WorkerSettings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="SD_", extra="ignore")

    model_id: str = "stable-diffusion-v1-5/stable-diffusion-v1-5"
    device: str = "cuda"
    width: int = 512
    height: int = 512
    inference_steps: int = 28
    guidance_scale: float = 7.0
    stub: bool = False
    # LoRA 화풍 학습
    lora_dir: str = "/data/lora"
    lora_steps: int = 300
    lora_rank: int = 8
    lora_lr: float = 1e-4


class StyleIn(BaseModel):
    kind: Literal["default", "learned"] = "default"
    weights_path: str | None = None


class DiaryImageIn(BaseModel):
    group_id: str = Field(pattern=r"^[1-9]\d*$")
    entry_date: date
    activities: list[Activity] = Field(min_length=1, max_length=24)
    caption: str = Field(min_length=1, max_length=255)
    style: StyleIn


settings = WorkerSettings()
_pipeline: Any | None = None
_load_error: str | None = None
_load_task: asyncio.Task[None] | None = None
_generation_lock = asyncio.Lock()

# BLIP 이미지 캡션(낙서/사진을 영어로 서술 → 백엔드가 EXAONE으로 펫 말투 한국어 변환).
_BLIP_MODEL = "Salesforce/blip-image-captioning-base"
_blip: Any | None = None  # (processor, model)
_blip_error: str | None = None

# LoRA 화풍 학습/서빙. 커플 손그림으로 SD 1.5 LoRA를 학습해 learned 일기에 적용한다.
# 학습·렌더 모두 트리거 토큰을 프롬프트에 넣어 화풍을 호출한다.
_LORA_TRIGGER = "sksdoodle"
_LORA_TRAIN_PROMPT = f"{_LORA_TRIGGER}, a hand-drawn doodle in a personal sketchy style"
_active_lora: str | None = None  # 현재 _pipeline 에 로드된 어댑터 경로(없으면 None)

_ACTIVITY_PROMPTS = {
    "eating": "happily eating a small meal",
    "sleeping": "sleeping under a soft blanket",
    "walking": "taking a cheerful walk",
    "playing": "playing with a colorful toy",
    "drawing": "drawing with crayons",
    "waiting": "waiting by the window",
}


def build_prompt(body: DiaryImageIn) -> tuple[str, str]:
    actions = ", ".join(_ACTIVITY_PROMPTS[item] for item in body.activities)
    prompt = (
        "one cute orange companion pet, "
        f"{actions}, cozy home, warm daylight, simple children's picture book "
        "illustration, clean outlines, soft colors, centered composition, no text"
    )
    negative = (
        "photorealistic, human, multiple characters, text, letters, watermark, logo, "
        "blurry, low quality, deformed, extra limbs, cropped"
    )
    return prompt, negative


def _seed(body: DiaryImageIn) -> int:
    digest = hashlib.sha256(
        f"{body.group_id}:{body.entry_date.isoformat()}".encode()
    ).digest()
    return int.from_bytes(digest[:4], "big")


def _load_pipeline() -> None:
    global _pipeline, _load_error
    try:
        import torch
        from diffusers import StableDiffusionPipeline

        if settings.device.startswith("cuda") and not torch.cuda.is_available():
            raise RuntimeError("CUDA를 사용할 수 없습니다")
        dtype = torch.float16 if settings.device.startswith("cuda") else torch.float32
        pipeline = StableDiffusionPipeline.from_pretrained(
            settings.model_id,
            torch_dtype=dtype,
            use_safetensors=True,
        )
        pipeline = pipeline.to(settings.device)
        pipeline.set_progress_bar_config(disable=True)
        _pipeline = pipeline
        _load_error = None
        logger.info("SD 모델 로드 완료: %s (%s)", settings.model_id, settings.device)
    except Exception as exc:
        _load_error = f"{type(exc).__name__}: {exc}"
        logger.exception("SD 모델 로드 실패")


async def _load_pipeline_async() -> None:
    await asyncio.to_thread(_load_pipeline)


def _stub_image(body: DiaryImageIn) -> Image.Image:
    image = Image.new("RGB", (settings.width, settings.height), (246, 244, 238))
    draw = ImageDraw.Draw(image)
    font = ImageFont.load_default(size=22)
    width, height = image.size
    draw.rounded_rectangle(
        (width * 0.14, height * 0.12, width * 0.86, height * 0.86),
        radius=28,
        fill=(255, 255, 255),
    )
    draw.ellipse(
        (width * 0.32, height * 0.25, width * 0.68, height * 0.61),
        fill=(245, 173, 88),
        outline=(45, 45, 45),
        width=4,
    )
    draw.ellipse(
        (width * 0.40, height * 0.38, width * 0.44, height * 0.42), fill=(45, 45, 45)
    )
    draw.ellipse(
        (width * 0.56, height * 0.38, width * 0.60, height * 0.42), fill=(45, 45, 45)
    )
    draw.arc(
        (width * 0.44, height * 0.40, width * 0.56, height * 0.50),
        start=10,
        end=170,
        fill=(45, 45, 45),
        width=4,
    )
    label = " / ".join(body.activities)
    draw.text((width * 0.18, height * 0.70), label[:36], fill=(45, 45, 45), font=font)
    draw.text(
        (width * 0.18, height * 0.77),
        body.entry_date.isoformat(),
        fill=(95, 95, 95),
        font=font,
    )
    return image


def _set_lora(path: str | None) -> None:
    """_pipeline 에 로드된 LoRA 어댑터를 path 로 맞춘다(없으면 언로드). 락 안에서 호출."""
    global _active_lora
    if path == _active_lora:
        return
    if _active_lora is not None:
        _pipeline.unload_lora_weights()
        _active_lora = None
    if path is not None:
        _pipeline.load_lora_weights(path)
        _active_lora = path


def _generate(body: DiaryImageIn) -> Image.Image:
    if settings.stub:
        return _stub_image(body)
    if _pipeline is None:
        raise RuntimeError(_load_error or "SD 모델을 아직 불러오는 중입니다")

    import torch

    learned = body.style.kind == "learned" and bool(body.style.weights_path)
    _set_lora(body.style.weights_path if learned else None)

    prompt, negative = build_prompt(body)
    if learned:
        prompt = f"{_LORA_TRIGGER}, {prompt}"
    generator = torch.Generator(device=settings.device).manual_seed(_seed(body))
    result = _pipeline(
        prompt=prompt,
        negative_prompt=negative,
        width=settings.width,
        height=settings.height,
        num_inference_steps=settings.inference_steps,
        guidance_scale=settings.guidance_scale,
        generator=generator,
    )
    return result.images[0].convert("RGB")


def _train_lora(images: list[bytes], out_dir: str) -> dict[str, Any]:
    """커플 손그림 여러 장으로 SD 1.5 LoRA(UNet attention)를 학습해 out_dir 에 저장한다.

    상주 _pipeline 컴포넌트(VAE/텍스트인코더/UNet)를 재사용한다. peak VRAM ~6GB
    (실측 2026-07-11). 학습이 끝나면 임시 어댑터를 제거해 기본 화풍을 되돌린다.
    """
    import numpy as np
    import torch
    import torch.nn.functional as F
    from diffusers import DDPMScheduler, StableDiffusionPipeline
    from diffusers.utils import convert_state_dict_to_diffusers
    from peft import LoraConfig
    from peft.utils import get_peft_model_state_dict

    if _pipeline is None:
        raise RuntimeError(_load_error or "SD 파이프라인이 아직 로드되지 않았다")

    device = settings.device
    pipe = _pipeline
    unet, vae, text_encoder, tokenizer = (
        pipe.unet,
        pipe.vae,
        pipe.text_encoder,
        pipe.tokenizer,
    )
    noise_scheduler = DDPMScheduler.from_config(pipe.scheduler.config)

    adapter = "train_tmp"
    unet.add_adapter(
        LoraConfig(
            r=settings.lora_rank,
            lora_alpha=settings.lora_rank,
            init_lora_weights="gaussian",
            target_modules=["to_k", "to_q", "to_v", "to_out.0"],
        ),
        adapter_name=adapter,
    )
    vae.requires_grad_(False)
    text_encoder.requires_grad_(False)
    lora_params = []
    for name, param in unet.named_parameters():
        if "lora" in name:
            param.requires_grad_(True)
            param.data = param.data.float()  # 학습 파라미터는 fp32 로(안정)
            lora_params.append(param)
        else:
            param.requires_grad_(False)

    try:
        import bitsandbytes as bnb

        optimizer = bnb.optim.AdamW8bit(lora_params, lr=settings.lora_lr)
    except Exception:
        optimizer = torch.optim.AdamW(lora_params, lr=settings.lora_lr)

    tokens = tokenizer(
        _LORA_TRAIN_PROMPT,
        padding="max_length",
        max_length=tokenizer.model_max_length,
        truncation=True,
        return_tensors="pt",
    ).input_ids.to(device)
    with torch.no_grad():
        enc = text_encoder(tokens)[0]

    def prep(data: bytes) -> torch.Tensor:
        image = Image.open(io.BytesIO(data)).convert("RGB").resize(
            (settings.width, settings.height)
        )
        arr = np.asarray(image, dtype=np.float32) / 127.5 - 1.0
        return torch.from_numpy(arr).permute(2, 0, 1)

    tensors = [prep(b) for b in images]
    scaler = torch.cuda.amp.GradScaler()
    unet.train()
    steps = settings.lora_steps
    last_loss = 0.0
    for step in range(steps):
        img = tensors[step % len(tensors)].unsqueeze(0).to(device, dtype=torch.float16)
        with torch.no_grad():
            latents = vae.encode(img).latent_dist.sample() * vae.config.scaling_factor
        noise = torch.randn_like(latents)
        timesteps = torch.randint(
            0, noise_scheduler.config.num_train_timesteps, (latents.shape[0],), device=device
        ).long()
        noisy = noise_scheduler.add_noise(latents, noise, timesteps)
        with torch.autocast("cuda", dtype=torch.float16):
            pred = unet(noisy, timesteps, encoder_hidden_states=enc).sample
            loss = F.mse_loss(pred.float(), noise.float())
        optimizer.zero_grad()
        scaler.scale(loss).backward()
        scaler.step(optimizer)
        scaler.update()
        last_loss = float(loss.detach())

    os.makedirs(out_dir, exist_ok=True)
    state = convert_state_dict_to_diffusers(
        get_peft_model_state_dict(unet, adapter_name=adapter)
    )
    StableDiffusionPipeline.save_lora_weights(
        save_directory=out_dir, unet_lora_layers=state, safe_serialization=True
    )

    unet.delete_adapters(adapter)  # 상주 파이프라인을 기본 화풍으로 되돌림
    unet.eval()
    torch.cuda.empty_cache()
    return {
        "weights_path": out_dir,
        "steps": steps,
        "num_images": len(images),
        "final_loss": round(last_loss, 4),
    }


def _load_blip() -> None:
    global _blip, _blip_error
    try:
        import torch
        from transformers import BlipForConditionalGeneration, BlipProcessor

        dtype = torch.float16 if settings.device.startswith("cuda") else torch.float32
        processor = BlipProcessor.from_pretrained(_BLIP_MODEL)
        model = BlipForConditionalGeneration.from_pretrained(
            _BLIP_MODEL, torch_dtype=dtype
        ).to(settings.device)
        _blip = (processor, model)
        _blip_error = None
        logger.info("BLIP 캡션 모델 로드 완료: %s", _BLIP_MODEL)
    except Exception as exc:
        _blip_error = f"{type(exc).__name__}: {exc}"
        logger.exception("BLIP 로드 실패")


def _caption_image(data: bytes) -> str:
    if settings.stub:
        return "a cute little drawing"
    if _blip is None:
        _load_blip()
    if _blip is None:
        raise RuntimeError(_blip_error or "BLIP 모델을 불러오지 못했습니다")

    import torch

    processor, model = _blip
    image = Image.open(io.BytesIO(data)).convert("RGB")
    inputs = processor(images=image, return_tensors="pt").to(settings.device)
    if settings.device.startswith("cuda"):
        inputs["pixel_values"] = inputs["pixel_values"].to(torch.float16)
    with torch.no_grad():
        out = model.generate(
            **inputs,
            max_new_tokens=25,
            num_beams=3,
            repetition_penalty=1.8,
            no_repeat_ngram_size=2,
        )
    return processor.decode(out[0], skip_special_tokens=True).strip()


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    global _load_task
    if not settings.stub:
        _load_task = asyncio.create_task(_load_pipeline_async())
    yield
    if _load_task is not None:
        await asyncio.gather(_load_task, return_exceptions=True)


app = FastAPI(title="Memory Pager SD Worker", version="0.1.0", lifespan=lifespan)


@app.get("/health")
async def health(response: Response) -> dict[str, str]:
    if settings.stub:
        return {"status": "stub", "model": settings.model_id}
    if _pipeline is not None:
        return {"status": "ok", "model": settings.model_id}
    if _load_error is not None:
        response.status_code = 503
        return {"status": "down", "error": _load_error}
    response.status_code = 503
    return {"status": "loading", "model": settings.model_id}


@app.post("/caption")
async def caption(file: UploadFile = File(...)) -> dict[str, str]:
    """이미지(낙서/사진) → 영어 캡션(BLIP). 백엔드가 EXAONE으로 한국어 펫 말투로 바꾼다."""
    data = await file.read()
    if not data:
        raise HTTPException(status_code=400, detail="empty image")
    async with _generation_lock:  # SD 생성과 VRAM 경합 방지
        try:
            text = await asyncio.to_thread(_caption_image, data)
        except Exception as exc:
            logger.exception("캡션 생성 실패")
            raise HTTPException(status_code=503, detail="caption failed") from exc
    return {"caption": text}


@app.post("/train/style")
async def train_style(
    style_id: str = Form(...),
    files: list[UploadFile] = File(...),
) -> dict[str, Any]:
    """커플 손그림들로 그룹 화풍 LoRA 를 학습한다. weights_path 를 백엔드가 style_models 에 저장."""
    if settings.stub:
        return {
            "weights_path": os.path.join(settings.lora_dir, style_id),
            "steps": 0,
            "num_images": len(files),
            "stub": True,
        }
    if _pipeline is None:
        raise HTTPException(
            status_code=503, detail=_load_error or "Stable Diffusion model is loading"
        )
    images = [b for b in [await f.read() for f in files] if b]
    if len(images) < 5:
        raise HTTPException(status_code=400, detail="need at least 5 drawings to train")
    out_dir = os.path.join(settings.lora_dir, style_id)
    async with _generation_lock:  # 학습 중 SD 생성 차단(VRAM 안전장치)
        try:
            info = await asyncio.to_thread(_train_lora, images, out_dir)
        except Exception as exc:
            logger.exception("LoRA 학습 실패")
            raise HTTPException(status_code=503, detail="lora training failed") from exc
    return info


@app.post("/generate/diary")
async def generate_diary(body: DiaryImageIn) -> Response:
    if body.style.kind == "learned" and not body.style.weights_path:
        # learned 라면서 가중치 경로가 없으면 기본 화풍으로 렌더하고 learned 라 속이는
        # 것보다 명시적으로 거부한다.
        raise HTTPException(status_code=400, detail="learned style requires weights_path")
    if not settings.stub and _pipeline is None:
        raise HTTPException(
            status_code=503,
            detail=_load_error or "Stable Diffusion model is loading",
        )

    async with _generation_lock:
        try:
            image = await asyncio.to_thread(_generate, body)
        except Exception as exc:
            logger.exception("일기 이미지 생성 실패")
            raise HTTPException(
                status_code=503, detail="image generation failed"
            ) from exc

    output = io.BytesIO()
    image.save(output, "PNG")
    return Response(
        content=output.getvalue(),
        media_type="image/png",
        headers={"X-Memory-Pager-Mode": "stub" if settings.stub else "sd15"},
    )
