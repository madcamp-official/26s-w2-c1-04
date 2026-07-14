"""이웃집 (#15, EX-1). 다른 공개 그룹의 펫 방을 구경하고 좋아요를 누른다.

정책(사용자 결정): 다른 공개 그룹이 하나도 없으면 neighbor=null 을 돌려주고
앱이 데모 방을 보여준다. 있으면 실제 이웃을 매칭한다.
자기 그룹은 이웃에서 제외한다. 좋아요는 (pet,user) 유니크라 멱등이다.
"""

from __future__ import annotations

from fastapi import APIRouter
from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError

from ..deps import CurrentUser, SessionDep
from ..errors import ApiError
from ..models import Group, GroupMember, Pet, PetLike
from ..schemas import LikeResultOut, NeighborOut, NeighborResp

router = APIRouter(tags=["neighbors"])

_ISO = "%Y-%m-%dT%H:%M:%SZ"


async def _my_group_id(session, user_id: int) -> int | None:
    return (
        await session.execute(
            select(GroupMember.group_id).where(GroupMember.user_id == user_id)
        )
    ).scalar_one_or_none()


async def _to_neighbor(session, group: Group, pet: Pet, user_id: int) -> NeighborOut:
    likes = (
        await session.execute(
            select(func.count(PetLike.id)).where(PetLike.pet_id == pet.id)
        )
    ).scalar_one()
    liked = (
        await session.execute(
            select(PetLike.id).where(
                PetLike.pet_id == pet.id, PetLike.user_id == user_id
            )
        )
    ).scalar_one_or_none() is not None
    return NeighborOut(
        group_id=str(group.id),
        group_name=group.name,
        pet_id=str(pet.id),
        pet_name=pet.name,
        pet_level=pet.level,
        created_at=group.created_at.strftime(_ISO) if group.created_at else None,
        background_color=group.background_color,
        likes=int(likes),
        liked_by_me=liked,
    )


@router.get("/neighbors/random", response_model=NeighborResp)
async def random_neighbor(user: CurrentUser, session: SessionDep) -> NeighborResp:
    my_gid = await _my_group_id(session, user.id)
    stmt = (
        select(Group, Pet)
        .join(Pet, Pet.group_id == Group.id)
        .where(Pet.is_public.is_(True))
    )
    if my_gid is not None:
        stmt = stmt.where(Group.id != my_gid)
    row = (await session.execute(stmt.order_by(func.rand()).limit(1))).first()
    if row is None:
        return NeighborResp(neighbor=None)  # 아직 이웃이 없다 → 앱이 데모를 보여준다
    g, pet = row
    return NeighborResp(neighbor=await _to_neighbor(session, g, pet, user.id))


@router.get("/neighbors/by-code/{invite_code}", response_model=NeighborResp)
async def neighbor_by_code(
    invite_code: str, user: CurrentUser, session: SessionDep
) -> NeighborResp:
    code = invite_code.strip().upper()
    g = (
        await session.execute(select(Group).where(Group.invite_code == code))
    ).scalar_one_or_none()
    if g is None:
        raise ApiError(404, "not_found", "그런 집이 없어요")
    my_gid = await _my_group_id(session, user.id)
    if my_gid is not None and g.id == my_gid:
        raise ApiError(400, "invalid_request", "우리 집이에요")
    pet = (
        await session.execute(select(Pet).where(Pet.group_id == g.id))
    ).scalar_one_or_none()
    if pet is None:
        raise ApiError(404, "not_found", "그 집엔 아직 펫이 없어요")
    return NeighborResp(neighbor=await _to_neighbor(session, g, pet, user.id))


@router.post("/neighbors/{pet_id}/like", response_model=LikeResultOut)
async def like_pet(
    pet_id: int, user: CurrentUser, session: SessionDep
) -> LikeResultOut:
    pet = await session.get(Pet, pet_id)
    if pet is None:
        raise ApiError(404, "not_found", "펫이 없어요")
    my_gid = await _my_group_id(session, user.id)
    if my_gid is not None and pet.group_id == my_gid:
        raise ApiError(400, "invalid_request", "우리 집 펫은 좋아요할 수 없어요")
    existing = (
        await session.execute(
            select(PetLike.id).where(
                PetLike.pet_id == pet_id, PetLike.user_id == user.id
            )
        )
    ).scalar_one_or_none()
    if existing is None:
        session.add(PetLike(pet_id=pet_id, user_id=user.id))
        try:
            await session.commit()
        except IntegrityError:
            await session.rollback()  # 동시 좋아요 경합 — 이미 눌린 것으로 취급
    likes = (
        await session.execute(
            select(func.count(PetLike.id)).where(PetLike.pet_id == pet_id)
        )
    ).scalar_one()
    return LikeResultOut(pet_id=str(pet_id), likes=int(likes), liked=True)
