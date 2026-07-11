"""DB 없이 도는 입력·배치 날짜 회귀 테스트."""

from __future__ import annotations

import asyncio
import sys
import types
from datetime import date, datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.errors import ApiError, parse_id  # noqa: E402
from app.notifications import FirebasePushClient  # noqa: E402
from app.scheduler import diary_entry_date  # noqa: E402
from app.services import _kst_day_range, validate_month  # noqa: E402


def _api_error(fn) -> ApiError:
    try:
        fn()
    except ApiError as exc:
        return exc
    raise AssertionError("ApiError가 나야 한다")


def test_parse_id_accepts_positive_decimal() -> None:
    assert parse_id("9007199254740993", "id") == 9_007_199_254_740_993


def test_parse_id_rejects_bad_values() -> None:
    for value in (
        None,
        "",
        "abc",
        "0",
        "-1",
        "1.0",
        "01",
        str(2**63),
        True,
    ):
        assert _api_error(lambda value=value: parse_id(value, "id")).status == 400


def test_month_bounds() -> None:
    validate_month("2026-07")
    for value in ("2026-7", "2026-13", "0000-01", "9999-12", "abcd-ef"):
        assert _api_error(lambda value=value: validate_month(value)).status == 400


def test_kst_midnight_selects_just_finished_day() -> None:
    # 2026-07-10 15:05 UTC == 2026-07-11 00:05 KST
    now = datetime(2026, 7, 10, 15, 5, tzinfo=timezone.utc)
    assert diary_entry_date(now) == date(2026, 7, 10)


def test_kst_diary_query_range_is_naive_utc() -> None:
    start, end = _kst_day_range(date(2026, 7, 10))
    assert start == datetime(2026, 7, 9, 15, 0)
    assert end == datetime(2026, 7, 10, 15, 0)


def test_fcm_multicast_is_chunked_and_aggregated() -> None:
    batch_sizes: list[int] = []

    class MulticastMessage:
        def __init__(self, *, tokens, data, android) -> None:
            self.tokens = tokens

    async def send_each(message, *, app):
        batch_sizes.append(len(message.tokens))
        return types.SimpleNamespace(
            success_count=len(message.tokens) - 1,
            failure_count=1,
        )

    messaging = types.SimpleNamespace(
        MulticastMessage=MulticastMessage,
        AndroidConfig=lambda **kwargs: kwargs,
        send_each_for_multicast_async=send_each,
    )
    module = types.ModuleType("firebase_admin")
    module.messaging = messaging
    previous = sys.modules.get("firebase_admin")
    sys.modules["firebase_admin"] = module
    try:
        client = object.__new__(FirebasePushClient)
        client._app = object()
        result = asyncio.run(
            client.send([f"token-{index}" for index in range(1001)], {"type": "test"})
        )
    finally:
        if previous is None:
            sys.modules.pop("firebase_admin", None)
        else:
            sys.modules["firebase_admin"] = previous

    assert batch_sizes == [500, 500, 1]
    assert (result.sent, result.failed) == (998, 3)


def main() -> int:
    tests = [
        value for name, value in sorted(globals().items()) if name.startswith("test_")
    ]
    failed = 0
    for test in tests:
        try:
            test()
        except Exception as exc:
            print(f"  FAIL  {test.__name__}: {type(exc).__name__}: {exc}")
            failed += 1
        else:
            print(f"  ok    {test.__name__}")
    print(f"\n{len(tests) - failed}/{len(tests)} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
