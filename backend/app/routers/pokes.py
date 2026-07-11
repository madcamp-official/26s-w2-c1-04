"""찌르기. SD-7. docs/API.md 4절.

내용 없이 알림만 보내는 가벼운 안부 인터랙션. 과제 주 옵션(실시간)의 일부다.
"""

from __future__ import annotations

from fastapi import APIRouter, Response, status

from .. import services
from ..deps import CurrentUser, SessionDep
from ..errors import ApiError, parse_id
from ..schemas import PokeIn

router = APIRouter(tags=["pokes"])


@router.post("/groups/{group_id}/pokes", status_code=status.HTTP_204_NO_CONTENT)
async def poke(
    group_id: int, body: PokeIn, user: CurrentUser, session: SessionDep
) -> Response:
    await services.require_member(session, user.id, group_id)
    if await services.my_group_id(session, user.id) != group_id:
        raise ApiError(403, "forbidden", "내 그룹이 아닙니다")
    await services.send_poke(
        session, user.id, parse_id(body.to_user_id, "to_user_id")
    )
    return Response(status_code=status.HTTP_204_NO_CONTENT)
