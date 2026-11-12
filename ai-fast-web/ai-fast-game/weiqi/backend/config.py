"""集中配置模块（v2 · 系统对弈，无任何模型配置）。

所有配置仅从本机环境变量读取。`load_settings()` 每次调用都重新装配，
便于测试注入环境，也避免陈旧缓存。
"""

import os
from dataclasses import dataclass

APP_VERSION = "2.0.0"

DEFAULT_CANDIDATE_TOP_K = 30
DEFAULT_ALLOWED_SIZES = (9, 13, 19)
DEFAULT_CORS_ORIGINS = ("http://127.0.0.1:5500", "http://localhost:5500")
# 中国数子法贴目：黑方贴 3¾ 子（结果不可能为和棋），任务 6 结算服务使用。
DEFAULT_SCORING_KOMI = 3.75


@dataclass(frozen=True)
class Settings:
    """运行时配置快照。"""

    candidate_top_k: int
    allowed_sizes: tuple[int, ...]
    cors_allow_origins: tuple[str, ...]
    scoring_komi: float


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


def _env_float(name: str, default: float, minimum: float | None = None) -> float:
    """读取浮点数环境变量；缺失、空白或非法时回退默认值。"""
    raw = os.environ.get(name)
    if raw is None or not raw.strip():
        return default
    try:
        value = float(raw)
    except ValueError:
        return default
    if minimum is not None and value < minimum:
        return default
    return value


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
    """从当前进程环境装配配置。"""
    return Settings(
        candidate_top_k=_env_int("AI_CANDIDATE_TOP_K", DEFAULT_CANDIDATE_TOP_K, minimum=1),
        allowed_sizes=_env_sizes(),
        cors_allow_origins=_env_cors_origins(),
        scoring_komi=_env_float("SCORING_KOMI", DEFAULT_SCORING_KOMI, minimum=0.0),
    )


def get_settings() -> Settings:
    """配置入口别名：当前实现为直接装配，保留统一调用点。"""
    return load_settings()
