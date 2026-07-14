"""이웃집(#15) 통합 테스트. **실제 MySQL 이 필요하다.**

    export DATABASE_URL='mysql+asyncmy://root:root@127.0.0.1:3306/memory_pager?charset=utf8mb4'
    python backend/tests/test_neighbors_integration.py

이웃 없음→null, 있음→실매칭, 좋아요 멱등, 자기 펫 좋아요 400, 코드 방문을 검증한다.
DATABASE_URL 이 없으면 조용히 건너뛴다.
"""

from __future__ import annotations

import os
import sys
import warnings
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
warnings.filterwarnings("ignore")

DB_URL = os.environ.get("DATABASE_URL")
if not DB_URL:
    print("DATABASE_URL 이 없어 건너뜀 (실제 MySQL 필요)")
    raise SystemExit(0)

import logging  # noqa: E402

logging.disable(logging.CRITICAL)

from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import create_engine, text  # noqa: E402

from app.main import app  # noqa: E402

_SYNC = DB_URL.replace("+asyncmy", "+pymysql").replace("+aiomysql", "+pymysql")
_TABLES = [
    "doodle_receipts", "doodles", "pokes", "pet_likes", "pet_activities",
    "pet_diaries", "style_models", "pet_items", "monthly_reports",
    "pets", "group_members", "groups", "devices", "auth_identities", "users",
]


def reset_db() -> None:
    engine = create_engine(_SYNC)
    with engine.begin() as conn:
        conn.execute(text("SET FOREIGN_KEY_CHECKS=0"))
        for t in _TABLES:
            conn.execute(text(f"TRUNCATE TABLE `{t}`"))
        conn.execute(text("SET FOREIGN_KEY_CHECKS=1"))
    engine.dispose()


pass_n = fail_n = 0


def check(label: str, cond: bool, detail: str = "") -> None:
    global pass_n, fail_n
    if cond:
        pass_n += 1
        print(f"  ok    {label}")
    else:
        fail_n += 1
        print(f"  FAIL  {label}  {detail}")


def code_of(r) -> str | None:
    try:
        return r.json()["error"]["code"]
    except Exception:
        return None


def main() -> int:
    reset_db()
    with TestClient(app) as c:
        ra = c.post("/v1/auth/register", json={"display_name": "A", "device_uid": "device-aaaa"})
        A = {"Authorization": f"Bearer {ra.json()['token']}"}
        rga = c.post("/v1/groups", json={"name": "A네집", "pet_name": "아리"}, headers=A)
        code_a = rga.json()["group"]["invite_code"]

        # 이웃이 나뿐 → null (데모 폴백)
        r = c.get("/v1/neighbors/random", headers=A)
        check("이웃 없음 200 + null", r.status_code == 200 and r.json()["neighbor"] is None, r.text[:120])

        # B 그룹 생성(다른 기기)
        rb = c.post("/v1/auth/register", json={"display_name": "B", "device_uid": "device-bbbb"})
        B = {"Authorization": f"Bearer {rb.json()['token']}"}
        rgb = c.post("/v1/groups", json={"name": "B네집", "pet_name": "베리"}, headers=B)
        pet_b = rgb.json()["pet"]["id"]
        code_b = rgb.json()["group"]["invite_code"]

        # 이제 A 는 B 를 이웃으로 매칭
        r = c.get("/v1/neighbors/random", headers=A)
        n = r.json()["neighbor"]
        check("이웃 매칭됨(null 아님)", n is not None, r.text[:150])
        check("이웃은 B 그룹(내 그룹 제외)", n and n["group_name"] == "B네집", str(n))
        check("이웃 필드(펫이름·레벨·D-day)", n and n["pet_name"] == "베리" and n["pet_level"] >= 1, str(n))
        check("초기 좋아요 0, 내가 안 누름", n and n["likes"] == 0 and n["liked_by_me"] is False, str(n))

        # 좋아요
        r = c.post(f"/v1/neighbors/{pet_b}/like", headers=A)
        check("좋아요 200 likes=1", r.status_code == 200 and r.json()["likes"] == 1, r.text[:120])
        r = c.post(f"/v1/neighbors/{pet_b}/like", headers=A)
        check("재좋아요 멱등 likes=1", r.json()["likes"] == 1, str(r.json()))
        r = c.get("/v1/neighbors/random", headers=A)
        check("이웃 재조회 liked_by_me=True", r.json()["neighbor"]["liked_by_me"] is True, str(r.json()))

        # 자기 그룹 펫 좋아요 금지
        pet_a = rga.json()["pet"]["id"]
        r = c.post(f"/v1/neighbors/{pet_a}/like", headers=A)
        check("자기 펫 좋아요 400", r.status_code == 400, str(r.status_code))

        # 코드로 방문
        r = c.get(f"/v1/neighbors/by-code/{code_b.lower()}", headers=A)
        check("코드 방문(소문자 정규화) → B", r.status_code == 200 and r.json()["neighbor"]["group_name"] == "B네집", r.text[:120])
        r = c.get(f"/v1/neighbors/by-code/{code_a}", headers=A)
        check("내 코드 방문 400", r.status_code == 400, str(r.status_code))
        r = c.get("/v1/neighbors/by-code/NOSUCHCD", headers=A)
        check("없는 코드 404", r.status_code == 404, str(r.status_code))

    print(f"\n{pass_n}/{pass_n + fail_n} passed")
    return 1 if fail_n else 0


if __name__ == "__main__":
    raise SystemExit(main())
