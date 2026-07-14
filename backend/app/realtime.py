"""Socket.IO 실시간 계층 (과제 주 옵션).

docs/STACK.md 5절의 함정 네 가지 중 셋이 여기 걸려 있다.

1. CORS 는 FastAPI 미들웨어가 아니라 `AsyncServer(cors_allowed_origins=...)` 에 건다.
   아니면 핸드셰이크가 통과하지 못한다.
2. FastAPI 를 `socketio.ASGIApp(sio, other_asgi_app=app)` 로 감싼다. `app.mount()` 가 아니다.
   (main.py 에서 한다)
3. Flutter 는 `setTransports(['websocket'])` 를 명시해야 한다. dart:io 는 polling 을 못 한다.

이 모듈은 DB 를 모른다. 인증과 서비스 로직은 콜백으로 주입받는다.
클라이언트 → 서버 이벤트는 **ack 로 결과를 돌려준다.** 소켓 경로에도 실패를 알릴 길이 있어야
앱이 REST 와 같은 UX 를 낼 수 있다 (docs/API.md 9절).
"""

from __future__ import annotations

import logging
from collections.abc import Awaitable, Callable
from typing import Any

import socketio

from .config import get_settings

logger = logging.getLogger(__name__)

NAMESPACE = "/rt"

sio = socketio.AsyncServer(
    async_mode="asgi",
    cors_allowed_origins=get_settings().parsed_cors_origins(),
)


def group_room(group_id: int) -> str:
    return f"group:{group_id}"


# ---------------------------------------------------------------------------
# 주입 지점 — DB 를 아는 쪽이 채운다
# ---------------------------------------------------------------------------

# token -> (user_id, group_id | None) | None
TokenResolver = Callable[[str], Awaitable[tuple[int, int | None] | None]]
# (user_id, payload) -> ack dict
ServiceHandler = Callable[[int, dict[str, Any]], Awaitable[dict[str, Any]]]

_resolve_token: TokenResolver | None = None
_on_doodle_viewed: ServiceHandler | None = None
_on_poke_send: ServiceHandler | None = None


def set_token_resolver(fn: TokenResolver) -> None:
    global _resolve_token
    _resolve_token = fn


def set_service_handlers(
    *, doodle_viewed: ServiceHandler, poke_send: ServiceHandler
) -> None:
    global _on_doodle_viewed, _on_poke_send
    _on_doodle_viewed = doodle_viewed
    _on_poke_send = poke_send


# ---------------------------------------------------------------------------
# 연결
# ---------------------------------------------------------------------------


@sio.event(namespace=NAMESPACE)
async def connect(sid: str, environ: dict, auth: dict | None = None) -> bool:
    token = auth.get("token") if isinstance(auth, dict) else None
    if not isinstance(token, str) or not token or _resolve_token is None:
        logger.info("소켓 연결 거부: 토큰 없음 (sid=%s)", sid)
        return False

    resolved = await _resolve_token(token)
    if resolved is None:
        logger.info("소켓 연결 거부: 토큰 불일치 (sid=%s)", sid)
        return False

    user_id, group_id = resolved
    await sio.save_session(
        sid, {"user_id": user_id, "group_id": group_id}, namespace=NAMESPACE
    )
    if group_id is not None:
        # AsyncServer.enter_room 은 코루틴이다 (python-socketio 5.16.3 에서 확인).
        await sio.enter_room(sid, group_room(group_id), namespace=NAMESPACE)
    else:
        # 그룹이 없는 유저도 연결은 허용한다. 그룹에 가입하면 앱이 재연결한다.
        logger.info("그룹 없는 유저가 연결됨 (user_id=%s)", user_id)
    return True


@sio.event(namespace=NAMESPACE)
async def disconnect(sid: str, reason: str | None = None) -> None:
    logger.debug("소켓 연결 종료 (sid=%s, reason=%s)", sid, reason)


# ---------------------------------------------------------------------------
# 클라이언트 → 서버. REST 와 동등하며 ack 로 결과를 돌려준다.
# ---------------------------------------------------------------------------


@sio.on("doodle:viewed", namespace=NAMESPACE)
async def on_doodle_viewed(sid: str, data: dict[str, Any]) -> dict[str, Any]:
    return await _dispatch(sid, _on_doodle_viewed, data, "doodle:viewed")


@sio.on("poke:send", namespace=NAMESPACE)
async def on_poke_send(sid: str, data: dict[str, Any]) -> dict[str, Any]:
    return await _dispatch(sid, _on_poke_send, data, "poke:send")


async def _dispatch(
    sid: str, handler: ServiceHandler | None, data: dict[str, Any], event: str
) -> dict[str, Any]:
    if handler is None:
        return {"error": {"code": "not_ready", "message": f"{event} 핸들러 미등록"}}
    if not isinstance(data, dict):
        return {
            "error": {
                "code": "invalid_request",
                "message": f"{event} 페이로드는 객체여야 합니다",
            }
        }
    try:
        session = await sio.get_session(sid, namespace=NAMESPACE)
    except Exception:
        logger.info("%s 세션 없음 (sid=%s)", event, sid)
        return {
            "error": {"code": "unauthorized", "message": "연결 세션이 없습니다"}
        }
    user_id = session.get("user_id")
    if not isinstance(user_id, int):
        return {
            "error": {"code": "unauthorized", "message": "연결 세션이 없습니다"}
        }
    try:
        return await handler(user_id, data or {})
    except Exception:
        logger.exception("%s 처리 실패", event)
        return {"error": {"code": "internal", "message": "처리 실패"}}


# ---------------------------------------------------------------------------
# 서버 → 클라이언트 (docs/API.md 9절)
# ---------------------------------------------------------------------------


async def _emit(group_id: int, event: str, payload: dict[str, Any]) -> None:
    try:
        await sio.emit(event, payload, room=group_room(group_id), namespace=NAMESPACE)
    except Exception:
        # DB 커밋 뒤의 보조 경로다. 소켓 장애가 성공한 REST 요청을 500으로 바꾸면
        # 클라이언트 재시도로 중복 데이터가 생긴다.
        logger.exception("소켓 이벤트 전송 실패: %s (group=%s)", event, group_id)


async def emit_doodle_new(group_id: int, payload: dict[str, Any]) -> None:
    await _emit(group_id, "doodle:new", payload)


async def emit_doodle_expired(group_id: int, doodle_id: int) -> None:
    await _emit(group_id, "doodle:expired", {"doodle_id": str(doodle_id)})


async def emit_doodle_updated(group_id: int, doodle_id: int) -> None:
    """낙서가 갱신됐음(예: AI 캡션 생성 완료)을 알린다. 앱은 목록을 다시 받는다.
    doodle:new 는 응답 직후 emit 되지만 캡션은 백그라운드로 뒤늦게 채워지므로,
    이 이벤트가 없으면 수신자는 재접속 전까지 캡션을 못 본다."""
    await _emit(group_id, "doodle:updated", {"doodle_id": str(doodle_id)})


async def emit_poke(group_id: int, from_user_id: int, at: str) -> None:
    await _emit(group_id, "poke", {"from_user_id": str(from_user_id), "at": at})


async def emit_group_updated(group_id: int, *, name: str, background_color: str) -> None:
    """그룹 설정(이름·배경색)이 바뀌었음을 알린다. 배경색은 공유 값이라 파트너도 같이
    봐야 하는데, 앱은 폴링에서 그룹을 일부러 재조회하지 않으므로(방금 바꾼 색 보호),
    이 이벤트가 없으면 파트너는 재시작 전까지 못 본다(BUG-3)."""
    await _emit(
        group_id,
        "group:updated",
        {"name": name, "background_color": background_color},
    )


async def emit_pet_activity(
    group_id: int, pet_id: int, activity: str, utterance: str
) -> None:
    await _emit(
        group_id,
        "pet:activity",
        {"pet_id": str(pet_id), "activity": activity, "utterance": utterance},
    )


async def emit_pet_levelup(group_id: int, pet_id: int, level: int) -> None:
    await _emit(group_id, "pet:levelup", {"pet_id": str(pet_id), "level": level})


async def emit_diary_new(
    group_id: int, diary_id: int, entry_date: str, style_kind: str
) -> None:
    await _emit(
        group_id,
        "diary:new",
        {"diary_id": str(diary_id), "entry_date": entry_date, "style_kind": style_kind},
    )


async def emit_member_left(group_id: int, user_id: int) -> None:
    """한쪽이 커플 연결을 끊었음(#24)을 남은 상대에게 알린다.
    남은 앱은 이 이벤트로 즉시 온보딩으로 되돌아간다(스스로 폴링할 때까지 방치 금지)."""
    await _emit(group_id, "member:left", {"user_id": str(user_id)})


async def emit_question_answered(group_id: int, user_id: int) -> None:
    """오늘의 질문에 누군가 답했음을 그룹에 알린다(#6). 상대 앱이 질문을 다시 받아
    (둘 다 답한 경우) 상대 답변을 즉시 볼 수 있게 한다 — 콜드스타트 전까지 못 보던 문제."""
    await _emit(group_id, "question:answered", {"user_id": str(user_id)})
