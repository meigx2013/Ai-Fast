# FT-TBD 在线智能体空间 — API 自动化测试

针对 **FT-TBD 在线智能体空间开放接入** 的 28 个 API 的可重复自动化测试方案。核心产物为自包含 shell 脚本 `ft-tbd-api-test.sh`（内嵌 Node.js 测试引擎，运行时释放到 `ft-api-test-data/engine.mjs`），无需预装 jq/curl，仅需 bash + Node.js ≥ 18。

- 测试对象：ASDM 在线智能体空间（AgentOrbit）开放接入 API
- 当前默认环境：`https://asdm-dt02.leansoftx.com`（workspace=2，账号 `test01@asdm.ai`）
- 最近一次实跑（2026-11-11）：**28/28 全部通过，退出码 0**

## 快速开始

```bash
# Windows 使用 Git Bash 执行（Linux / macOS 直接运行）
cd api-test

./ft-tbd-api-test.sh --self-check   # 五项自检：bash 语法 / node 版本 / 引擎语法 / 连通性 / 配置完整性
./ft-tbd-api-test.sh                # 全量新鲜执行（默认，等价 --fresh）
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
| 2 | 致命错误（依赖缺失/登录失败/执行中断） |

## 配置

优先级：**命令行参数 > 环境变量 > 脚本内默认值**。

| CLI 参数 | 环境变量 | 默认值 | 说明 |
|----------|----------|--------|------|
| `--base-url` | `FT_BASE_URL` | `https://asdm-dt02.leansoftx.com` | 目标环境 |
| `--email` | `FT_EMAIL` | `test01@asdm.ai` | 登录账号 |
| `--password` | `FT_PASSWORD` | `admin@2026` | 登录密码 |
| `--workspace-id` | `FT_WORKSPACE_ID` | `2` | 智能体空间工作区 ID |
| `--pat` | `FT_PAT` | （脚本内内置） | 个人访问令牌，用于 0.2 PAT 兑换 JWT |
| — | `FT_WORK_DIR` | `./ft-api-test-data` | 工作目录（引擎/日志/报告/状态） |

示例：

```bash
./ft-tbd-api-test.sh --base-url https://asdm-dt01.leansoftx.com --workspace-id 17 --pat pat_xxx
# 或
FT_BASE_URL=https://asdm-dt01.leansoftx.com FT_WORKSPACE_ID=17 ./ft-tbd-api-test.sh
```

## 接口清单（28 个）

按执行编排顺序，编号与 Postman 集合（`docs/FT-TBD 在线智能体空间开放接入.postman_collection.json`）一致：

| 编号 | 接口名称 | 编号 | 接口名称 |
|------|---------|------|---------|
| 0.1 | 账号密码登录 | 3.2 | 创建会话 |
| 0.2 | PAT 兑换 JWT | 3.3 | 切换会话 |
| 1.7 | 可用镜像列表 | 3.4 | 删除会话 |
| 1.1 | 创建实例 | 3.5 | 获取会话可用模型 |
| 1.2 | 实例列表 | 3.6 | 切换会话模型 |
| 1.3 | 实例详情 | 3.7 | 停止生成 |
| 1.4 | 暂停实例 | 4.1 | 上传文件 |
| 1.5 | 重启实例 | 4.2 | 下载文件 |
| 1.6 | 删除实例 | 4.3 | 上传制品到智能体空间 |
| 1.8 | 项目列表 | 4.4 | 获取智能体空间制品列表 |
| 1.9 | 项目详情 | 4.5 | 下载制品 |
| 1.10 | 创建项目 | | |
| 1.11 | 删除项目 | | |
| 2.1 | 进入实例 | | |
| 2.2 | 获取连接信息 | | |
| 2.3 | 查询用户连接状态 | | |
| 3.1 | 会话列表 | | |

依赖链：`0.1 登录 → token` → `1.7 镜像 → imageConfigId` → `1.1 实例 → instanceId` → `1.10 项目 → projectId` → `2.2 → wsUrl` → `[ACP WS 连接]` → `3.2 会话 → sessionId` → `4.1 → filePath`、`4.3 → artifactId`。关键依赖步骤失败会中止后续执行，避免雪崩式误报。

## 自愈机制（7 类）

| # | 场景 | 策略 |
|---|------|------|
| 1 | 网络错误 / 5xx | 自动重试（最多 3 次，间隔 2s） |
| 2 | 401 未授权 | 自动重新登录后重试（鉴权接口除外） |
| 3 | 3.2 创建会话 409 被拒 | 建立裸 ACP WebSocket 连接后重试（注意：不能主动发 initialize，裸连接即可） |
| 4 | 1.11 删除项目被占用 | 删除前先关闭我方 ACP WS 连接 |
| 5 | 0.2 PAT 失效 | 使用登录 JWT 作为凭据兜底兑换 |
| 6 | 1.1 创建实例返回已存在的 error 实例 | 创建接口幂等会复用旧 error 实例；检测到 status=error 时自动删除（POST `/workspaces/{id}`）→ 等 5s → 重建，`@healed` 注释留痕 |
| 7 | 1.3 等待实例就绪遇 error 终态 | 早退不再空等，同样删除重建 1 次（1 次阈值） |

## 产物

运行后在工作目录（`ft-api-test-data/`）生成：

| 文件 | 说明 |
|------|------|
| `engine.mjs` | 内嵌 Node.js 测试引擎（每次运行由脚本释放覆盖） |
| `run-<时间戳>.log` | 执行日志（含每步 HTTP 状态、业务码、耗时、自愈轨迹） |
| `report-<时间戳>.md` | Markdown 测试报告（环境、汇总、逐接口结果表含响应时间(秒)列及响应时间统计） |
| `results.json` / `state.json` | 断点续跑状态（`--resume` 门控依据） |

运行结束后自动校验 `results.json` 28 条记录的完整性。

## 脚本结构

```
ft-tbd-api-test.sh        # 单文件自包含：参数解析 + 自检 + 引擎释放 + 执行 + 结果校验
ft-api-test-data/         # 运行时工作目录（引擎、日志、报告、状态、断点数据）
```

修改测试逻辑只需编辑 `ft-tbd-api-test.sh` 中 `FT_ENGINE_EOF` heredoc 内的引擎代码（步骤定义位于 `steps` 数组），下次运行会重新释放 `engine.mjs`。

## 环境切换记录

| 日期 | 环境 | workspaceId | 结果 |
|------|------|-------------|------|
| 2026-10-27 | `https://asdm-dt01.leansoftx.com` | 17 | 27/28（仅 0.2 因 PAT 失效，需 FT_PAT 传入有效 PAT） |
| 2026-11-11 | `https://asdm-dt02.leansoftx.com` | 2 | **28/28 全部通过**（含 3.2 ACP WS 自愈、error 实例删除重建自愈实测验证） |
