"""실행 중인 서버에 실제 WebSocket으로 붙는 Socket.IO E2E 테스트.

    E2E_BASE_URL=http://127.0.0.1:8000 python backend/tests/test_realtime_e2e.py

환경변수가 없으면 건너뛴다. DB를 비우지 않고 고유한 데모 유저를 추가한다.
"""

from __future__ import annotations

import asyncio
import os
import time
import uuid

BASE_URL = os.environ.get("E2E_BASE_URL")
if not BASE_URL:
    print("E2E_BASE_URL 이 없어 건너뜀 (실행 중인 서버 필요)")
    raise SystemExit(0)

import httpx  # noqa: E402
import socketio  # noqa: E402

pass_n = fail_n = 0


def check(label: str, condition: bool, detail: str = "") -> None:
    global pass_n, fail_n
    if condition:
        pass_n += 1
        print(f"  ok    {label}")
    else:
        fail_n += 1
        print(f"  FAIL  {label}  {detail}")


async def run() -> None:
    nonce = uuid.uuid4().hex
    async with httpx.AsyncClient(base_url=BASE_URL, timeout=10) as client:

        async def register(name: str, suffix: str) -> tuple[str, str]:
            response = await client.post(
                "/v1/auth/register",
                json={"display_name": name, "device_uid": f"e2e-{suffix}-{nonce}"},
            )
            return response.json()["token"], response.json()["user"]["id"]

        token_a, user_a = await register("소켓A", "a")
        token_b, user_b = await register("소켓B", "b")
        auth_a = {"Authorization": f"Bearer {token_a}"}
        auth_b = {"Authorization": f"Bearer {token_b}"}
        created = await client.post(
            "/v1/groups",
            json={"name": "소켓 E2E", "pet_name": "핑"},
            headers=auth_a,
        )
        group = created.json()["group"]
        await client.post(
            "/v1/groups/join",
            json={"invite_code": group["invite_code"]},
            headers=auth_b,
        )

        socket_a = socketio.AsyncClient(reconnection=False)
        socket_b = socketio.AsyncClient(reconnection=False)
        poke_received = asyncio.Event()
        expired_received = asyncio.Event()
        received_poke: dict = {}
        received_expiry: dict = {}

        @socket_b.on("poke", namespace="/rt")
        async def on_poke(data):
            received_poke.update(data)
            poke_received.set()

        @socket_b.on("doodle:expired", namespace="/rt")
        async def on_expired(data):
            received_expiry.update(data)
            expired_received.set()

        try:
            await asyncio.gather(
                socket_a.connect(
                    BASE_URL,
                    auth={"token": token_a},
                    namespaces=["/rt"],
                    transports=["websocket"],
                    socketio_path="socket.io",
                ),
                socket_b.connect(
                    BASE_URL,
                    auth={"token": token_b},
                    namespaces=["/rt"],
                    transports=["websocket"],
                    socketio_path="socket.io",
                ),
            )
            check("두 소켓 /rt 연결", socket_a.connected and socket_b.connected)

            invalid = await socket_a.call(
                "poke:send", {"to_user_id": "abc"}, namespace="/rt", timeout=5
            )
            check(
                "잘못된 socket ID ack 400 계약",
                invalid.get("error", {}).get("code") == "invalid_request",
                str(invalid),
            )

            ack = await socket_a.call(
                "poke:send", {"to_user_id": user_b}, namespace="/rt", timeout=5
            )
            check("poke:send ack", ack == {"ok": True}, str(ack))
            await asyncio.wait_for(poke_received.wait(), timeout=5)
            check(
                "상대 룸에 poke 도착",
                received_poke.get("from_user_id") == user_a,
                str(received_poke),
            )

            doodle = await client.post(
                "/v1/doodles",
                data={
                    "mode": "ephemeral",
                    "content_type": "text",
                    "text_body": "socket viewed",
                },
                headers=auth_a,
            )
            doodle_id = doodle.json()["id"]
            viewed = await socket_b.call(
                "doodle:viewed", {"doodle_id": doodle_id}, namespace="/rt", timeout=5
            )
            check(
                "doodle:viewed ack expires_at",
                bool(viewed.get("expires_at")),
                str(viewed),
            )
            await asyncio.wait_for(expired_received.wait(), timeout=8)
            check(
                "5초 뒤 expired 이벤트",
                received_expiry.get("doodle_id") == doodle_id,
                str(received_expiry),
            )
            gone = await client.get(f"/v1/doodles/{doodle_id}", headers=auth_b)
            check("만료 후 REST 410", gone.status_code == 410, str(gone.status_code))
        finally:
            await asyncio.gather(
                socket_a.disconnect(), socket_b.disconnect(), return_exceptions=True
            )


def main() -> int:
    started = time.monotonic()
    asyncio.run(run())
    print(f"\n{pass_n}/{pass_n + fail_n} passed ({time.monotonic() - started:.1f}s)")
    return 1 if fail_n else 0


if __name__ == "__main__":
    raise SystemExit(main())
