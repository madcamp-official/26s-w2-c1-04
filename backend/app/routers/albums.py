"""사진첩 AI 큐레이션 (#6). LLM 이 낙서 캡션을 보고 주제별 앨범으로 묶는다.

앱은 '모두'(전체) 앨범을 로컬로 앞에 두고, 여기서 받은 큐레이션 앨범들을 뒤에 붙인다.
낙서가 3건 미만이거나 아직 캡션이 없으면 빈 목록 → 앱은 '모두'만 보여준다.
"""

from __future__ import annotations

from fastapi import APIRouter

from .. import services
from ..deps import CurrentUser, SessionDep
from ..schemas import AlbumOut, AlbumsResp

router = APIRouter(tags=["albums"])


@router.get("/groups/{group_id}/albums", response_model=AlbumsResp)
async def list_albums(
    group_id: int, user: CurrentUser, session: SessionDep
) -> AlbumsResp:
    await services.require_member(session, user.id, group_id)
    albums = await services.curate_albums(group_id)
    return AlbumsResp(
        albums=[
            AlbumOut(
                title=a["title"],
                cover_url=a.get("cover_url"),
                doodle_ids=a["doodle_ids"],
                count=len(a["doodle_ids"]),
            )
            for a in albums
        ]
    )
