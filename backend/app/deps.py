"""FastAPI 의존성."""

from __future__ import annotations

from typing import Annotated

from fastapi import Depends, Header
from sqlalchemy.ext.asyncio import AsyncSession

from .db import get_session
from .errors import ApiError
from .models import User
from .security import user_from_token

SessionDep = Annotated[AsyncSession, Depends(get_session)]


async def bearer_token(
    authorization: Annotated[str | None, Header()] = None,
) -> str:
    if not authorization or not authorization.lower().startswith("bearer "):
        raise ApiError(401, "unauthorized", "Bearer 토큰이 필요합니다")
    token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise ApiError(401, "unauthorized", "Bearer 토큰이 필요합니다")
    return token


TokenDep = Annotated[str, Depends(bearer_token)]


async def current_user(token: TokenDep, session: SessionDep) -> User:
    """`token` 을 `session` 보다 먼저 선언한 것은 의도적이다.

    FastAPI 는 시그니처 순서대로 의존성을 푼다. 토큰이 없는 요청에까지 DB 커넥션을
    열 이유가 없고, DB 가 죽어 있을 때 401 이 500 으로 둔갑하지도 않는다.
    """
    user = await user_from_token(session, token)
    if user is None:
        raise ApiError(401, "unauthorized", "토큰이 유효하지 않습니다")
    return user


CurrentUser = Annotated[User, Depends(current_user)]
