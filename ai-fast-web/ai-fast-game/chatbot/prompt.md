# 任务：开发一个可运行的 AI 聊天机器人（前端 + 后端）

## 一、技术栈（硬约束，不得变更）
- 前端：原生 HTML5 + CSS3 + JavaScript (ES6)，axios 通过 CDN 引入，不使用任何框架（React/Vue/Tailwind 均禁止）
- 后端：Python 3.11+，FastAPI + uvicorn
- 大模型：DeepSeek V4.1 Flash，通过 OpenAI 兼容 SDK 接入
- 文件结构：
  - 后端：`main.py`、`requirements.txt`、`.env.example`
  - 前端：`index.html`、`style.css`、`app.js`
  - 根目录：`README.md`（只写启动步骤，不超过 30 行）

## 二、DeepSeek 接入规范（必须严格照此写）
- Python 包：`openai`
- 初始化：
  ```python
  from openai import OpenAI
  import os
  client = OpenAI(
      api_key=os.environ["DEEPSEEK_API_KEY"],
      base_url="https://api.deepseek.com"
  )

 - 模型参数：model="deepseek-flash"（该名称指向 DeepSeek-V4.1-Flash-1017，不要写成 deepseek-v4-flash 等旧名）

- API Key 只从环境变量读取，禁止硬编码，禁止出现在前端

- 前端不得直接请求 DeepSeek，所有请求必须经后端转发 

## 三、后端 API 契约（前后端必须一致）
接口：POST /api/chat

请求体：
{
  "message": "用户输入文本",
  "history": [
    {"role": "user", "content": "..."},
    {"role": "assistant", "content": "..."}
  ]
}

- message 必填，history 可选（默认空数组）

- 响应体（成功）：

{"reply": "模型返回文本", "error": null}

- 响应体（失败）：

{"reply": null, "error": "用户友好的错误提示"}

其他要求：
 - 开启 CORS，允许 http://localhost:3000 和 http://localhost:8080
 - 后端把 history + 当前 message 拼成 messages 数组传给 DeepSeek
 - 捕获 DeepSeek 调用异常，返回友好 error，同时在服务端日志打印完整 traceback
 - 不实现流式输出（保持简单），但代码结构要便于后续扩展

## 四、前端 UI 与交互要求 

- 聊天窗口：消息气泡区分用户（右对齐、浅色背景）和 AI（左对齐、灰色/深色背景）

- 输入区：多行文本框 + 发送按钮；Enter 发送，Shift+Enter 换行

- 加载状态：请求中显示“思考中...”，并禁用发送按钮

- 错误展示：响应 error 非空时，在聊天窗口插入一条系统提示样式的错误消息

- 多轮对话：前端维护 history 数组，每次发送时把最近 10 轮历史一并传给后端

- 页面加载后自动聚焦输入框；发送后清空输入框并滚动到底部

- 样式简洁美观即可，不追求复杂动效

## 五、禁止事项

- 不要引入任何前端框架或 CSS 框架

- 不要生成 TypeScript

- 不要添加语音、图片上传、登录、数据库等未要求的功能

- 不要生成测试文件、Dockerfile、CI 配置等额外内容

- 不要省略任何文件的完整代码

## 六、交付要求

- 按以下顺序一次性输出全部文件，每个文件用代码块标注文件名：
  requirements.txt → .env.example → main.py → index.html → style.css → app.js → README.md

- 每个文件必须是完整可运行的代码，不允许出现 # 省略、... 之类的占位

- 代码中关键位置加简短中文注释（如 DeepSeek 调用处、CORS 配置处、history 拼接处）

- README 包含：安装依赖、设置 DEEPSEEK_API_KEY、启动后端、打开前端的步骤

- 最后附一段“验收自检清单”，逐条确认：API 契约一致、Key 未硬编码、CORS 已开、多轮 history 已传、错误处理已覆盖

## 七、我的环境信息

- 操作系统： Windows 

- Python 版本：3.11.8

- 前端打开方式：直接双击 index.html

- 额外要求：无
