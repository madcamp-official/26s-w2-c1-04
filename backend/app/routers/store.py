"""스토어 (#13). 코인으로 아이템을 사고 착용한다.

코인은 펫(그룹 공유)에 있다. 구매는 펫 행을 `FOR UPDATE` 로 잠가 원자적으로 차감해,
같은 순간 두 사람이 사도 코인이 음수로 새거나 손실 갱신되지 않게 한다.
착용은 한 카테고리에 하나만 — 새로 착용하면 같은 카테고리의 다른 아이템은 벗겨진다.
"""

from __future__ import annotations

from fastapi import APIRouter
from sqlalchemy import select
from sqlalchemy.exc import IntegrityError

from .. import services
from ..deps import CurrentUser, SessionDep
from ..errors import ApiError
from ..models import Item, Pet, PetItem
from ..schemas import (
    BuyResultOut,
    EquipIn,
    EquipResultOut,
    StoreItemOut,
    StoreListOut,
)

router = APIRouter(tags=["store"])


async def _pet_for_group(session, group_id: int) -> Pet:
    pet = (
        await session.execute(select(Pet).where(Pet.group_id == group_id))
    ).scalar_one_or_none()
    if pet is None:
        raise ApiError(404, "not_found", "펫이 없습니다")
    return pet


@router.get("/groups/{group_id}/store", response_model=StoreListOut)
async def list_store(
    group_id: int, user: CurrentUser, session: SessionDep
) -> StoreListOut:
    await services.require_member(session, user.id, group_id)
    pet = await _pet_for_group(session, group_id)
    items = (
        await session.execute(
            select(Item).order_by(Item.category, Item.price_coins, Item.id)
        )
    ).scalars().all()
    owned = {
        pi.item_id: pi
        for pi in (
            await session.execute(
                select(PetItem).where(PetItem.pet_id == pet.id)
            )
        ).scalars()
    }
    return StoreListOut(
        coins=pet.coins,
        items=[
            StoreItemOut(
                id=str(it.id),
                category=it.category.value,
                name=it.name,
                price_coins=it.price_coins,
                asset_url=it.asset_url,
                owned=it.id in owned,
                equipped=bool(owned[it.id].is_equipped) if it.id in owned else False,
            )
            for it in items
        ],
    )


@router.post("/groups/{group_id}/store/{item_id}/buy", response_model=BuyResultOut)
async def buy_item(
    group_id: int, item_id: int, user: CurrentUser, session: SessionDep
) -> BuyResultOut:
    await services.require_member(session, user.id, group_id)
    item = await session.get(Item, item_id)
    if item is None:
        raise ApiError(404, "not_found", "아이템이 없습니다")
    # 코인 차감을 위해 펫을 잠근다(동시 구매 안전).
    pet = (
        await session.execute(
            select(Pet).where(Pet.group_id == group_id).with_for_update()
        )
    ).scalar_one_or_none()
    if pet is None:
        raise ApiError(404, "not_found", "펫이 없습니다")
    existing = (
        await session.execute(
            select(PetItem).where(
                PetItem.pet_id == pet.id, PetItem.item_id == item_id
            )
        )
    ).scalar_one_or_none()
    if existing is not None:
        return BuyResultOut(item_id=str(item_id), coins=pet.coins)  # 멱등
    if pet.coins < item.price_coins:
        raise ApiError(400, "insufficient_coins", "코인이 부족합니다")
    pet.coins -= item.price_coins
    session.add(PetItem(pet_id=pet.id, item_id=item_id, is_equipped=False))
    try:
        await session.commit()
    except IntegrityError:
        # UNIQUE(pet_id,item_id) 경합 — 이미 보유로 처리(코인은 롤백).
        await session.rollback()
        pet2 = await _pet_for_group(session, group_id)
        return BuyResultOut(item_id=str(item_id), coins=pet2.coins)
    return BuyResultOut(item_id=str(item_id), coins=pet.coins)


@router.post(
    "/groups/{group_id}/store/{item_id}/equip", response_model=EquipResultOut
)
async def equip_item(
    group_id: int,
    item_id: int,
    body: EquipIn,
    user: CurrentUser,
    session: SessionDep,
) -> EquipResultOut:
    await services.require_member(session, user.id, group_id)
    pet = await _pet_for_group(session, group_id)
    row = (
        await session.execute(
            select(PetItem, Item)
            .join(Item, Item.id == PetItem.item_id)
            .where(PetItem.pet_id == pet.id, PetItem.item_id == item_id)
        )
    ).first()
    if row is None:
        raise ApiError(404, "not_found", "보유하지 않은 아이템입니다")
    pet_item, item = row
    if body.equipped:
        # 한 카테고리 하나 — 같은 카테고리의 다른 착용은 벗긴다.
        others = (
            await session.execute(
                select(PetItem)
                .join(Item, Item.id == PetItem.item_id)
                .where(
                    PetItem.pet_id == pet.id,
                    Item.category == item.category,
                    PetItem.item_id != item_id,
                )
            )
        ).scalars()
        for o in others:
            o.is_equipped = False
    pet_item.is_equipped = body.equipped
    await session.commit()
    return EquipResultOut(item_id=str(item_id), equipped=body.equipped)
