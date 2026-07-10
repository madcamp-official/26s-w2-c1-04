"""배치 작업. APScheduler `AsyncIOScheduler` 를 인프로세스로 돌린다.

**사라지기 모드의 5초 만료는 여기 없다.** 그건 `ephemeral.py` 의 이벤트 드리븐 타이머다.
5초짜리를 스케줄러로 폴링하면 최악 5초 지연에 매초 부하가 얹힌다.

여기 있는 것은 진짜 배치다.
- 펫 활동 갱신 (몇 시간마다) — LLM 을 부른다
- 자정 일기 생성 (하루 1회) — LLM + SD 를 부른다

GPU 가 죽어 있어도 이 잡들은 죽지 않는다. `gpu.py` 가 스텁으로 열화한다.
"""

from __future__ import annotations

import logging
from datetime import date, timedelta

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger
from apscheduler.triggers.interval import IntervalTrigger
from sqlalchemy import select

from . import services
from .config import get_settings
from .db import session_factory
from .models import Group, Pet

logger = logging.getLogger(__name__)

_scheduler: AsyncIOScheduler | None = None


async def _all_pet_ids() -> list[int]:
    async with session_factory()() as session:
        return list((await session.execute(select(Pet.id))).scalars())


async def rotate_all_activities() -> None:
    for pet_id in await _all_pet_ids():
        try:
            await services.rotate_pet_activity(pet_id)
        except Exception:
            # 펫 하나가 터져도 나머지는 굴러가야 한다.
            logger.exception("펫 %s 활동 갱신 실패", pet_id)


async def generate_yesterday_diaries() -> None:
    yesterday = date.today() - timedelta(days=1)
    for pet_id in await _all_pet_ids():
        try:
            await services.generate_diary(pet_id, yesterday)
        except Exception:
            logger.exception("펫 %s 일기 생성 실패 (%s)", pet_id, yesterday)


async def _all_group_ids() -> list[int]:
    async with session_factory()() as session:
        return list((await session.execute(select(Group.id))).scalars())


async def generate_last_month_reports() -> None:
    """매월 1일에 지난 달 레포트를 굳힌다 (MR-3). 데모에선 수동 트리거를 주로 쓴다."""
    today = date.today()
    last_month = (today.replace(day=1) - timedelta(days=1)).strftime("%Y-%m")
    for group_id in await _all_group_ids():
        try:
            await services.generate_report(group_id, last_month)
        except Exception:
            logger.exception("그룹 %s 레포트 생성 실패 (%s)", group_id, last_month)


def start() -> None:
    global _scheduler
    settings = get_settings()
    if not settings.scheduler_enabled:
        logger.info("스케줄러 비활성 (SCHEDULER_ENABLED=false)")
        return

    _scheduler = AsyncIOScheduler(timezone="UTC")
    _scheduler.add_job(
        rotate_all_activities,
        IntervalTrigger(minutes=settings.activity_interval_minutes),
        id="rotate_activities",
        # 서버가 오래 꺼져 있었어도 밀린 실행을 몰아서 돌리지 않는다.
        coalesce=True,
        max_instances=1,
    )
    _scheduler.add_job(
        generate_yesterday_diaries,
        CronTrigger(hour=settings.diary_hour_utc, minute=5),
        id="generate_diaries",
        coalesce=True,
        max_instances=1,
    )
    _scheduler.add_job(
        generate_last_month_reports,
        # 매월 1일 00:10 UTC. 자정 배치들과 겹치지 않게 조금 뒤로 민다.
        CronTrigger(day=1, hour=0, minute=10),
        id="generate_reports",
        coalesce=True,
        max_instances=1,
    )
    _scheduler.start()
    logger.info(
        "스케줄러 시작: 활동 %d분마다, 일기 %02d:05 UTC, 레포트 매월 1일 00:10 UTC",
        settings.activity_interval_minutes,
        settings.diary_hour_utc,
    )


def shutdown() -> None:
    if _scheduler is not None:
        _scheduler.shutdown(wait=False)
