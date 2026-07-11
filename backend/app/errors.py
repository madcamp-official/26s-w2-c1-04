"""에러 형식. docs/API.md 0절.

    { "error": { "code": "group_full", "message": "그룹 정원은 2명입니다" } }
"""

from __future__ import annotations

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette.exceptions import HTTPException as StarletteHTTPException

# MySQL 이 SIGNAL SQLSTATE '45000' 을 던질 때의 에러 번호.
# schema.sql 의 trg_group_members_before_insert 가 3번째 가입을 막을 때 나온다.
MYSQL_SIGNAL_ERRNO = 1644
MYSQL_DUPLICATE_ERRNO = 1062
MYSQL_DEADLOCK_ERRNO = 1213
MAX_BIGINT_ID = 2**63 - 1


class ApiError(Exception):
    def __init__(self, status: int, code: str, message: str) -> None:
        self.status = status
        self.code = code
        self.message = message
        super().__init__(f"{code}: {message}")


def _body(code: str, message: str) -> dict:
    return {"error": {"code": code, "message": message}}


def install_error_handlers(app: FastAPI) -> None:
    @app.exception_handler(ApiError)
    async def _api_error(_: Request, exc: ApiError) -> JSONResponse:
        return JSONResponse(status_code=exc.status, content=_body(exc.code, exc.message))

    @app.exception_handler(RequestValidationError)
    async def _validation(_: Request, exc: RequestValidationError) -> JSONResponse:
        return JSONResponse(
            status_code=400,
            content=_body("invalid_request", str(exc.errors()[:3])),
        )

    @app.exception_handler(StarletteHTTPException)
    async def _http(_: Request, exc: StarletteHTTPException) -> JSONResponse:
        code = {401: "unauthorized", 403: "forbidden", 404: "not_found"}.get(
            exc.status_code, "error"
        )
        return JSONResponse(
            status_code=exc.status_code, content=_body(code, str(exc.detail))
        )


def mysql_errno(exc: BaseException) -> int | None:
    """SQLAlchemy 예외에서 MySQL 에러 번호를 꺼낸다. 못 꺼내면 None."""
    orig = getattr(exc, "orig", None)
    args = getattr(orig, "args", None)
    if args and isinstance(args[0], int):
        return args[0]
    return None


def parse_id(value: object, field: str) -> int:
    """문자열로 받은 64비트 ID를 양의 정수로 검증한다.

    API 계약은 JavaScript 정밀도 문제 때문에 ID를 문자열로 주고받는다. 폼·쿼리·
    Socket.IO 페이로드는 FastAPI의 경로 파라미터 검증을 타지 않으므로 여기서 같은
    규칙을 적용한다.
    """
    if isinstance(value, bool):
        raise ApiError(400, "invalid_request", f"{field} 는 양의 정수 ID여야 합니다")
    try:
        parsed = int(value)  # type: ignore[arg-type]
    except (TypeError, ValueError, OverflowError):
        raise ApiError(400, "invalid_request", f"{field} 는 양의 정수 ID여야 합니다") from None
    if (
        parsed <= 0
        or parsed > MAX_BIGINT_ID
        or str(value).strip() != str(parsed)
    ):
        raise ApiError(400, "invalid_request", f"{field} 는 양의 정수 ID여야 합니다")
    return parsed
