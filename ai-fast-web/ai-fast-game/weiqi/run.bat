@echo off
rem ============================================================
rem 弈境 · 人机对弈后端一键启动脚本（Windows）
rem 用法：
rem   run.bat                以默认 127.0.0.1:8000 启动
rem   run.bat --reload       透传额外 uvicorn 参数（开发模式）
rem 可用环境变量：
rem   WEIQI_HOST / WEIQI_PORT  覆盖监听地址与端口
rem   DEEPSEEK_API_KEY 等     见 .env.example（若存在 .env 会自动加载）
rem ============================================================
setlocal EnableExtensions
cd /d "%~dp0"

set "HOST=%WEIQI_HOST%"
if not defined HOST set "HOST=127.0.0.1"
set "PORT=%WEIQI_PORT%"
if not defined PORT set "PORT=8000"

rem ---------- 可选：加载同目录 .env（KEY=VALUE，# 开头为注释） ----------
if exist ".env" (
    for /f "usebackq eol=# tokens=1,* delims==" %%a in (`findstr /r /c:"^[A-Za-z_][A-Za-z_0-9]*=" ".env"`) do set "%%a=%%b"
)

rem ---------- 确保虚拟环境存在 ----------
if not exist ".venv\Scripts\python.exe" (
    echo [run.bat] 未找到虚拟环境 .venv，正在创建 ...
    python -m venv .venv
    if errorlevel 1 (
        echo [run.bat] 创建虚拟环境失败，请确认已安装 Python 3.11+ 并在 PATH 中。
        exit /b 1
    )
    ".venv\Scripts\python.exe" -m pip install --upgrade pip
)

rem ---------- 确保依赖已安装 ----------
".venv\Scripts\python.exe" -c "import fastapi, uvicorn, httpx, pydantic" >nul 2>nul
if errorlevel 1 (
    echo [run.bat] 正在安装依赖 requirements.txt ...
    ".venv\Scripts\python.exe" -m pip install -r requirements.txt
    if errorlevel 1 (
        echo [run.bat] 依赖安装失败，请检查网络或 pip 配置。
        exit /b 1
    )
)

echo [run.bat] 启动后端服务：http://%HOST%:%PORT%  （Ctrl+C 停止）
".venv\Scripts\python.exe" -m uvicorn backend.main:app --host "%HOST%" --port "%PORT%" %*
set "EXITCODE=%ERRORLEVEL%"
if not "%EXITCODE%"=="0" echo [run.bat] 服务异常退出，退出码 %EXITCODE%。
exit /b %EXITCODE%
