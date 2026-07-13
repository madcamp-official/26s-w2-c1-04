"""인증과 온보딩. ON-1, ST-1. docs/API.md 2절."""

from __future__ import annotations

from fastapi import APIRouter
from sqlalchemy import select
from sqlalchemy.exc import DBAPIError

from ..deps import CurrentUser, SessionDep
from ..errors import MYSQL_DEADLOCK_ERRNO, MYSQL_DUPLICATE_ERRNO, mysql_errno
from ..models import AuthIdentity, AuthProvider, Group, GroupMember, User
from ..schemas import GroupBrief, MeOut, RegisterIn, RegisterOut, UpdateMeIn, UserOut
from ..security import hash_token, issue_token

router = APIRouter(tags=["auth"])


async def _issue_for_identity(session: SessionDep, identity: AuthIdentity) -> RegisterOut:
    """기존 identity 에 새 토큰을 발급하고 커밋한다."""
    user = await session.get(User, identity.user_id)
    assert user is not None
    token = issue_token(user.id)
    identity.secret_hash = hash_token(token)
    await session.commit()
    return RegisterOut(
        token=token, user=UserOut(id=str(user.id), display_name=user.display_name)
    )


@router.post("/auth/register", response_model=RegisterOut)
async def register(body: RegisterIn, session: SessionDep) -> RegisterOut:
    """앱 최초 실행 시 한 번. 인증 불필요.

    같은 `device_uid` 로 다시 부르면 기존 유저에게 **새 토큰을 발급**한다.
    `secret_hash` 만 저장하므로 원래 토큰을 되돌려줄 수 없기 때문이다.
    이전 토큰은 그 즉시 무효가 된다.

    **동시성:** 서로 다른 device_uid 두 건이 동시에 등록하면 InnoDB 가 (device_uid
    충돌이 아니라) 인덱스 갭 락에서 **deadlock** 을 낼 수 있다. deadlock 은 "누가 내
    행을 이미 넣었다"는 뜻이 아니므로 재조회하면 안 되고, **트랜잭션 전체를 재시도**해야
    한다. 반면 UNIQUE 위반(같은 device_uid 최초 등록 경합)은 승자 행을 재조회한다.
    """
    last_exc: Exception | None = None
    for _ in range(3):
        try:
            identity = (
                await session.execute(
                    select(AuthIdentity)
                    .where(
                        AuthIdentity.provider == AuthProvider.DEVICE,
                        AuthIdentity.provider_uid == body.device_uid,
                    )
                    .with_for_update()
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

            return await _issue_for_identity(session, identity)
        except DBAPIError as exc:
            errno = mysql_errno(exc)
            await session.rollback()
            if errno == MYSQL_DUPLICATE_ERRNO:
                # 같은 device_uid 최초 등록 경합: 승자 identity 에 새 토큰 발급.
                winner = (
                    await session.execute(
                        select(AuthIdentity)
                        .where(
                            AuthIdentity.provider == AuthProvider.DEVICE,
                            AuthIdentity.provider_uid == body.device_uid,
                        )
                        .with_for_update()
                    )
                ).scalar_one_or_none()
                if winner is not None:
                    return await _issue_for_identity(session, winner)
                last_exc = exc  # 승자 행이 아직 안 보이면 재시도
                continue
            if errno == MYSQL_DEADLOCK_ERRNO:
                last_exc = exc  # deadlock → 전체 재시도
                continue
            raise
    assert last_exc is not None
    raise last_exc


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
