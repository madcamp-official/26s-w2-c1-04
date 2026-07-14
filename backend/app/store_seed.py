"""스토어 카탈로그 시드 (#13). 부팅 때 멱등 실행 — 이미 있는 (카테고리,이름)은 건너뛴다.

asset_url 은 "emoji:🎩" 형식으로 이모지 글리프를 담는다. 앱은 "emoji:" 접두면
이모지를 그리고, /media 경로면 이미지를 띄운다. 별도 에셋 파일 없이 확장 가능하다.
"모자 + 모든 인테리어" 요구(#13)에 맞춰 전 카테고리를 채운다.
"""

from __future__ import annotations

import logging

from sqlalchemy import select

from .db import session_factory
from .models import Item, ItemCategory

logger = logging.getLogger(__name__)

# (카테고리, 이름, 가격, 이모지). 첫 무료(0) 아이템은 기본 제공 느낌.
_CATALOG: list[tuple[ItemCategory, str, int, str]] = [
    # 모자
    (ItemCategory.HAT, "중절모", 0, "emoji:🎩"),
    (ItemCategory.HAT, "새싹핀", 150, "emoji:🌱"),
    (ItemCategory.HAT, "리본", 200, "emoji:🎀"),
    (ItemCategory.HAT, "비니", 280, "emoji:🧢"),
    (ItemCategory.HAT, "밀짚모자", 300, "emoji:👒"),
    (ItemCategory.HAT, "딸기베레모", 450, "emoji:🍓"),
    (ItemCategory.HAT, "왕관", 900, "emoji:👑"),
    # 옷
    (ItemCategory.CLOTHES, "기본 티셔츠", 0, "emoji:👕"),
    (ItemCategory.CLOTHES, "후드티", 350, "emoji:🧥"),
    (ItemCategory.CLOTHES, "원피스", 480, "emoji:👗"),
    (ItemCategory.CLOTHES, "정장", 600, "emoji:🤵"),
    (ItemCategory.CLOTHES, "우주복", 850, "emoji:🧑‍🚀"),
    # 액세서리
    (ItemCategory.ACCESSORY, "동그란 안경", 180, "emoji:👓"),
    (ItemCategory.ACCESSORY, "목도리", 240, "emoji:🧣"),
    (ItemCategory.ACCESSORY, "가방", 320, "emoji:🎒"),
    (ItemCategory.ACCESSORY, "선글라스", 400, "emoji:🕶️"),
    # 가구
    (ItemCategory.FURNITURE, "화분", 150, "emoji:🪴"),
    (ItemCategory.FURNITURE, "러그", 300, "emoji:🟫"),
    (ItemCategory.FURNITURE, "책장", 520, "emoji:📚"),
    (ItemCategory.FURNITURE, "소파", 700, "emoji:🛋️"),
    (ItemCategory.FURNITURE, "괘종시계", 780, "emoji:🕰️"),
    (ItemCategory.FURNITURE, "벽난로", 950, "emoji:🔥"),
    # 배경
    (ItemCategory.BACKGROUND, "민트벽", 0, "emoji:🟩"),
    (ItemCategory.BACKGROUND, "벚꽃", 500, "emoji:🌸"),
    (ItemCategory.BACKGROUND, "밤하늘", 500, "emoji:🌌"),
    (ItemCategory.BACKGROUND, "바닷가", 550, "emoji:🏖️"),
    (ItemCategory.BACKGROUND, "설원", 550, "emoji:🏔️"),
    # 소품
    (ItemCategory.PROP, "풍선", 120, "emoji:🎈"),
    (ItemCategory.PROP, "케이크", 300, "emoji:🍰"),
    (ItemCategory.PROP, "선물상자", 260, "emoji:🎁"),
    (ItemCategory.PROP, "화환", 340, "emoji:💐"),
]


async def seed_items() -> None:
    async with session_factory()() as session:
        existing = {
            (c, n)
            for c, n in (
                await session.execute(select(Item.category, Item.name))
            ).all()
        }
        added = 0
        for cat, name, price, asset in _CATALOG:
            if (cat, name) in existing:
                continue
            session.add(
                Item(category=cat, name=name, price_coins=price, asset_url=asset)
            )
            added += 1
        if added:
            await session.commit()
            logger.info("스토어 카탈로그 시드: %d개 아이템 추가", added)
