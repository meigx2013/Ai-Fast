# FT-TBD 在线智能体空间（服务化接口）— API 自动化测试

针对 **FT-TBD 在线智能体空间开放接入（服务化接口）** 的 19 个 API 的可重复自动化测试方案。核心产物为自包含 shell 脚本 `ft-tbd-api-test.sh`（内嵌 Node.js 测试引擎，运行时释放到 `ft-api-test-data/engine.mjs`），无需预装 jq/curl，仅需 bash + Node.js ≥ 18。

- 接口契约：`docs/FT-TBD-在线智能体空间开放接入.postman_collection_v2.json`（19 个服务化 HTTP 接口，不含 WebSocket 端点）
- 鉴权方式：`X-Open-Access-Token`（组织级 `oat_xxx` 令牌）全局携带；`enter` / `connect` 额外要求 `X-Asdm-Pat`（个人 PAT）；需要成员身份的请求携带 `userId`。**不再使用账号密码登录 / PAT 兑换 JWT**
- 当前默认环境：`https://asdm-dt01.leansoftx.com`（userId=52）
- 最近一次实跑（2026-11-17）：**19/19 全部通过，退出码 0**（含 3.2 ACP WS+initialize 自愈、1.3 停止后自动恢复实测验证）

## 快速开始

```bash
# Windows 使用 Git Bash 执行（Linux / macOS 直接运行）
cd api-test

./ft-tbd-api-test.sh --self-check   # 五项自检：bash 语法 / node 版本 / 引擎语法 / 连通性 / 配置完整性
./ft-tbd-api-test.sh                # 全量新鲜执行（默认，不传参数即使用内置默认配置）
./ft-tbd-api-test.sh --resume       # 断点续跑（依据 results.json 跳过已成功步骤）
```

## 运行模式与退出码

| 模式 | 说明 |
|------|------|
| `--fresh`（默认） | 全量执行，重建 results.json |
| `--resume` | 断点续跑，跳过已成功步骤，仅重试失败/未执行项 |
| `--self-check` | 仅自检（语法/依赖/引擎释放/连通性/配置完整性），不发业务请求 |

| 退出码 | 含义 |
|--------|------|
| 0 | 全部接口通过 |
| 1 | 存在失败接口 |
| 2 | 致命错误（依赖缺失/无可用实例/执行中断） |

## 配置

优先级：**命令行参数 > 环境变量 > 脚本内默认值**。不传任何参数即使用内置默认值。

| CLI 参数 | 环境变量 | 默认值 | 说明 |
|----------|----------|--------|------|
| `--base-url` | `FT_BASE_URL` | `https://asdm-dt01.leansoftx.com` | 目标环境 |
| `--open-access-token`（`--oat`） | `FT_OPEN_ACCESS_TOKEN` | （脚本内内置） | 组织开放访问令牌 `oat_xxx`，全局请求头 `X-Open-Access-Token` |
| `--asdm-pat`（`--pat`） | `FT_ASDM_PAT` | （脚本内内置） | 个人 PAT，仅 `enter` / `connect` 两个请求使用（`X-Asdm-Pat` 头） |
| `--user-id` | `FT_USER_ID` | `52` | 成员用户 ID（任意正整数，不必是真实 ASDM 用户） |
| — | `FT_WORK_DIR` | `./ft-api-test-data` | 工作目录（引擎/日志/报告/状态） |

示例：

```bash
./ft-tbd-api-test.sh --base-url https://asdm-dt02.leansoftx.com --user-id 88 \
  --open-access-token oat_xxx --asdm-pat pat_yyy
# 或
FT_BASE_URL=https://asdm-dt02.leansoftx.com FT_USER_ID=88 ./ft-tbd-api-test.sh
```

## 接口清单（19 个）

按执行编排顺序，编号与 Postman v2 集合一致：

| 编号 | 接口名称 | 编号 | 接口名称 |
|------|---------|------|---------|
| 1.1 | 查询全部在线智能体空间 | 3.3 | 删除会话 |
| 1.2 | 实例详情（兼作状态轮询） | 3.4 | 获取会话可用模型 |
| 1.3 | 暂停实例 | 3.5 | 切换会话模型 |
| 1.4 | 重启实例 | 3.6 | 获取会话历史 |
| 2.1 | 进入实例 | 3.7 | 停止生成 |
| 2.2 | 获取连接信息 | 4.1 | 上传文件 |
| 2.3 | 查询用户连接状态 | 4.2 | 下载文件 |
| 3.1 | 会话列表 | 4.3 | 上传制品到智能体空间 |
| 3.2 | 创建会话 | 4.4 | 获取智能体空间制品列表 |
| | | 4.5 | 下载制品（按 artifactId） |

执行编排：`1.1 → instanceId/workspaceId（动态发现，优先 running 实例）` → `1.2 → 确保 running` → `2.1/2.2 → 成员环境与 wsUrl` → `[脚本自建 ACP WS + initialize]` → `3.2 → sessionId` → `3.4 → currentModel` → `4.1 → filePath` → `4.3 → artifactId`；`3.3 删除会话` 后执行 `1.4 重启`、`1.3 暂停`（收尾状态类操作，避免影响会话/文件测试）。`1.1` / `1.2` 失败会中止执行。

> 说明：v2 集合不含「创建实例 / 删除实例 / 项目 CRUD」端点（由平台侧或其他通道提供），脚本通过 1.1 动态发现存量实例进行测试；工作目录固定为成员默认工作目录 `_default`。

## 自愈机制（6 类）

| # | 场景 | 策略 |
|---|------|------|
| 1 | 网络错误 / 5xx | 自动重试（最多 3 次，间隔 2s） |
| 2 | 3.2 创建会话 409（无活跃 ACP 连接） | 使用 2.2 返回的 `wsUrl` 建立裸 ACP WebSocket 连接 → 发送 `initialize`（protocolVersion=1）→ 等待响应与 `session/new` 通知 → 重试创建，`@healed` 注释留痕 |
| 3 | 1.2 实例非 running | 先轮询等待（120s）；仍非 running 或终态 → 调用 1.4 `restart` 拉起并等待 running（300s） |
| 4 | 1.4 重启后 | 轮询等待 running（最长 5 分钟，error/terminated 终态早退） |
| 5 | 1.3 暂停后 | 轮询确认 stopped，随后**自动 restart 恢复 running**（实例非脚本创建，测试后环境还原，`@restored` 注释留痕） |
| 6 | 401 / 403 | 令牌/权限失效（openAccessToken 或 asdmPat 无效），判定为不可自愈，直接失败返回 |

## 产物

运行后在工作目录（`ft-api-test-data/`）生成：

| 文件 | 说明 |
|------|------|
| `engine.mjs` | 内嵌 Node.js 测试引擎（每次运行由脚本释放覆盖） |
| `run-<时间戳>.log` | 执行日志（含每步 HTTP 状态、业务码、耗时、自愈轨迹、ACP WS 消息） |
| `report-<时间戳>.md` | Markdown 测试报告（环境、汇总、逐接口结果表含响应时间(秒)列及响应时间统计） |
| `results.json` / `state.json` | 断点续跑状态（`--resume` 门控依据） |

运行结束后自动校验 `results.json` 19 条记录的完整性。

## 脚本结构

```
ft-tbd-api-test.sh        # 单文件自包含：参数解析 + 自检 + 引擎释放 + 执行 + 结果校验
ft-api-test-data/         # 运行时工作目录（引擎、日志、报告、状态、断点数据）
```

修改测试逻辑只需编辑 `ft-tbd-api-test.sh` 中 `FT_ENGINE_EOF` heredoc 内的引擎代码（步骤定义位于 `steps` 数组），下次运行会重新释放 `engine.mjs`。

## 环境切换记录

| 日期 | 环境 | userId | 结果 |
|------|------|--------|------|
| 2026-11-17 | `https://asdm-dt01.leansoftx.com` | 52 | **19/19 全部通过**（含 3.2 ACP WS+initialize 自愈、1.3 停止后 @restored 自动恢复 running 实测验证） |
