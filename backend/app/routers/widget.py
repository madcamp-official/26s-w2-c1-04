"""홈 화면 위젯. RV-5. docs/API.md 7절.

**가볍게 유지한다.** 위젯은 배터리 제약 아래서 돈다.
"""

from __future__ import annotations

from fastapi import APIRouter
from sqlalchemy import select

from .. import media, services
from ..deps import CurrentUser, SessionDep
from ..models import Doodle, DoodleMode, GroupMember, User
from ..schemas import WidgetOut

router = APIRouter(tags=["widget"])

_ISO = "%Y-%m-%dT%H:%M:%SZ"


@router.get("/widget/{group_id}", response_model=WidgetOut)
async def widget(group_id: int, user: CurrentUser, session: SessionDep) -> WidgetOut:
    await services.require_member(session, user.id, group_id)

    doodle = (
        await session.execute(
            select(Doodle)
            .where(Doodle.group_id == group_id, Doodle.deleted_at.is_(None))
            .order_by(Doodle.id.desc())
            .limit(1)
        )
    ).scalar_one_or_none()

    if doodle is None:
        # 낙서가 하나도 없으면 위젯은 빈 상태를 그린다.
        return WidgetOut(doodle_id=None)

    nickname = (
        await session.execute(
            select(GroupMember.nickname, User.display_name)
            .join(User, User.id == GroupMember.user_id)
            .where(
                GroupMember.group_id == group_id,
                GroupMember.user_id == doodle.sender_id,
            )
        )
    ).first()
    sender_name = (nickname[0] or nickname[1]) if nickname else None

    is_ephemeral = doodle.mode is DoodleMode.EPHEMERAL
    return WidgetOut(
        doodle_id=str(doodle.id),
        content_type=doodle.content_type.value,
        # ★ 사라지기 낙서는 썸네일을 주지 않는다.
        #   위젯에 띄우는 순간을 "확인"으로 칠 수 없기 때문이다. 자물쇠 아이콘만 띄우고,
        #   탭해서 앱 뷰어로 들어가야 POST /doodles/{id}/view 가 나간다.
        thumb_url=None if is_ephemeral else media.thumb_url(group_id, doodle.id),
        sender_nickname=sender_name,
        created_at=doodle.created_at.strftime(_ISO),
        is_ephemeral=is_ephemeral,
    )
