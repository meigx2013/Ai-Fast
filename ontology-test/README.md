# aos-snapshot-test.sh — AOS 技术本体快照 API 测试与对比报告生成脚本

## 一、脚本用途

`aos-snapshot-test.sh` 是一个**自包含**的 Shell 脚本（bash 外壳 + 内嵌 Node.js 引擎），用于对 AOS（技术本体服务）的**快照历史 API** 做端到端测试，并自动生成一份**快照历史数据对比分析报告**（Markdown 格式）。

核心工作流程：

```
登录获取 JWT → 分页全量拉取 available 快照 → 提取数据元素
→ 数据质量校验 → 生成对比分析报告（.md）
```

具体来说，脚本会：

1. **登录鉴权**：调用 `POST /api/auth/login` 获取 JWT（Bearer Token）。
2. **拉取快照**：调用 `GET /api/aos/contexts/{contextId}/snapshots?page=&pageSize=&status=available`，自动分页（每页默认 36 条，最多 50 页防死循环），全量获取指定上下文下所有 `available` 状态的快照。
3. **提取数据元素**：对每个快照提取 13 类本体对象明细（`Class / Route / Table / Mapper / Method / Module / Package / Function / Component / Interface / Dependency / Repository / ApiEndpoint`）、`objectCount`、`linkCount`、`violationCount`、时间戳、输入材料、是否默认快照等。
4. **数据质量校验**：
   - 计数自洽性：13 类明细之和是否等于 `objectCount`；
   - 时间戳合理性：`completedAt` 是否早于 `createdAt`、是否恰差 8 小时（疑似 UTC/UTC+8 时区写入不一致）、是否延迟超过 1 小时。
5. **生成报告**：输出 `aos-snapshot-report-<contextId前8位>-<时间戳>.md`，包含五大章节：
   - API 调用自验证结果（登录/列表/分页完整性/计数自洽性）
   - 快照列表及核心数据（ID、完成时间、对象数、链接数、输入、默认标记）
   - objectCount 明细对比（全部快照 × 13 类对象，按完成时间升序）
   - 核心指标变化分析（最新两代对比：对象数/链接数/链接密度/违规数增量与增幅，以及结论）
   - 数据质量异常提示（时间戳/计数异常清单）

## 二、依赖与环境要求

| 依赖 | 说明 |
|---|---|
| bash | 脚本外壳（Windows 下用 Git Bash 执行，如 `D:\Program Files\Git\bin\bash.exe`） |
| Node.js ≥ 18 | 内嵌引擎使用原生 `fetch`（无需安装任何 npm 包） |

**无需** `jq`、`curl` 或任何第三方依赖——脚本运行时将内嵌的 Node 引擎（ESM）释放到临时文件（`mktemp`），执行完毕自动清理（`trap ... EXIT`）。

## 三、用法

### 3.1 标准执行

```bash
# 基本用法：位置参数传 contextId
./aos-snapshot-test.sh <contextId>

# 或用 --context-id 指定
./aos-snapshot-test.sh --context-id <contextId>
```

`contextId` 必须为 **UUID 格式**（8-4-4-4-12 十六进制），否则直接报错退出。

### 3.2 完整选项

```text
用法:
  ./aos-snapshot-test.sh <contextId> [选项]
  ./aos-snapshot-test.sh --self-check          # 仅自检，不执行测试
  ./aos-snapshot-test.sh --help

选项:
  --base-url URL      API 基础地址 (env: AOS_BASE_URL, 默认 https://asdm-dt01.leansoftx.com)
  --email EMAIL       登录邮箱     (env: AOS_EMAIL,    默认 test01@asdm.ai)
  --password PWD      登录密码     (env: AOS_PASSWORD, 默认 admin@2026)
  --page-size N       分页大小     (env: AOS_PAGE_SIZE, 默认 36)
  --out-dir DIR       报告输出目录 (env: AOS_OUT_DIR, 默认脚本所在目录)
  --self-check        自检模式
  -h, --help          帮助
```

配置优先级：**CLI 参数 > 环境变量（`AOS_*`）> 默认值**。

### 3.3 自检模式

```bash
./aos-snapshot-test.sh --self-check
```

依次执行 5 项检查并输出 PASS/FAIL 汇总：

1. bash 语法检查（`bash -n`）
2. Node.js 版本 ≥ 18
3. 内嵌 Node 引擎提取与语法检查（`node --check`）
4. API 服务连通性探测（10 秒超时）
5. contextId 参数格式校验（提供时才校验，未提供则 SKIP）

全部通过退出码 0，否则 1。

## 四、产出

| 产物 | 位置 |
|---|---|
| 分析报告 | `<out-dir>/aos-snapshot-report-<contextId前8位>-<时间戳>.md` |
| 标准输出 | 报告文件的绝对路径（stdout） |
| 运行日志 | 进度与结果信息（stderr，带 `[时间] [OK]/[FAIL]` 前缀） |

## 五、退出码

| 退出码 | 含义 |
|---|---|
| `0` | 成功（登录、拉取、报告生成全部通过） |
| `1` | 测试失败（登录失败 / API 错误 / 无 available 快照 / 自检有 FAIL 项） |
| `2` | 用法或致命错误（参数缺失/非法、引擎提取失败、无法创建目录等） |

## 六、内建自愈与健壮性机制

- **网络/5xx 重试**：请求层最多重试 2 次，5xx 与网络错误均按递增延迟（1s、2s）重试，单请求超时 30s（登录 20s）。
- **分页防死循环**：页数上限 50 页，`total` 或空页即停。
- **响应字段容错**：登录 Token 支持 `data.token / data.accessToken / token / accessToken` 多种结构；对象/链接计数支持 `counters.*` 与 `stats.*` 双回退。
- **临时文件自动清理**：`trap 'rm -f "$ENGINE_FILE"' EXIT`，异常退出也不留残余。
- **报告文件名防冲突**：使用 contextId 前 8 位 + 精确到秒的时间戳命名。

## 七、示例

```bash
# 1. 先自检确认环境就绪
./aos-snapshot-test.sh --self-check

# 2. 指定环境与账号执行测试
./aos-snapshot-test.sh \
  --base-url https://asdm-dt01.leansoftx.com \
  --email test01@asdm.ai \
  --password 'admin@2026' \
  --out-dir ./reports \
  3f2b8c1a-1234-5678-9abc-def012345678

# 3. 或使用环境变量
export AOS_BASE_URL=https://asdm-dt01.leansoftx.com
export AOS_EMAIL=test01@asdm.ai
export AOS_PASSWORD=admin@2026
export AOS_OUT_DIR=./reports
./aos-snapshot-test.sh 3f2b8c1a-1234-5678-9abc-def012345678
```

Windows（PowerShell / CMD）下通过 Git Bash 执行：

```powershell
& "D:\Program Files\Git\bin\bash.exe" d:\dev-src\Ai-Fast\ontology-test\aos-snapshot-test.sh --self-check
& "D:\Program Files\Git\bin\bash.exe" d:\dev-src\Ai-Fast\ontology-test\aos-snapshot-test.sh <contextId>
```

## 八、报告章节结构说明

| 章节 | 内容 |
|---|---|
| 一、API 调用自验证结果 | 登录 / 快照列表 / 分页完整性 / 计数自洽性的验证结论表 |
| 二、快照列表及核心数据 | 全部快照的 ID、completedAt、objectCount、linkCount、输入材料、默认标记 |
| 三、objectCount 明细对比 | 全部快照 × 13 类对象的计数矩阵（按完成时间升序），末行为合计 |
| 四、核心指标变化分析 | 最新两代快照的对象数/链接数/链接密度/违规数增量增幅 + 结论；仅 1 个快照时给出提示 |
| 五、数据质量异常提示 | 计数不自洽、时间戳异常（早于创建 / 恰差 8 小时时区疑似 / 延迟超 1h）清单 |
