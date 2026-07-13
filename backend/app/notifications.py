"""FCM data-only 푸시.

자격 증명이 없으면 조용히 비활성화된다. 푸시는 DB 커밋 뒤의 보조 전달 경로이므로
Firebase 장애가 이미 성공한 낙서·찌르기 요청을 500으로 바꾸지 않는다.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass
from typing import Protocol

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from .config import Settings, get_settings
from .models import Device, GroupMember, Pet, User

logger = logging.getLogger(__name__)
FCM_MULTICAST_LIMIT = 500


@dataclass(frozen=True)
class PushResult:
    sent: int = 0
    failed: int = 0


class PushClient(Protocol):
    async def send(self, tokens: list[str], data: dict[str, str]) -> PushResult: ...


class NullPushClient:
    async def send(self, tokens: list[str], data: dict[str, str]) -> PushResult:
        return PushResult()


class FirebasePushClient:
    def __init__(self, settings: Settings) -> None:
        import firebase_admin
        from firebase_admin import credentials

        path = settings.fcm_credentials_path
        if path is None:
            raise ValueError("FCM_CREDENTIALS_PATH가 없습니다")

        app_name = "memory-pager"
        try:
            self._app = firebase_admin.get_app(app_name)
        except ValueError:
            self._app = firebase_admin.initialize_app(
                credentials.Certificate(str(path)), name=app_name
            )

    async def send(self, tokens: list[str], data: dict[str, str]) -> PushResult:
        if not tokens:
            return PushResult()

        from firebase_admin import messaging

        sent = failed = 0
        for offset in range(0, len(tokens), FCM_MULTICAST_LIMIT):
            batch = tokens[offset : offset + FCM_MULTICAST_LIMIT]
            message = messaging.MulticastMessage(
                tokens=batch,
                data=data,
                # 실시간 상호작용용 data-only 메시지다. Android 백그라운드 전달 지연을 줄인다.
                android=messaging.AndroidConfig(priority="high"),
            )
            response = await messaging.send_each_for_multicast_async(
                message, app=self._app
            )
            sent += response.success_count
            failed += response.failure_count
        if failed:
            # 등록 토큰은 인증 정보이므로 원문을 로그에 남기지 않는다.
            logger.warning("FCM 전송 실패 %d건", failed)
        return PushResult(sent, failed)


_client: PushClient | None = None


def init_push(settings: Settings | None = None) -> PushClient:
    global _client
    if _client is not None:
        return _client

    cfg = settings or get_settings()
    path = cfg.fcm_credentials_path
    if path is None:
        logger.info("FCM 비활성: FCM_CREDENTIALS_PATH 없음")
        _client = NullPushClient()
        return _client
    if not path.is_file():
        logger.error("FCM 비활성: 자격 증명 파일이 없음 (%s)", path)
        _client = NullPushClient()
        return _client

    try:
        _client = FirebasePushClient(cfg)
    except Exception:
        logger.exception("FCM 초기화 실패. 푸시 없이 계속한다")
        _client = NullPushClient()
    return _client


def set_push_client(client: PushClient) -> None:
    """테스트에서 네트워크 없는 기록용 클라이언트를 주입한다."""
    global _client
    _client = client


async def _safe_send(tokens: list[str], data: dict[str, str]) -> PushResult:
    if not tokens:
        return PushResult()
    try:
        return await init_push().send(tokens, data)
    except Exception:
        logger.exception("FCM 전송 실패. 핵심 요청은 이미 커밋되어 계속한다")
        return PushResult(failed=len(tokens))


async def _tokens_for_users(session: AsyncSession, user_ids: list[int]) -> list[str]:
    if not user_ids:
        return []
    return list(
        (
            await session.execute(
                select(Device.fcm_token)
                .where(Device.user_id.in_(user_ids))
                .order_by(Device.id)
            )
        ).scalars()
    )


async def _group_user_ids(
    session: AsyncSession, group_id: int, *, exclude_user_id: int | None = None
) -> list[int]:
    stmt = select(GroupMember.user_id).where(GroupMember.group_id == group_id)
    if exclude_user_id is not None:
        stmt = stmt.where(GroupMember.user_id != exclude_user_id)
    return list((await session.execute(stmt)).scalars())


async def _name_in_group(session: AsyncSession, group_id: int, user_id: int) -> str:
    row = (
        await session.execute(
            select(GroupMember.nickname, User.display_name)
            .join(User, User.id == GroupMember.user_id)
            .where(
                GroupMember.group_id == group_id,
                GroupMember.user_id == user_id,
            )
        )
    ).first()
    return (row[0] or row[1]) if row else "상대"


async def send_doodle_received(
    session: AsyncSession,
    *,
    group_id: int,
    sender_id: int,
    doodle_id: int,
    is_ephemeral: bool,
) -> PushResult:
    try:
        recipients = await _group_user_ids(session, group_id, exclude_user_id=sender_id)
        tokens = await _tokens_for_users(session, recipients)
        if not tokens:
            return PushResult()
        return await _safe_send(
            tokens,
            {
                "type": "doodle_received",
                "doodle_id": str(doodle_id),
                "sender_nickname": await _name_in_group(session, group_id, sender_id),
                "is_ephemeral": str(is_ephemeral).lower(),
            },
        )
    except Exception:
        logger.exception("낙서 수신 푸시 준비 실패")
        return PushResult()


async def send_poke(
    session: AsyncSession, *, group_id: int, from_user_id: int, to_user_id: int
) -> PushResult:
    try:
        tokens = await _tokens_for_users(session, [to_user_id])
        if not tokens:
            return PushResult()
        return await _safe_send(
            tokens,
            {
                "type": "poke",
                "from_nickname": await _name_in_group(session, group_id, from_user_id),
            },
        )
    except Exception:
        logger.exception("찌르기 푸시 준비 실패")
        return PushResult()


async def send_widget_refresh(session: AsyncSession, group_id: int) -> PushResult:
    try:
        user_ids = await _group_user_ids(session, group_id)
        tokens = await _tokens_for_users(session, user_ids)
        if not tokens:
            return PushResult()
        # 조용한 푸시지만 펫 스냅샷을 실어 보내야 앱(백그라운드 포함)이 홈 위젯을
        # 실제로 갱신할 수 있다. 값이 없으면 앱은 위젯을 그대로 둔다.
        data = {"type": "widget_refresh"}
        pet = (
            await session.execute(select(Pet).where(Pet.group_id == group_id))
        ).scalar_one_or_none()
        if pet is not None:
            data["pet_name"] = pet.name
            data["pet_level"] = f"Lv.{pet.level}"
        return await _safe_send(tokens, data)
    except Exception:
        logger.exception("위젯 갱신 푸시 준비 실패")
        return PushResult()


async def send_monthly_report(
    session: AsyncSession, group_id: int, report_month: str
) -> PushResult:
    try:
        user_ids = await _group_user_ids(session, group_id)
        return await _safe_send(
            await _tokens_for_users(session, user_ids),
            {"type": "monthly_report", "report_month": report_month},
        )
    except Exception:
        logger.exception("월간 레포트 푸시 준비 실패")
        return PushResult()
