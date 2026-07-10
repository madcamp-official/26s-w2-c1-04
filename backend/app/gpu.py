"""GPU 서버 클라이언트. 스텁과 실물을 같은 인터페이스 뒤에 둔다.

**앱과 백엔드 작업이 GPU 환경 구성에 막히면 안 된다.** `GPU_ENABLED=false`(기본)면
스텁이 그럴듯한 값을 돌려주고, GPU 서버가 준비되면 환경변수 하나로 갈아끼운다.

GPU 서버가 죽어도 앱은 살아야 한다. 그래서 실물 클라이언트도 실패 시 예외를 던지지 않고
스텁 값으로 열화(degrade)한다. 펫은 무슨 일이 있어도 말을 해야 한다.

내부 API 명세는 docs/API.md 11절.
"""

from __future__ import annotations

import base64
import logging
import random
from dataclasses import dataclass
from typing import Protocol

import httpx

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

# 1x1 투명 PNG. 스텁 이미지이자 실물 실패 시의 폴백.
_BLANK_PNG = base64.b64decode(
    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="
)

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
    async def diary_caption(self, activities: list[str]) -> str: ...
    async def health(self) -> bool: ...


class ImageClient(Protocol):
    async def diary_image(
        self, *, activities: list[str], caption: str, weights_path: str | None
    ) -> bytes: ...
    async def health(self) -> bool: ...


# ---------------------------------------------------------------------------
# 스텁 — GPU 없이 개발할 때
# ---------------------------------------------------------------------------


class StubLlmClient:
    model = "stub"

    async def pet_activity(self, ctx: GroupContext) -> PetActivity:
        activity = random.choice(ACTIVITIES)
        return PetActivity(activity, _STUB_UTTERANCES[activity], self.model)

    async def diary_caption(self, activities: list[str]) -> str:
        return f"오늘은 {', '.join(activities) or '아무것도 안'} 했다."

    async def health(self) -> bool:
        return True


class StubImageClient:
    async def diary_image(self, **_: object) -> bytes:
        return _BLANK_PNG

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

    async def diary_caption(self, activities: list[str]) -> str:
        prompt = (
            "반려 펫의 하루를 한 문장짜리 일기로 써라. 활동: "
            + (", ".join(activities) or "없음")
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
            )
            return data["caption"]
        except Exception:
            logger.warning("LLM 캡션 생성 실패. 스텁으로 열화한다.", exc_info=True)
            return await self._fallback.diary_caption(activities)

    async def _chat(self, prompt: str, schema: dict) -> dict:
        import json

        payload = {
            "model": self._model,
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": 256,
            # TODO(docs/API.md 13절): vLLM 0.24.0 의 구조화 출력 파라미터 이름을
            # 실제로 띄워 보고 확정한다. guided_json 인지 response_format 인지.
            "guided_json": schema,
        }
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

    async def diary_image(
        self, *, activities: list[str], caption: str, weights_path: str | None
    ) -> bytes:
        payload = {
            "activities": activities,
            "caption": caption,
            "style": {
                "kind": "learned" if weights_path else "default",
                "weights_path": weights_path,
            },
        }
        try:
            async with httpx.AsyncClient(timeout=self._timeout) as client:
                resp = await client.post(f"{self._base}/generate/diary", json=payload)
                resp.raise_for_status()
            return resp.content
        except Exception:
            logger.warning("일기 그림 생성 실패. 빈 이미지로 열화한다.", exc_info=True)
            return _BLANK_PNG

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
