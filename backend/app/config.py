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
    max_upload_bytes: int = 10 * 1024 * 1024
    max_image_dimension: int = 8192
    max_text_length: int = 4000
    max_stroke_bytes: int = 512 * 1024

    # --- GPU 서버 ------------------------------------------------------------
    # 기본은 스텁이다. GPU 환경이 준비되기 전에도 앱·백엔드가 굴러가야 한다.
    gpu_enabled: bool = False
    gpu_llm_url: str = "http://127.0.0.1:8100"   # vLLM (OpenAI 호환)
    gpu_sd_url: str = "http://127.0.0.1:8200"    # sd-worker
    llm_model: str = "LGAI-EXAONE/EXAONE-3.5-7.8B-Instruct-AWQ"
    gpu_timeout_seconds: float = 120.0           # 일기 그림 생성이 10~30초 걸린다

    # --- 사라지기 모드 -------------------------------------------------------
    ephemeral_ttl_seconds: float = 5.0

    # --- 스케줄러 ------------------------------------------------------------
    # 테스트에서는 끈다. 배치가 테스트 도중 끼어들면 재현이 안 된다.
    scheduler_enabled: bool = True
    activity_interval_minutes: int = 180   # 펫이 하루 몇 번 활동을 바꾸나 (API.md 13절: 미확정)
    diary_hour_utc: int = 15               # 자정 KST = 15시 UTC

    # --- 펫 성장 -----------------------------------------------------------
    # exp는 누적값이다. API 예시의 level=4, exp=320과 같은 규칙이다.
    pet_exp_per_level: int = 100
    pet_doodle_exp: int = 10
    pet_reply_exp: int = 5
    pet_poke_exp: int = 2
    pet_pat_exp: int = 1
    pet_levelup_coins: int = 50
    # 활동별 즉시 코인(#12) — 실제 콘텐츠 생성(낙서/답장)에만 소량 지급한다.
    # 쓰다듬기·찌르기는 연타로 파밍이 가능하므로 코인을 직접 주지 않고
    # exp→레벨업(50코인) 경로로만 보상한다.
    pet_doodle_coins: int = 3
    pet_reply_coins: int = 2

    # --- 푸시 ---------------------------------------------------------------
    fcm_credentials_path: Path | None = None

    cors_origins: str = "*"

    def parsed_cors_origins(self) -> str | list[str]:
        if self.cors_origins.strip() == "*":
            return "*"
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
