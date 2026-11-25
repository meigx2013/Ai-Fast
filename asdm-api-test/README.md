# ASDM Admin API 幂等自动化测试

基于 Postman Collection `api.json`（1000 个接口）自动生成的分领域 Shell 测试脚本。
统一走 SIT 域名（`https://asdm-sit.leansoftx.com`），按 URL 路径前缀区分服务，不使用 localhost 端口。

## 目录结构

```
asdm-api-test/
├── api.json                  # Postman Collection v2.1（输入）
├── common.sh                 # 公共库（登录 / req / 断言 / 凭据守卫 / 清理钩子）
├── run-all.sh                # 批量执行全部领域并汇总
├── bin/jq.exe                # 内置 jq 1.7.1（自动加入 PATH）
├── gen/
│   ├── extract.js            # api.json → gen/domains.json 结构化摘要
│   ├── generate.js           # domains.json → tests/test_*_domain.sh
│   ├── domains.json          # 中间产物（领域/接口/鉴权/请求示例）
│   └── check-syntax.sh       # bash -n 语法检查
└── tests/                    # 12 个领域脚本（见下表）
```

## 领域清单

| 领域 | 服务 | 接口数 | 脚本 |
|---|---|---|---|
| 认证授权域 | core, sso | 53 | `tests/test_auth_domain.sh` |
| 用户与组织管理域 | core, org-mapping | 81 | `tests/test_user_org_domain.sh` |
| 项目管理域 | core | 36 | `tests/test_project_domain.sh` |
| 工作空间域 | agentorbit, core | 94 | `tests/test_workspace_domain.sh` |
| 上下文库域 | core | 95 | `tests/test_context_domain.sh` |
| 流水线域 | core | 22 | `tests/test_pipeline_domain.sh` |
| 资产注册域 | core | 88 | `tests/test_asset_registry_domain.sh` |
| 集成域 | adapter-ads, adapter-automation, adapter-codearts, adapter-gitlab, core, integration | 209 | `tests/test_integration_domain.sh` |
| 代码评审域 | core | 18 | `tests/test_pr_review_domain.sh` |
| 门户与内容域 | core, portal-backend | 97 | `tests/test_portal_domain.sh` |
| 基础设施域 | core, file-service, mcp-hosting, telemetry | 152 | `tests/test_infra_domain.sh` |
| 数字分身域 | agentorbit | 55 | `tests/test_twin_domain.sh` |

## 运行

```bash
# Git Bash（推荐，Windows 下路径 D:\Program Files\Git\bin\bash.exe）
cd asdm-api-test

# 1) 基础冒烟（读接口直测；写操作默认跳过；无凭据时相关用例自动 SKIP）
./run-all.sh                      # 全部 12 个领域
./run-all.sh auth portal          # 指定领域（slug 见文件名）
bash tests/test_auth_domain.sh    # 单独运行一个领域脚本

# 2) 带真实凭据（覆盖面自动扩大）
export ASDM_LOGIN_EMAIL='you@leansoftx.com'
export ASDM_LOGIN_PASSWORD='******'
./run-all.sh

# 或直接提供 token 跳过登录
export ASDM_TOKEN='<jwt>'
export ASDM_PAT='<pat>'                   # asdmPat / X-Asdm-Pat 接口
export ASDM_INTERNAL_TOKEN='<internal>'   # X-Internal-Token 接口
export ASDM_OPEN_ACCESS_TOKEN='<oat>'     # X-Open-Access-Token 接口
export ASDM_CITIC_SECRET='<secret>'       # Citic 外部接口（SIT 通常不可达）

# 3) 启用写操作（POST/PUT/PATCH/DELETE，默认 GUARDED 跳过）
export ASDM_ALLOW_WRITES=1
```

## 环境变量

| 变量 | 说明 | 默认 |
|---|---|---|
| `ASDM_BASE_URL` | 目标服务地址 | `https://asdm-sit.leansoftx.com` |
| `ASDM_LOGIN_EMAIL` / `ASDM_LOGIN_PASSWORD` | 登录账号（**SIT 请务必覆盖**） | `user@example.com` / `Admin@123`（仅文档示例，失败记 SKIP） |
| `ASDM_TOKEN` | JWT，提供则跳过登录 | 空 |
| `ASDM_PAT` / `ASDM_INTERNAL_TOKEN` / `ASDM_OPEN_ACCESS_TOKEN` / `ASDM_CITIC_SECRET` | 各类鉴权凭据 | 空（缺失时对应接口 SKIP） |
| `ASDM_ALLOW_WRITES` | `1` 时执行写操作 | `0`（全部写操作 SKIP） |
| `ASDM_RUN_ID` | 运行 ID（写操作唯一后缀） | 时间戳+随机数 |
| `ASDM_TEST_<参数名>` | 路径参数覆盖，如 `ASDM_TEST_projectId=42` | `1` |
| `ASDM_DUMMY_ID` | DELETE 幂等校验用的"不存在资源 ID" | `999999999` |
| `ASDM_HTTP_TIMEOUT` | 单请求超时（秒） | `30` |

## 幂等性设计

- **读接口（GET/HEAD）**：直接调用；断言分级——2xx+业务码 200 → PASS；
  404（资源不存在）/ 401·403（鉴权）/ 400（占位参数）/ 502·503·504（依赖不可达）/
  500 "No static resource"（路由差异）→ SKIP（重复执行结果稳定）；其余 → FAIL。
- **写接口（POST/PUT/PATCH/DELETE）**：默认 SKIP（`ASDM_ALLOW_WRITES=1` 启用）：
  - POST：`email/username/name/displayName/title/nickname` 注入 `__RUN_ID__` 唯一后缀；
    `requestId/idempotencyKey` 固定为可复现幂等键；过期 `expiresAt` 推远至 2099。
  - POST + 可配对同域 DELETE：走「创建 → 提取 ID → 删除 → 再删（断言 200/404 幂等）」链，无残留。
  - DELETE：对 `DUMMY_ID`（不存在资源）执行，断言 200（服务端幂等）或 404，防误删真实数据。
  - PUT/PATCH：404 → SKIP（资源不存在）。
- **永久跳过**：改密码 / 登出（作废 JWT）/ 注册（创建真实用户无自清理）/ 实例
  stop·start·restart·migrate·reset·clean 等状态破坏段 / 静态路径整体删除 / multipart 文件上传。
- **退出码**：全部通过或全部跳过 = 0；有 FAIL = 1。末尾输出 `PASS= FAIL= SKIP=` 汇总。

## 重新生成脚本

修改 `api.json` 后：

```bash
node gen/extract.js     # api.json → gen/domains.json
node gen/generate.js    # domains.json → tests/*.sh
bash gen/check-syntax.sh
```

## 已知环境限制（SIT 实测）

- 默认文档账号无法登录：JWT 类接口全部 SKIP（用真实账号后恢复）。
- PAT / X-Internal-Token / OpenAccess / Citic 凭据未配置：对应接口 SKIP。
- `/_api/org-mapping/*` 部分子路由返回 500 "No static resource"（环境与集合版本差异）。
- Automation 适配器未注册时 `/api/integrations/*` health 返回 503 → SKIP。
