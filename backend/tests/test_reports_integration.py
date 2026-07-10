"""월간 레포트 통합 테스트. **실제 MySQL 이 필요하다.**

    export DATABASE_URL='mysql+asyncmy://root:root@127.0.0.1:3306/memory_pager?charset=utf8mb4'
    python backend/tests/test_reports_integration.py

낙서·찌르기의 `created_at` 을 SQL 로 뒤로 당겨 특정 달에 심고, 그 달 레포트를 생성해
집계·최고의 낙서·펫 레벨 변화를 끝까지 검증한다. GPU 스텁(`GPU_ENABLED=false`)으로 돈다.
"""

from __future__ import annotations

import asyncio
import io
import json
import os
import sys
import tempfile
import warnings
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
warnings.filterwarnings("ignore")

DB_URL = os.environ.get("DATABASE_URL")
if not DB_URL:
    print("DATABASE_URL 이 없어 건너뜀 (실제 MySQL 필요)")
    raise SystemExit(0)

MEDIA = Path(tempfile.mkdtemp(prefix="mp_reports_"))
os.environ["MEDIA_ROOT"] = str(MEDIA)
os.environ["SCHEDULER_ENABLED"] = "false"   # 월간 배치가 테스트 도중 끼어들면 안 된다
os.environ["GPU_ENABLED"] = "false"

import logging  # noqa: E402

logging.disable(logging.CRITICAL)

import httpx  # noqa: E402
from PIL import Image  # noqa: E402
from sqlalchemy import create_engine, text  # noqa: E402

from app import services  # noqa: E402
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


def sql_exec(q: str, **p):
    e = create_engine(SYNC)
    with e.begin() as conn:
        conn.execute(text(q), p)
    e.dispose()


def sql_scalar(q: str, **p):
    e = create_engine(SYNC)
    with e.connect() as conn:
        v = conn.execute(text(q), p).scalar()
    e.dispose()
    return v


def set_created(table: str, row_id, ts: str):
    sql_exec(f"UPDATE `{table}` SET created_at=:ts WHERE id=:id", ts=ts, id=int(row_id))


def set_pet_level(gid, level: int):
    sql_exec("UPDATE pets SET level=:lv WHERE group_id=:g", lv=level, g=int(gid))


def png_bytes():
    buf = io.BytesIO()
    Image.new("RGBA", (32, 32), (0, 0, 255, 200)).save(buf, "PNG")
    return buf.getvalue()


def jpg_bytes():
    buf = io.BytesIO()
    Image.new("RGB", (32, 32), (200, 100, 50)).save(buf, "JPEG")
    return buf.getvalue()


def strokes(n: int) -> str:
    return json.dumps({
        "canvas": {"w": 100, "h": 100}, "duration_ms": 900,
        "strokes": [
            {"pen": "pen", "color": "000000", "width": 3, "points": [[i, i, 0]]}
            for i in range(n)
        ],
    })


async def register(c, name, uid):
    r = await c.post("/v1/auth/register", json={"display_name": name, "device_uid": uid})
    return r.json()["token"], r.json()["user"]["id"]


async def post_doodle(c, headers, *, ctype, mode="normal", n_strokes=1,
                      text_body="글", parent_id=None):
    data = {"mode": mode, "content_type": ctype}
    files = None
    if ctype == "drawing":
        data["stroke_data"] = strokes(n_strokes)
        files = {"drawing": ("d.png", png_bytes(), "image/png")}
    elif ctype == "photo":
        files = {"photo": ("p.jpg", jpg_bytes(), "image/jpeg")}
    elif ctype == "text":
        data["text_body"] = text_body
    if parent_id is not None:
        data["parent_id"] = str(parent_id)
    r = await c.post("/v1/doodles", data=data, files=files, headers=headers)
    assert r.status_code == 201, r.text
    return r.json()["id"]


async def run() -> None:
    transport = httpx.ASGITransport(app=app)
    async with app.router.lifespan_context(app):
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
            tok_a, uid_a = await register(c, "종화", "rep-device-a")
            tok_b, uid_b = await register(c, "종혁", "rep-device-b")
            tok_c, uid_c = await register(c, "제삼자", "rep-device-c")
            A = {"Authorization": f"Bearer {tok_a}"}
            B = {"Authorization": f"Bearer {tok_b}"}
            C = {"Authorization": f"Bearer {tok_c}"}

            gr = (await c.post("/v1/groups", json={"name": "우리집", "pet_name": "삐삐"}, headers=A)).json()
            gid = gr["group"]["id"]
            await c.post("/v1/groups/join", json={"invite_code": gr["group"]["invite_code"]}, headers=B)

            # ================= 2026-05: 집계 + 최고의 낙서(답장 수) =================
            d1 = await post_doodle(c, A, ctype="drawing", n_strokes=2)   # 답장 1개 달림
            d2 = await post_doodle(c, A, ctype="photo")
            d3 = await post_doodle(c, A, ctype="text", text_body="글1")
            d5 = await post_doodle(c, B, ctype="photo")
            d4 = await post_doodle(c, A, ctype="drawing", mode="ephemeral", n_strokes=1)
            r1 = await post_doodle(c, B, ctype="drawing", parent_id=d1, n_strokes=1)

            # 사라지기 d4 를 만료(soft delete) — 집계엔 남고 최고의 낙서 후보에선 빠져야 한다
            await services.expire_doodle(int(d4))

            for row, day in [(d1, 10), (d2, 11), (d3, 12), (d5, 13), (d4, 14), (r1, 15)]:
                set_created("doodles", row, f"2026-05-{day:02d} 10:00:00")

            # 경계: 4월 말 / 6월 초 낙서는 5월 집계에서 빠져야 한다
            d_apr = await post_doodle(c, A, ctype="text", text_body="4월")
            d_jun = await post_doodle(c, A, ctype="text", text_body="6월")
            set_created("doodles", d_apr, "2026-04-30 23:59:59")
            set_created("doodles", d_jun, "2026-06-01 00:00:00")

            # 찌르기: 5월에 2개, 6월에 1개
            await c.post(f"/v1/groups/{gid}/pokes", json={"to_user_id": str(uid_b)}, headers=A)
            await c.post(f"/v1/groups/{gid}/pokes", json={"to_user_id": str(uid_b)}, headers=A)
            sql_exec("UPDATE pokes SET created_at='2026-05-20 10:00:00' WHERE group_id=:g", g=int(gid))
            await c.post(f"/v1/groups/{gid}/pokes", json={"to_user_id": str(uid_a)}, headers=B)
            sql_exec(
                "UPDATE pokes SET created_at='2026-06-05 10:00:00' "
                "WHERE group_id=:g AND created_at >= '2026-07-01'", g=int(gid))

            set_pet_level(gid, 4)
            gen = await c.post(f"/v1/groups/{gid}/reports/2026-05/generate", headers=A)
            check("레포트 생성 200", gen.status_code == 200, gen.text[:200])
            j = gen.json()
            check("photo_count=2", j["photo_count"] == 2, str(j))
            check("★ drawing_count=3 (만료된 사라지기 포함)", j["drawing_count"] == 3, str(j))
            check("text_count=1 (4·6월 경계 제외)", j["text_count"] == 1, str(j))
            check("poke_count=2 (6월 제외)", j["poke_count"] == 2, str(j))
            check("dominant_type=drawing", j["dominant_type"] == "drawing", str(j["dominant_type"]))
            check("pet_level_end=4", j["pet_level_end"] == 4, str(j))
            check("첫 달이라 pet_level_start=end", j["pet_level_start"] == 4, str(j))

            b = j["best_doodle"]
            check("최고의 낙서 존재", b is not None, str(j))
            check("★ 최고=답장 달린 d1", b and b["id"] == str(d1), f"{b} vs d1={d1}")
            check("rule=most_replies", b and b["rule"] == "most_replies", str(b))
            check("최고의 낙서 content_type=drawing", b and b["content_type"] == "drawing", str(b))
            check("drawing 승자는 drawing_url 채움", b and b["drawing_url"], str(b))
            check("drawing 승자는 photo_url null", b and b["photo_url"] is None, str(b))
            check("drawing 승자는 thumb_url 채움", b and b["thumb_url"], str(b))
            check("★ 만료된 d4 는 최고가 아니다", b and b["id"] != str(d4))

            # ================= 최고의 낙서: 획 수 tie-break (2026-03) =================
            d6 = await post_doodle(c, A, ctype="drawing", n_strokes=1)
            d7 = await post_doodle(c, A, ctype="drawing", n_strokes=3)
            set_created("doodles", d6, "2026-03-05 10:00:00")
            set_created("doodles", d7, "2026-03-06 10:00:00")
            j3 = (await c.post(f"/v1/groups/{gid}/reports/2026-03/generate", headers=A)).json()
            check("★ 답장 동률이면 획 수로: d7 승", j3["best_doodle"]["id"] == str(d7), str(j3["best_doodle"]))
            check("rule=most_strokes", j3["best_doodle"]["rule"] == "most_strokes", str(j3["best_doodle"]))

            # ================= 최고의 낙서: 최신 tie-break (2026-02) =================
            d8 = await post_doodle(c, A, ctype="text", text_body="ㄱ")
            d9 = await post_doodle(c, A, ctype="text", text_body="ㄴ")
            set_created("doodles", d8, "2026-02-05 10:00:00")
            set_created("doodles", d9, "2026-02-10 10:00:00")
            j2 = (await c.post(f"/v1/groups/{gid}/reports/2026-02/generate", headers=A)).json()
            check("★ 답장·획 동률이면 최신: d9 승", j2["best_doodle"]["id"] == str(d9), str(j2["best_doodle"]))
            check("rule=latest", j2["best_doodle"]["rule"] == "latest", str(j2["best_doodle"]))
            check("text 승자는 text_body 채움", j2["best_doodle"]["text_body"] == "ㄴ", str(j2["best_doodle"]))
            check("text 승자도 thumb_url 채움", bool(j2["best_doodle"]["thumb_url"]), str(j2["best_doodle"]))

            # ================= 빈 달 (2026-01) =================
            j1 = (await c.post(f"/v1/groups/{gid}/reports/2026-01/generate", headers=A)).json()
            check("빈 달 counts 0", (j1["photo_count"], j1["drawing_count"], j1["text_count"]) == (0, 0, 0), str(j1))
            check("빈 달 dominant_type=null", j1["dominant_type"] is None, str(j1))
            check("빈 달 best_doodle=null", j1["best_doodle"] is None, str(j1))
            check("빈 달 poke_count=0", j1["poke_count"] == 0, str(j1))

            # ===== 회귀(리뷰): 안 열린 사라지기 낙서는 최고의 낙서가 될 수 없다 (SPEC 6.5) =====
            # 사라지기 낙서는 열기 전엔 만료 타이머가 안 걸려 deleted_at 이 NULL 이다. mode 로
            # 명시적으로 빼지 않으면 최신 후보로 뽑혀 안 본 낙서 내용이 레포트로 새어나간다.
            eu = await post_doodle(c, A, ctype="drawing", mode="ephemeral", n_strokes=5)  # 안 봄·안 만료
            tn = await post_doodle(c, A, ctype="text", text_body="일반")
            set_created("doodles", eu, "2026-10-20 10:00:00")   # 사라지기가 더 최신
            set_created("doodles", tn, "2026-10-10 10:00:00")
            ju = (await c.post(f"/v1/groups/{gid}/reports/2026-10/generate", headers=A)).json()
            check("★ 안 열린 사라지기는 최고의 낙서가 아니다",
                  ju["best_doodle"] and ju["best_doodle"]["id"] == str(tn),
                  f"{ju['best_doodle']} (eu={eu} 이면 유출 버그)")
            check("사라지기 낙서도 집계엔 포함(drawing_count=1)", ju["drawing_count"] == 1, str(ju))

            ev = await post_doodle(c, A, ctype="photo", mode="ephemeral")  # 안 봄·안 만료
            set_created("doodles", ev, "2026-11-05 10:00:00")
            jv = (await c.post(f"/v1/groups/{gid}/reports/2026-11/generate", headers=A)).json()
            check("★ 후보가 사라지기뿐이면 best_doodle=null", jv["best_doodle"] is None, str(jv))
            check("그래도 photo_count=1 (집계 포함)", jv["photo_count"] == 1, str(jv))

            # ===== 회귀(리뷰): 동시 생성 경합이 500 이 아니라 정상 처리된다 =====
            # 5월 행을 지우고 같은 달을 두 번 동시에 생성 → 둘 다 INSERT 를 시도해 한쪽이 1062.
            # 잡아서 UPDATE 로 재시도하므로 예외 없이 끝나고 행은 하나만 남아야 한다.
            sql_exec("DELETE FROM monthly_reports WHERE group_id=:g AND report_month='2026-05'", g=int(gid))
            res = await asyncio.gather(
                services.generate_report(int(gid), "2026-05"),
                services.generate_report(int(gid), "2026-05"),
                return_exceptions=True,
            )
            check("★ 동시 생성이 예외 없이 끝난다",
                  all(not isinstance(r, Exception) for r in res), str(res))
            cnt5 = sql_scalar(
                "SELECT COUNT(*) FROM monthly_reports WHERE group_id=:g AND report_month='2026-05'",
                g=int(gid))
            check("★ 동시 생성 후에도 5월 행은 하나뿐", cnt5 == 1, str(cnt5))

            # ================= 펫 레벨 변화 연쇄 =================
            set_pet_level(gid, 5)
            await c.post(f"/v1/groups/{gid}/reports/2026-08/generate", headers=A)
            set_pet_level(gid, 8)
            j9 = (await c.post(f"/v1/groups/{gid}/reports/2026-09/generate", headers=A)).json()
            check("★ pet_level_start=지난달 end(5)", j9["pet_level_start"] == 5, str(j9))
            check("pet_level_end=현재 레벨(8)", j9["pet_level_end"] == 8, str(j9))

            # ================= 덮어쓰기(멱등) =================
            again = (await c.post(f"/v1/groups/{gid}/reports/2026-05/generate", headers=A)).json()
            check("재생성해도 집계 동일", again["drawing_count"] == 3 and again["photo_count"] == 2, str(again))
            e = create_engine(SYNC)
            with e.connect() as conn:
                cnt = conn.execute(text(
                    "SELECT COUNT(*) FROM monthly_reports WHERE group_id=:g AND report_month='2026-05'"
                ), {"g": int(gid)}).scalar()
            e.dispose()
            check("★ 덮어쓰기라 5월 행은 하나뿐", cnt == 1, str(cnt))

            # ================= 조회 =================
            one = await c.get(f"/v1/groups/{gid}/reports/2026-05", headers=B)
            check("단건 조회 200", one.status_code == 200 and one.json()["report_month"] == "2026-05", one.text[:120])
            lst = (await c.get(f"/v1/groups/{gid}/reports", headers=A)).json()["items"]
            months = [it["report_month"] for it in lst]
            check("목록에 생성한 달들이 있다", {"2026-05", "2026-03", "2026-02", "2026-01"} <= set(months), str(months))
            check("★ 목록은 최신월 내림차순", months == sorted(months, reverse=True), str(months))

            # ================= 에러 =================
            check("없는 달 조회 404", (await c.get(f"/v1/groups/{gid}/reports/2026-12", headers=A)).status_code == 404)
            r13 = await c.get(f"/v1/groups/{gid}/reports/2026-13", headers=A)
            check("잘못된 달 형식 400", r13.status_code == 400, str(r13.status_code))
            rgen13 = await c.post(f"/v1/groups/{gid}/reports/2026-13/generate", headers=A)
            check("잘못된 달 생성 400", rgen13.status_code == 400, str(rgen13.status_code))
            check("남의 그룹 레포트 목록 403", (await c.get(f"/v1/groups/{gid}/reports", headers=C)).status_code == 403)
            check("남의 그룹 레포트 생성 403",
                  (await c.post(f"/v1/groups/{gid}/reports/2026-05/generate", headers=C)).status_code == 403)
            check("토큰 없으면 401", (await c.get(f"/v1/groups/{gid}/reports")).status_code == 401)


def main() -> int:
    reset_db()
    asyncio.run(run())
    print(f"\n{pass_n}/{pass_n + fail_n} passed")
    return 1 if fail_n else 0


if __name__ == "__main__":
    raise SystemExit(main())
