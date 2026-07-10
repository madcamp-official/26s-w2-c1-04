"""프로세스 전역 상태.

사라지기 모드 타이머는 **프로세스 인메모리**다. uvicorn 워커를 늘리면 공유되지 않는다.
그래서 단일 프로세스로 돌린다 (docs/STACK.md 6절).
"""

from __future__ import annotations

from .ephemeral import ExpiryScheduler

_expiry: ExpiryScheduler | None = None


def set_expiry(scheduler: ExpiryScheduler) -> None:
    global _expiry
    _expiry = scheduler


def get_expiry() -> ExpiryScheduler:
    if _expiry is None:
        raise RuntimeError("ExpiryScheduler 가 아직 없다 (lifespan 에서 만든다)")
    return _expiry
