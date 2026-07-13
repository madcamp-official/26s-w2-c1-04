"""인증과 온보딩. ON-1, ST-1. docs/API.md 2절."""

from __future__ import annotations

import asyncio
import random

from fastapi import APIRouter
from sqlalchemy import select
from sqlalchemy.exc import DBAPIError

from ..deps import CurrentUser, SessionDep
from ..errors import MYSQL_DEADLOCK_ERRNO, MYSQL_DUPLICATE_ERRNO, mysql_errno
from ..models import AuthIdentity, AuthProvider, Group, GroupMember, User
from ..schemas import GroupBrief, MeOut, RegisterIn, RegisterOut, UpdateMeIn, UserOut
from ..security import hash_token, issue_token

router = APIRouter(tags=["auth"])

# 동시 등록 폭주 시 재시도 상한. 갭 락 deadlock·유니크 충돌 모두 재시도로 수렴한다.
_REGISTER_MAX_TRIES = 6


@router.post("/auth/register", response_model=RegisterOut)
async def register(body: RegisterIn, session: SessionDep) -> RegisterOut:
    """앱 최초 실행 시 한 번. 인증 불필요.

    같은 `device_uid` 로 다시 부르면 기존 유저에게 **새 토큰을 발급**한다.
    `secret_hash` 만 저장하므로 원래 토큰을 되돌려줄 수 없기 때문이다.
    이전 토큰은 그 즉시 무효가 된다.

    동시 등록(서로 다른 uid든 같은 uid든)은 InnoDB 갭 락으로 deadlock(1213)이
    나거나 같은 uid 두 건이 동시에 INSERT하며 유니크 충돌(1062)이 날 수 있다.
    두 경우 모두 rollback 후 짧게 백오프하고 통째로 재시도하면 수렴한다.
    """
    last_exc: DBAPIError | None = None
    for attempt in range(_REGISTER_MAX_TRIES):
        try:
            return await _register_once(session, body)
        except DBAPIError as exc:
            if mysql_errno(exc) not in (MYSQL_DUPLICATE_ERRNO, MYSQL_DEADLOCK_ERRNO):
                raise
            await session.rollback()
            last_exc = exc
            # 지수 백오프 + 지터로 재충돌을 흩뜨린다(같은 타이밍에 재시도하지 않게).
            await asyncio.sleep(random.uniform(0.01, 0.03) * (attempt + 1))
    assert last_exc is not None
    raise last_exc


async def _register_once(session: SessionDep, body: RegisterIn) -> RegisterOut:
    """등록 1회 시도. 매 재시도마다 세션 상태를 새로 읽어 새 객체로 작업한다.

    초기 SELECT에 `FOR UPDATE`를 걸지 않는다. 존재하지 않는 행에 대한 FOR UPDATE는
    갭 락을 잡아 동시 INSERT 사이에 deadlock을 유발하기 때문이다. 대신 낙관적으로
    INSERT하고, 같은 uid가 먼저 들어온 경우의 유니크 충돌은 상위 재시도가 처리한다.
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
