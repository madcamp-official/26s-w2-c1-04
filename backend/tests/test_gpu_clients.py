"""GPU HTTP 클라이언트 계약. 실제 GPU나 네트워크 없이 돈다."""

from __future__ import annotations

import asyncio
import io
import json
import sys
from pathlib import Path
from unittest.mock import patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import httpx  # noqa: E402
from PIL import Image  # noqa: E402

from app import gpu  # noqa: E402
from app.config import Settings  # noqa: E402


def png_bytes() -> bytes:
    output = io.BytesIO()
    Image.new("RGB", (32, 32), (120, 180, 220)).save(output, "PNG")
    return output.getvalue()


def client_factory(transport: httpx.MockTransport):
    original = httpx.AsyncClient

    def factory(*args, **kwargs):
        kwargs["transport"] = transport
        return original(*args, **kwargs)

    return factory


async def test_stub_image_is_visible_png() -> None:
    data = await gpu.StubImageClient().diary_image(activities=["walking"])
    with Image.open(io.BytesIO(data)) as image:
        assert image.format == "PNG"
        assert image.size == (512, 512)


async def test_vllm_uses_024_json_schema_contract() -> None:
    captured = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured.update(json.loads(request.content))
        content = json.dumps({"activity": "sleeping", "utterance": "잘 자는 중"})
        return httpx.Response(
            200, json={"choices": [{"message": {"content": content}}]}
        )

    settings = Settings(gpu_llm_url="http://llm", llm_model="test-model")
    transport = httpx.MockTransport(handler)
    with patch.object(gpu.httpx, "AsyncClient", side_effect=client_factory(transport)):
        result = await gpu.HttpLlmClient(settings).pet_activity(
            gpu.GroupContext(1, 2, 3, "drawing")
        )
    assert result.activity == "sleeping"
    assert "guided_json" not in captured
    assert captured["response_format"]["type"] == "json_schema"
    assert (
        captured["response_format"]["json_schema"]["schema"]["additionalProperties"]
        is False
    )


async def test_sd_payload_keeps_default_style_and_context() -> None:
    captured = {}

    def handler(request: httpx.Request) -> httpx.Response:
        captured.update(json.loads(request.content))
        return httpx.Response(
            200, content=png_bytes(), headers={"content-type": "image/png"}
        )

    settings = Settings(gpu_sd_url="http://sd")
    transport = httpx.MockTransport(handler)
    with patch.object(gpu.httpx, "AsyncClient", side_effect=client_factory(transport)):
        data = await gpu.HttpImageClient(settings).diary_image(
            group_id=7,
            entry_date="2026-07-10",
            activities=["drawing"],
            caption="오늘의 일기",
            style_kind="default",
            weights_path="presets/sd15_default",
        )
    assert data.startswith(b"\x89PNG")
    assert captured["group_id"] == "7"
    assert captured["entry_date"] == "2026-07-10"
    assert captured["style"] == {
        "kind": "default",
        "weights_path": "presets/sd15_default",
    }


async def test_sd_rejects_non_image_success_response() -> None:
    transport = httpx.MockTransport(
        lambda _: httpx.Response(
            200, text="not an image", headers={"content-type": "text/plain"}
        )
    )
    settings = Settings(gpu_sd_url="http://sd")
    with patch.object(gpu.httpx, "AsyncClient", side_effect=client_factory(transport)):
        try:
            await gpu.HttpImageClient(settings).diary_image(
                group_id=1,
                entry_date="2026-07-10",
                activities=["waiting"],
                caption="기다렸다",
                style_kind="default",
                weights_path=None,
            )
        except gpu.ImageGenerationError:
            return
    raise AssertionError("유효하지 않은 이미지 응답을 받아들이면 안 된다")


async def main() -> int:
    tests = [
        value for name, value in sorted(globals().items()) if name.startswith("test_")
    ]
    failed = 0
    for test in tests:
        try:
            await test()
        except Exception as exc:
            print(f"  FAIL  {test.__name__}: {type(exc).__name__}: {exc}")
            failed += 1
        else:
            print(f"  ok    {test.__name__}")
    print(f"\n{len(tests) - failed}/{len(tests)} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
