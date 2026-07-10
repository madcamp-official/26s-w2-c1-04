"""REST 와 Socket.IO 가 공유하는 로직.

`POST /doodles/{id}/view` 와 소켓 `doodle:viewed` 는 **같은 함수를 부른다.**
REST 는 항상 되는 길이고 소켓은 빠른 길이다 (docs/API.md 9절).
"""

from __future__ import annotations

import logging
from datetime import date, datetime, timedelta, timezone

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from . import gpu, media, realtime, state
from .config import get_settings
from .db import session_factory
from .errors import ApiError
from .models import (
    ContentType,
    Doodle,
    DoodleMode,
    DoodleReceipt,
    GroupMember,
    Pet,
    PetActivity,
    PetDiary,
    Poke,
    StyleKind,
    StyleModel,
    StyleStatus,
)

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
# 펫 (PT-1, PT-6a) — 과제 부 옵션(LLM)
# ---------------------------------------------------------------------------

# GPU 가 죽어도 펫은 말을 해야 한다.
DEFAULT_UTTERANCE = "…아직 잠에서 덜 깼어."
DEFAULT_ACTIVITY = "waiting"


async def load_pet(session: AsyncSession, user_id: int, pet_id: int) -> Pet:
    pet = await session.get(Pet, pet_id)
    if pet is None:
        raise ApiError(404, "not_found", "펫이 없습니다")
    await require_member(session, user_id, pet.group_id)
    return pet


async def current_activity(session: AsyncSession, pet_id: int) -> PetActivity | None:
    """`ended_at IS NULL` 인 행. 인덱스 `ix_activities_pet_ended` 가 이걸 태운다."""
    return (
        await session.execute(
            select(PetActivity)
            .where(PetActivity.pet_id == pet_id, PetActivity.ended_at.is_(None))
            .order_by(PetActivity.id.desc())
            .limit(1)
        )
    ).scalar_one_or_none()


async def pat_pet(session: AsyncSession, user_id: int, pet_id: int) -> dict:
    """쓰다듬기 (PT-1). **LLM 을 부르지 않는다.**

    사용자가 연타할 수 있는 인터랙션이라 매 탭마다 추론을 돌리면 GPU 가 버티지 못한다.
    `pet_activities` 테이블 자체가 캐시다. 활동이 바뀔 때만 새 대사가 생긴다.

    활동이 아직 없으면 기본 대사를 돌려준다. GPU 가 죽어도 펫은 말을 해야 한다.
    """
    pet = await load_pet(session, user_id, pet_id)
    act = await current_activity(session, pet_id)

    # exp 증가 규칙은 아직 미확정이다 (docs/API.md 13절). 일단 1.
    pet.exp += 1
    await session.commit()

    return {
        "activity": act.activity.value if act else DEFAULT_ACTIVITY,
        "utterance": act.utterance if act else DEFAULT_UTTERANCE,
        "exp_gained": 1,
    }


async def rotate_pet_activity(pet_id: int) -> None:
    """스케줄러가 부른다. 이전 활동을 닫고 새 활동을 LLM 으로 만든다."""
    async with session_factory()() as session:
        pet = await session.get(Pet, pet_id)
        if pet is None:
            return
        group_id = pet.group_id

        since = _real_now() - timedelta(hours=24)
        doodles_24h = (
            await session.execute(
                select(func.count(Doodle.id)).where(
                    Doodle.group_id == group_id, Doodle.created_at >= since
                )
            )
        ).scalar_one()
        pokes_24h = (
            await session.execute(
                select(func.count(Poke.id)).where(
                    Poke.group_id == group_id, Poke.created_at >= since
                )
            )
        ).scalar_one()
        last_type = (
            await session.execute(
                select(Doodle.content_type)
                .where(Doodle.group_id == group_id)
                .order_by(Doodle.id.desc())
                .limit(1)
            )
        ).scalar_one_or_none()

        ctx = gpu.GroupContext(
            pet_level=pet.level,
            doodles_24h=int(doodles_24h),
            pokes_24h=int(pokes_24h),
            last_content_type=last_type.value if last_type else None,
        )
        result = await gpu.get_llm_client().pet_activity(ctx)

        prev = await current_activity(session, pet_id)
        now = _now()
        if prev is not None:
            prev.ended_at = now
        session.add(
            PetActivity(
                pet_id=pet_id,
                activity=result.activity,
                utterance=result.utterance,
                model=result.model,
                started_at=now,
            )
        )
        await session.commit()

    await realtime.emit_pet_activity(group_id, pet_id, result.activity, result.utterance)
    logger.info("펫 %s 활동 갱신: %s", pet_id, result.activity)


async def _active_style(session: AsyncSession, group_id: int) -> StyleModel:
    """학습된 그림체가 준비돼 있으면 그것, 아니면 기본 프리셋.

    기본 그림체가 없으면 가입 첫날 일기장이 빈 화면이 된다 (SPEC 6.3절).
    """
    learned = (
        await session.execute(
            select(StyleModel)
            .where(
                StyleModel.group_id == group_id,
                StyleModel.kind == StyleKind.LEARNED,
                StyleModel.status == StyleStatus.READY,
            )
            .order_by(StyleModel.version.desc())
            .limit(1)
        )
    ).scalar_one_or_none()
    if learned is not None:
        return learned

    default = (
        await session.execute(
            select(StyleModel).where(
                StyleModel.group_id == group_id, StyleModel.kind == StyleKind.DEFAULT
            )
        )
    ).scalar_one_or_none()
    if default is None:
        raise ApiError(500, "error", "기본 그림체가 없습니다")
    return default


async def generate_diary(pet_id: int, entry_date: date) -> int | None:
    """하루치 활동을 그림 한 장 + 캡션으로 묶는다 (PT-6a).

    `pet_diaries` 는 `image_url`·`caption` 이 NOT NULL 이라 **부분 저장이 불가능하다.**
    GPU 가 죽어 그림을 못 만들면 그날 일기는 없다. 그게 정상 동작이다.
    """
    async with session_factory()() as session:
        pet = await session.get(Pet, pet_id)
        if pet is None:
            return None
        group_id = pet.group_id

        exists = (
            await session.execute(
                select(PetDiary.id).where(
                    PetDiary.pet_id == pet_id, PetDiary.entry_date == entry_date
                )
            )
        ).scalar_one_or_none()
        if exists:
            return exists  # UNIQUE(pet_id, entry_date). 하루 한 장.

        rows = (
            await session.execute(
                select(PetActivity)
                .where(
                    PetActivity.pet_id == pet_id,
                    func.date(PetActivity.started_at) == entry_date,
                )
                .order_by(PetActivity.id)
            )
        ).scalars().all()
        if not rows:
            logger.info("펫 %s 의 %s 활동이 없어 일기를 만들지 않는다", pet_id, entry_date)
            return None

        activities = [a.activity.value for a in rows]
        style = await _active_style(session, group_id)

        caption = await gpu.get_llm_client().diary_caption(activities)
        image = await gpu.get_image_client().diary_image(
            activities=activities, caption=caption, weights_path=style.weights_path
        )

        diary = PetDiary(
            pet_id=pet_id,
            style_model_id=style.id,
            entry_date=entry_date,
            image_url="",  # 파일명에 id 가 필요해 flush 후 채운다
            caption=caption,
        )
        session.add(diary)
        await session.flush()
        diary.image_url = media.save_bytes(group_id, f"diary_{diary.id}.png", image)

        for a in rows:
            a.diary_id = diary.id
        await session.commit()
        diary_id, style_kind = diary.id, style.kind.value

    await realtime.emit_diary_new(group_id, diary_id, entry_date.isoformat(), style_kind)
    logger.info("펫 %s 의 %s 일기 생성 (style=%s)", pet_id, entry_date, style_kind)
    return diary_id


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
