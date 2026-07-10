"""그룹. ON-2, ON-3, ON-4, GR-1, GR-2. docs/API.md 3절.

**정원 2명이 이 파일의 주제다.** 세 겹으로 막는다.

1. `groups.member_count` 에 CHECK (schema.sql)
2. `group_members` 의 BEFORE INSERT 트리거가 3번째 행을 SIGNAL 로 거부 (schema.sql)
3. 여기서 가입 트랜잭션이 `groups` 행을 `FOR UPDATE` 로 잠근다

세 겹인 이유는 초대 코드를 두 사람이 동시에 입력하는 경합이 실제로 나기 때문이다.
잠금이 없으면 둘 다 `member_count == 1` 을 읽고 둘 다 통과한다. 그때 트리거가 하나를
막아주지만, 트리거만 믿으면 에러 메시지가 사용자에게 그대로 새어 나간다.
"""

from __future__ import annotations

import secrets

from fastapi import APIRouter
from sqlalchemy import select
from sqlalchemy.exc import DBAPIError, IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from ..deps import CurrentUser, SessionDep
from ..errors import MYSQL_SIGNAL_ERRNO, ApiError, mysql_errno
from ..models import (
    Group,
    GroupMember,
    MemberRole,
    Pet,
    StyleKind,
    StyleModel,
    StyleStatus,
    User,
)
from ..schemas import (
    CreateGroupIn,
    CreateGroupOut,
    GroupOut,
    JoinGroupIn,
    MemberOut,
    PetOut,
    UpdateGroupIn,
    UpdateNicknameIn,
)
from ..security import group_id_of

router = APIRouter(tags=["groups"])

# 헷갈리는 글자(I, O, 0, 1)를 뺐다. 초대 코드는 사람이 손으로 옮겨 적는다.
_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

# 기본 그림체 프리셋. 그룹 생성 시 style_models 에 미리 넣어 가입 첫날부터
# 일기가 그려지게 한다 (SPEC 6.3절).
DEFAULT_STYLE_WEIGHTS = "presets/sd15_default"


def _invite_code() -> str:
    return "".join(secrets.choice(_ALPHABET) for _ in range(8))


async def _members(session: AsyncSession, group_id: int) -> list[MemberOut]:
    rows = (
        await session.execute(
            select(GroupMember, User)
            .join(User, User.id == GroupMember.user_id)
            .where(GroupMember.group_id == group_id)
            .order_by(GroupMember.joined_at)
        )
    ).all()
    return [
        MemberOut(
            user_id=str(u.id),
            display_name=u.display_name,
            nickname=gm.nickname,
            role=gm.role.value,
        )
        for gm, u in rows
    ]


async def _group_out(session: AsyncSession, group: Group) -> GroupOut:
    return GroupOut(
        id=str(group.id),
        name=group.name,
        invite_code=group.invite_code,
        background_color=group.background_color,
        member_count=group.member_count,
        members=await _members(session, group.id),
    )


async def _require_member(session: AsyncSession, user_id: int, group_id: int) -> None:
    hit = (
        await session.execute(
            select(GroupMember.id).where(
                GroupMember.group_id == group_id, GroupMember.user_id == user_id
            )
        )
    ).scalar_one_or_none()
    if hit is None:
        raise ApiError(403, "forbidden", "내 그룹이 아닙니다")


# ---------------------------------------------------------------------------


@router.post("/groups", response_model=CreateGroupOut, status_code=201)
async def create_group(
    body: CreateGroupIn, user: CurrentUser, session: SessionDep
) -> CreateGroupOut:
    """부수 효과가 둘 있다. 펫 1마리와 기본 그림체 행이 함께 생긴다."""
    if await group_id_of(session, user.id) is not None:
        raise ApiError(409, "already_in_group", "이미 그룹에 속해 있습니다")

    # UNIQUE(invite_code) 충돌은 사실상 안 나지만, 나면 다시 뽑는다.
    for attempt in range(5):
        group = Group(
            name=body.name, invite_code=_invite_code(), owner_user_id=user.id
        )
        session.add(group)
        try:
            await session.flush()
            break
        except IntegrityError:
            await session.rollback()
            if attempt == 4:
                raise ApiError(500, "error", "초대 코드 발급 실패")
    else:  # pragma: no cover
        raise ApiError(500, "error", "초대 코드 발급 실패")

    session.add(GroupMember(group_id=group.id, user_id=user.id, role=MemberRole.OWNER))
    pet = Pet(group_id=group.id, name=body.pet_name)
    session.add(pet)
    session.add(
        StyleModel(
            group_id=group.id,
            kind=StyleKind.DEFAULT,
            version=0,
            status=StyleStatus.READY,
            weights_path=DEFAULT_STYLE_WEIGHTS,
        )
    )
    await session.commit()

    # member_count 는 AFTER INSERT 트리거가 올린다. 우리 쪽 객체는 모른다.
    await session.refresh(group)
    await session.refresh(pet)

    return CreateGroupOut(
        group=await _group_out(session, group),
        pet=PetOut(
            id=str(pet.id),
            name=pet.name,
            level=pet.level,
            exp=pet.exp,
            coins=pet.coins,
        ),
    )


@router.post("/groups/join", response_model=GroupOut)
async def join_group(
    body: JoinGroupIn, user: CurrentUser, session: SessionDep
) -> GroupOut:
    # FOR UPDATE 가 동시 가입 경합을 직렬화한다.
    group = (
        await session.execute(
            select(Group).where(Group.invite_code == body.invite_code).with_for_update()
        )
    ).scalar_one_or_none()
    if group is None:
        raise ApiError(404, "not_found", "초대 코드를 찾을 수 없습니다")

    existing = await group_id_of(session, user.id)
    if existing == group.id:
        raise ApiError(409, "already_member", "이미 이 그룹의 멤버입니다")
    if existing is not None:
        raise ApiError(409, "already_in_group", "이미 다른 그룹에 속해 있습니다")

    if group.member_count >= 2:
        raise ApiError(409, "group_full", "그룹 정원은 2명입니다")

    session.add(
        GroupMember(group_id=group.id, user_id=user.id, role=MemberRole.MEMBER)
    )
    try:
        await session.commit()
    except IntegrityError:
        # uq_group_members (같은 그룹 재가입) 또는 uq_group_members_user (다른 그룹 소속).
        # 위 선검사를 통과했는데 여기 걸렸다면 두 요청이 경합한 것이다.
        await session.rollback()
        raise ApiError(409, "already_in_group", "이미 그룹에 속해 있습니다") from None
    except DBAPIError as exc:
        await session.rollback()
        if mysql_errno(exc) == MYSQL_SIGNAL_ERRNO:
            # 트리거가 3번째 행을 막았다. FOR UPDATE 를 우회한 경합이거나
            # member_count 가 실제 행 수와 어긋난 경우다.
            raise ApiError(409, "group_full", "그룹 정원은 2명입니다") from None
        raise

    await session.refresh(group)
    return await _group_out(session, group)


@router.get("/groups/{group_id}", response_model=GroupOut)
async def get_group(group_id: int, user: CurrentUser, session: SessionDep) -> GroupOut:
    await _require_member(session, user.id, group_id)
    group = await session.get(Group, group_id)
    if group is None:
        raise ApiError(404, "not_found", "그룹이 없습니다")
    return await _group_out(session, group)


@router.patch("/groups/{group_id}", response_model=GroupOut)
async def update_group(
    group_id: int, body: UpdateGroupIn, user: CurrentUser, session: SessionDep
) -> GroupOut:
    await _require_member(session, user.id, group_id)
    group = await session.get(Group, group_id)
    if group is None:
        raise ApiError(404, "not_found", "그룹이 없습니다")

    if body.name is not None:
        group.name = body.name
    if body.background_color is not None:
        group.background_color = body.background_color.upper()

    await session.commit()
    await session.refresh(group)
    return await _group_out(session, group)


@router.patch("/groups/{group_id}/members/{target_user_id}", response_model=GroupOut)
async def set_nickname(
    group_id: int,
    target_user_id: int,
    body: UpdateNicknameIn,
    user: CurrentUser,
    session: SessionDep,
) -> GroupOut:
    """상대에게 별명을 지어준다. 자기 자신에게는 못 짓는다."""
    await _require_member(session, user.id, group_id)
    if target_user_id == user.id:
        raise ApiError(400, "invalid_request", "자기 자신에게는 별명을 지을 수 없습니다")

    member = (
        await session.execute(
            select(GroupMember).where(
                GroupMember.group_id == group_id,
                GroupMember.user_id == target_user_id,
            )
        )
    ).scalar_one_or_none()
    if member is None:
        raise ApiError(404, "not_found", "그 사람은 이 그룹의 멤버가 아닙니다")

    member.nickname = body.nickname
    await session.commit()

    group = await session.get(Group, group_id)
    assert group is not None
    return await _group_out(session, group)
