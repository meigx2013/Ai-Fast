"""集中配置模块。

所有配置仅从本机环境变量读取；密钥不得写入代码、日志、前端或响应。
`load_settings()` 每次调用都重新装配，便于测试注入环境，也避免陈旧缓存。
"""

import os
from dataclasses import dataclass

APP_VERSION = "1.0.0"

DEFAULT_MODEL = "deepseek-v4.1-flash"
DEFAULT_BASE_URL = "https://api.deepseek.com"
DEFAULT_TIMEOUT_SECONDS = 12.0
DEFAULT_MAX_RETRIES = 1
DEFAULT_RETRY_BACKOFF_SECONDS = 0.5
DEFAULT_MAX_TOKENS = 512
DEFAULT_CANDIDATE_TOP_K = 30
DEFAULT_ALLOWED_SIZES = (9, 13, 19)
DEFAULT_CORS_ORIGINS = ("http://127.0.0.1:5500", "http://localhost:5500")


@dataclass(frozen=True)
class Settings:
    """运行时配置快照。"""

    api_key: str
    model: str
    base_url: str
    timeout_seconds: float
    max_retries: int
    retry_backoff_seconds: float
    max_tokens: int
    candidate_top_k: int
    allowed_sizes: tuple[int, ...]
    cors_allow_origins: tuple[str, ...]

    @property
    def llm_enabled(self) -> bool:
        """仅当密钥为非空白字符串时启用模型。"""
        return bool(self.api_key.strip())


def _env_str(name: str, default: str) -> str:
    raw = os.environ.get(name)
    if raw is None:
        return default
    raw = raw.strip()
    return raw or default


def _env_float(name: str, default: float) -> float:
    """读取正浮点数环境变量；缺失、空白或非法时回退默认值。"""
    raw = os.environ.get(name)
    if raw is None or not raw.strip():
        return default
    try:
        value = float(raw)
    except ValueError:
        return default
    return value if value > 0 else default


def _env_int(name: str, default: int, minimum: int = 0) -> int:
    """读取不小于 minimum 的整数环境变量；非法时回退默认值。"""
    raw = os.environ.get(name)
    if raw is None or not raw.strip():
        return default
    try:
        value = int(raw)
    except ValueError:
        return default
    return value if value >= minimum else default


def _env_sizes() -> tuple[int, ...]:
    raw = os.environ.get("ALLOWED_BOARD_SIZES", "")
    if not raw.strip():
        return DEFAULT_ALLOWED_SIZES
    sizes = []
    for part in raw.split(","):
        part = part.strip()
        if not part:
            continue
        try:
            size = int(part)
        except ValueError:
            continue
        if size > 0 and size not in sizes:
            sizes.append(size)
    return tuple(sizes) if sizes else DEFAULT_ALLOWED_SIZES


def _env_cors_origins() -> tuple[str, ...]:
    raw = os.environ.get("CORS_ALLOW_ORIGINS")
    if raw is None:
        return DEFAULT_CORS_ORIGINS
    raw = raw.strip()
    # 显式 "none" 表示禁用 CORS（生产同源模式无需跨域）。
    if not raw or raw.lower() == "none":
        return ()
    return tuple(origin.strip() for origin in raw.split(",") if origin.strip())


def load_settings() -> Settings:
    """从当前进程环境装配配置；调用方不得把 api_key 写入日志。"""
    return Settings(
        api_key=os.environ.get("DEEPSEEK_API_KEY", ""),
        model=_env_str("DEEPSEEK_MODEL", DEFAULT_MODEL),
        base_url=_env_str("DEEPSEEK_BASE_URL", DEFAULT_BASE_URL).rstrip("/"),
        timeout_seconds=_env_float("DEEPSEEK_TIMEOUT_SECONDS", DEFAULT_TIMEOUT_SECONDS),
        max_retries=_env_int("DEEPSEEK_MAX_RETRIES", DEFAULT_MAX_RETRIES),
        retry_backoff_seconds=_env_float(
            "DEEPSEEK_RETRY_BACKOFF_SECONDS", DEFAULT_RETRY_BACKOFF_SECONDS
        ),
        max_tokens=_env_int("DEEPSEEK_MAX_TOKENS", DEFAULT_MAX_TOKENS, minimum=64),
        candidate_top_k=_env_int("AI_CANDIDATE_TOP_K", DEFAULT_CANDIDATE_TOP_K, minimum=1),
        allowed_sizes=_env_sizes(),
        cors_allow_origins=_env_cors_origins(),
    )


def get_settings() -> Settings:
    """配置入口别名：当前实现为直接装配，保留统一调用点。"""
    return load_settings()
