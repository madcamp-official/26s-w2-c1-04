"""앱 진입점.

기동:
    uvicorn app.main:asgi --host 0.0.0.0 --port 8000

**워커를 늘리지 마라.** 사라지기 모드의 5초 타이머가 프로세스 인메모리다
(docs/STACK.md 6절). `--workers 2` 를 주는 순간 타이머가 공유되지 않아 낙서가 안 사라진다.
"""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager
from collections.abc import AsyncIterator
from datetime import datetime, timezone

import socketio
from fastapi import APIRouter, FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles

from . import db, gpu, notifications, realtime, scheduler, services, state
from .config import get_settings
from .ephemeral import ExpiryScheduler
from .errors import install_error_handlers
from .realtime import sio
from .routers import (
    auth,
    devices,
    doodles,
    groups,
    pets,
    pokes,
    questions,
    reports,
    widget,
)
from .security import group_id_of, user_from_token

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
logger = logging.getLogger(__name__)

async def _resolve_socket_token(token: str) -> tuple[int, int | None] | None:
    """Socket.IO 연결 인증. realtime 모듈은 DB 를 모르므로 여기서 주입한다."""
    try:
        async with db.session_factory()() as session:
            user = await user_from_token(session, token)
            if user is None:
                return None
            return user.id, await group_id_of(session, user.id)
    except Exception:
        logger.warning("소켓 토큰 검증 실패", exc_info=True)
        return None


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncIterator[None]:
    settings = get_settings()
    settings.media_root.mkdir(parents=True, exist_ok=True)
    notifications.init_push(settings)

    expiry = ExpiryScheduler(services.expire_doodle)
    state.set_expiry(expiry)

    realtime.set_token_resolver(_resolve_socket_token)
    realtime.set_service_handlers(
        doodle_viewed=services.sock_doodle_viewed,
        poke_send=services.sock_poke_send,
    )

    db_ok = False
    try:
        db.init_engine()
        db_ok = await db.ping()
    except Exception:
        # asyncmy 가 없거나 DB 가 죽어 있어도 서버는 뜬다. /health 가 db: down 을 보고한다.
        logger.warning("DB 엔진 초기화 실패. db 기능 없이 계속한다.", exc_info=True)

    if db_ok:
        # 부팅 스윕. 타이머는 프로세스 인메모리라 재기동하면 전부 사라진다.
        # 이미 만료 시각이 지난 낙서는 즉시 정리하고, 아직 안 지난 것은 재스케줄한다.
        try:
            await services.boot_sweep()  # ExpiryScheduler.sweep 이 결과를 로깅한다
        except Exception:
            logger.warning("부팅 스윕 실패", exc_info=True)
        scheduler.start()

    logger.info("기동 완료. gpu_enabled=%s db=%s", settings.gpu_enabled, db_ok)

    yield

    scheduler.shutdown()
    await expiry.aclose()
    await db.dispose_engine()


app = FastAPI(title="Memory Pager", version="0.1.0", lifespan=lifespan)
install_error_handlers(app)

cors_origins = get_settings().parsed_cors_origins()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"] if cors_origins == "*" else cors_origins,
    allow_methods=["*"],
    allow_headers=["*"],
    allow_credentials=False,
)

v1 = APIRouter(prefix="/v1")


@v1.get("/health")
async def health() -> dict[str, str]:
    """Day 1 관통 확인용. GPU 가 down 이어도 앱은 정상이어야 한다."""
    return {
        "status": "ok",
        "db": "ok" if await db.ping() else "down",
        "gpu": await gpu.gpu_status(),
        "time": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    }


v1.include_router(auth.router)
v1.include_router(devices.router)
v1.include_router(doodles.router)
v1.include_router(pets.router)
v1.include_router(pokes.router)
v1.include_router(widget.router)
v1.include_router(reports.router)
v1.include_router(questions.router)
v1.include_router(groups.router)

app.include_router(v1)

# 미디어는 /v1 밖이다. photo_url 이 "/media/..." 로 내려간다 (docs/API.md 0절).
app.mount(
    get_settings().media_url_prefix,
    StaticFiles(directory=get_settings().media_root, check_dir=False),
    name="media",
)

# **이게 uvicorn 이 받는 앱이다.** app.mount("/socket.io", ...) 로 붙이면
# 특정 FastAPI 버전에서 404 가 난다 (docs/STACK.md 5절).
asgi = socketio.ASGIApp(sio, other_asgi_app=app)
