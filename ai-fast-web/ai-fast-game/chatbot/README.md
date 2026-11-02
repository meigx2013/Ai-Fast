# 启动步骤

1. 在 PowerShell 中进入项目目录：
   ```powershell
   cd d:\dev-src\Ai-Fast\ai-fast-web\ai-fast-game\chatbot
   ```
2. 创建并激活虚拟环境，然后安装依赖：
   ```powershell
   py -3.11 -m venv .venv
   .\.venv\Scripts\Activate.ps1
   pip install -r requirements.txt
   ```
3. 在本机环境变量中配置 `DEEPSEEK_API_KEY`，不再使用 `.env` 文件。当前 PowerShell 会话可执行：
   ```powershell
   $env:DEEPSEEK_API_KEY = "你的密钥"
   ```
   如需永久保存，请在 Windows 环境变量设置中添加同名用户或系统变量，然后重新打开终端。
4. 启动后端服务：
   ```powershell
   uvicorn main:app --reload --port 8000
   ```
5. 直接双击 `index.html`，在浏览器中开始聊天。
