"""펫. PT-1, PT-6a. docs/API.md 5절.

앱의 첫 화면(홈)이 `GET /groups/{id}/pet` 으로 그려진다.
"""

from __future__ import annotations

from datetime import date as date_type

from fastapi import APIRouter, Query
from sqlalchemy import func, select
from typing import Annotated

from .. import services
from ..deps import CurrentUser, SessionDep
from ..errors import ApiError, parse_id
from ..models import ContentType, Doodle, Item, Pet, PetDiary, PetItem, StyleModel
from ..schemas import (
    ActivityOut,
    DiaryListOut,
    DiaryOut,
    EquippedItemOut,
    PatOut,
    PetDetailOut,
)

router = APIRouter(tags=["pets"])

_ISO = "%Y-%m-%dT%H:%M:%SZ"


@router.get("/groups/{group_id}/pet", response_model=PetDetailOut)
async def get_pet(group_id: int, user: CurrentUser, session: SessionDep) -> PetDetailOut:
    await services.require_member(session, user.id, group_id)
    pet = (
        await session.execute(select(Pet).where(Pet.group_id == group_id))
    ).scalar_one_or_none()
    if pet is None:
        raise ApiError(404, "not_found", "펫이 없습니다")

    # 학습 진행(#5) — 그룹 누적 손그림 수(앱 목록 40건 한계와 무관하게 정확).
    drawing_count = (
        await session.execute(
            select(func.count(Doodle.id)).where(
                Doodle.group_id == group_id,
                Doodle.content_type == ContentType.DRAWING,
                Doodle.deleted_at.is_(None),
            )
        )
    ).scalar_one()

    act = await services.current_activity(session, pet.id)
    equipped = (
        await session.execute(
            select(PetItem, Item)
            .join(Item, Item.id == PetItem.item_id)
            .where(PetItem.pet_id == pet.id, PetItem.is_equipped.is_(True))
        )
    ).all()

    return PetDetailOut(
        id=str(pet.id),
        name=pet.name,
        level=pet.level,
        exp=pet.exp,
        coins=pet.coins,
        is_public=pet.is_public,
        # 펫이 아직 첫 활동을 못 받았으면 null. 앱은 이 상태를 정상으로 그린다.
        current_activity=(
            ActivityOut(
                activity=act.activity.value,
                started_at=act.started_at.strftime(_ISO),
            )
            if act
            else None
        ),
        drawing_count=int(drawing_count),
        learn_goal=services.LEARN_MIN_DRAWINGS,
        equipped_items=[
            EquippedItemOut(
                item_id=str(i.id), category=i.category.value, asset_url=i.asset_url
            )
            for _, i in equipped
        ],
    )


@router.post("/pets/{pet_id}/pat", response_model=PatOut)
async def pat(pet_id: int, user: CurrentUser, session: SessionDep) -> PatOut:
    """쓰다듬기. LLM 을 부르지 않고 현재 활동의 대사를 그대로 돌려준다."""
    return PatOut(**await services.pat_pet(session, user.id, pet_id))


def _diary_out(d: PetDiary, style: StyleModel, activities: list[str]) -> DiaryOut:
    return DiaryOut(
        id=str(d.id),
        entry_date=d.entry_date.isoformat(),
        image_url=d.image_url,
        caption=d.caption,
        style={"kind": style.kind.value, "version": style.version},
        activities=activities,
    )


async def _load_diaries(session, rows: list[PetDiary]) -> list[DiaryOut]:
    if not rows:
        return []
    styles = {
        s.id: s
        for s in (
            await session.execute(
                select(StyleModel).where(
                    StyleModel.id.in_([d.style_model_id for d in rows])
                )
            )
        ).scalars()
    }
    from ..models import PetActivity  # 지역 임포트로 순환 방지

    acts: dict[int, list[str]] = {}
    for a in (
        await session.execute(
            select(PetActivity).where(PetActivity.diary_id.in_([d.id for d in rows]))
        )
    ).scalars():
        acts.setdefault(a.diary_id, []).append(a.activity.value)

    return [_diary_out(d, styles[d.style_model_id], acts.get(d.id, [])) for d in rows]


@router.get("/pets/{pet_id}/diaries", response_model=DiaryListOut)
async def list_diaries(
    pet_id: int,
    user: CurrentUser,
    session: SessionDep,
    before: Annotated[str | None, Query()] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 30,
) -> DiaryListOut:
    """일기장. 가입 첫날은 비어 있다. 에러가 아니다."""
    await services.load_pet(session, user.id, pet_id)

    stmt = select(PetDiary).where(PetDiary.pet_id == pet_id)
    if before:
        stmt = stmt.where(PetDiary.id < parse_id(before, "before"))
    rows = list(
        (await session.execute(stmt.order_by(PetDiary.id.desc()).limit(limit))).scalars()
    )
    return DiaryListOut(
        items=await _load_diaries(session, rows),
        next_before=str(rows[-1].id) if len(rows) == limit else None,
    )


@router.get("/pets/{pet_id}/diaries/{entry_date}", response_model=DiaryOut)
async def get_diary(
    pet_id: int, entry_date: date_type, user: CurrentUser, session: SessionDep
) -> DiaryOut:
    """그날 일기가 없으면 404. 자정 배치가 안 돌았거나 GPU 가 죽어 못 만든 경우다."""
    await services.load_pet(session, user.id, pet_id)
    diary = (
        await session.execute(
            select(PetDiary).where(
                PetDiary.pet_id == pet_id, PetDiary.entry_date == entry_date
            )
        )
    ).scalar_one_or_none()
    if diary is None:
        raise ApiError(404, "not_found", "그날 일기가 없습니다")
    return (await _load_diaries(session, [diary]))[0]
