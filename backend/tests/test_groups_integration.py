"""온보딩·그룹 통합 테스트. **실제 MySQL 이 필요하다.**

    # 로컬 (root/root)
    export DATABASE_URL='mysql+asyncmy://root:root@127.0.0.1:3306/memory_pager?charset=utf8mb4'
    python backend/tests/test_groups_integration.py

`backend/schema.sql` 이 먼저 적용되어 있어야 한다. 이 스크립트는 매 실행마다 테이블을
비우므로 **개발용 DB 에만 쓸 것.**

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

_TABLES = [
    "doodle_receipts", "doodles", "pokes", "pet_likes", "pet_activities",
    "pet_diaries", "style_models", "pet_items", "monthly_reports",
    "pets", "group_members", "groups", "devices", "auth_identities", "users",
]


def reset_db() -> None:
    sync_url = DB_URL.replace("+asyncmy", "+pymysql").replace("+aiomysql", "+pymysql")
    engine = create_engine(sync_url)
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
        h = c.get("/v1/health").json()
        check("health db=ok", h["db"] == "ok", f"got {h}")

        # --- 온보딩 -------------------------------------------------------
        ra = c.post("/v1/auth/register", json={"display_name": "종화", "device_uid": "device-aaaa"})
        check("A 등록 201/200", ra.status_code == 200, str(ra.status_code))
        tok_a, uid_a = ra.json()["token"], ra.json()["user"]["id"]
        check("토큰이 mp_{user_id}_ 로 시작", tok_a.startswith(f"mp_{uid_a}_"), tok_a[:16])

        ra2 = c.post("/v1/auth/register", json={"display_name": "종화", "device_uid": "device-aaaa"})
        check("같은 device_uid 는 같은 유저", ra2.json()["user"]["id"] == uid_a)
        check("재등록 시 토큰은 새로 발급", ra2.json()["token"] != tok_a)
        tok_a = ra2.json()["token"]
        check("이전 토큰은 무효", c.get("/v1/me", headers={"Authorization": f"Bearer {ra.json()['token']}"}).status_code == 401)

        rb = c.post("/v1/auth/register", json={"display_name": "종혁", "device_uid": "device-bbbb"})
        tok_b, uid_b = rb.json()["token"], rb.json()["user"]["id"]
        rc = c.post("/v1/auth/register", json={"display_name": "제삼자", "device_uid": "device-cccc"})
        tok_c = rc.json()["token"]
        check("서로 다른 유저", uid_a != uid_b)

        A = {"Authorization": f"Bearer {tok_a}"}
        B = {"Authorization": f"Bearer {tok_b}"}
        C = {"Authorization": f"Bearer {tok_c}"}

        check("가입 전 /me 의 group 은 null", c.get("/v1/me", headers=A).json()["group"] is None)

        # --- 디바이스 -----------------------------------------------------
        check("FCM 토큰 등록 204", c.post("/v1/devices", json={"fcm_token": "fcm-a", "app_version": "1.0.0"}, headers=A).status_code == 204)
        check("같은 토큰 재등록도 204 (멱등)", c.post("/v1/devices", json={"fcm_token": "fcm-a"}, headers=A).status_code == 204)

        # --- 그룹 생성 ----------------------------------------------------
        rg = c.post("/v1/groups", json={"name": "우리집", "pet_name": "삐삐"}, headers=A)
        check("그룹 생성 201", rg.status_code == 201, str(rg.status_code) + rg.text[:120])
        g = rg.json()["group"]
        gid, code = g["id"], g["invite_code"]
        check("member_count 가 트리거로 1", g["member_count"] == 1, str(g["member_count"]))
        check("초대코드 8자", len(code) == 8, code)
        check("펫이 함께 생성됨", rg.json()["pet"]["name"] == "삐삐")
        check("owner 역할", g["members"][0]["role"] == "owner")

        # 기본 그림체 행이 생겼는가 (SPEC 6.3절)
        sync = create_engine(DB_URL.replace("+asyncmy", "+pymysql").replace("+aiomysql", "+pymysql"))
        with sync.connect() as conn:
            row = conn.execute(text(
                "SELECT kind, version, status FROM style_models WHERE group_id=:g"), {"g": int(gid)}
            ).fetchone()
        sync.dispose()
        check("기본 그림체 style_models 행 생성", row is not None and row[0] == "default" and row[1] == 0 and row[2] == "ready", str(row))

        r = c.post("/v1/groups", json={"name": "딴집", "pet_name": "뽀뽀"}, headers=A)
        check("이미 그룹이 있으면 409 already_in_group", r.status_code == 409 and code_of(r) == "already_in_group", f"{r.status_code} {code_of(r)}")

        # --- 가입 ---------------------------------------------------------
        r = c.post("/v1/groups/join", json={"invite_code": code.lower()}, headers=B)
        check("소문자 초대코드도 통과 (정규화)", r.status_code == 200, str(r.status_code))
        check("member_count 가 2", r.json()["member_count"] == 2)

        r = c.post("/v1/groups/join", json={"invite_code": code}, headers=B)
        check("같은 그룹 재가입 409 already_member", r.status_code == 409 and code_of(r) == "already_member", f"{r.status_code} {code_of(r)}")

        r = c.post("/v1/groups/join", json={"invite_code": code}, headers=C)
        check("3번째 가입 409 group_full", r.status_code == 409 and code_of(r) == "group_full", f"{r.status_code} {code_of(r)}")

        r = c.post("/v1/groups/join", json={"invite_code": "NOSUCHCD"}, headers=C)
        check("없는 초대코드 404", r.status_code == 404, str(r.status_code))

        # --- 별명 · 수정 ---------------------------------------------------
        r = c.patch(f"/v1/groups/{gid}/members/{uid_a}", json={"nickname": "곰돌이"}, headers=B)
        check("상대에게 별명 지어주기 200", r.status_code == 200, str(r.status_code))
        me_row = [m for m in r.json()["members"] if m["user_id"] == uid_a][0]
        check("별명이 저장됨", me_row["nickname"] == "곰돌이", str(me_row))

        r = c.patch(f"/v1/groups/{gid}/members/{uid_b}", json={"nickname": "나"}, headers=B)
        check("자기 자신에게는 400", r.status_code == 400, str(r.status_code))

        r = c.patch(f"/v1/groups/{gid}", json={"background_color": "ffe4e1"}, headers=A)
        check("배경색 변경 + 대문자 정규화", r.status_code == 200 and r.json()["background_color"] == "FFE4E1", r.text[:80])

        # --- 권한 ---------------------------------------------------------
        r = c.get(f"/v1/groups/{gid}", headers=C)
        check("남의 그룹 조회 403", r.status_code == 403 and code_of(r) == "forbidden", f"{r.status_code} {code_of(r)}")

        check("가입 후 /me 에 group 있음", c.get("/v1/me", headers=B).json()["group"]["id"] == gid)

    print(f"\n{pass_n}/{pass_n + fail_n} passed")
    return 1 if fail_n else 0


if __name__ == "__main__":
    raise SystemExit(main())
