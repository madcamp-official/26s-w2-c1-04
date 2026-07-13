"""낙서. SD-5, SD-6, RV-1~4. docs/API.md 4절."""

from __future__ import annotations

import json
from datetime import date as date_type
from typing import Annotated, Any

from fastapi import APIRouter, BackgroundTasks, File, Form, Query, UploadFile
from pydantic import ValidationError
from sqlalchemy import func, select

from .. import media, notifications, realtime, services
from ..config import get_settings
from ..deps import CurrentUser, SessionDep
from ..errors import ApiError, parse_id
from ..models import ContentType, Doodle, DoodleMode, DoodleReceipt
from ..schemas import DoodleListOut, DoodleOut, StrokeData, ViewOut

router = APIRouter(tags=["doodles"])

_ISO = "%Y-%m-%dT%H:%M:%SZ"


def _iso(dt: Any) -> str | None:
    if not dt:
        return None
    if dt.microsecond:
        return dt.isoformat(timespec="microseconds") + "Z"
    return dt.strftime(_ISO)


def _to_out(d: Doodle, *, reply_count: int, viewed_by_me: bool) -> DoodleOut:
    locked = d.mode is DoodleMode.EPHEMERAL and not viewed_by_me
    return DoodleOut(
        id=str(d.id),
        group_id=str(d.group_id),
        sender_id=str(d.sender_id),
        parent_id=str(d.parent_id) if d.parent_id else None,
        mode=d.mode.value,
        content_type=d.content_type.value,
        photo_url=None if locked else d.photo_url,
        drawing_url=None if locked else d.drawing_url,
        thumb_url=None if locked else media.thumb_url(d.group_id, d.id),
        text_body=None if locked else d.text_body,
        caption=None if locked else d.caption,
        reply_count=reply_count,
        viewed_by_me=viewed_by_me,
        expires_at=_iso(d.expires_at),
        created_at=_iso(d.created_at) or "",
    )


async def _read_image(
    upload: UploadFile, *, field: str, allowed_formats: set[str]
) -> bytes:
    settings = get_settings()
    data = await upload.read(settings.max_upload_bytes + 1)
    if len(data) > settings.max_upload_bytes:
        raise ApiError(
            413,
            "payload_too_large",
            f"{field} 파일은 {settings.max_upload_bytes // (1024 * 1024)}MB 이하여야 합니다",
        )
    try:
        media.validate_image_bytes(
            data,
            allowed_formats=allowed_formats,
            max_dimension=settings.max_image_dimension,
        )
    except ValueError as exc:
        raise ApiError(422, "unprocessable", f"{field}: {exc}") from None
    return data


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
        _to_out(
            d,
            reply_count=counts.get(d.id, 0),
            viewed_by_me=d.sender_id == user_id or d.id in seen,
        )
        for d in doodles
    ]


# ---------------------------------------------------------------------------


@router.post("/doodles", response_model=DoodleOut, status_code=201)
async def create_doodle(
    user: CurrentUser,
    session: SessionDep,
    background_tasks: BackgroundTasks,
    mode: Annotated[str, Form()],
    content_type: Annotated[str, Form()],
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
    if text_body is not None and len(text_body) > get_settings().max_text_length:
        raise ApiError(
            422,
            "unprocessable",
            f"text_body 는 {get_settings().max_text_length}자 이하여야 합니다",
        )

    photo_bytes = (
        await _read_image(photo, field="photo", allowed_formats={"JPEG", "PNG"})
        if ctype_e is ContentType.PHOTO and photo is not None
        else None
    )
    drawing_bytes = (
        await _read_image(drawing, field="drawing", allowed_formats={"PNG"})
        if ctype_e is ContentType.DRAWING and drawing is not None
        else None
    )

    strokes = None
    if stroke_data:
        if len(stroke_data.encode("utf-8")) > get_settings().max_stroke_bytes:
            raise ApiError(413, "payload_too_large", "stroke_data 가 너무 큽니다")
        try:
            raw_strokes = json.loads(stroke_data)
            strokes = StrokeData.model_validate(raw_strokes).model_dump(mode="json")
        except json.JSONDecodeError:
            raise ApiError(400, "invalid_request", "stroke_data 가 JSON 이 아닙니다") from None
        except ValidationError as exc:
            raise ApiError(
                422,
                "unprocessable",
                f"stroke_data 형식이 잘못됐습니다: {exc.errors()[:2]}",
            ) from None

    parent = None
    if parent_id:
        parent = await services.load_visible_doodle(
            session, user.id, parse_id(parent_id, "parent_id")
        )
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
    levelup = None
    photo_name = drawing_name = ""
    try:
        await session.flush()  # 파일명에 doodle.id 가 필요하다

        if photo_bytes is not None:
            # PNG 업로드도 URL 계약은 photo.jpg지만 실제 바이트 확장자 불일치를 피한다.
            extension = "png" if photo_bytes.startswith(b"\x89PNG") else "jpg"
            photo_name = f"{doodle.id}_photo.{extension}"
            doodle.photo_url = media.save_bytes(group_id, photo_name, photo_bytes)
        if drawing_bytes is not None:
            drawing_name = f"{doodle.id}_draw.png"
            doodle.drawing_url = media.save_bytes(group_id, drawing_name, drawing_bytes)

        # 썸네일 파일은 모든 유형에 만든다. 미열람 사라지기 응답에서만 URL을 숨긴다.
        if ctype_e is ContentType.PHOTO:
            media.make_thumbnail(group_id, doodle.id, photo_name)
        elif ctype_e is ContentType.DRAWING:
            media.make_thumbnail(group_id, doodle.id, drawing_name)
        else:
            media.render_text_thumbnail(group_id, doodle.id, text_body or "")

        reward = (
            get_settings().pet_reply_exp
            if parent is not None
            else get_settings().pet_doodle_exp
        )
        levelup = await services.award_pet_exp(session, group_id, reward)
        await session.commit()
    except Exception:
        await session.rollback()
        if doodle.id is not None:
            media.delete_doodle_files(group_id, doodle.id)
        raise
    await session.refresh(doodle)

    # 펫이 낙서를 보고 한마디 — 사진/그림이면 GPU(BLIP→EXAONE)로 캡션을 비동기 생성.
    # 응답을 막지 않는다. 수신자가 뷰어를 열 때쯤 caption 이 채워진다.
    caption_bytes = photo_bytes if photo_bytes is not None else drawing_bytes
    if caption_bytes is not None:
        background_tasks.add_task(
            services.generate_doodle_caption, doodle.id, caption_bytes
        )

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
    if levelup is not None:
        await realtime.emit_pet_levelup(group_id, levelup.pet_id, levelup.level)
    await notifications.send_doodle_received(
        session,
        group_id=group_id,
        sender_id=user.id,
        doodle_id=doodle.id,
        is_ephemeral=doodle.mode is DoodleMode.EPHEMERAL,
    )

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
        stmt = stmt.where(Doodle.id < parse_id(before, "before"))
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
