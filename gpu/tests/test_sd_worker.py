"""SD worker의 스텁 HTTP 계약."""

from __future__ import annotations

import io
import os
import sys
from pathlib import Path

os.environ["SD_STUB"] = "true"
sys.path.insert(0, str(Path(__file__).resolve().parents[2]))

from fastapi.testclient import TestClient  # noqa: E402
from PIL import Image  # noqa: E402

from gpu.sd_worker import app  # noqa: E402


VALID = {
    "group_id": "7",
    "entry_date": "2026-07-10",
    "activities": ["eating", "drawing"],
    "caption": "오늘은 그림을 그렸다.",
    "style": {"kind": "default", "weights_path": "presets/sd15_default"},
}


def _png_bytes() -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", (64, 64), (240, 240, 235)).save(buf, "PNG")
    return buf.getvalue()


def main() -> int:
    failed = 0

    def check(label: str, condition: bool, detail: str = "") -> None:
        nonlocal failed
        if condition:
            print(f"  ok    {label}")
        else:
            failed += 1
            print(f"  FAIL  {label} {detail}")

    with TestClient(app) as client:
        health = client.get("/health")
        check(
            "health stub",
            health.status_code == 200 and health.json()["status"] == "stub",
        )

        response = client.post("/generate/diary", json=VALID)
        check("일기 생성 200", response.status_code == 200, response.text[:100])
        check(
            "content-type image/png",
            response.headers.get("content-type") == "image/png",
        )
        with Image.open(io.BytesIO(response.content)) as image:
            check("512x512 PNG", image.format == "PNG" and image.size == (512, 512))

        bad = dict(VALID, activities=["unknown"])
        check(
            "알 수 없는 활동 422",
            client.post("/generate/diary", json=bad).status_code == 422,
        )

        # learned + weights_path: 스텁도 200(화풍 어댑터는 실모델에서만 적용).
        learned = dict(VALID, style={"kind": "learned", "weights_path": "/tmp/lora"})
        check(
            "learned+weights 200",
            client.post("/generate/diary", json=learned).status_code == 200,
        )
        # learned 인데 weights_path 없음 → 400(기본 화풍으로 속이지 않음).
        learned_bad = dict(VALID, style={"kind": "learned", "weights_path": None})
        check(
            "learned without weights 400",
            client.post("/generate/diary", json=learned_bad).status_code == 400,
        )

        # /train/style 스텁 계약(파일 5장 미만이어도 스텁은 배선만 확인).
        train_files = [
            ("files", (f"d{i}.png", _png_bytes(), "image/png")) for i in range(3)
        ]
        train = client.post(
            "/train/style", data={"style_id": "g7-v1"}, files=train_files
        )
        check("train/style 200(stub)", train.status_code == 200, train.text[:100])
        check(
            "train weights_path 반환",
            train.status_code == 200 and "weights_path" in train.json(),
        )

    total = 9
    print(f"\n{total - failed}/{total} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
