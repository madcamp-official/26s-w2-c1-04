"""토큰 형식 검증. DB 없이 돈다.

    python backend/tests/test_security.py
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from app.security import hash_token, issue_token, parse_user_id  # noqa: E402


def test_roundtrip() -> None:
    token = issue_token(42)
    assert token.startswith("mp_42_"), token
    assert parse_user_id(token) == 42


def test_tokens_are_unique() -> None:
    tokens = {issue_token(1) for _ in range(200)}
    assert len(tokens) == 200, "토큰이 겹쳤다"


def test_hash_is_sha256_hex() -> None:
    h = hash_token(issue_token(7))
    assert len(h) == 64, f"CHAR(64) 에 맞아야 한다. got={len(h)}"
    assert all(c in "0123456789abcdef" for c in h)


def test_hash_is_stable() -> None:
    t = issue_token(9)
    assert hash_token(t) == hash_token(t)


def test_rejects_garbage() -> None:
    for bad in ["", "mp_", "mp_abc_xyz", "xx_1_abc", "1_abc", "mp_1", "Bearer mp_1_a"]:
        assert parse_user_id(bad) is None, f"{bad!r} 를 통과시키면 안 된다"


def test_user_id_boundary() -> None:
    """64비트 정수를 문자열로 직렬화하는 이유이기도 하다."""
    big = 9_007_199_254_740_993  # 2^53 + 1, JS Number 로는 표현 불가
    assert parse_user_id(issue_token(big)) == big


def main() -> int:
    tests = [v for k, v in sorted(globals().items()) if k.startswith("test_")]
    failed = 0
    for t in tests:
        try:
            t()
        except AssertionError as e:
            print(f"  FAIL  {t.__name__}: {e}")
            failed += 1
        else:
            print(f"  ok    {t.__name__}")
    print(f"\n{len(tests) - failed}/{len(tests)} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
