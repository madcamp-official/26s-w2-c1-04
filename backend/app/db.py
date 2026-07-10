"""비동기 엔진과 세션.

엔진을 **모듈 임포트 시점에 만들지 않는다.** 그러면 asyncmy 가 없는 환경(로컬 개발 기계,
CI, 문서 빌드)에서 임포트만 해도 터진다. `init_engine()`을 lifespan 에서 부른다.
"""

from __future__ import annotations

from collections.abc import AsyncIterator

from sqlalchemy import text
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from .config import get_settings

_engine: AsyncEngine | None = None
_session_factory: async_sessionmaker[AsyncSession] | None = None


def init_engine() -> AsyncEngine:
    global _engine, _session_factory
    if _engine is not None:
        return _engine

    settings = get_settings()
    _engine = create_async_engine(
        settings.database_url,
        # pool_pre_ping: 죽은 커넥션을 걸러낸다.
        # pool_recycle < MySQL 의 wait_timeout: 'server has gone away' 를 막는다.
        pool_pre_ping=True,
        pool_recycle=3600,
        # 앱 VM RAM 이 4GB 뿐이고 사용자는 둘이다. 풀을 키울 이유가 없다.
        pool_size=5,
        max_overflow=5,
    )
    _session_factory = async_sessionmaker(_engine, expire_on_commit=False)
    return _engine


def session_factory() -> async_sessionmaker[AsyncSession]:
    if _session_factory is None:
        raise RuntimeError("init_engine() 을 먼저 불러라 (lifespan 에서 부른다)")
    return _session_factory


async def dispose_engine() -> None:
    global _engine, _session_factory
    if _engine is not None:
        await _engine.dispose()
    _engine = None
    _session_factory = None


async def get_session() -> AsyncIterator[AsyncSession]:
    """FastAPI 의존성."""
    async with session_factory()() as session:
        yield session


async def ping() -> bool:
    """`GET /health` 용. 실패해도 예외를 던지지 않는다."""
    if _engine is None:
        return False
    try:
        async with _engine.connect() as conn:
            await conn.execute(text("SELECT 1"))
        return True
    except Exception:
        return False
