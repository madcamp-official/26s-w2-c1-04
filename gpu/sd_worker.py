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
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from datetime import date
from typing import Any, Literal

from fastapi import FastAPI, File, HTTPException, Response, UploadFile
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


def _generate(body: DiaryImageIn) -> Image.Image:
    if settings.stub:
        return _stub_image(body)
    if _pipeline is None:
        raise RuntimeError(_load_error or "SD 모델을 아직 불러오는 중입니다")

    import torch

    prompt, negative = build_prompt(body)
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


@app.post("/generate/diary")
async def generate_diary(body: DiaryImageIn) -> Response:
    if body.style.kind == "learned":
        # LoRA 학습·동적 어댑터 전환은 PT-5/PT-6b(P2)다. 잘못 기본 화풍으로
        # 생성해 learned라고 기록하는 것보다 명시적으로 거부한다.
        raise HTTPException(status_code=501, detail="learned style is not enabled")
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
