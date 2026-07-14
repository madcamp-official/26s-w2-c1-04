"""GPU 서버 클라이언트. 스텁과 실물을 같은 인터페이스 뒤에 둔다.

**앱과 백엔드 작업이 GPU 환경 구성에 막히면 안 된다.** `GPU_ENABLED=false`(기본)면
스텁이 그럴듯한 값을 돌려주고, GPU 서버가 준비되면 환경변수 하나로 갈아끼운다.

GPU 서버가 죽어도 앱은 살아야 한다. LLM 실패는 스텁 대사로 열화한다. 이미지 실패는
빈 PNG를 일기로 위장하지 않고 그날 일기 생성을 건너뛴다.

내부 API 명세는 docs/API.md 11절.
"""

from __future__ import annotations

import io
import logging
import random
import re
from dataclasses import dataclass
from typing import Protocol

import httpx
from PIL import Image, ImageDraw, ImageFont

from .config import Settings, get_settings

logger = logging.getLogger(__name__)

# docs/ERD.md 의 pet_activities.activity ENUM 과 값이 같아야 한다.
ACTIVITIES = ("eating", "sleeping", "walking", "playing", "drawing", "waiting")

# vLLM 에 강제할 응답 스키마. activity 가 자유 문자열이면 SD 프롬프트를 조립할 수 없다.
PET_ACTIVITY_SCHEMA = {
    "type": "object",
    "properties": {
        "activity": {"type": "string", "enum": list(ACTIVITIES)},
        "utterance": {"type": "string", "maxLength": 120},
    },
    "required": ["activity", "utterance"],
    "additionalProperties": False,
}

_STUB_UTTERANCES = {
    "eating": "밥 먹는 중! 오늘 뭐 했어?",
    "sleeping": "방금 밥 먹고 졸려…",
    "walking": "산책 나왔어. 날씨 좋다!",
    "playing": "심심해서 혼자 놀고 있었어.",
    "drawing": "너희 그림 따라 그려보는 중이야.",
    "waiting": "언제 오나 기다리고 있었어.",
}


@dataclass(frozen=True)
class PetActivity:
    activity: str
    utterance: str
    model: str


@dataclass(frozen=True)
class GroupContext:
    """LLM 에 넘길 그룹의 최근 활동 요약."""

    pet_level: int
    doodles_24h: int
    pokes_24h: int
    last_content_type: str | None


class LlmClient(Protocol):
    async def pet_activity(self, ctx: GroupContext) -> PetActivity: ...
    async def diary_caption(self, activities: list[str], pet_name: str) -> str: ...
    async def doodle_caption(
        self, english: str, pet_name: str, sender_name: str
    ) -> str: ...
    async def curate_albums(self, items: list[dict]) -> list[dict]: ...
    async def health(self) -> bool: ...


# 앨범 큐레이션(#6) 출력 스키마 — 2~4개 앨범, 각 제목 + 소속 낙서 id.
ALBUM_CURATION_SCHEMA = {
    "type": "object",
    "properties": {
        "albums": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "title": {"type": "string", "maxLength": 24},
                    "doodle_ids": {"type": "array", "items": {"type": "string"}},
                },
                "required": ["title", "doodle_ids"],
                "additionalProperties": False,
            },
        }
    },
    "required": ["albums"],
    "additionalProperties": False,
}


_ID_DIGITS = re.compile(r"\d+")


def _norm_doodle_id(x: object) -> str:
    """LLM 이 프롬프트의 '[id] 본문' 표기를 통째로 흉내내 '1] 오늘...' 처럼 돌려주는 경우가
    있어, 반환값의 첫 숫자열(=실제 doodle id)만 뽑는다. id 는 항상 숫자이고 본문은
    한글로 시작하므로 안전. 매칭 실패로 앨범이 통째로 비는 것을 방지(#6)."""
    m = _ID_DIGITS.search(str(x))
    return m.group(0) if m else str(x).strip()


def _heuristic_albums(items: list[dict]) -> list[dict]:
    """GPU 없이도 앨범을 만드는 폴백 — 캡션 키워드로 묶는다."""
    themes = [
        ("맛있는 날", ["음식", "맛", "먹", "카페", "커피", "디저트", "케이크", "밥", "떡볶이", "food", "eat"]),
        # "산"(mountain)은 "산책"(walk)을 부분매칭하므로 넣지 않는다.
        ("우리의 풍경", ["하늘", "노을", "바다", "꽃", "풍경", "야경", "별", "억새", "단풍", "sky", "sea"]),
        ("함께한 나들이", ["데이트", "나들이", "여행", "공원", "산책", "축제", "길", "park"]),
    ]
    out: list[dict] = []
    used: set[str] = set()
    for title, kws in themes:
        ids = [
            str(it["id"])
            for it in items
            if str(it["id"]) not in used and any(k in (it.get("text") or "") for k in kws)
        ]
        if len(ids) >= 2:
            out.append({"title": title, "doodle_ids": ids})
            used.update(ids)
    return out


class ImageClient(Protocol):
    async def diary_image(
        self,
        *,
        group_id: int,
        entry_date: str,
        activities: list[str],
        caption: str,
        style_kind: str,
        weights_path: str | None,
    ) -> bytes: ...
    async def image_caption(self, image_bytes: bytes) -> str: ...
    async def train_style(
        self, style_id: str, images: list[bytes]
    ) -> dict[str, object]: ...
    async def health(self) -> bool: ...


# ---------------------------------------------------------------------------
# 스텁 — GPU 없이 개발할 때
# ---------------------------------------------------------------------------


class StubLlmClient:
    model = "stub"

    async def pet_activity(self, ctx: GroupContext) -> PetActivity:
        activity = random.choice(ACTIVITIES)
        return PetActivity(activity, _STUB_UTTERANCES[activity], self.model)

    async def diary_caption(self, activities: list[str], pet_name: str) -> str:
        return f"오늘 나 {pet_name}는 {', '.join(activities) or '아무것도 안'} 했어."

    async def doodle_caption(
        self, english: str, pet_name: str, sender_name: str
    ) -> str:
        return f"{sender_name}가 그려준 낙서 ♥"

    async def curate_albums(self, items: list[dict]) -> list[dict]:
        return _heuristic_albums(items)

    async def health(self) -> bool:
        return True


class ImageGenerationError(RuntimeError):
    pass


class StubImageClient:
    async def image_caption(self, image_bytes: bytes) -> str:
        return "a cute little drawing"

    async def diary_image(self, **kwargs: object) -> bytes:
        """GPU가 없는 개발 환경에서도 눈으로 확인 가능한 512px PNG를 만든다."""
        activities = kwargs.get("activities")
        labels = ", ".join(activities) if isinstance(activities, list) else "waiting"
        image = Image.new("RGB", (512, 512), (246, 244, 238))
        draw = ImageDraw.Draw(image)
        font = ImageFont.load_default(size=22)
        draw.rounded_rectangle((72, 80, 440, 432), radius=28, fill=(255, 255, 255))
        draw.ellipse((166, 130, 346, 310), fill=(245, 173, 88), outline=(45, 45, 45), width=4)
        draw.ellipse((202, 195, 222, 215), fill=(45, 45, 45))
        draw.ellipse((290, 195, 310, 215), fill=(45, 45, 45))
        draw.arc((225, 205, 287, 255), start=10, end=170, fill=(45, 45, 45), width=4)
        draw.text((96, 350), labels[:34], fill=(45, 45, 45), font=font)
        output = io.BytesIO()
        image.save(output, "PNG")
        return output.getvalue()

    async def train_style(
        self, style_id: str, images: list[bytes]
    ) -> dict[str, object]:
        return {"weights_path": f"lora/{style_id}", "num_images": len(images), "steps": 0}

    async def health(self) -> bool:
        return True


# ---------------------------------------------------------------------------
# 실물
# ---------------------------------------------------------------------------


class HttpLlmClient:
    """vLLM 의 OpenAI 호환 엔드포인트를 부른다."""

    def __init__(self, settings: Settings) -> None:
        self._base = settings.gpu_llm_url.rstrip("/")
        self._model = settings.llm_model
        self._timeout = settings.gpu_timeout_seconds
        self._fallback = StubLlmClient()

    async def pet_activity(self, ctx: GroupContext) -> PetActivity:
        prompt = (
            "너는 커플의 반려 펫이다. 아래 상황을 보고 지금 네가 하고 있는 활동 하나와, "
            "주인이 쓰다듬었을 때 건넬 한두 문장의 말을 정해라.\n"
            f"- 레벨: {ctx.pet_level}\n"
            f"- 최근 24시간 낙서: {ctx.doodles_24h}건\n"
            f"- 최근 24시간 찌르기: {ctx.pokes_24h}회\n"
            f"- 마지막 낙서 유형: {ctx.last_content_type or '없음'}\n"
        )
        try:
            data = await self._chat(prompt, PET_ACTIVITY_SCHEMA)
            activity = data["activity"]
            if activity not in ACTIVITIES:  # 스키마 강제가 안 먹은 경우
                raise ValueError(f"알 수 없는 activity: {activity}")
            return PetActivity(activity, data["utterance"], self._model)
        except Exception:
            logger.warning("LLM 펫 활동 생성 실패. 스텁으로 열화한다.", exc_info=True)
            return await self._fallback.pet_activity(ctx)

    async def diary_caption(self, activities: list[str], pet_name: str) -> str:
        # 펫 이름을 넘기지 않으면 모델이 이름을 지어낸다(브루노·햇님이…). 1인칭·한국어를
        # 강제하고 이름을 박아 넣으면 지어내기·외국어 토큰이 크게 줄어든다(실측).
        prompt = (
            f"너는 '{pet_name}'라는 이름의 반려 펫이야. 오늘 한 활동: "
            f"{', '.join(activities) or '없음'}.\n"
            "이걸 바탕으로 한국어로만, 40자 안팎의 짧고 귀여운 한 문장짜리 일기를 1인칭으로 써.\n"
            "다른 이름을 지어내지 말고, 외국어나 이상한 글자를 섞지 마."
        )
        try:
            data = await self._chat(
                prompt,
                {
                    "type": "object",
                    "properties": {"caption": {"type": "string", "maxLength": 120}},
                    "required": ["caption"],
                    "additionalProperties": False,
                },
                temperature=0.4,  # 자유도를 낮춰 외국어·환각 토큰을 줄인다
            )
            return data["caption"]
        except Exception:
            logger.warning("LLM 캡션 생성 실패. 스텁으로 열화한다.", exc_info=True)
            return await self._fallback.diary_caption(activities, pet_name)

    async def doodle_caption(
        self, english: str, pet_name: str, sender_name: str
    ) -> str:
        # BLIP 의 영어 설명을 펫 말투 한국어 한마디로 바꾼다.
        prompt = (
            f"너는 '{pet_name}'라는 커플의 반려 펫이야. 방금 '{sender_name}'가 낙서를 보냈어.\n"
            f"그림 내용(영어 설명): {english}\n"
            "이 낙서를 보고 네가 건네는 짧고 귀여운 한국어 한마디를 25자 안팎으로 써.\n"
            "1인칭, 한국어만. 외국어나 이상한 글자를 섞지 말고, 그림 내용을 자연스럽게 언급해."
        )
        try:
            data = await self._chat(
                prompt,
                {
                    "type": "object",
                    "properties": {"caption": {"type": "string", "maxLength": 120}},
                    "required": ["caption"],
                    "additionalProperties": False,
                },
                temperature=0.5,
            )
            return data["caption"]
        except Exception:
            logger.warning("낙서 캡션 한국어 변환 실패.", exc_info=True)
            return await self._fallback.doodle_caption(english, pet_name, sender_name)

    async def curate_albums(self, items: list[dict]) -> list[dict]:
        if not items:
            return []
        lines = "\n".join(
            f'[{it["id"]}] {(it.get("text") or "").strip()[:60]}' for it in items
        )
        prompt = (
            "아래는 커플이 주고받은 낙서/사진에 대한 설명 목록이야. "
            "비슷한 주제끼리 묶어 2~4개의 앨범으로 정리해줘. 각 앨범엔 어울리는 짧은 "
            "한국어 제목(예: '맛있는 날', '우리의 풍경', '함께한 나들이')을 붙이고, "
            "그 앨범에 속하는 id 들을 doodle_ids 에 넣어. 되도록 모든 id 를 한 번씩만 "
            "넣고, 한국어 제목만 써(외국어 금지).\n"
            f"{lines}\n"
        )
        try:
            data = await self._chat(prompt, ALBUM_CURATION_SCHEMA, temperature=0.5)
            return [
                {
                    "title": a["title"],
                    "doodle_ids": [_norm_doodle_id(x) for x in a.get("doodle_ids", [])],
                }
                for a in data.get("albums", [])
            ]
        except Exception:
            logger.warning("LLM 앨범 큐레이션 실패. 스텁으로 열화.", exc_info=True)
            return await self._fallback.curate_albums(items)

    async def _chat(
        self, prompt: str, schema: dict, temperature: float | None = None
    ) -> dict:
        import json

        payload: dict[str, object] = {
            "model": self._model,
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": 256,
            # vLLM 0.24.0의 OpenAI 호환 JSON Schema 형식.
            "response_format": {
                "type": "json_schema",
                "json_schema": {
                    "name": "memory_pager_response",
                    "schema": schema,
                },
            },
        }
        if temperature is not None:
            payload["temperature"] = temperature
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            resp = await client.post(f"{self._base}/v1/chat/completions", json=payload)
            resp.raise_for_status()
            content = resp.json()["choices"][0]["message"]["content"]
        return json.loads(content)

    async def health(self) -> bool:
        try:
            async with httpx.AsyncClient(timeout=3.0) as client:
                resp = await client.get(f"{self._base}/health")
            return resp.status_code == 200
        except Exception:
            return False


class HttpImageClient:
    """직접 만든 sd-worker 를 부른다."""

    def __init__(self, settings: Settings) -> None:
        self._base = settings.gpu_sd_url.rstrip("/")
        self._timeout = settings.gpu_timeout_seconds

    async def image_caption(self, image_bytes: bytes) -> str:
        async with httpx.AsyncClient(timeout=self._timeout) as client:
            resp = await client.post(
                f"{self._base}/caption",
                files={"file": ("doodle.png", image_bytes, "image/png")},
            )
            resp.raise_for_status()
        return str(resp.json()["caption"])

    async def diary_image(
        self,
        *,
        group_id: int,
        entry_date: str,
        activities: list[str],
        caption: str,
        style_kind: str,
        weights_path: str | None,
    ) -> bytes:
        payload = {
            "group_id": str(group_id),
            "entry_date": entry_date,
            "activities": activities,
            "caption": caption,
            "style": {
                "kind": style_kind,
                "weights_path": weights_path,
            },
        }
        try:
            async with httpx.AsyncClient(timeout=self._timeout) as client:
                resp = await client.post(f"{self._base}/generate/diary", json=payload)
                resp.raise_for_status()
            if not resp.headers.get("content-type", "").lower().startswith("image/png"):
                raise ValueError("sd-worker가 image/png가 아닌 응답을 반환했습니다")
            with Image.open(io.BytesIO(resp.content)) as image:
                if image.format != "PNG":
                    raise ValueError("sd-worker 응답이 유효한 PNG가 아닙니다")
                image.verify()
            return resp.content
        except Exception as exc:
            # image_url/caption이 NOT NULL인 일기에 1x1 빈 이미지를 저장하지 않는다.
            logger.warning("일기 그림 생성 실패. 그날 일기를 생성하지 않는다.", exc_info=True)
            raise ImageGenerationError("sd-worker 일기 이미지 생성 실패") from exc

    async def train_style(
        self, style_id: str, images: list[bytes]
    ) -> dict[str, object]:
        """손그림들로 그룹 화풍 LoRA 를 학습한다. 학습은 수 분 걸리므로 별도 타임아웃."""
        files = [
            ("files", (f"d{i}.png", data, "image/png"))
            for i, data in enumerate(images)
        ]
        async with httpx.AsyncClient(timeout=900.0) as client:
            resp = await client.post(
                f"{self._base}/train/style",
                data={"style_id": style_id},
                files=files,
            )
            resp.raise_for_status()
        return dict(resp.json())

    async def health(self) -> bool:
        try:
            async with httpx.AsyncClient(timeout=3.0) as client:
                resp = await client.get(f"{self._base}/health")
            return resp.status_code == 200
        except Exception:
            return False


# ---------------------------------------------------------------------------


def get_llm_client() -> LlmClient:
    settings = get_settings()
    return HttpLlmClient(settings) if settings.gpu_enabled else StubLlmClient()


def get_image_client() -> ImageClient:
    settings = get_settings()
    return HttpImageClient(settings) if settings.gpu_enabled else StubImageClient()


async def gpu_status() -> str:
    """`GET /v1/health` 용. 'ok' | 'down' | 'stub'."""
    if not get_settings().gpu_enabled:
        return "stub"
    llm_ok = await get_llm_client().health()
    img_ok = await get_image_client().health()
    return "ok" if (llm_ok and img_ok) else "down"
