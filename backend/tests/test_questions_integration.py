"""오늘의 질문(E-1) 통합 테스트. **실제 MySQL 필요.**

    export DATABASE_URL='mysql+asyncmy://root:root@127.0.0.1:3306/memory_pager?charset=utf8mb4'
    python backend/tests/test_questions_integration.py
"""

from __future__ import annotations

import asyncio
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

os.environ["MEDIA_ROOT"] = str(Path(tempfile.mkdtemp(prefix="mp_q_")))
os.environ["SCHEDULER_ENABLED"] = "false"
os.environ["GPU_ENABLED"] = "false"

import logging  # noqa: E402

logging.disable(logging.CRITICAL)

import httpx  # noqa: E402
from sqlalchemy import create_engine, text  # noqa: E402

from app.main import app  # noqa: E402
from app.routers.questions import _today_kst, question_for  # noqa: E402

SYNC = DB_URL.replace("+asyncmy", "+pymysql").replace("+aiomysql", "+pymysql")
_TABLES = [
    "question_answers", "doodle_receipts", "doodles", "pokes", "pet_likes",
    "pet_activities", "pet_diaries", "style_models", "pet_items", "monthly_reports",
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


async def register(c, name, uid):
    r = await c.post("/v1/auth/register", json={"display_name": name, "device_uid": uid})
    return r.json()["token"], r.json()["user"]["id"]


async def run() -> None:
    transport = httpx.ASGITransport(app=app)
    async with app.router.lifespan_context(app):
        async with httpx.AsyncClient(transport=transport, base_url="http://test") as c:
            tok_a, uid_a = await register(c, "지우", "q-device-aaa")
            tok_b, uid_b = await register(c, "나무", "q-device-bbb")
            tok_c, _ = await register(c, "제삼자", "q-device-ccc")
            A = {"Authorization": f"Bearer {tok_a}"}
            B = {"Authorization": f"Bearer {tok_b}"}
            C = {"Authorization": f"Bearer {tok_c}"}

            gr = (await c.post("/v1/groups", json={"name": "우리집", "pet_name": "모리"}, headers=A)).json()
            gid = gr["group"]["id"]
            await c.post("/v1/groups/join", json={"invite_code": gr["group"]["invite_code"]}, headers=B)

            today = _today_kst().isoformat()
            expected = question_for(_today_kst())

            # --- 최초 조회: 아무도 안 답함 ---
            q = await c.get(f"/v1/groups/{gid}/question/today", headers=A)
            check("질문 조회 200", q.status_code == 200, q.text[:120])
            j = q.json()
            check("오늘 날짜", j["date"] == today, str(j["date"]))
            check("질문 텍스트가 코드 풀과 일치", j["text"] == expected, str(j["text"]))
            check("내 답변 없음(null)", j["my_answer"] is None, str(j))
            check("상대 미답변", j["partner_answered"] is False, str(j))

            # --- A 답변 저장 ---
            r = await c.post(f"/v1/groups/{gid}/question/today", json={"answer": "억새밭 첫 데이트"}, headers=A)
            check("답변 저장 200", r.status_code == 200, r.text[:120])
            check("저장 후 my_answer 반영", r.json()["my_answer"] == "억새밭 첫 데이트", str(r.json()))

            # --- B 시점: 내 답변 없음, 상대(A)는 답함 ---
            qb = (await c.get(f"/v1/groups/{gid}/question/today", headers=B)).json()
            check("★ B 시점 partner_answered=True", qb["partner_answered"] is True, str(qb))
            check("B 자기 답변은 아직 null", qb["my_answer"] is None, str(qb))
            check("★ 상대 답변 원문은 노출 안 함", "억새밭" not in str(qb), str(qb))

            # --- A 재답변(수정) ---
            r2 = await c.post(f"/v1/groups/{gid}/question/today", json={"answer": "수정된 답"}, headers=A)
            check("★ 재답변으로 수정됨", r2.json()["my_answer"] == "수정된 답", str(r2.json()))
            cnt = None
            e = create_engine(SYNC)
            with e.connect() as conn:
                cnt = conn.execute(text(
                    "SELECT COUNT(*) FROM question_answers WHERE group_id=:g AND user_id=:u"
                ), {"g": int(gid), "u": int(uid_a)}).scalar()
            e.dispose()
            check("★ 수정이지 새 행 아님(행 1개)", cnt == 1, str(cnt))

            # --- 둘 다 답한 뒤 ---
            await c.post(f"/v1/groups/{gid}/question/today", json={"answer": "나도 억새밭"}, headers=B)
            qa2 = (await c.get(f"/v1/groups/{gid}/question/today", headers=A)).json()
            check("둘 다 답하면 A도 partner_answered=True", qa2["partner_answered"] is True, str(qa2))

            # --- 권한 ---
            check("남의 그룹 조회 403", (await c.get(f"/v1/groups/{gid}/question/today", headers=C)).status_code == 403)
            check("남의 그룹 답변 403", (await c.post(f"/v1/groups/{gid}/question/today", json={"answer": "x"}, headers=C)).status_code == 403)
            check("빈 답변 400", (await c.post(f"/v1/groups/{gid}/question/today", json={"answer": ""}, headers=A)).status_code == 400)
            check("토큰 없으면 401", (await c.get(f"/v1/groups/{gid}/question/today")).status_code == 401)


def main() -> int:
    reset_db()
    asyncio.run(run())
    print(f"\n{pass_n}/{pass_n + fail_n} passed")
    return 1 if fail_n else 0


if __name__ == "__main__":
    raise SystemExit(main())
