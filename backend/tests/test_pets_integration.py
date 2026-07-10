"""펫 · 일기 · 위젯 통합 테스트. **실제 MySQL 이 필요하다.**

    export DATABASE_URL='mysql+asyncmy://root:root@127.0.0.1:3306/memory_pager?charset=utf8mb4'
    python backend/tests/test_pets_integration.py

GPU 는 스텁(`GPU_ENABLED=false`)으로 돈다. 실물 없이도 PT-1 과 PT-6a 가 끝까지 검증된다.

HTTP 요청과 서비스 함수를 **같은 이벤트 루프**에서 돌린다. asyncmy 엔진은 자기를 만든
루프에 묶이므로, 별도 포털/루프를 쓰면 깨진다. 그래서 TestClient 대신 httpx 의
ASGITransport 를 쓰고 lifespan 을 직접 연다.
"""

from __future__ import annotations

import asyncio
import io
import json
import os
import sys
import tempfile
import warnings
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
warnings.filterwarnings("ignore")

DB_URL = os.environ.get("DATABASE_URL")
if not DB_URL:
    print("DATABASE_URL 이 없어 건너뜀 (실제 MySQL 필요)")
    raise SystemExit(0)

MEDIA = Path(tempfile.mkdtemp(prefix="mp_pets_"))
os.environ["MEDIA_ROOT"] = str(MEDIA)
os.environ["SCHEDULER_ENABLED"] = "false"   # 배치가 테스트 도중 끼어들면 재현이 안 된다
os.environ["GPU_ENABLED"] = "false"

import logging  # noqa: E402

logging.disable(logging.CRITICAL)

import httpx  # noqa: E402
from PIL import Image  # noqa: E402
from sqlalchemy import create_engine, text  # noqa: E402

from app import services  # noqa: E402
from app.gpu import ACTIVITIES  # noqa: E402
from app.main import app  # noqa: E402

SYNC = DB_URL.replace("+asyncmy", "+pymysql").replace("+aiomysql", "+pymysql")
_TABLES = [
    "doodle_receipts", "doodles", "pokes", "pet_likes", "pet_activities",
    "pet_diaries", "style_models", "pet_items", "monthly_reports",
    "pets", "group_members", "groups", "devices", "auth_identities", "users",
]

pass_n = fail_n = 0


def check(label, cond, detail=""):
    global pass_n, fail_n
    if cond:
        pass_n += 1
        print(f"  ok    {label}")
    else:
        fail_n += 1
        print(f"  FAIL  {label}  {detail}")


def reset_db():
    e = create_engine(SYNC)
    with e.begin() as conn:
        conn.execute(text("SET FOREIGN_KEY_CHECKS=0"))
        for t in _TABLES:
            conn.execute(text(f"TRUNCATE TABLE `{t}`"))
        conn.execute(text("SET FOREIGN_KEY_CHECKS=1"))
    e.dispose()


def sql_scalar(q: str, **p):
    e = create_engine(SYNC)
    with e.connect() as conn:
        v = conn.execute(text(q), p).scalar()
    e.dispose()
    return v


def png_bytes():
    buf = io.BytesIO()
    Image.new("RGBA", (32, 32), (0, 0, 255, 200)).save(buf, "PNG")
    return buf.getvalue()


STROKES = json.dumps({"canvas": {"w": 100, "h": 100}, "duration_ms": 900,
                      "strokes": [{"pen": "pen", "color": "000000", "width": 3,
                                   "points": [[1, 1, 0], [2, 2, 10]]}]})


async def register(c, name, uid):
    r = await c.post("/v1/auth/register", json={"display_name": name, "device_uid": uid})
    return r.json()["token"], r.json()["user"]["id"]


async def run() -> None:
    transport = httpx.ASGITransport(app=app)
    async with app.router.lifespan_context(app):
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
            tok_a, uid_a = await register(c, "종화", "pet-device-a")
            tok_b, _ = await register(c, "종혁", "pet-device-b")
            tok_c, _ = await register(c, "제삼자", "pet-device-c")
            A = {"Authorization": f"Bearer {tok_a}"}
            B = {"Authorization": f"Bearer {tok_b}"}
            C = {"Authorization": f"Bearer {tok_c}"}

            gr = (await c.post("/v1/groups", json={"name": "우리집", "pet_name": "삐삐"}, headers=A)).json()
            gid, pet_id = gr["group"]["id"], gr["pet"]["id"]
            await c.post("/v1/groups/join", json={"invite_code": gr["group"]["invite_code"]}, headers=B)

            # --- 홈 화면 (첫 활동 전) ---------------------------------------
            p = await c.get(f"/v1/groups/{gid}/pet", headers=A)
            check("펫 조회 200", p.status_code == 200, p.text[:100])
            check("첫 활동 전 current_activity 는 null", p.json()["current_activity"] is None)
            check("equipped_items 는 빈 배열", p.json()["equipped_items"] == [])
            check("남의 펫 조회 403", (await c.get(f"/v1/groups/{gid}/pet", headers=C)).status_code == 403)

            # --- 쓰다듬기: 활동이 없어도 말을 한다 ----------------------------
            r = await c.post(f"/v1/pets/{pet_id}/pat", headers=A)
            check("활동 없어도 pat 200", r.status_code == 200, r.text[:100])
            check("기본 대사가 나온다", bool(r.json()["utterance"]))
            check("기본 활동은 waiting", r.json()["activity"] == "waiting", str(r.json()["activity"]))
            check("exp 가 오른다", (await c.get(f"/v1/groups/{gid}/pet", headers=A)).json()["exp"] == 1)

            # --- 위젯 -------------------------------------------------------
            w = (await c.get(f"/v1/widget/{gid}", headers=A)).json()
            check("낙서 없으면 widget doodle_id=null", w["doodle_id"] is None, str(w))

            await c.post("/v1/doodles", data={"mode": "normal", "content_type": "drawing", "stroke_data": STROKES},
                         files={"drawing": ("d.png", png_bytes(), "image/png")}, headers=A)
            w = (await c.get(f"/v1/widget/{gid}", headers=B)).json()
            check("일반 낙서는 위젯에 썸네일이 있다", w["thumb_url"] is not None, str(w))
            check("위젯에 content_type 이 있다", w["content_type"] == "drawing")
            check("위젯 is_ephemeral=false", w["is_ephemeral"] is False)

            await c.post("/v1/doodles", data={"mode": "ephemeral", "content_type": "drawing", "stroke_data": STROKES},
                         files={"drawing": ("e.png", png_bytes(), "image/png")}, headers=A)
            w = (await c.get(f"/v1/widget/{gid}", headers=B)).json()
            check("★ 사라지기 낙서는 위젯에 썸네일을 주지 않는다", w["thumb_url"] is None, str(w))
            check("위젯 is_ephemeral=true", w["is_ephemeral"] is True)
            check("위젯에 보낸이 이름", w["sender_nickname"] == "종화", str(w["sender_nickname"]))

            await c.patch(f"/v1/groups/{gid}/members/{uid_a}", json={"nickname": "곰돌이"}, headers=B)
            w = (await c.get(f"/v1/widget/{gid}", headers=B)).json()
            check("별명이 위젯에 반영됨", w["sender_nickname"] == "곰돌이", str(w["sender_nickname"]))

            # --- 펫 활동 갱신 (LLM 스텁) --------------------------------------
            await services.rotate_pet_activity(int(pet_id))
            p = (await c.get(f"/v1/groups/{gid}/pet", headers=A)).json()
            act = p["current_activity"]
            check("활동 갱신 후 current_activity 가 채워짐", act is not None, str(p))
            check("activity 가 열거값 안에 있다", act and act["activity"] in ACTIVITIES, str(act))

            r = (await c.post(f"/v1/pets/{pet_id}/pat", headers=A)).json()
            check("pat 이 현재 활동의 대사를 그대로 돌려준다", r["activity"] == act["activity"], f"{r} vs {act}")
            check("대사가 비어 있지 않다", bool(r["utterance"]))

            await services.rotate_pet_activity(int(pet_id))
            open_n = sql_scalar("SELECT COUNT(*) FROM pet_activities WHERE pet_id=:p AND ended_at IS NULL", p=int(pet_id))
            total = sql_scalar("SELECT COUNT(*) FROM pet_activities WHERE pet_id=:p", p=int(pet_id))
            check("열려 있는 활동은 항상 하나", open_n == 1, f"open={open_n}")
            check("이전 활동은 닫히고 누적된다", total == 2, f"total={total}")

            # --- 일기장 (PT-6a) ----------------------------------------------
            d = (await c.get(f"/v1/pets/{pet_id}/diaries", headers=A)).json()
            check("가입 첫날 일기장은 빈 목록", d["items"] == [] and d["next_before"] is None, str(d))
            check("없는 날짜 일기는 404", (await c.get(f"/v1/pets/{pet_id}/diaries/2020-01-01", headers=A)).status_code == 404)

            today = date.today()
            diary_id = await services.generate_diary(int(pet_id), today)
            check("일기 생성됨", diary_id is not None, str(diary_id))
            check("일기 이미지 파일이 실제로 저장됨", (MEDIA / f"g{gid}" / f"diary_{diary_id}.png").exists())

            d = (await c.get(f"/v1/pets/{pet_id}/diaries", headers=A)).json()
            check("일기장에 1건", len(d["items"]) == 1, str(len(d["items"])))
            item = d["items"][0]
            check("기본 그림체로 그려짐 (default v0)",
                  item["style"]["kind"] == "default" and item["style"]["version"] == 0, str(item["style"]))
            check("캡션이 있다", bool(item["caption"]))
            check("그날의 활동들이 일기에 묶임", len(item["activities"]) == 2, str(item["activities"]))

            one = await c.get(f"/v1/pets/{pet_id}/diaries/{today.isoformat()}", headers=A)
            check("날짜로 단건 조회 200", one.status_code == 200 and one.json()["id"] == str(diary_id))

            again = await services.generate_diary(int(pet_id), today)
            check("하루 한 장 (재생성해도 같은 id)", again == diary_id, f"{again} vs {diary_id}")

            # 활동이 하나도 없는 날은 일기를 만들지 않는다
            none_day = await services.generate_diary(int(pet_id), date(2020, 1, 1))
            check("활동 없는 날은 일기 없음", none_day is None, str(none_day))


def main() -> int:
    reset_db()
    asyncio.run(run())
    print(f"\n{pass_n}/{pass_n + fail_n} passed")
    return 1 if fail_n else 0


if __name__ == "__main__":
    raise SystemExit(main())
