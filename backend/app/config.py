"""설정. `.env`에서 읽는다.

보안이 비목표라(SPEC 1.2절) 시크릿 관리를 하지 않는다. `.env`는 커밋하지 않을 뿐이다.
"""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_file_encoding="utf-8", extra="ignore"
    )

    # --- DB (앱 VM) ---------------------------------------------------------
    # asyncmy 를 쓴다. 근거는 docs/STACK.md 7절.
    database_url: str = (
        "mysql+asyncmy://memory:pager@127.0.0.1:3306/memory_pager?charset=utf8mb4"
    )

    # --- 미디어 (앱 VM 파일시스템) -------------------------------------------
    media_root: Path = Path("./media")
    media_url_prefix: str = "/media"

    # --- GPU 서버 ------------------------------------------------------------
    # 기본은 스텁이다. GPU 환경이 준비되기 전에도 앱·백엔드가 굴러가야 한다.
    gpu_enabled: bool = False
    gpu_llm_url: str = "http://127.0.0.1:8100"   # vLLM (OpenAI 호환)
    gpu_sd_url: str = "http://127.0.0.1:8200"    # sd-worker
    llm_model: str = "LGAI-EXAONE/EXAONE-3.5-7.8B-Instruct-AWQ"
    gpu_timeout_seconds: float = 120.0           # 일기 그림 생성이 10~30초 걸린다

    # --- 사라지기 모드 -------------------------------------------------------
    ephemeral_ttl_seconds: float = 5.0

    # --- 푸시 ---------------------------------------------------------------
    fcm_credentials_path: Path | None = None

    cors_origins: str = "*"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
