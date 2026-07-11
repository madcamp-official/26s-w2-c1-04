"""REST 와 Socket.IO 가 공유하는 로직.

`POST /doodles/{id}/view` 와 소켓 `doodle:viewed` 는 **같은 함수를 부른다.**
REST 는 항상 되는 길이고 소켓은 빠른 길이다 (docs/API.md 9절).
"""

from __future__ import annotations

import logging
import re
from dataclasses import dataclass
from datetime import date, datetime, time, timedelta, timezone
from zoneinfo import ZoneInfo

from sqlalchemy import func, select
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from . import gpu, media, notifications, realtime, state
from .config import get_settings
from .db import session_factory
from .errors import ApiError, parse_id
from .models import (
    BestDoodleRule,
    ContentType,
    Doodle,
    DoodleMode,
    DoodleReceipt,
    GroupMember,
    MonthlyReport,
    Pet,
    PetActivity,
    PetDiary,
    Poke,
    StyleKind,
    StyleModel,
    StyleStatus,
)

logger = logging.getLogger(__name__)
_KST = ZoneInfo("Asia/Seoul")


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


def _kst_day_range(entry_date: date) -> tuple[datetime, datetime]:
    """KST 달력 날짜를 MySQL에 저장된 naive UTC 반개구간으로 바꾼다."""
    local_start = datetime.combine(entry_date, time.min, tzinfo=_KST)
    local_end = local_start + timedelta(days=1)
    return (
        local_start.astimezone(timezone.utc).replace(tzinfo=None),
        local_end.astimezone(timezone.utc).replace(tzinfo=None),
    )


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
    session: AsyncSession, user_id: int, doodle_id: int, *, for_update: bool = False
) -> Doodle:
    """404(없는 id)와 410(만료됨)을 갈라 쓴다. soft delete 라 행은 남는다."""
    if for_update:
        doodle = (
            await session.execute(
                select(Doodle).where(Doodle.id == doodle_id).with_for_update()
            )
        ).scalar_one_or_none()
    else:
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
    # 같은 사용자의 REST와 Socket.IO 확인이 동시에 들어와도 receipt INSERT가
    # 경합하지 않게 낙서 행 하나로 직렬화한다.
    doodle = await load_visible_doodle(
        session, user_id, doodle_id, for_update=True
    )

    # receipt 행에는 FOR UPDATE 를 걸지 않는다. 위의 낙서 행 잠금이 같은 낙서의
    # 확인을 이미 직렬화하므로 여기서 필요 없고, 존재하지 않는 (doodle_id,user_id)
    # 키에 FOR UPDATE 를 걸면 REPEATABLE READ 에서 유니크 인덱스에 갭 잠금이 생겨,
    # 서로 다른 낙서를 동시에 처음 확인하는 두 트랜잭션이 데드락(1213)에 빠진다.
    receipt = (
        await session.execute(
            select(DoodleReceipt).where(
                DoodleReceipt.doodle_id == doodle_id,
                DoodleReceipt.user_id == user_id,
            )
        )
    ).scalar_one_or_none()

    viewed_at = _real_now()

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

    try:
        await session.commit()
    except IntegrityError:
        # UNIQUE(doodle_id,user_id) 경합: 같은 사용자의 REST·소켓 확인이 거의 동시에
        # 들어와 둘 다 first_view 로 INSERT 했다. REPEATABLE READ 스냅샷 탓에 낙서
        # 행을 잠가도 진 쪽의 평문 읽기는 승자의 receipt 를 못 본다. 승자가 이미
        # receipt·expires_at 을 커밋하고 타이머도 걸었으니, 멱등하게 승자의 값만
        # 되돌려준다 (타이머 재예약 없음).
        await session.rollback()
        winner = await session.get(Doodle, doodle_id)
        return winner.expires_at if winner is not None else None

    if arm:
        # DATETIME(6)에 저장한 expires_at까지 남은 실제 시간으로 건다. API의
        # 카운트다운과 삭제 시점이 같은 값을 기준으로 움직인다.
        delay = max((doodle.expires_at - _real_now()).total_seconds(), 0.0)
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
    try:
        async with session_factory()() as session:
            await notifications.send_widget_refresh(session, group_id)
    except Exception:
        logger.exception("낙서 %s 만료 후 위젯 푸시 실패", doodle_id)
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
    levelup = await award_pet_exp(
        session, group_id, get_settings().pet_poke_exp
    )
    await session.commit()

    await realtime.emit_poke(group_id, user_id, now.isoformat() + "Z")
    if levelup is not None:
        await realtime.emit_pet_levelup(group_id, levelup.pet_id, levelup.level)
    await notifications.send_poke(
        session,
        group_id=group_id,
        from_user_id=user_id,
        to_user_id=to_user_id,
    )


# ---------------------------------------------------------------------------
# 펫 (PT-1, PT-6a) — 과제 부 옵션(LLM)
# ---------------------------------------------------------------------------

# GPU 가 죽어도 펫은 말을 해야 한다.
DEFAULT_UTTERANCE = "…아직 잠에서 덜 깼어."
DEFAULT_ACTIVITY = "waiting"


@dataclass(frozen=True)
class LevelUp:
    pet_id: int
    level: int


async def award_pet_exp(
    session: AsyncSession, group_id: int, amount: int
) -> LevelUp | None:
    """그룹 펫의 누적 exp를 올리고 레벨 경계를 원자적으로 넘긴다.

    같은 순간 낙서·찌르기·쓰다듬기가 들어와도 `FOR UPDATE`로 손실 갱신을 막는다.
    exp는 누적값이고 `level = exp // PET_EXP_PER_LEVEL + 1`이다.
    """
    if amount <= 0:
        return None
    pet = (
        await session.execute(
            select(Pet)
            .where(Pet.group_id == group_id)
            .with_for_update()
            # load_pet()이 같은 트랜잭션 초기에 읽은 객체가 identity map에 있어도
            # 잠금을 얻은 시점의 최신 exp/level로 덮어쓴다.
            .execution_options(populate_existing=True)
        )
    ).scalar_one_or_none()
    if pet is None:
        return None

    settings = get_settings()
    old_level = pet.level
    pet.exp += amount
    calculated = pet.exp // max(settings.pet_exp_per_level, 1) + 1
    if calculated <= old_level:
        return None

    pet.level = calculated
    pet.coins += (calculated - old_level) * max(settings.pet_levelup_coins, 0)
    return LevelUp(pet_id=pet.id, level=pet.level)


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

    exp_gained = get_settings().pet_pat_exp
    levelup = await award_pet_exp(session, pet.group_id, exp_gained)
    await session.commit()

    if levelup is not None:
        await realtime.emit_pet_levelup(pet.group_id, levelup.pet_id, levelup.level)

    return {
        "activity": act.activity.value if act else DEFAULT_ACTIVITY,
        "utterance": act.utterance if act else DEFAULT_UTTERANCE,
        "exp_gained": exp_gained,
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

        day_start, day_end = _kst_day_range(entry_date)
        rows = (
            await session.execute(
                select(PetActivity)
                .where(
                    PetActivity.pet_id == pet_id,
                    PetActivity.started_at >= day_start,
                    PetActivity.started_at < day_end,
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
            group_id=group_id,
            entry_date=entry_date.isoformat(),
            activities=activities,
            caption=caption,
            style_kind=style.kind.value,
            weights_path=style.weights_path,
        )

        diary = PetDiary(
            pet_id=pet_id,
            style_model_id=style.id,
            entry_date=entry_date,
            image_url="",  # 파일명에 id 가 필요해 flush 후 채운다
            caption=caption,
        )
        session.add(diary)
        filename: str | None = None
        try:
            await session.flush()
            filename = f"diary_{diary.id}.png"
            diary.image_url = media.save_bytes(group_id, filename, image)

            for a in rows:
                a.diary_id = diary.id
            await session.commit()
        except IntegrityError:
            # 자정 잡이 중복 실행돼도 하루 한 장 불변식과 파일 정합성을 지킨다.
            await session.rollback()
            if filename is not None:
                media.delete_file(group_id, filename)
            existing = (
                await session.execute(
                    select(PetDiary.id).where(
                        PetDiary.pet_id == pet_id,
                        PetDiary.entry_date == entry_date,
                    )
                )
            ).scalar_one_or_none()
            if existing is not None:
                return existing
            raise
        except Exception:
            await session.rollback()
            if filename is not None:
                media.delete_file(group_id, filename)
            raise
        diary_id, style_kind = diary.id, style.kind.value

    await realtime.emit_diary_new(group_id, diary_id, entry_date.isoformat(), style_kind)
    logger.info("펫 %s 의 %s 일기 생성 (style=%s)", pet_id, entry_date, style_kind)
    return diary_id


# ---------------------------------------------------------------------------
# 월간 레포트 (MR-1 ~ MR-4) — docs/API.md 6절, SPEC 6.5
# ---------------------------------------------------------------------------

_MONTH_RE = re.compile(r"^\d{4}-(0[1-9]|1[0-2])$")


def validate_month(report_month: str) -> None:
    if not _MONTH_RE.match(report_month):
        raise ApiError(400, "invalid_request", "report_month 는 YYYY-MM 이어야 합니다")
    # 0000과 9999-12는 datetime 범위 밖의 인접 월을 만들 수 있다.
    year = int(report_month[:4])
    if year < 1 or year > 9998:
        raise ApiError(400, "invalid_request", "report_month 는 YYYY-MM 이어야 합니다")


def _month_range(report_month: str) -> tuple[datetime, datetime]:
    """'YYYY-MM' -> [해당 달 1일 00:00, 다음 달 1일 00:00). naive UTC."""
    year, month = int(report_month[:4]), int(report_month[5:7])
    start = datetime(year, month, 1)
    end = datetime(year + 1, 1, 1) if month == 12 else datetime(year, month + 1, 1)
    return start, end


def _prev_month(report_month: str) -> str:
    year, month = int(report_month[:4]), int(report_month[5:7])
    return f"{year - 1}-12" if month == 1 else f"{year}-{month - 1:02d}"


def _stroke_count(stroke_data: object) -> int:
    """손그림만 stroke_data 를 갖는다. 다른 유형은 0."""
    if isinstance(stroke_data, dict):
        strokes = stroke_data.get("strokes")
        if isinstance(strokes, list):
            return len(strokes)
    return 0


async def generate_report(
    group_id: int, report_month: str, *, notify: bool = False
) -> int:
    """그 달의 활동을 집계해 monthly_reports 한 행으로 굳힌다 (MR-3).

    데모용 수동 트리거와 월 1회 배치가 같은 이 함수를 부른다. 이미 있으면 덮어쓴다.

    **집계(count)는 그 달에 만들어진 모든 낙서를 센다** — 사라지기 모드로 보냈다가
    만료된 것(soft delete)도 그 달의 '활동'이므로 포함한다. 반면 **최고의 낙서는 살아있는
    후보(deleted_at IS NULL)만** 대상으로 한다. 만료돼 파일이 지워진 낙서는 화면에 띄울 수
    없기 때문이다. 이 비대칭은 의도된 것이다.
    """
    validate_month(report_month)
    start, end = _month_range(report_month)

    async with session_factory()() as session:
        # --- 유형별 낙서 수 (만료분 포함) ---
        type_rows = (
            await session.execute(
                select(Doodle.content_type, func.count(Doodle.id))
                .where(
                    Doodle.group_id == group_id,
                    Doodle.created_at >= start,
                    Doodle.created_at < end,
                )
                .group_by(Doodle.content_type)
            )
        ).all()
        counts = {ct: n for ct, n in type_rows}
        photo_count = counts.get(ContentType.PHOTO, 0)
        drawing_count = counts.get(ContentType.DRAWING, 0)
        text_count = counts.get(ContentType.TEXT, 0)

        # 최다 유형. 동률이면 photo > drawing > text 순으로 고정(결정적). 없으면 null.
        by_type = [
            (ContentType.PHOTO, photo_count),
            (ContentType.DRAWING, drawing_count),
            (ContentType.TEXT, text_count),
        ]
        dominant = max(by_type, key=lambda kv: kv[1])
        dominant_type = dominant[0] if dominant[1] > 0 else None

        # --- 찌르기 수 ---
        poke_count = (
            await session.execute(
                select(func.count(Poke.id)).where(
                    Poke.group_id == group_id,
                    Poke.created_at >= start,
                    Poke.created_at < end,
                )
            )
        ).scalar_one()

        # --- 펫 레벨 변화. 이력 테이블이 없어 end 는 현재 레벨, start 는 지난 달 레포트의 end ---
        pet = (
            await session.execute(select(Pet).where(Pet.group_id == group_id))
        ).scalar_one_or_none()
        pet_level_end = pet.level if pet else 1
        prev_end = (
            await session.execute(
                select(MonthlyReport.pet_level_end).where(
                    MonthlyReport.group_id == group_id,
                    MonthlyReport.report_month == _prev_month(report_month),
                )
            )
        ).scalar_one_or_none()
        pet_level_start = prev_end if prev_end is not None else pet_level_end

        # --- 이번 달 최고의 낙서 (SPEC 6.5). 사라지기 모드는 후보에서 제외 ---
        best_id, best_rule = await _pick_best_doodle(session, group_id, start, end)

        values = dict(
            photo_count=photo_count,
            drawing_count=drawing_count,
            text_count=text_count,
            poke_count=poke_count,
            dominant_type=dominant_type,
            best_doodle_id=best_id,
            best_doodle_rule=best_rule,
            pet_level_start=pet_level_start,
            pet_level_end=pet_level_end,
        )
        # upsert. UNIQUE(group_id, report_month). 월배치와 수동 트리거(또는 더블탭)가 겹치면
        # 둘 다 INSERT 를 시도해 진 쪽이 1062 로 터진다. 잡아서 UPDATE 경로로 다시 쓴다.
        # (groups.py 가입 경합과 같은 처리. 안 잡으면 껍데기 500 이 난다.)
        try:
            report_id = await _upsert_report(session, group_id, report_month, values)
        except IntegrityError:
            await session.rollback()
            report_id = await _upsert_report(session, group_id, report_month, values)

    if notify:
        try:
            async with session_factory()() as push_session:
                await notifications.send_monthly_report(
                    push_session, group_id, report_month
                )
        except Exception:
            logger.exception("그룹 %s 월간 레포트 푸시 실패", group_id)

    logger.info(
        "그룹 %s %s 레포트 생성: 사진 %d 그림 %d 글 %d 찌르기 %d 최고=%s(%s)",
        group_id, report_month, photo_count, drawing_count, text_count,
        poke_count, best_id, best_rule.value if best_rule else None,
    )
    return report_id


async def _pick_best_doodle(
    session: AsyncSession, group_id: int, start: datetime, end: datetime
) -> tuple[int | None, BestDoodleRule | None]:
    """답장 수 → 획 수 → 최신 순으로 그 달 최고의 낙서를 고른다.

    반환한 rule 은 **승자를 실제로 결정지은 기준**이다. 답장 수 최댓값이 유일하면
    most_replies, 답장이 동률이라 획 수가 갈랐으면 most_strokes, 그마저 동률이면 latest.

    **사라지기 모드 낙서는 후보에서 뺀다 (SPEC 6.5).** 만료된 것은 deleted_at 으로 걸러지지만,
    아직 안 열린 사라지기 낙서는 만료 타이머가 안 걸려 deleted_at 이 NULL 이다. 이걸 후보에
    두면 최고의 낙서로 뽑혀 '확인 전 노출 금지' 불변식을 깬다. mode 로 명시적으로 제외한다.
    """
    candidates = (
        await session.execute(
            select(Doodle).where(
                Doodle.group_id == group_id,
                Doodle.created_at >= start,
                Doodle.created_at < end,
                Doodle.deleted_at.is_(None),
                Doodle.mode != DoodleMode.EPHEMERAL,
            )
        )
    ).scalars().all()
    if not candidates:
        return None, None

    cand_ids = [d.id for d in candidates]
    # 답장 수는 앱의 reply_count 와 같은 정의(삭제되지 않은 답장만).
    reply_counts = dict(
        (
            await session.execute(
                select(Doodle.parent_id, func.count(Doodle.id))
                .where(Doodle.parent_id.in_(cand_ids), Doodle.deleted_at.is_(None))
                .group_by(Doodle.parent_id)
            )
        ).all()
    )

    def replies(d: Doodle) -> int:
        return reply_counts.get(d.id, 0)

    # 정렬 키: 답장 수, 획 수, 생성시각, id. 마지막 두 개가 결정적 tie-break.
    best = max(candidates, key=lambda d: (replies(d), _stroke_count(d.stroke_data), d.created_at, d.id))

    top_replies = replies(best)
    if top_replies > 0 and sum(1 for d in candidates if replies(d) == top_replies) == 1:
        return best.id, BestDoodleRule.MOST_REPLIES

    tied = [d for d in candidates if replies(d) == top_replies]
    top_strokes = _stroke_count(best.stroke_data)
    if top_strokes > 0 and sum(1 for d in tied if _stroke_count(d.stroke_data) == top_strokes) == 1:
        return best.id, BestDoodleRule.MOST_STROKES

    return best.id, BestDoodleRule.LATEST


async def _upsert_report(
    session: AsyncSession, group_id: int, report_month: str, values: dict
) -> int:
    """(group_id, report_month) 행을 있으면 UPDATE, 없으면 INSERT 하고 commit 한다.

    동시성은 부르는 쪽이 IntegrityError 로 처리한다. 여기선 순수 upsert 만 한다.
    """
    report = (
        await session.execute(
            select(MonthlyReport).where(
                MonthlyReport.group_id == group_id,
                MonthlyReport.report_month == report_month,
            )
        )
    ).scalar_one_or_none()
    if report is None:
        report = MonthlyReport(group_id=group_id, report_month=report_month)
        session.add(report)
    for key, val in values.items():
        setattr(report, key, val)
    report.generated_at = _now()
    await session.commit()
    return report.id


# ---------------------------------------------------------------------------
# Socket.IO 핸들러. REST 와 같은 함수를 부르고 ack 로 결과를 돌려준다.
# ---------------------------------------------------------------------------


def _ack_error(exc: ApiError) -> dict:
    return {"error": {"code": exc.code, "message": exc.message}}


async def sock_doodle_viewed(user_id: int, payload: dict) -> dict:
    doodle_id = payload.get("doodle_id")
    if doodle_id is None:
        return {"error": {"code": "invalid_request", "message": "doodle_id 가 없습니다"}}
    try:
        parsed_id = parse_id(doodle_id, "doodle_id")
        async with session_factory()() as session:
            expires_at = await mark_viewed(session, user_id, parsed_id)
    except ApiError as e:
        return _ack_error(e)
    return {"expires_at": expires_at.isoformat() + "Z" if expires_at else None}


async def sock_poke_send(user_id: int, payload: dict) -> dict:
    to_user_id = payload.get("to_user_id")
    if to_user_id is None:
        return {"error": {"code": "invalid_request", "message": "to_user_id 가 없습니다"}}
    try:
        parsed_id = parse_id(to_user_id, "to_user_id")
        async with session_factory()() as session:
            await send_poke(session, user_id, parsed_id)
    except ApiError as e:
        return _ack_error(e)
    return {"ok": True}
