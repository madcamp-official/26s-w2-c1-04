"""스토어(#13) 통합 테스트. **실제 MySQL 이 필요하다.**

    export DATABASE_URL='mysql+asyncmy://root:root@127.0.0.1:3306/memory_pager?charset=utf8mb4'
    python backend/tests/test_store_integration.py

카탈로그 시드(부팅)·구매(코인 원자 차감)·멱등·부족·착용(카테고리 배타)을 검증한다.
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


def set_coins(group_id: int, coins: int) -> None:
    engine = create_engine(_SYNC)
    with engine.begin() as conn:
        conn.execute(
            text("UPDATE pets SET coins=:c WHERE group_id=:g"),
            {"c": coins, "g": group_id},
        )
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
        ra = c.post("/v1/auth/register", json={"display_name": "종화", "device_uid": "dev-a"})
        A = {"Authorization": f"Bearer {ra.json()['token']}"}
        rg = c.post("/v1/groups", json={"name": "우리집", "pet_name": "삐삐"}, headers=A)
        gid = rg.json()["group"]["id"]

        # --- 카탈로그 -----------------------------------------------------
        r = c.get(f"/v1/groups/{gid}/store", headers=A)
        check("스토어 200", r.status_code == 200, str(r.status_code))
        items = r.json()["items"]
        cats = {it["category"] for it in items}
        check("시드가 전 카테고리를 채움", cats >= {"hat", "clothes", "furniture", "background", "prop"}, str(cats))
        check("아이템 다수(>=20)", len(items) >= 20, str(len(items)))
        check("초기 코인 0", r.json()["coins"] == 0, str(r.json()["coins"]))
        by_name = {it["name"]: it for it in items}
        straw = by_name["밀짚모자"]  # 300
        crown = by_name["왕관"]      # 900
        beanie = by_name["비니"]     # 280

        # --- 코인 없이 구매 → 부족 ---------------------------------------
        r = c.post(f"/v1/groups/{gid}/store/{straw['id']}/buy", headers=A)
        check("코인 부족 400", r.status_code == 400 and code_of(r) == "insufficient_coins", f"{r.status_code} {code_of(r)}")

        # --- 코인 지급 후 구매 -------------------------------------------
        set_coins(int(gid), 1000)
        r = c.post(f"/v1/groups/{gid}/store/{straw['id']}/buy", headers=A)
        check("구매 200", r.status_code == 200, r.text[:120])
        check("코인 300 차감(1000→700)", r.json()["coins"] == 700, str(r.json()["coins"]))

        r = c.post(f"/v1/groups/{gid}/store/{straw['id']}/buy", headers=A)
        check("재구매 멱등(코인 그대로 700)", r.json()["coins"] == 700, str(r.json()["coins"]))

        r = c.post(f"/v1/groups/{gid}/store/{crown['id']}/buy", headers=A)
        check("비싼 아이템 부족 400(700<900)", r.status_code == 400 and code_of(r) == "insufficient_coins", f"{r.status_code}")

        # --- 착용(카테고리 배타) -----------------------------------------
        r = c.post(f"/v1/groups/{gid}/store/{straw['id']}/equip", json={"equipped": True}, headers=A)
        check("밀짚모자 착용 200", r.status_code == 200 and r.json()["equipped"] is True, str(r.status_code))
        pet = c.get(f"/v1/groups/{gid}/pet", headers=A).json()
        eq_ids = {e["item_id"] for e in pet["equipped_items"]}
        check("펫에 밀짚모자 착용 반영", straw["id"] in eq_ids, str(eq_ids))

        # 비니 사서 착용 → 밀짚모자는 벗겨져야(모자 하나)
        c.post(f"/v1/groups/{gid}/store/{beanie['id']}/buy", headers=A)
        r = c.post(f"/v1/groups/{gid}/store/{beanie['id']}/equip", json={"equipped": True}, headers=A)
        check("비니 착용 200", r.status_code == 200, str(r.status_code))
        pet = c.get(f"/v1/groups/{gid}/pet", headers=A).json()
        eq_ids = {e["item_id"] for e in pet["equipped_items"]}
        check("모자 카테고리 하나만(비니만 착용)", beanie["id"] in eq_ids and straw["id"] not in eq_ids, str(eq_ids))

        # 미보유 아이템 착용 → 404
        r = c.post(f"/v1/groups/{gid}/store/{crown['id']}/equip", json={"equipped": True}, headers=A)
        check("미보유 착용 404", r.status_code == 404, str(r.status_code))

        # 스토어 재조회 — owned/equipped 반영
        items2 = {it["name"]: it for it in c.get(f"/v1/groups/{gid}/store", headers=A).json()["items"]}
        check("밀짚모자 owned=True, equipped=False", items2["밀짚모자"]["owned"] and not items2["밀짚모자"]["equipped"])
        check("비니 owned=True, equipped=True", items2["비니"]["owned"] and items2["비니"]["equipped"])
        check("왕관 owned=False", not items2["왕관"]["owned"])

    print(f"\n{pass_n}/{pass_n + fail_n} passed")
    return 1 if fail_n else 0


if __name__ == "__main__":
    raise SystemExit(main())
