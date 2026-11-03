# 弈境 · 围棋人机对弈

玩家执黑先行、AI 执白应手的单页围棋应用。后端基于 Python 3.11+ / FastAPI / Uvicorn / httpx，优先调用 DeepSeek（Chat Completions 风格接口）生成白方应手；未配置密钥或模型调用失败时自动降级为本地启发式 AI，**对局永不中断**。前端为无框架、无 CDN 的单文件 HTML5/CSS/Canvas 页面，由后端同源托管。

- 开局可选 10 级（最弱）～ 1 级（最强）共 10 档级位，支持 9 / 13 / 19 路棋盘。
- 规则内核：气与提子、自杀禁入、简单劫、连续两次 Pass 终局、简易数子（活子 + 单方围空）。
- 保留原始双人版本的视觉体系（木纹棋盘、立体棋子、最后一手标记、悬停预览）。
- 密钥只从本机环境变量读取，不出现在前端、仓库、响应和普通日志中。

## 目录结构

```text
weiqi/
├── index.html                # 原始双人版本，作为迁移基线保留（对照用，非交付入口）
├── front/
│   └── index.html            # 人机对弈前端（单文件，后端同源托管于 GET /）
├── backend/
│   ├── main.py               # FastAPI 入口、路由与静态资源托管
│   ├── config.py             # 环境变量与集中配置
│   ├── models.py             # Pydantic 请求/响应模型与棋局语义校验
│   ├── go_rules.py           # 服务端规则内核（邻点/连通块/气/提子/自杀/简单劫）
│   ├── ai/
│   │   ├── engine.py         # 级位调度、模型优先 + 启发式永久兜底的统一入口
│   │   ├── heuristic.py      # 合法候选生成与七维评分（提子/气/叫吃/救援/贴手/位置/联络）
│   │   ├── levels.py         # 10 档级位参数档案（温度/噪声/随性率/Top-K/权重）
│   │   └── llm.py            # DeepSeek 调用、提示词、防御性解析、重试与降级
│   └── tests/                # 后端自动化测试（133 个，见"测试"一节）
├── requirements.txt
├── .env.example              # 仅含空密钥与默认值的配置示例
└── README.md
```

## 环境要求与依赖安装

- Python **3.11+**（实测 3.11.8）
- 依赖仅 4 项：fastapi、uvicorn、httpx、pydantic（见 `requirements.txt`）

```powershell
# Windows PowerShell（在 weiqi/ 目录下）
python --version                  # 确认 3.11+
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r requirements.txt
```

```bash
# macOS / Linux bash
python3 --version
python3 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt
```

## 环境变量配置

所有配置仅从**本机环境变量**读取（本项目运行时不自动加载 `.env` 文件，`.env.example` 仅作说明示例）。密钥示例一律使用占位符，禁止写入真实凭据。

### 设置 DEEPSEEK_API_KEY

```powershell
# Windows PowerShell（仅当前会话生效）
$env:DEEPSEEK_API_KEY = "<your-key-here>"
```

```powershell
# Windows CMD
set DEEPSEEK_API_KEY=<your-key-here>
```

```powershell
# Windows 永久（用户级）
[Environment]::SetEnvironmentVariable("DEEPSEEK_API_KEY", "<your-key-here>", "User")
```

```bash
# macOS / Linux bash
export DEEPSEEK_API_KEY="<your-key-here>"
```

### 其他配置项

| 环境变量 | 默认值 | 说明 |
|---|---|---|
| `DEEPSEEK_API_KEY` | 空 | 为空时 `llm=false`，使用本地启发式 AI（可完整对弈） |
| `DEEPSEEK_MODEL` | `deepseek-flash` | 模型标识（服务端支持 `deepseek-flash` / `deepseek-v4-pro`） |
| `DEEPSEEK_BASE_URL` | `https://api.deepseek.com` | 模型服务地址 |
| `DEEPSEEK_TIMEOUT_SECONDS` | `12` | 单次模型调用超时（秒） |
| `DEEPSEEK_MAX_RETRIES` | `1` | 模型调用失败后最大重试次数 |
| `DEEPSEEK_RETRY_BACKOFF_SECONDS` | `0.5` | 重试退避间隔（秒） |
| `DEEPSEEK_MAX_TOKENS` | `512` | 模型单次响应上限，避免无界响应 |
| `AI_CANDIDATE_TOP_K` | `30` | 启发式候选 Top-K 基准值（随级位在后端调整） |
| `ALLOWED_BOARD_SIZES` | `9,13,19` | 允许的棋盘尺寸 |
| `CORS_ALLOW_ORIGINS` | `http://127.0.0.1:5500,http://localhost:5500` | 开发期 CORS 白名单；设为 `none` 禁用（生产同源无需 CORS） |

### 无密钥本地 AI 模式

不设置 `DEEPSEEK_API_KEY` 时：服务正常启动，启动日志标记 `llm: disabled`，`/api/health` 返回 `llm=false`，`/api/ai-move` 全部由启发式引擎应手；前端提示"未配置模型密钥，当前为本地 AI"，不阻止开局。**密钥无效、超时、限流、网络错误、非 JSON 响应、非法坐标时同样自动降级启发式**，响应 `engine` 字段如实标记实际使用的引擎。

## 启动与访问

```powershell
# Windows PowerShell（在 weiqi/ 目录下）
.venv\Scripts\python.exe -m uvicorn backend.main:app --host 127.0.0.1 --port 8000
```

```bash
# macOS / Linux bash
.venv/bin/python -m uvicorn backend.main:app --host 127.0.0.1 --port 8000
```

启动后浏览器访问 <http://127.0.0.1:8000>，`GET /` 即人机对弈页面（同源托管 `front/index.html`）。开发期若用独立静态服务器打开前端，可将 `front/index.html` 内 `API_BASE` 从 `''` 改为 `'http://127.0.0.1:8000'`，并把该源加入 `CORS_ALLOW_ORIGINS`。

## 接口契约

### GET /api/health

```json
{
  "status": "ok",
  "llm": false,
  "model": "deepseek-flash",
  "version": "1.0.0"
}
```

`llm` 表示是否配置了有效密钥（仅此含义，不代表模型当前可用）。

### POST /api/ai-move

请求（关键约定：`row`/`col` 均为 **0 基**坐标；棋盘值 `0=空、1=黑、2=白`；AI 固定执白）：

```json
{
  "board": [[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,1,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0]],
  "size": 9,
  "level": 10,
  "moveNumber": 1,
  "lastMove": {"row": 2, "col": 2},
  "previousBoard": [[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0],[0,0,0,0,0,0,0,0,0]],
  "consecutivePasses": 0
}
```

成功响应：

```json
{
  "move": {"row": 3, "col": 3},
  "reason": "[10级]贴身应战",
  "elapsedMs": 25,
  "engine": "heuristic"
}
```

字段说明：

- `move`：`{row,col}` 或字符串 `"pass"`（无合法落点 / 引擎主动虚手）。
- `engine`：`"llm"` 或 `"heuristic"`，如实标记实际生成应手的引擎；启发式结果的 `reason` 带 `[N级]` 前缀。
- `lastMove`：`null`、`"pass"` 或 `{row,col}`。
- **`previousBoard` 劫校验语义**：上一手落子前的棋盘快照（二维数组或 `null`）。服务端模拟白方落子后，将结果盘面与 `previousBoard` 逐点比较，完全相同即判定为简单劫（立即回提禁着），与前端本地劫判定语义一致。Pass 后无劫限制，传 `null`。

错误与降级策略：

- 结构/语义非法（维度不符、值域越界、字符串坐标、级位越界、`size` 不在白名单等）由 Pydantic 返回 **422**，错误信息为中文友好描述，不含堆栈与敏感细节。
- 模型超时 / 网络失败 / 限流 / HTTP 错误 / 非 JSON / 非法坐标：最多重试 1 次后降级启发式，正常返回 200。
- 引擎三层兜底：启发式异常 → 首个合法点 → `"pass"`；预期内失败不返回 500。
- 前端约定：15 秒请求超时；收到非法坐标时同局面重试一次，仍非法则让 AI Pass；新局/悔棋/回退/切尺寸时中止或忽略旧请求。

## 级位强度映射（1 级最强，10 级最弱）

级位映射只在后端实现，前端仅传 1～10 整数。所有级位先保证落子合法，再体现强度差异；关键手段（提子/叫吃/救棋）任何级位都不放弃。

| 级位 | 策略 | 温度 | 评分噪声 | 随性率 | Top-K |
|---|---|---|---|---|---|
| 10 级 | 吃子与基础死活为核心，无围空概念，局部缠斗 | 1.3 | 12.0 | 40% | 20 |
| 9 级 | 吃子熟练 + 开始有围空意识，效率低 | 1.2 | 10.0 | 32% | 22 |
| 8 级 | 吃子对杀稳定，尝试占角/边，常弃已占区域 | 1.1 | 8.0 | 25% | 24 |
| 7 级 | 基础布局 + 分断连接概念，星/小目开局点 | 1.0 | 6.5 | 18% | 26 |
| 6 级 | 布局成形，连接分断明确，对杀气数可靠 | 0.9 | 5.0 | 13% | 28 |
| 5 级 | 死活棋形（板六/盘角曲四）+ 基础手筋，候选集中 | 0.8 | 4.0 | 9% | 24 |
| 4 级 | 手筋熟练 + 基础定式，方向仍模糊 | 0.7 | 3.0 | 6% | 26 |
| 3 级 | 布局选点 + 中盘战术入门，打入侵消时机，官子收束 | 0.6 | 2.0 | 4% | 34 |
| 2 级 | 大场急所初具雏形，收官有序 | 0.5 | 1.5 | 2% | 36 |
| 1 级 | 综合实战 + 全局平衡，附加死活/联络加强读 | 0.2 | 0.5 | 0% | 40 |

强度差异同时体现在本地评分权重（级位越低，位置价值/联络权重越高，"贴手缠斗"权重越低），并已用固定随机种子验证：1 级平均候选排名严格优于 10 级（见 `backend/tests/test_levels.py`）。

## 历史与悔棋策略

- **人机悔棋**：AI 已应手时撤销"玩家一手 + AI 一手"，回到玩家回合；AI 思考中悔棋则取消在途请求并只撤销玩家刚下的一手；历史不足时不破坏状态。
- **历史回退**：采用"精确恢复所选局面；若恢复后轮到 AI（白方），则以恢复后的完整状态重新请求一次 AI"的统一策略，不沿用回退前的请求或响应。
- 悔棋与回退通过历史快照整体恢复 `previousBoard`、`consecutivePasses`、提子数、手数、终局状态和最后一手。
- 新局/重新开始/尺寸切换统一进入请求清理流程（abort 在途请求 + 递增请求序号），迟到响应经局身份/请求序号/手数/回合多重守卫后忽略，不污染新局面。

## 测试

### 自动化测试（无需密钥、无公网依赖，模型路径全部使用 Mock）

```powershell
# Windows PowerShell（在 weiqi/ 目录下）
.venv\Scripts\python.exe -m compileall backend
.venv\Scripts\python.exe -m unittest discover -s backend/tests -v
```

```bash
# macOS / Linux bash
.venv/bin/python -m compileall backend
.venv/bin/python -m unittest discover -s backend/tests -v
```

共 **133 个测试**（`test_go_rules` 17、`test_heuristic` 11、`test_ai_move_api` 21、`test_config`/`test_health` 15、`test_levels` 16、`test_llm` 27、`test_boundary_hardening` 26），覆盖：规则内核（提子/多块提子/自杀/简单劫/无合法点 Pass）、接口校验（12 类非法输入 422、9/13/19 × 1～10 级全组合）、模型降级（超时/网络/HTTP/限流/非 JSON/非法坐标/重试一次/无密钥禁用/密钥不泄露）、固定种子强度趋势、三层引擎兜底。

### 手工测试清单（已在任务 7 实测通过，无密钥环境）

开局设置（9/13/19 路 × 级位、默认 10 级）→ 玩家落子 → 真实启发式应手 → 提子 → 自杀禁入 → 简单劫完整生命周期（回提被禁/悔棋恢复/别处解劫）→ 双方 Pass 终局数子 → 终局后输入忽略 → 终局悔棋恢复对局 → 成对悔棋 → AI 思考中悔棋（迟到响应不落子）→ 历史回退两类（玩家回合零请求/AI 回合恰一次请求）→ 失败态点击重试 → 失败态代白方虚手 → 非法坐标重试一次后虚手 → 前端 15 秒超时真实等待 → 思考中重开/切尺寸（迟到响应不污染、级位保留）→ 控制台 0 JS 错误 → 0 外部 CDN 资源 → 后端日志无密钥无堆栈泄露。

### 真实模型联调状态

真实密钥环境联调结论：总纲原始默认模型名 `deepseek-v4.1-flash` 在真实服务返回 400（服务端实际支持 `deepseek-flash` / `deepseek-v4-pro`），**默认值已修正为 `deepseek-flash`**，配置有效密钥后无需额外设置即可 `engine=llm` 正常应手。非法模型名约 2 秒内完成降级 `engine=heuristic`，对局不中断；如需改用其他模型，请将 `DEEPSEEK_MODEL` 设为服务端实际支持的标识。

## 已知限制

- 仅实现**简单劫**（上一手局面比对），不支持超级劫（positional superko）。
- 数子为**简易规则**：活子 + 单方围空，双方接触空点不计分；不处理复杂死活判定，终局数子可能与严格规则有出入。
- 无贴目、无让子、无账号系统、无联网双人对战。
- 启发式 AI 与通用语言模型**不等于专业围棋引擎**，棋力上限有限；1 级强度不代表业余段位水平。
- 模型响应延迟接近前端 15 秒超时上限时，可能出现一次"请求失败 → 重试/虚手"路径（Mock 已覆盖该分支，真实高延迟网络未压测）。
