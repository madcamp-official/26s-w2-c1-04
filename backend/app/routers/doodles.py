"""낙서. SD-5, SD-6, RV-1~4. docs/API.md 4절."""

from __future__ import annotations

import json
from datetime import date as date_type
from typing import Annotated, Any

from fastapi import APIRouter, File, Form, Query, UploadFile
from sqlalchemy import func, select

from .. import media, realtime, services
from ..deps import CurrentUser, SessionDep
from ..errors import ApiError
from ..models import ContentType, Doodle, DoodleMode, DoodleReceipt
from ..schemas import DoodleListOut, DoodleOut, ViewOut

router = APIRouter(tags=["doodles"])

_ISO = "%Y-%m-%dT%H:%M:%SZ"


def _iso(dt: Any) -> str | None:
    return dt.strftime(_ISO) if dt else None


def _to_out(d: Doodle, *, reply_count: int, viewed_by_me: bool) -> DoodleOut:
    return DoodleOut(
        id=str(d.id),
        group_id=str(d.group_id),
        sender_id=str(d.sender_id),
        parent_id=str(d.parent_id) if d.parent_id else None,
        mode=d.mode.value,
        content_type=d.content_type.value,
        photo_url=d.photo_url,
        drawing_url=d.drawing_url,
        thumb_url=media.thumb_url(d.group_id, d.id),
        text_body=d.text_body,
        reply_count=reply_count,
        viewed_by_me=viewed_by_me,
        expires_at=_iso(d.expires_at),
        created_at=_iso(d.created_at) or "",
    )


async def _decorate(session, user_id: int, doodles: list[Doodle]) -> list[DoodleOut]:
    """`reply_count` 와 `viewed_by_me` 는 DB 컬럼이 아니다. 조립해서 내려준다."""
    if not doodles:
        return []
    ids = [d.id for d in doodles]

    counts = dict(
        (
            await session.execute(
                select(Doodle.parent_id, func.count(Doodle.id))
                .where(Doodle.parent_id.in_(ids), Doodle.deleted_at.is_(None))
                .group_by(Doodle.parent_id)
            )
        ).all()
    )
    seen = set(
        (
            await session.execute(
                select(DoodleReceipt.doodle_id).where(
                    DoodleReceipt.doodle_id.in_(ids), DoodleReceipt.user_id == user_id
                )
            )
        ).scalars()
    )
    return [
        _to_out(d, reply_count=counts.get(d.id, 0), viewed_by_me=d.id in seen)
        for d in doodles
    ]


# ---------------------------------------------------------------------------


@router.post("/doodles", response_model=DoodleOut, status_code=201)
async def create_doodle(
    user: CurrentUser,
    session: SessionDep,
    mode: Annotated[str, Form()] = "normal",
    content_type: Annotated[str, Form()] = "drawing",
    parent_id: Annotated[str | None, Form()] = None,
    text_body: Annotated[str | None, Form()] = None,
    stroke_data: Annotated[str | None, Form()] = None,
    photo: Annotated[UploadFile | None, File()] = None,
    drawing: Annotated[UploadFile | None, File()] = None,
) -> DoodleOut:
    """`multipart/form-data`. 답장(RV-1)도 여기에 `parent_id` 를 실어 보낸다.

    그룹은 보낸 사람의 소속에서 유도한다. 유저는 그룹 하나에만 속한다.
    """
    try:
        mode_e, ctype_e = DoodleMode(mode), ContentType(content_type)
    except ValueError:
        raise ApiError(400, "invalid_request", "mode 또는 content_type 이 잘못됐습니다") from None

    group_id = await services.my_group_id(session, user.id)

    # content_type 별 필수 입력 (docs/API.md 4절)
    if ctype_e is ContentType.PHOTO and photo is None:
        raise ApiError(422, "unprocessable", "photo 파일이 필요합니다")
    if ctype_e is ContentType.DRAWING and (drawing is None or not stroke_data):
        raise ApiError(422, "unprocessable", "drawing 파일과 stroke_data 가 필요합니다")
    if ctype_e is ContentType.TEXT and not text_body:
        raise ApiError(422, "unprocessable", "text_body 가 필요합니다")

    strokes = None
    if stroke_data:
        try:
            strokes = json.loads(stroke_data)
        except json.JSONDecodeError:
            raise ApiError(400, "invalid_request", "stroke_data 가 JSON 이 아닙니다") from None

    parent = None
    if parent_id:
        parent = await services.load_visible_doodle(session, user.id, int(parent_id))
        if parent.group_id != group_id:
            raise ApiError(403, "forbidden", "다른 그룹의 낙서에는 답장할 수 없습니다")

    doodle = Doodle(
        group_id=group_id,
        sender_id=user.id,
        parent_id=parent.id if parent else None,
        mode=mode_e,
        content_type=ctype_e,
        text_body=text_body,
        stroke_data=strokes,
    )
    session.add(doodle)
    await session.flush()  # 파일명에 doodle.id 가 필요하다

    if photo is not None:
        doodle.photo_url = media.save_bytes(group_id, f"{doodle.id}_photo.jpg", await photo.read())
    if drawing is not None:
        doodle.drawing_url = media.save_bytes(group_id, f"{doodle.id}_draw.png", await drawing.read())

    # 썸네일은 어떤 유형이든 null 이 되지 않는다 (docs/API.md 4절)
    if ctype_e is ContentType.PHOTO:
        media.make_thumbnail(group_id, doodle.id, f"{doodle.id}_photo.jpg")
    elif ctype_e is ContentType.DRAWING:
        media.make_thumbnail(group_id, doodle.id, f"{doodle.id}_draw.png")
    else:
        media.render_text_thumbnail(group_id, doodle.id, text_body or "")

    await session.commit()
    await session.refresh(doodle)

    payload: dict[str, Any] = {
        "doodle_id": str(doodle.id),
        "sender_id": str(user.id),
        "mode": doodle.mode.value,
        "content_type": doodle.content_type.value,
        "created_at": _iso(doodle.created_at),
    }
    # ★ 사라지기 모드는 썸네일을 싣지 않는다.
    #   소켓이 붙은 수신자가 뷰어를 열기 전에 내용을 받아버리면 doodle_receipts 가
    #   찍히지 않아 타이머가 걸리지 않고, 미디어 파일이 영영 지워지지 않는다.
    #   위젯과 FCM 은 이 불변식을 지킨다. 소켓만 예외일 이유가 없다.
    if doodle.mode is DoodleMode.NORMAL:
        payload["thumb_url"] = media.thumb_url(group_id, doodle.id)
    await realtime.emit_doodle_new(group_id, payload)
    # TODO: FCM `doodle_received` 푸시 (SD-8). Firebase 프로젝트가 생기면.

    return _to_out(doodle, reply_count=0, viewed_by_me=True)


@router.get("/groups/{group_id}/doodles", response_model=DoodleListOut)
async def list_doodles(
    group_id: int,
    user: CurrentUser,
    session: SessionDep,
    before: Annotated[str | None, Query()] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 30,
    content_type: Annotated[str | None, Query()] = None,
    date: Annotated[date_type | None, Query()] = None,
) -> DoodleListOut:
    """사진첩 (RV-2, RV-3, RV-4). 최신순. 만료된 낙서는 나오지 않는다."""
    await services.require_member(session, user.id, group_id)

    stmt = select(Doodle).where(
        Doodle.group_id == group_id, Doodle.deleted_at.is_(None)
    )
    if before:
        stmt = stmt.where(Doodle.id < int(before))
    if content_type:
        try:
            stmt = stmt.where(Doodle.content_type == ContentType(content_type))
        except ValueError:
            raise ApiError(400, "invalid_request", "content_type 이 잘못됐습니다") from None
    if date:
        stmt = stmt.where(func.date(Doodle.created_at) == date)

    rows = list(
        (await session.execute(stmt.order_by(Doodle.id.desc()).limit(limit))).scalars()
    )
    items = await _decorate(session, user.id, rows)
    # 더 없으면(빈 목록 포함) next_before 는 null (docs/API.md 0절)
    next_before = str(rows[-1].id) if len(rows) == limit else None
    return DoodleListOut(items=items, next_before=next_before)


@router.get("/doodles/{doodle_id}", response_model=DoodleOut)
async def get_doodle(doodle_id: int, user: CurrentUser, session: SessionDep) -> DoodleOut:
    doodle = await services.load_visible_doodle(session, user.id, doodle_id)
    return (await _decorate(session, user.id, [doodle]))[0]


@router.post("/doodles/{doodle_id}/view", response_model=ViewOut)
async def view_doodle(doodle_id: int, user: CurrentUser, session: SessionDep) -> ViewOut:
    """사라지기 모드의 방아쇠 (SD-6). 멱등하다."""
    expires_at = await services.mark_viewed(session, user.id, doodle_id)
    return ViewOut(expires_at=_iso(expires_at))
