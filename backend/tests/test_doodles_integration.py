"""낙서 + 사라지기 모드 + 찌르기 통합 테스트. **실제 MySQL 이 필요하다.**

    export DATABASE_URL='mysql+asyncmy://root:root@127.0.0.1:3306/memory_pager?charset=utf8mb4'
    python backend/tests/test_doodles_integration.py

과제 주 옵션(실시간)의 서버 쪽이 여기서 검증된다. 특히:
- 최초 확인일 때만 타이머를 건다 (재확인이 만료를 무한 연장하지 않는다)
- 보낸 사람이 자기 낙서를 열어도 타이머가 걸리지 않는다
- 만료되면 soft delete + 미디어 파일 실제 삭제 + 410
- 재기동 시 부팅 스윕이 지난 것을 정리한다
"""

from __future__ import annotations

import io
import json
import os
import sys
import tempfile
import time
import warnings
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
warnings.filterwarnings("ignore")

DB_URL = os.environ.get("DATABASE_URL")
if not DB_URL:
    print("DATABASE_URL 이 없어 건너뜀 (실제 MySQL 필요)")
    raise SystemExit(0)

TTL = 2.0
MEDIA = Path(tempfile.mkdtemp(prefix="mp_media_"))
os.environ["EPHEMERAL_TTL_SECONDS"] = str(TTL)
os.environ["MEDIA_ROOT"] = str(MEDIA)

import logging  # noqa: E402

logging.disable(logging.CRITICAL)

from fastapi.testclient import TestClient  # noqa: E402
from PIL import Image  # noqa: E402
from sqlalchemy import create_engine, text  # noqa: E402

from app.main import app  # noqa: E402

SYNC = DB_URL.replace("+asyncmy", "+pymysql").replace("+aiomysql", "+pymysql")
_TABLES = [
    "doodle_receipts", "doodles", "pokes", "pet_likes", "pet_activities",
    "pet_diaries", "style_models", "pet_items", "monthly_reports",
    "pets", "group_members", "groups", "devices", "auth_identities", "users",
]

pass_n = fail_n = 0


def check(label: str, cond: bool, detail: str = "") -> None:
    global pass_n, fail_n
    if cond:
        pass_n += 1
        print(f"  ok    {label}")
    else:
        fail_n += 1
        print(f"  FAIL  {label}  {detail}")


def reset_db() -> None:
    e = create_engine(SYNC)
    with e.begin() as conn:
        conn.execute(text("SET FOREIGN_KEY_CHECKS=0"))
        for t in _TABLES:
            conn.execute(text(f"TRUNCATE TABLE `{t}`"))
        conn.execute(text("SET FOREIGN_KEY_CHECKS=1"))
    e.dispose()


def png_bytes(color=(255, 0, 0, 128)) -> bytes:
    buf = io.BytesIO()
    Image.new("RGBA", (64, 64), color).save(buf, "PNG")
    return buf.getvalue()


def jpg_bytes() -> bytes:
    buf = io.BytesIO()
    Image.new("RGB", (128, 96), (10, 200, 90)).save(buf, "JPEG")
    return buf.getvalue()


STROKES = json.dumps({
    "canvas": {"w": 1080, "h": 1080},
    "duration_ms": 12480,
    "strokes": [{"pen": "marker", "color": "FF5A5F", "width": 6,
                 "points": [[120, 340, 0], [124, 351, 16], [131, 366, 33]]}],
})


def register(c, name, uid):
    r = c.post("/v1/auth/register", json={"display_name": name, "device_uid": uid})
    return r.json()["token"], r.json()["user"]["id"]


def code_of(r):
    try:
        return r.json()["error"]["code"]
    except Exception:
        return None


def main() -> int:
    reset_db()
    with TestClient(app) as c:
        tok_a, uid_a = register(c, "종화", "dev-aaaa")
        tok_b, uid_b = register(c, "종혁", "dev-bbbb")
        tok_c, _ = register(c, "제삼자", "dev-cccc")
        A = {"Authorization": f"Bearer {tok_a}"}
        B = {"Authorization": f"Bearer {tok_b}"}
        C = {"Authorization": f"Bearer {tok_c}"}

        g = c.post("/v1/groups", json={"name": "우리집", "pet_name": "삐삐"}, headers=A).json()["group"]
        gid, invite = g["id"], g["invite_code"]
        c.post("/v1/groups/join", json={"invite_code": invite}, headers=B)

        # --- 그룹 없는 유저는 낙서를 못 보낸다 --------------------------------
        r = c.post("/v1/doodles", data={"mode": "normal", "content_type": "text", "text_body": "hi"}, headers=C)
        check("그룹 없이 전송 400", r.status_code == 400, str(r.status_code))

        # --- 손그림 (SD-5) -------------------------------------------------
        r = c.post("/v1/doodles",
                   data={"mode": "normal", "content_type": "drawing", "stroke_data": STROKES},
                   files={"drawing": ("d.png", png_bytes(), "image/png")}, headers=A)
        check("손그림 전송 201", r.status_code == 201, r.text[:120])
        d1 = r.json()
        check("thumb_url 이 null 이 아니다 (손그림)", bool(d1["thumb_url"]), str(d1["thumb_url"]))
        check("썸네일 파일이 실제로 생성됨", (MEDIA / f"g{gid}" / f"{d1['id']}_thumb.jpg").exists())
        check("보낸 사람은 viewed_by_me=true", d1["viewed_by_me"] is True)

        # stroke_data 없이 손그림 -> 422
        r = c.post("/v1/doodles", data={"mode": "normal", "content_type": "drawing"},
                   files={"drawing": ("d.png", png_bytes(), "image/png")}, headers=A)
        check("stroke_data 없는 손그림 422", r.status_code == 422 and code_of(r) == "unprocessable", str(r.status_code))

        # --- 텍스트 낙서: 원본 이미지가 없어도 썸네일이 생긴다 ----------------
        r = c.post("/v1/doodles", data={"mode": "normal", "content_type": "text", "text_body": "오늘 뭐해?"}, headers=A)
        d_text = r.json()
        check("텍스트 낙서 201", r.status_code == 201, r.text[:80])
        check("텍스트도 썸네일이 렌더됨", (MEDIA / f"g{gid}" / f"{d_text['id']}_thumb.jpg").exists())

        # --- 사진 낙서 -------------------------------------------------------
        r = c.post("/v1/doodles", data={"mode": "normal", "content_type": "photo"},
                   files={"photo": ("p.jpg", jpg_bytes(), "image/jpeg")}, headers=A)
        d_photo = r.json()
        check("사진 낙서 201", r.status_code == 201)
        check("사진 썸네일 생성", (MEDIA / f"g{gid}" / f"{d_photo['id']}_thumb.jpg").exists())

        # --- 답장 (RV-1) -----------------------------------------------------
        r = c.post("/v1/doodles",
                   data={"mode": "normal", "content_type": "text", "text_body": "산책!", "parent_id": d1["id"]},
                   headers=B)
        check("답장 201", r.status_code == 201, r.text[:80])
        check("답장 후 원본 reply_count=1", c.get(f"/v1/doodles/{d1['id']}", headers=A).json()["reply_count"] == 1)

        # --- 사진첩 (RV-2, RV-3) ---------------------------------------------
        lst = c.get(f"/v1/groups/{gid}/doodles", headers=B).json()
        check("사진첩 4건, 최신순", len(lst["items"]) == 4 and lst["items"][0]["id"] > lst["items"][-1]["id"], str(len(lst["items"])))
        check("빈 목록이 아니면 next_before 는 null (limit 미달)", lst["next_before"] is None)
        only_text = c.get(f"/v1/groups/{gid}/doodles?content_type=text", headers=B).json()
        check("유형 필터", all(i["content_type"] == "text" for i in only_text["items"]) and len(only_text["items"]) == 2)
        r = c.get(f"/v1/groups/{gid}/doodles", headers=C)
        check("남의 그룹 사진첩 403", r.status_code == 403)

        # --- 사라지기 모드 (SD-6) ★ -----------------------------------------
        r = c.post("/v1/doodles",
                   data={"mode": "ephemeral", "content_type": "drawing", "stroke_data": STROKES},
                   files={"drawing": ("e.png", png_bytes(), "image/png")}, headers=A)
        eph = r.json()
        eid = eph["id"]
        check("사라지기 낙서 전송 201", r.status_code == 201)
        check("전송 직후 expires_at 은 null", eph["expires_at"] is None)

        locked = c.get(f"/v1/doodles/{eid}", headers=B).json()
        check("미열람 사라지기 단건은 내용을 숨김",
              locked["drawing_url"] is None and locked["thumb_url"] is None,
              str(locked))
        locked_list = c.get(f"/v1/groups/{gid}/doodles", headers=B).json()
        locked_item = next(item for item in locked_list["items"] if item["id"] == eid)
        check("미열람 사라지기 목록도 내용을 숨김",
              locked_item["drawing_url"] is None and locked_item["thumb_url"] is None,
              str(locked_item))

        # 보낸 사람이 열어도 타이머가 걸리면 안 된다
        r = c.post(f"/v1/doodles/{eid}/view", headers=A)
        check("보낸 사람이 열면 expires_at 없음", r.json()["expires_at"] is None, str(r.json()))

        # 수신자 최초 확인 -> 타이머 무장
        view_started = datetime.now(timezone.utc)
        r = c.post(f"/v1/doodles/{eid}/view", headers=B)
        view_finished = datetime.now(timezone.utc)
        exp1 = r.json()["expires_at"]
        check("수신자 최초 확인 -> expires_at 세팅", exp1 is not None, str(r.json()))
        expires = datetime.fromisoformat(exp1.replace("Z", "+00:00"))
        from_start = (expires - view_started).total_seconds()
        from_finish = (expires - view_finished).total_seconds()
        check("만료 시각은 실제 열람 후 정확히 TTL",
              TTL - 0.05 <= from_start <= TTL + 0.5
              and TTL - 0.5 <= from_finish <= TTL + 0.05,
              f"start={from_start:.3f}s finish={from_finish:.3f}s")
        revealed = c.get(f"/v1/doodles/{eid}", headers=B).json()
        check("열람 뒤 사라지기 내용 공개",
              bool(revealed["drawing_url"]) and bool(revealed["thumb_url"]),
              str(revealed))

        # ★ 재확인이 타이머를 리셋하면 안 된다
        time.sleep(0.4)
        r = c.post(f"/v1/doodles/{eid}/view", headers=B)
        exp2 = r.json()["expires_at"]
        check("재확인해도 expires_at 이 그대로 (타이머 리셋 없음)", exp1 == exp2, f"{exp1} vs {exp2}")

        draw_file = MEDIA / f"g{gid}" / f"{eid}_draw.png"
        check("만료 전에는 파일이 있다", draw_file.exists())

        time.sleep(TTL + 1.0)

        r = c.get(f"/v1/doodles/{eid}", headers=B)
        check("만료 후 410 doodle_expired", r.status_code == 410 and code_of(r) == "doodle_expired", f"{r.status_code} {code_of(r)}")
        check("만료 후 미디어 파일이 지워짐", not draw_file.exists())
        lst = c.get(f"/v1/groups/{gid}/doodles", headers=B).json()
        check("만료된 낙서는 사진첩에서 빠짐", all(i["id"] != eid for i in lst["items"]))

        # 없는 id 는 404 (410 과 구분)
        check("없는 id 는 404", c.get("/v1/doodles/999999", headers=B).status_code == 404)

        # --- 찌르기 (SD-7) ---------------------------------------------------
        check("찌르기 204", c.post(f"/v1/groups/{gid}/pokes", json={"to_user_id": uid_b}, headers=A).status_code == 204)
        r = c.post(f"/v1/groups/{gid}/pokes", json={"to_user_id": uid_a}, headers=A)
        check("자기 자신 찌르기 400", r.status_code == 400, str(r.status_code))
        r = c.post(f"/v1/groups/{gid}/pokes", json={"to_user_id": uid_b}, headers=C)
        check("남의 그룹 찌르기 403", r.status_code == 403, str(r.status_code))

    # --- 부팅 스윕: 서버가 죽은 사이 만료 시각이 지난 낙서 ---------------------
    e = create_engine(SYNC)
    with e.begin() as conn:
        conn.execute(text(
            "INSERT INTO doodles (id, group_id, sender_id, mode, content_type, expires_at, created_at) "
            "VALUES (777, :g, :s, 'ephemeral', 'drawing', DATE_SUB(UTC_TIMESTAMP(), INTERVAL 10 SECOND), UTC_TIMESTAMP())"
        ), {"g": int(gid), "s": int(uid_a)})
    with TestClient(app) as c:   # lifespan 이 boot_sweep 을 부른다
        time.sleep(0.3)
        r = c.get("/v1/doodles/777", headers=A)
        check("부팅 스윕이 지난 낙서를 만료시킴 (410)", r.status_code == 410, str(r.status_code))
    with e.begin() as conn:
        row = conn.execute(text("SELECT deleted_at FROM doodles WHERE id=777")).fetchone()
    check("deleted_at 이 채워짐", row is not None and row[0] is not None, str(row))
    e.dispose()

    print(f"\n{pass_n}/{pass_n + fail_n} passed")
    return 1 if fail_n else 0


if __name__ == "__main__":
    raise SystemExit(main())
