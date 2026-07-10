"""인증과 온보딩. ON-1, ST-1. docs/API.md 2절."""

from __future__ import annotations

from fastapi import APIRouter
from sqlalchemy import select

from ..deps import CurrentUser, SessionDep
from ..models import AuthIdentity, AuthProvider, Group, GroupMember, User
from ..schemas import GroupBrief, MeOut, RegisterIn, RegisterOut, UpdateMeIn, UserOut
from ..security import hash_token, issue_token

router = APIRouter(tags=["auth"])


@router.post("/auth/register", response_model=RegisterOut)
async def register(body: RegisterIn, session: SessionDep) -> RegisterOut:
    """앱 최초 실행 시 한 번. 인증 불필요.

    같은 `device_uid` 로 다시 부르면 기존 유저에게 **새 토큰을 발급**한다.
    `secret_hash` 만 저장하므로 원래 토큰을 되돌려줄 수 없기 때문이다.
    이전 토큰은 그 즉시 무효가 된다.
    """
    identity = (
        await session.execute(
            select(AuthIdentity).where(
                AuthIdentity.provider == AuthProvider.DEVICE,
                AuthIdentity.provider_uid == body.device_uid,
            )
        )
    ).scalar_one_or_none()

    if identity is None:
        user = User(display_name=body.display_name)
        session.add(user)
        await session.flush()  # user.id 가 필요하다
        identity = AuthIdentity(
            user_id=user.id,
            provider=AuthProvider.DEVICE,
            provider_uid=body.device_uid,
        )
        session.add(identity)
    else:
        user = await session.get(User, identity.user_id)
        assert user is not None

    token = issue_token(user.id)
    identity.secret_hash = hash_token(token)
    await session.commit()

    return RegisterOut(
        token=token, user=UserOut(id=str(user.id), display_name=user.display_name)
    )


@router.get("/me", response_model=MeOut)
async def me(user: CurrentUser, session: SessionDep) -> MeOut:
    row = (
        await session.execute(
            select(Group.id, Group.name)
            .join(GroupMember, GroupMember.group_id == Group.id)
            .where(GroupMember.user_id == user.id)
            .limit(1)
        )
    ).first()

    return MeOut(
        user=UserOut(id=str(user.id), display_name=user.display_name),
        group=GroupBrief(id=str(row[0]), name=row[1]) if row else None,
    )


@router.patch("/me", response_model=UserOut)
async def update_me(body: UpdateMeIn, user: CurrentUser, session: SessionDep) -> UserOut:
    user.display_name = body.display_name
    await session.commit()
    return UserOut(id=str(user.id), display_name=user.display_name)
