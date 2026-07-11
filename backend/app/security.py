"""토큰. 보안은 이 프로젝트의 비목표다(SPEC 1.2절).

토큰 형식은 `mp_{user_id}_{secret}` 이다. **user_id 를 토큰에 박은 이유가 있다.**
`auth_identities.secret_hash` 에는 인덱스가 없다(schema.sql 참조). 해시로 조회하면
풀스캔이 난다. user_id 를 파싱해 PK 로 찾으면 O(1)이다.

`secret_hash` 에는 토큰 전체의 sha256(hex 64자)을 넣는다. `CHAR(64)` 와 맞는다.
"""

from __future__ import annotations

import hashlib
import secrets

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .errors import MAX_BIGINT_ID
from .models import AuthIdentity, AuthProvider, GroupMember, User

TOKEN_PREFIX = "mp_"


def issue_token(user_id: int) -> str:
    return f"{TOKEN_PREFIX}{user_id}_{secrets.token_urlsafe(32)}"


def hash_token(token: str) -> str:
    return hashlib.sha256(token.encode()).hexdigest()


def parse_user_id(token: str) -> int | None:
    if not token.startswith(TOKEN_PREFIX):
        return None
    rest = token[len(TOKEN_PREFIX) :]
    head, sep, _ = rest.partition("_")
    if not sep or not head.isdigit():
        return None
    user_id = int(head)
    return user_id if 0 < user_id <= MAX_BIGINT_ID else None


async def user_from_token(session: AsyncSession, token: str) -> User | None:
    user_id = parse_user_id(token)
    if user_id is None:
        return None

    identity = (
        await session.execute(
            select(AuthIdentity).where(
                AuthIdentity.user_id == user_id,
                AuthIdentity.provider == AuthProvider.DEVICE,
            )
        )
    ).scalar_one_or_none()

    if identity is None or identity.secret_hash is None:
        return None
    if not secrets.compare_digest(identity.secret_hash, hash_token(token)):
        return None

    return await session.get(User, user_id)


async def group_id_of(session: AsyncSession, user_id: int) -> int | None:
    """이 유저가 속한 그룹. 커플 앱이라 하나뿐이다."""
    return (
        await session.execute(
            select(GroupMember.group_id).where(GroupMember.user_id == user_id).limit(1)
        )
    ).scalar_one_or_none()
