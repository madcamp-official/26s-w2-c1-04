"""사진첩 AI 큐레이션(#6) 통합 테스트. **실제 MySQL 이 필요하다.**

    export DATABASE_URL='mysql+asyncmy://root:root@127.0.0.1:3306/memory_pager?charset=utf8mb4'
    python backend/tests/test_albums_integration.py

GPU_ENABLED=false 로 강제해 큐레이션이 결정적 휴리스틱(키워드) 스텁을 타게 한다.
낙서 캡션/본문을 주제별로 묶고, 3건 미만이면 빈 목록임을 검증한다.
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

os.environ["GPU_ENABLED"] = "false"  # 결정적 휴리스틱 스텁으로 큐레이션

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


def send_text(c, headers, body: str) -> None:
    r = c.post(
        "/v1/doodles",
        data={"mode": "normal", "content_type": "text", "text_body": body},
        headers=headers,
    )
    assert r.status_code in (200, 201), r.text[:150]


def main() -> int:
    reset_db()
    with TestClient(app) as c:
        ra = c.post("/v1/auth/register", json={"display_name": "A", "device_uid": "device-aaaa"})
        A = {"Authorization": f"Bearer {ra.json()['token']}"}
        gid = c.post("/v1/groups", json={"name": "우리집", "pet_name": "삐삐"}, headers=A).json()["group"]["id"]

        # 낙서 1건 → 큐레이션 안 함(3건 미만)
        send_text(c, A, "오늘 맛집 갔다")
        r = c.get(f"/v1/groups/{gid}/albums", headers=A)
        check("낙서 부족 시 앨범 없음", r.status_code == 200 and r.json()["albums"] == [], r.text[:120])

        # 주제별 낙서 축적
        send_text(c, A, "떡볶이 먹음 최고")       # 맛
        send_text(c, A, "하늘이 너무 예뻐")        # 풍경
        send_text(c, A, "노을 보러 바다 감")       # 풍경
        send_text(c, A, "공원 산책 데이트")        # 나들이
        send_text(c, A, "축제 나들이 갔어")        # 나들이

        r = c.get(f"/v1/groups/{gid}/albums", headers=A)
        albums = r.json()["albums"]
        titles = {a["title"] for a in albums}
        check("앨범 200", r.status_code == 200, str(r.status_code))
        check("주제 앨범 생성됨(>=2개)", len(albums) >= 2, str(titles))
        check("'맛있는 날' 앨범", "맛있는 날" in titles, str(titles))
        check("'우리의 풍경' 앨범", "우리의 풍경" in titles, str(titles))
        check("'함께한 나들이' 앨범", "함께한 나들이" in titles, str(titles))
        # 각 앨범은 2건 이상, doodle_ids/count 일치
        ok_counts = all(a["count"] == len(a["doodle_ids"]) and a["count"] >= 2 for a in albums)
        check("각 앨범 count==len(ids)>=2", ok_counts, str([(a["title"], a["count"]) for a in albums]))
        # 풍경 앨범엔 3건(하늘·노을·바다는 한 낙서라 2건: 하늘, 노을바다)
        scenery = next((a for a in albums if a["title"] == "우리의 풍경"), None)
        check("풍경 앨범 2건 이상", scenery and scenery["count"] >= 2, str(scenery))

    print(f"\n{pass_n}/{pass_n + fail_n} passed")
    return 1 if fail_n else 0


if __name__ == "__main__":
    raise SystemExit(main())
