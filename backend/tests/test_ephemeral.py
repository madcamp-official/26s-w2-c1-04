"""ExpiryScheduler 동작 확인. 의존성 없이 그냥 돌린다.

    python backend/tests/test_ephemeral.py

pytest 를 requirements 에 넣지 않았다. 7일 프로젝트에 테스트 러너까지 붙일 이유가 없고,
이 모듈은 순수 asyncio 라 표준 라이브러리만으로 검증된다.
"""

from __future__ import annotations

import asyncio
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.ephemeral import ExpiryScheduler  # noqa: E402


async def test_fires_after_ttl() -> None:
    fired: list[int] = []
    sched = ExpiryScheduler(lambda did: _record(fired, did))

    sched.schedule(1, 0.05)
    assert sched.pending == 1, "타이머가 등록돼야 한다"
    assert fired == [], "아직 발화하면 안 된다"

    await asyncio.sleep(0.12)
    assert fired == [1], f"0.05초 뒤 발화해야 한다. got={fired}"
    assert sched.pending == 0, "발화 후 타이머가 정리돼야 한다"
    await sched.aclose()


async def test_cancel_prevents_fire() -> None:
    fired: list[int] = []
    sched = ExpiryScheduler(lambda did: _record(fired, did))

    sched.schedule(2, 0.05)
    assert sched.cancel(2) is True
    assert sched.cancel(2) is False, "두 번 취소하면 False"

    await asyncio.sleep(0.12)
    assert fired == [], "취소했으면 발화하면 안 된다"
    await sched.aclose()


async def test_reschedule_replaces() -> None:
    """같은 낙서를 두 번 확인해도 타이머가 하나여야 한다."""
    fired: list[int] = []
    sched = ExpiryScheduler(lambda did: _record(fired, did))

    sched.schedule(3, 0.05)
    sched.schedule(3, 0.05)
    assert sched.pending == 1, "타이머가 겹치면 안 된다"

    await asyncio.sleep(0.12)
    assert fired == [3], f"한 번만 발화해야 한다. got={fired}"
    await sched.aclose()


async def test_zero_ttl_fires_immediately() -> None:
    fired: list[int] = []
    sched = ExpiryScheduler(lambda did: _record(fired, did))
    sched.schedule(4, 0.0)
    await asyncio.sleep(0)  # 태스크에 한 번 양보
    await asyncio.sleep(0)
    assert fired == [4], "ttl<=0 이면 즉시 발화"
    await sched.aclose()


async def test_sweep_splits_past_and_future() -> None:
    """서버가 죽었다 살아난 상황. 지난 건 즉시, 남은 건 재스케줄."""
    fired: list[int] = []
    sched = ExpiryScheduler(lambda did: _record(fired, did))
    now = datetime(2026, 7, 10, 12, 0, 0, tzinfo=timezone.utc)

    rows = [
        (10, now - timedelta(seconds=3)),   # 이미 지남
        (11, now - timedelta(seconds=1)),   # 이미 지남
        (12, now + timedelta(seconds=0.05)),  # 아직
    ]
    expired, rescheduled = await sched.sweep(rows, now=now)

    assert (expired, rescheduled) == (2, 1), f"got={(expired, rescheduled)}"
    assert sorted(fired) == [10, 11], f"지난 것만 즉시 만료. got={fired}"
    assert sched.pending == 1

    await asyncio.sleep(0.12)
    assert sorted(fired) == [10, 11, 12], f"남은 것도 결국 만료. got={fired}"
    await sched.aclose()


async def test_naive_datetime_treated_as_utc() -> None:
    """MySQL DATETIME 은 tz 가 없다. naive 를 UTC 로 읽어야 한다."""
    fired: list[int] = []
    sched = ExpiryScheduler(lambda did: _record(fired, did))
    now = datetime(2026, 7, 10, 12, 0, 0, tzinfo=timezone.utc)
    naive_past = datetime(2026, 7, 10, 11, 59, 55)  # tzinfo 없음

    expired, rescheduled = await sched.sweep([(20, naive_past)], now=now)
    assert (expired, rescheduled) == (1, 0), f"got={(expired, rescheduled)}"
    assert fired == [20]
    await sched.aclose()


async def test_callback_exception_does_not_kill_others() -> None:
    fired: list[int] = []

    async def flaky(doodle_id: int) -> None:
        if doodle_id == 30:
            raise RuntimeError("DB 가 죽었다고 치자")
        fired.append(doodle_id)

    sched = ExpiryScheduler(flaky)
    sched.schedule(30, 0.02)
    sched.schedule(31, 0.04)

    await asyncio.sleep(0.12)
    assert fired == [31], f"하나가 터져도 나머지는 살아야 한다. got={fired}"
    await sched.aclose()


async def _record(sink: list[int], doodle_id: int) -> None:
    sink.append(doodle_id)


async def main() -> int:
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    failed = 0
    for t in tests:
        try:
            await t()
        except AssertionError as e:
            print(f"  FAIL  {t.__name__}: {e}")
            failed += 1
        except Exception as e:  # noqa: BLE001
            print(f"  ERROR {t.__name__}: {type(e).__name__}: {e}")
            failed += 1
        else:
            print(f"  ok    {t.__name__}")
    print(f"\n{len(tests) - failed}/{len(tests)} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
