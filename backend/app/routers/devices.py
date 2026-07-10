"""FCM 토큰 등록. docs/API.md 1절."""

from __future__ import annotations

from datetime import datetime, timezone

from fastapi import APIRouter, Response, status
from sqlalchemy import select

from ..deps import CurrentUser, SessionDep
from ..models import Device
from ..schemas import DeviceIn

router = APIRouter(tags=["devices"])


@router.post("/devices", status_code=status.HTTP_204_NO_CONTENT)
async def register_device(
    body: DeviceIn, user: CurrentUser, session: SessionDep
) -> Response:
    """멱등. 같은 토큰이면 `last_active_at` 만 갱신한다.

    `fcm_token` 은 UNIQUE 다. 기기를 다른 유저가 쓰게 되면(재설치 후 다른 이름으로
    가입) 같은 토큰이 다른 user_id 로 온다. 그 경우 소유자를 옮긴다 —
    안 그러면 이전 유저에게 푸시가 계속 간다.
    """
    device = (
        await session.execute(select(Device).where(Device.fcm_token == body.fcm_token))
    ).scalar_one_or_none()

    now = datetime.now(timezone.utc).replace(tzinfo=None)
    if device is None:
        session.add(
            Device(
                user_id=user.id,
                fcm_token=body.fcm_token,
                app_version=body.app_version,
                last_active_at=now,
            )
        )
    else:
        device.user_id = user.id
        device.app_version = body.app_version
        device.last_active_at = now

    await session.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
