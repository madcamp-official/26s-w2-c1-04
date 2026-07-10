"""사라지기 모드(SD-6)의 5초 만료 타이머.

**스케줄러 폴링이 아니다.** 5초짜리를 1초마다 DB 스캔하면 최악 5초 지연에 매초 부하가
얹힌다. 확인 시점에 `loop.call_later` 로 지연 태스크 하나를 걸고, 조기 삭제 시 취소한다.
근거: docs/STACK.md 6절.

타이머는 **프로세스 인메모리**다. 두 가지 결과가 따른다.

1. 서버가 죽으면 타이머가 전부 사라진다. 그래서 기동 시 `sweep()` 으로 DB 의
   `doodles.expires_at` 을 훑어, 지난 건 즉시 만료시키고 안 지난 건 재스케줄한다.
2. uvicorn 워커를 여러 개로 늘리면 타이머가 공유되지 않는다. **단일 프로세스로 돌린다.**

이 모듈은 DB 도 Socket.IO 도 모른다. 만료 시 무엇을 할지는 `on_expire` 콜백이 정한다.
그래서 테스트할 수 있다.
"""

from __future__ import annotations

import asyncio
import logging
from collections.abc import Awaitable, Callable, Iterable
from datetime import datetime, timezone

logger = logging.getLogger(__name__)

OnExpire = Callable[[int], Awaitable[None]]


def _as_utc(dt: datetime) -> datetime:
    """MySQL DATETIME 은 타임존을 갖지 않는다. naive 면 UTC 로 간주한다."""
    return dt.replace(tzinfo=timezone.utc) if dt.tzinfo is None else dt


class ExpiryScheduler:
    def __init__(self, on_expire: OnExpire) -> None:
        self._on_expire = on_expire
        self._timers: dict[int, asyncio.TimerHandle] = {}
        # create_task 가 돌려준 Task 를 붙들지 않으면 GC 가 실행 중인 태스크를 거둘 수 있다.
        self._tasks: set[asyncio.Task[None]] = set()

    # -- 스케줄링 ----------------------------------------------------------

    def schedule(self, doodle_id: int, ttl_seconds: float) -> None:
        """`ttl_seconds` 뒤에 만료시킨다. 이미 걸려 있으면 새 것으로 교체한다."""
        self.cancel(doodle_id)

        if ttl_seconds <= 0:
            self._fire(doodle_id)
            return

        loop = asyncio.get_running_loop()
        self._timers[doodle_id] = loop.call_later(ttl_seconds, self._fire, doodle_id)

    def cancel(self, doodle_id: int) -> bool:
        """조기 삭제·취소 시. 걸려 있던 타이머가 있었으면 True."""
        handle = self._timers.pop(doodle_id, None)
        if handle is None:
            return False
        handle.cancel()
        return True

    @property
    def pending(self) -> int:
        return len(self._timers)

    # -- 실행 --------------------------------------------------------------

    def _fire(self, doodle_id: int) -> None:
        """`call_later` 는 동기 콜백만 받는다. 이벤트루프를 막지 않도록 태스크로 넘긴다."""
        self._timers.pop(doodle_id, None)
        task = asyncio.create_task(self._run(doodle_id))
        self._tasks.add(task)
        task.add_done_callback(self._tasks.discard)

    async def _run(self, doodle_id: int) -> None:
        try:
            await self._on_expire(doodle_id)
        except Exception:
            # 하나가 터져도 나머지 타이머는 살아야 한다.
            logger.exception("낙서 %s 만료 처리 실패", doodle_id)

    # -- 부팅 스윕 ----------------------------------------------------------

    async def sweep(
        self,
        rows: Iterable[tuple[int, datetime]],
        now: datetime | None = None,
    ) -> tuple[int, int]:
        """재기동 복구.

        `rows` 는 `(doodle_id, expires_at)` 이다. 이미 지난 건 즉시 만료시키고,
        아직 안 지난 건 남은 시간으로 재스케줄한다.

        반환: (즉시 만료시킨 수, 재스케줄한 수)
        """
        current = now or datetime.now(timezone.utc)
        expired = rescheduled = 0

        for doodle_id, expires_at in rows:
            remaining = (_as_utc(expires_at) - current).total_seconds()
            if remaining <= 0:
                await self._run(doodle_id)
                expired += 1
            else:
                self.schedule(doodle_id, remaining)
                rescheduled += 1

        logger.info("부팅 스윕: 즉시 만료 %d건, 재스케줄 %d건", expired, rescheduled)
        return expired, rescheduled

    # -- 종료 --------------------------------------------------------------

    async def aclose(self) -> None:
        for handle in self._timers.values():
            handle.cancel()
        self._timers.clear()
        if self._tasks:
            await asyncio.gather(*self._tasks, return_exceptions=True)
