"""FastAPI 入口（v2 · 系统对弈）：健康检查（引擎信息）、全局异常处理、
开发 CORS 与前端静态托管。

启动命令（在 weiqi/ 目录）：
    .venv\\Scripts\\python.exe -m uvicorn backend.main:app --host 127.0.0.1 --port 8000
"""

import logging
from pathlib import Path

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse, JSONResponse

from .ai import engine
from .config import APP_VERSION, get_settings
from .models import HealthResponse, SystemMoveRequest, SystemMoveResponse

logger = logging.getLogger("weiqi.backend")

# 系统对弈前端目标位置（同源静态托管）。
FRONT_INDEX = Path(__file__).resolve().parent.parent / "front" / "index.html"


def create_app() -> FastAPI:
    """应用工厂：测试与生产共用同一装配流程。"""
    settings = get_settings()
    app = FastAPI(title="弈境 · 系统对弈后端", version=APP_VERSION)

    # 开发期 CORS 仅允许配置中列出的明确本地源；生产模式为同源访问。
    if settings.cors_allow_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=list(settings.cors_allow_origins),
            allow_methods=["GET", "POST"],
            allow_headers=["Content-Type"],
        )

    @app.get("/api/health", response_model=HealthResponse)
    def read_health() -> HealthResponse:
        current = get_settings()
        return HealthResponse(
            status="ok",
            engine=engine.ENGINE_NAME,
            levels=list(range(1, 11)),
            sizes=list(current.allowed_sizes),
            version=APP_VERSION,
        )

    @app.post("/api/system-move", response_model=SystemMoveResponse)
    async def create_system_move(request: SystemMoveRequest) -> SystemMoveResponse:
        # 引擎内部已含规则兜底与异常降级；此处请求体结构/语义错误由 Pydantic 返回 422。
        return await engine.generate_move(request)

    # 静态托管：front/index.html 存在时同源返回对弈前端。
    if FRONT_INDEX.is_file():

        @app.get("/", include_in_schema=False)
        def serve_index() -> FileResponse:
            return FileResponse(FRONT_INDEX)

    @app.exception_handler(Exception)
    async def unhandled_exception_handler(request: Request, exc: Exception) -> JSONResponse:
        # 堆栈只进入服务器日志，响应不携带 traceback 或内部细节。
        logger.exception("未处理异常: %s %s", request.method, request.url.path)
        return JSONResponse(status_code=500, content={"detail": "服务器内部错误，请稍后重试"})

    print(
        f"[weiqi-backend] engine: {engine.ENGINE_NAME} | levels: 1-10 | "
        f"sizes: {list(settings.allowed_sizes)} | version: {APP_VERSION}",
        flush=True,
    )
    return app


app = create_app()
