"""FCM 대상·입력 검증·동시성·펫 성장 통합 회귀 테스트. 실제 MySQL 필요."""

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

MEDIA = Path(tempfile.mkdtemp(prefix="mp_hardening_"))
os.environ["MEDIA_ROOT"] = str(MEDIA)
os.environ["SCHEDULER_ENABLED"] = "false"
os.environ["EPHEMERAL_TTL_SECONDS"] = "30"
os.environ["PET_EXP_PER_LEVEL"] = "10"
os.environ["PET_DOODLE_EXP"] = "6"
os.environ["PET_REPLY_EXP"] = "4"
os.environ["PET_POKE_EXP"] = "3"
os.environ["PET_PAT_EXP"] = "1"
os.environ["PET_LEVELUP_COINS"] = "7"

import httpx  # noqa: E402
from PIL import Image  # noqa: E402
from sqlalchemy import create_engine, text  # noqa: E402

from app import notifications, services  # noqa: E402
from app.main import app  # noqa: E402
from app.notifications import PushResult  # noqa: E402

SYNC = DB_URL.replace("+asyncmy", "+pymysql").replace("+aiomysql", "+pymysql")
_TABLES = [
    "doodle_receipts",
    "doodles",
    "pokes",
    "pet_likes",
    "pet_activities",
    "pet_diaries",
    "style_models",
    "pet_items",
    "monthly_reports",
    "pets",
    "group_members",
    "groups",
    "devices",
    "auth_identities",
    "users",
]

pass_n = fail_n = 0


def check(label: str, condition: bool, detail: str = "") -> None:
    global pass_n, fail_n
    if condition:
        pass_n += 1
        print(f"  ok    {label}")
    else:
        fail_n += 1
        print(f"  FAIL  {label}  {detail}")


def reset_db() -> None:
    engine = create_engine(SYNC)
    with engine.begin() as connection:
        connection.execute(text("SET FOREIGN_KEY_CHECKS=0"))
        for table in _TABLES:
            connection.execute(text(f"TRUNCATE TABLE `{table}`"))
        connection.execute(text("SET FOREIGN_KEY_CHECKS=1"))
    engine.dispose()


def png_bytes() -> bytes:
    output = io.BytesIO()
    Image.new("RGBA", (32, 32), (50, 100, 200, 180)).save(output, "PNG")
    return output.getvalue()


class RecordingPushClient:
    def __init__(self) -> None:
        self.messages: list[tuple[list[str], dict[str, str]]] = []

    async def send(self, tokens: list[str], data: dict[str, str]) -> PushResult:
        self.messages.append((list(tokens), dict(data)))
        return PushResult(sent=len(tokens))


async def register(client, name: str, uid: str) -> tuple[str, str]:
    response = await client.post(
        "/v1/auth/register", json={"display_name": name, "device_uid": uid}
    )
    return response.json()["token"], response.json()["user"]["id"]


async def run() -> None:
    recorder = RecordingPushClient()
    transport = httpx.ASGITransport(app=app)
    async with app.router.lifespan_context(app):
        notifications.set_push_client(recorder)
        async with httpx.AsyncClient(
            transport=transport, base_url="http://test"
        ) as client:
            concurrent_register = await asyncio.gather(
                client.post(
                    "/v1/auth/register",
                    json={
                        "display_name": "동시등록",
                        "device_uid": "hardening-race-device",
                    },
                ),
                client.post(
                    "/v1/auth/register",
                    json={
                        "display_name": "동시등록",
                        "device_uid": "hardening-race-device",
                    },
                ),
            )
            check(
                "동일 device_uid 동시 등록 500 없음",
                all(item.status_code == 200 for item in concurrent_register),
                str([item.status_code for item in concurrent_register]),
            )
            check(
                "동일 device_uid는 같은 user",
                len({item.json()["user"]["id"] for item in concurrent_register}) == 1,
            )
            race_auth_results = await asyncio.gather(
                *[
                    client.get(
                        "/v1/me",
                        headers={"Authorization": f"Bearer {item.json()['token']}"},
                    )
                    for item in concurrent_register
                ]
            )
            check(
                "동시 등록 응답 중 최종 토큰 사용 가능",
                any(item.status_code == 200 for item in race_auth_results),
            )

            token_a, user_a = await register(client, "종화", "hardening-device-a")
            token_b, user_b = await register(client, "종혁", "hardening-device-b")
            auth_a = {"Authorization": f"Bearer {token_a}"}
            auth_b = {"Authorization": f"Bearer {token_b}"}

            await client.post(
                "/v1/devices", json={"fcm_token": "fcm-a"}, headers=auth_a
            )
            await client.post(
                "/v1/devices", json={"fcm_token": "fcm-b"}, headers=auth_b
            )
            device_race = await asyncio.gather(
                client.post(
                    "/v1/devices", json={"fcm_token": "fcm-race"}, headers=auth_a
                ),
                client.post(
                    "/v1/devices", json={"fcm_token": "fcm-race"}, headers=auth_b
                ),
            )
            check(
                "동일 FCM 토큰 동시 등록 500 없음",
                all(item.status_code == 204 for item in device_race),
                str([item.status_code for item in device_race]),
            )

            token_c, _ = await register(client, "그룹경합", "hardening-device-c")
            auth_c = {"Authorization": f"Bearer {token_c}"}
            group_race = await asyncio.gather(
                client.post(
                    "/v1/groups",
                    json={"name": "경합1", "pet_name": "펫1"},
                    headers=auth_c,
                ),
                client.post(
                    "/v1/groups",
                    json={"name": "경합2", "pet_name": "펫2"},
                    headers=auth_c,
                ),
            )
            check(
                "동일 유저 그룹 동시 생성은 201/409",
                sorted(item.status_code for item in group_race) == [201, 409],
                str([item.status_code for item in group_race]),
            )

            created = await client.post(
                "/v1/groups",
                json={"name": "우리집", "pet_name": "삐삐"},
                headers=auth_a,
            )
            group = created.json()["group"]
            group_id = group["id"]
            pet_id = created.json()["pet"]["id"]
            await client.post(
                "/v1/groups/join",
                json={"invite_code": group["invite_code"]},
                headers=auth_b,
            )

            doodle = await client.post(
                "/v1/doodles",
                data={"mode": "normal", "content_type": "text", "text_body": "안녕"},
                headers=auth_a,
            )
            check("일반 낙서 201", doodle.status_code == 201, doodle.text[:100])
            check(
                "FCM 낙서는 상대 기기만",
                "fcm-b" in recorder.messages[-1][0]
                and "fcm-a" not in recorder.messages[-1][0]
                and recorder.messages[-1][1]["type"] == "doodle_received",
                str(recorder.messages[-1]),
            )
            listing = await client.get(f"/v1/groups/{group_id}/doodles", headers=auth_a)
            check(
                "보낸 사람 목록 viewed_by_me=true",
                listing.json()["items"][0]["viewed_by_me"] is True,
            )

            invalid_parent = await client.post(
                "/v1/doodles",
                data={
                    "mode": "normal",
                    "content_type": "text",
                    "text_body": "답장",
                    "parent_id": "abc",
                },
                headers=auth_a,
            )
            check(
                "잘못된 parent_id 400",
                invalid_parent.status_code == 400,
                invalid_parent.text,
            )
            check(
                "잘못된 before 400",
                (
                    await client.get(
                        f"/v1/groups/{group_id}/doodles?before=abc", headers=auth_a
                    )
                ).status_code
                == 400,
            )
            check(
                "잘못된 poke ID 400",
                (
                    await client.post(
                        f"/v1/groups/{group_id}/pokes",
                        json={"to_user_id": "abc"},
                        headers=auth_a,
                    )
                ).status_code
                == 400,
            )
            check(
                "범위 밖 report_month 400",
                (
                    await client.get(
                        f"/v1/groups/{group_id}/reports/0000-01", headers=auth_a
                    )
                ).status_code
                == 400,
            )

            broken = await client.post(
                "/v1/doodles",
                data={"mode": "normal", "content_type": "photo"},
                files={"photo": ("fake.jpg", b"not-an-image", "image/jpeg")},
                headers=auth_a,
            )
            check("손상 이미지 422", broken.status_code == 422, broken.text)

            invalid_strokes = json.dumps(
                {
                    "canvas": {"w": 100, "h": 100},
                    "duration_ms": 100,
                    "strokes": [
                        {
                            "pen": "marker",
                            "color": "not-hex",
                            "width": 3,
                            "points": [[1, 2, 0]],
                        }
                    ],
                }
            )
            malformed_drawing = await client.post(
                "/v1/doodles",
                data={
                    "mode": "normal",
                    "content_type": "drawing",
                    "stroke_data": invalid_strokes,
                },
                files={"drawing": ("drawing.png", png_bytes(), "image/png")},
                headers=auth_a,
            )
            check("잘못된 stroke_data 422", malformed_drawing.status_code == 422)

            missing_mode = await client.post(
                "/v1/doodles",
                data={"content_type": "text", "text_body": "mode 없음"},
                headers=auth_a,
            )
            check("필수 mode 누락 400", missing_mode.status_code == 400)

            oversized_text = await client.post(
                "/v1/doodles",
                data={
                    "mode": "normal",
                    "content_type": "text",
                    "text_body": "x" * 4001,
                },
                headers=auth_a,
            )
            check("과대 text_body 422", oversized_text.status_code == 422)

            photo = await client.post(
                "/v1/doodles",
                data={"mode": "normal", "content_type": "photo"},
                files={"photo": ("photo.png", png_bytes(), "image/png")},
                headers=auth_a,
            )
            check("PNG 사진 201", photo.status_code == 201, photo.text[:100])
            check(
                "PNG 확장자 보존",
                photo.json()["photo_url"].endswith(".png"),
                photo.json()["photo_url"],
            )

            poke = await client.post(
                f"/v1/groups/{group_id}/pokes",
                json={"to_user_id": user_b},
                headers=auth_a,
            )
            check("찌르기 204", poke.status_code == 204)
            check(
                "FCM 찌르기는 대상 기기만",
                "fcm-b" in recorder.messages[-1][0]
                and "fcm-a" not in recorder.messages[-1][0]
                and recorder.messages[-1][1]["type"] == "poke",
                str(recorder.messages[-1]),
            )

            # exp: 일반 낙서 6 + 사진 6 + 찌르기 3 = 15 -> level 2.
            # 코인: 레벨업 보너스 7 + 활동별 코인(낙서 2건 × 3, #12) = 13.
            #   찌르기는 활동 코인을 주지 않는다(연타 파밍 방지).
            pet = (
                await client.get(f"/v1/groups/{group_id}/pet", headers=auth_a)
            ).json()
            check("누적 exp로 레벨업", pet["exp"] == 15 and pet["level"] == 2, str(pet))
            check("레벨업 7 + 활동 코인 6 = 13", pet["coins"] == 13, str(pet))

            before_exp = pet["exp"]
            results = await asyncio.gather(
                *[
                    client.post(f"/v1/pets/{pet_id}/pat", headers=auth_a)
                    for _ in range(12)
                ]
            )
            check("동시 pat 모두 200", all(item.status_code == 200 for item in results))
            after = (
                await client.get(f"/v1/groups/{group_id}/pet", headers=auth_a)
            ).json()
            check("동시 pat exp 손실 없음", after["exp"] == before_exp + 12, str(after))

            ephemeral = await client.post(
                "/v1/doodles",
                data={"mode": "ephemeral", "content_type": "text", "text_body": "5초"},
                headers=auth_a,
            )
            ephemeral_id = ephemeral.json()["id"]
            views = await asyncio.gather(
                client.post(f"/v1/doodles/{ephemeral_id}/view", headers=auth_b),
                client.post(f"/v1/doodles/{ephemeral_id}/view", headers=auth_b),
            )
            check(
                "동시 확인 둘 다 200",
                all(item.status_code == 200 for item in views),
                str([v.status_code for v in views]),
            )
            check(
                "동시 확인 expires_at 동일",
                views[0].json() == views[1].json(),
                str([v.json() for v in views]),
            )

            # 서로 다른 낙서를 두 사람이 동시에 처음 확인해도 receipt 유니크 인덱스
            # 갭 잠금 데드락(1213)이 없어야 한다. 낙서 행 잠금만으로 직렬화된다.
            cross_x = await client.post(
                "/v1/doodles",
                data={"mode": "ephemeral", "content_type": "text", "text_body": "X"},
                headers=auth_a,
            )
            cross_y = await client.post(
                "/v1/doodles",
                data={"mode": "ephemeral", "content_type": "text", "text_body": "Y"},
                headers=auth_b,
            )
            cross_views = await asyncio.gather(
                client.post(f"/v1/doodles/{cross_x.json()['id']}/view", headers=auth_b),
                client.post(f"/v1/doodles/{cross_y.json()['id']}/view", headers=auth_a),
            )
            check(
                "서로 다른 낙서 동시 최초확인 데드락 없음",
                all(item.status_code == 200 for item in cross_views),
                str([v.status_code for v in cross_views]),
            )

            await services.expire_doodle(int(ephemeral_id))
            check(
                "만료 후 widget_refresh는 두 기기",
                recorder.messages[-1][1]["type"] == "widget_refresh"
                and {"fcm-a", "fcm-b"} <= set(recorder.messages[-1][0]),
                str(recorder.messages[-1]),
            )

            await services.generate_report(int(group_id), "2026-07", notify=True)
            check(
                "월간 레포트 FCM은 두 기기",
                recorder.messages[-1][1]
                == {
                    "type": "monthly_report",
                    "report_month": "2026-07",
                }
                and {"fcm-a", "fcm-b"} <= set(recorder.messages[-1][0]),
                str(recorder.messages[-1]),
            )


def main() -> int:
    reset_db()
    asyncio.run(run())
    print(f"\n{pass_n}/{pass_n + fail_n} passed")
    return 1 if fail_n else 0


if __name__ == "__main__":
    raise SystemExit(main())
