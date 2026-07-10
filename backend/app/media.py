"""미디어 파일 저장. 앱 VM 파일시스템에 둔다 (SPEC 7절 ②).

썸네일은 **어떤 유형이든 `null`이 되지 않는다** (docs/API.md 4절).

| content_type | 썸네일 원본 |
|---|---|
| photo | photo 축소본 |
| drawing | drawing (투명 배경이라 흰 바탕에 합성) |
| text | text_body 를 렌더한 미리보기 |

앱 VM 은 RAM 이 4GB 뿐이라 큰 이미지 처리를 하지 않는다. 512px 짜리 썸네일 한 장은
문제없지만, 그 이상이 필요해지면 GPU 서버로 넘긴다.
"""

from __future__ import annotations

import logging
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

from .config import get_settings

logger = logging.getLogger(__name__)

THUMB_MAX = 512
_WHITE = (255, 255, 255)


def group_dir(group_id: int) -> Path:
    d = get_settings().media_root / f"g{group_id}"
    d.mkdir(parents=True, exist_ok=True)
    return d


def url_of(group_id: int, filename: str) -> str:
    return f"{get_settings().media_url_prefix}/g{group_id}/{filename}"


def thumb_url(group_id: int, doodle_id: int) -> str:
    """`thumb_url` 은 DB 컬럼이 아니라 규칙으로 유도한다. 어떤 유형이든 null 이 아니다."""
    return url_of(group_id, f"{doodle_id}_thumb.jpg")


def save_bytes(group_id: int, filename: str, data: bytes) -> str:
    path = group_dir(group_id) / filename
    path.write_bytes(data)
    return url_of(group_id, filename)


def _flatten(img: Image.Image) -> Image.Image:
    """투명 배경(손그림 PNG)을 흰 바탕에 합성한다. JPEG 는 알파를 못 담는다."""
    if img.mode in ("RGBA", "LA", "P"):
        img = img.convert("RGBA")
        canvas = Image.new("RGB", img.size, _WHITE)
        canvas.paste(img, mask=img.split()[-1])
        return canvas
    return img.convert("RGB")


def make_thumbnail(group_id: int, doodle_id: int, source_filename: str) -> str:
    src = group_dir(group_id) / source_filename
    name = f"{doodle_id}_thumb.jpg"
    with Image.open(src) as img:
        flat = _flatten(img)
        flat.thumbnail((THUMB_MAX, THUMB_MAX))
        flat.save(group_dir(group_id) / name, "JPEG", quality=80)
    return url_of(group_id, name)


def render_text_thumbnail(group_id: int, doodle_id: int, text: str) -> str:
    """텍스트 낙서는 유도할 원본 이미지가 아예 없다. 서버가 그린다."""
    name = f"{doodle_id}_thumb.jpg"
    img = Image.new("RGB", (THUMB_MAX, THUMB_MAX), _WHITE)
    draw = ImageDraw.Draw(img)
    font = ImageFont.load_default()

    # 대충 줄바꿈. 폰트 메트릭을 정밀하게 볼 이유가 없다.
    line_len = 34
    lines = [text[i : i + line_len] for i in range(0, min(len(text), line_len * 12), line_len)]
    y = 24
    for line in lines:
        draw.text((24, y), line, fill=(30, 30, 30), font=font)
        y += 18

    img.save(group_dir(group_id) / name, "JPEG", quality=80)
    return url_of(group_id, name)


def delete_doodle_files(group_id: int, doodle_id: int) -> int:
    """사라지기 모드 만료 시 실제로 지운다. 지운 파일 수를 돌려준다."""
    removed = 0
    d = get_settings().media_root / f"g{group_id}"
    if not d.exists():
        return 0
    for path in d.glob(f"{doodle_id}_*"):
        try:
            path.unlink()
            removed += 1
        except OSError:
            logger.warning("미디어 삭제 실패: %s", path, exc_info=True)
    return removed
