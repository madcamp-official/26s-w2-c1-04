"""REST 와 Socket.IO 가 공유하는 로직.

`POST /doodles/{id}/view` 와 소켓 `doodle:viewed` 는 **같은 함수를 부른다.**
REST 는 항상 되는 길이고 소켓은 빠른 길이다 (docs/API.md 9절).
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from . import media, realtime, state
from .config import get_settings
from .db import session_factory
from .errors import ApiError
from .models import Doodle, DoodleMode, DoodleReceipt, GroupMember, Poke

logger = logging.getLogger(__name__)


def _real_now() -> datetime:
    """naive UTC. MySQL DATETIME 은 tz 를 갖지 않는다."""
    return datetime.now(timezone.utc).replace(tzinfo=None)


def _now() -> datetime:
    """**소수점 초를 버린 naive UTC.**

    MySQL 의 `DATETIME` 은 초 단위이고, 소수점 이하를 **반올림해서** 저장한다.
    `13:02:38.7` 을 넣으면 `13:02:39` 가 되어 나온다. 그래서 최초 확인 응답(메모리 값)과
    재확인 응답(DB 값)이 1초 어긋났다. 저장 전에 잘라내면 둘이 같아진다.
    """
    return _real_now().replace(microsecond=0)


async def require_member(session: AsyncSession, user_id: int, group_id: int) -> None:
    hit = (
        await session.execute(
            select(GroupMember.id).where(
                GroupMember.group_id == group_id, GroupMember.user_id == user_id
            )
        )
    ).scalar_one_or_none()
    if hit is None:
        raise ApiError(403, "forbidden", "내 그룹이 아닙니다")


async def my_group_id(session: AsyncSession, user_id: int) -> int:
    gid = (
        await session.execute(
            select(GroupMember.group_id).where(GroupMember.user_id == user_id)
        )
    ).scalar_one_or_none()
    if gid is None:
        raise ApiError(400, "invalid_request", "먼저 그룹에 들어가야 합니다")
    return gid


async def load_visible_doodle(
    session: AsyncSession, user_id: int, doodle_id: int
) -> Doodle:
    """404(없는 id)와 410(만료됨)을 갈라 쓴다. soft delete 라 행은 남는다."""
    doodle = await session.get(Doodle, doodle_id)
    if doodle is None:
        raise ApiError(404, "not_found", "낙서가 없습니다")
    await require_member(session, user_id, doodle.group_id)
    if doodle.deleted_at is not None:
        raise ApiError(410, "doodle_expired", "사라진 낙서입니다")
    return doodle


# ---------------------------------------------------------------------------
# 사라지기 모드 (SD-6) — 과제 주 옵션
# ---------------------------------------------------------------------------


async def mark_viewed(
    session: AsyncSession, user_id: int, doodle_id: int
) -> datetime | None:
    """확인 처리. 몇 번 불러도 안전하다.

    **최초 확인일 때만 타이머를 건다.** 게이트가 없으면 뷰어를 닫았다 열 때마다
    `expires_at` 이 갱신되어 낙서가 영영 사라지지 않는다. receipt 는 멱등인데
    만료는 멱등이 아닌, 놓치기 쉬운 구멍이다 (docs/API.md 4절).

    기준 시각은 `now` 가 아니라 **`viewed_at`** 이다.
    """
    doodle = await load_visible_doodle(session, user_id, doodle_id)

    receipt = (
        await session.execute(
            select(DoodleReceipt).where(
                DoodleReceipt.doodle_id == doodle_id,
                DoodleReceipt.user_id == user_id,
            )
        )
    ).scalar_one_or_none()

    real = _real_now()
    viewed_at = real.replace(microsecond=0)

    first_view = receipt is None
    if first_view:
        session.add(DoodleReceipt(doodle_id=doodle_id, user_id=user_id, viewed_at=viewed_at))

    ttl = get_settings().ephemeral_ttl_seconds
    arm = (
        first_view
        and doodle.mode == DoodleMode.EPHEMERAL
        and doodle.sender_id != user_id
    )
    if arm:
        doodle.expires_at = viewed_at + timedelta(seconds=ttl)

    await session.commit()

    if arm:
        # 타이머는 **저장된 expires_at 까지 남은 실제 시간**으로 건다.
        # ttl 을 그대로 쓰면 소수점을 버린 만큼 실제 삭제가 늦어져,
        # 앱이 카운트다운을 끝냈는데 낙서가 아직 남아 있게 된다.
        delay = max((doodle.expires_at - real).total_seconds(), 0.0)
        state.get_expiry().schedule(doodle_id, delay)
        logger.info("낙서 %s 만료 예약 (%.2fs)", doodle_id, delay)

    return doodle.expires_at


async def expire_doodle(doodle_id: int) -> None:
    """`ExpiryScheduler` 콜백. soft delete + 파일 삭제 + 브로드캐스트."""
    async with session_factory()() as session:
        doodle = await session.get(Doodle, doodle_id)
        if doodle is None or doodle.deleted_at is not None:
            return
        group_id = doodle.group_id
        doodle.deleted_at = _now()
        await session.commit()

    removed = media.delete_doodle_files(group_id, doodle_id)
    await realtime.emit_doodle_expired(group_id, doodle_id)
    logger.info("낙서 %s 만료 완료 (파일 %d개 삭제)", doodle_id, removed)


async def boot_sweep() -> tuple[int, int]:
    """재기동 복구. 타이머는 인메모리라 프로세스가 죽으면 전부 사라진다."""
    async with session_factory()() as session:
        rows = (
            await session.execute(
                select(Doodle.id, Doodle.expires_at).where(
                    Doodle.expires_at.is_not(None), Doodle.deleted_at.is_(None)
                )
            )
        ).all()
    return await state.get_expiry().sweep([(r[0], r[1]) for r in rows])


# ---------------------------------------------------------------------------
# 찌르기 (SD-7)
# ---------------------------------------------------------------------------


async def send_poke(session: AsyncSession, user_id: int, to_user_id: int) -> None:
    group_id = await my_group_id(session, user_id)
    if to_user_id == user_id:
        raise ApiError(400, "invalid_request", "자기 자신은 찌를 수 없습니다")
    await require_member(session, to_user_id, group_id)

    now = _now()
    session.add(
        Poke(group_id=group_id, from_user_id=user_id, to_user_id=to_user_id, created_at=now)
    )
    await session.commit()

    await realtime.emit_poke(group_id, user_id, now.isoformat() + "Z")
    # TODO: FCM `poke` 푸시. Firebase 프로젝트가 생기면.


# ---------------------------------------------------------------------------
# Socket.IO 핸들러. REST 와 같은 함수를 부르고 ack 로 결과를 돌려준다.
# ---------------------------------------------------------------------------


def _ack_error(exc: ApiError) -> dict:
    return {"error": {"code": exc.code, "message": exc.message}}


async def sock_doodle_viewed(user_id: int, payload: dict) -> dict:
    doodle_id = payload.get("doodle_id")
    if doodle_id is None:
        return {"error": {"code": "invalid_request", "message": "doodle_id 가 없습니다"}}
    async with session_factory()() as session:
        try:
            expires_at = await mark_viewed(session, user_id, int(doodle_id))
        except ApiError as e:
            return _ack_error(e)
    return {"expires_at": expires_at.isoformat() + "Z" if expires_at else None}


async def sock_poke_send(user_id: int, payload: dict) -> dict:
    to_user_id = payload.get("to_user_id")
    if to_user_id is None:
        return {"error": {"code": "invalid_request", "message": "to_user_id 가 없습니다"}}
    async with session_factory()() as session:
        try:
            await send_poke(session, user_id, int(to_user_id))
        except ApiError as e:
            return _ack_error(e)
    return {"ok": True}
