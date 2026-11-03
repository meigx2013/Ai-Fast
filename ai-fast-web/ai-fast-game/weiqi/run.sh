#!/usr/bin/env bash
# ============================================================
# 弈境 · 人机对弈后端一键启动脚本（Linux / macOS / Git Bash）
# 用法：
#   ./run.sh                以默认 127.0.0.1:8000 启动
#   ./run.sh --reload       透传额外 uvicorn 参数（开发模式）
# 可用环境变量：
#   WEIQI_HOST / WEIQI_PORT  覆盖监听地址与端口
#   DEEPSEEK_API_KEY 等     见 .env.example（若存在 .env 会自动加载）
# ============================================================
set -euo pipefail
cd "$(dirname "$0")"

HOST="${WEIQI_HOST:-127.0.0.1}"
PORT="${WEIQI_PORT:-8000}"

# ---------- 可选：加载同目录 .env（KEY=VALUE，# 开头为注释） ----------
if [ -f .env ]; then
    set -a
    # shellcheck disable=SC1091
    . ./.env
    set +a
fi

# ---------- 确保虚拟环境存在 ----------
PY=".venv/bin/python"
if [ ! -x "$PY" ]; then
    PY=".venv/Scripts/python.exe"   # Git Bash on Windows
    if [ ! -f "$PY" ]; then
        echo "[run.sh] 未找到虚拟环境 .venv，正在创建 ..."
        python3 -m venv .venv || python -m venv .venv
        PY=".venv/bin/python"
        if [ ! -x "$PY" ] && [ -f ".venv/Scripts/python.exe" ]; then
            PY=".venv/Scripts/python.exe"
        fi
    fi
    "$PY" -m pip install --upgrade pip
fi

# ---------- 确保依赖已安装 ----------
if ! "$PY" -c "import fastapi, uvicorn, httpx, pydantic" >/dev/null 2>&1; then
    echo "[run.sh] 正在安装依赖 requirements.txt ..."
    "$PY" -m pip install -r requirements.txt
fi

echo "[run.sh] 启动后端服务：http://${HOST}:${PORT}  （Ctrl+C 停止）"
exec "$PY" -m uvicorn backend.main:app --host "$HOST" --port "$PORT" "$@"
