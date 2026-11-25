## 提示词：为 ASDM Admin API 生成按业务领域划分的幂等自动化测试 Shell 脚本

### 角色
你是一名资深后端接口测试工程师，熟悉 Postman Collection v2.1 结构、RESTful API、JWT/PAT 鉴权、幂等性测试设计，以及 Bash + curl + jq 的自动化脚本编写。

### 输入
- 已提供的 Postman Collection JSON：`api.json`
- 目标服务地址（SIT 环境）：`https://asdm-sit.leansoftx.com/`
- 集合中定义了各服务 baseUrl 变量（core=8880、sso=8881、integration=8882 等），但本次统一使用 SIT 域名，按“服务前缀路径”区分，不再使用 localhost 端口。

### 任务
分析 `api.json` 的 `item` 顶层分组（即业务领域），为**每个业务领域**生成一个独立的自动化测试 shell 脚本。脚本必须可重复执行且结果稳定（幂等），不得因重复运行产生脏数据或失败。

### 业务领域识别规则
1. 以 `api.json` 顶层 `item[].name` 作为业务领域名称，例如：
   - `认证授权域`
   - `用户与组织管理域`
   - 以及文件中后续出现的其他顶层领域（如集成、适配器、AgentOrbit、MCP、遥测、文件服务、组织映射、门户后端、自动化适配器等，按实际 JSON 内容识别）。
2. 每个领域脚本只覆盖该领域下出现的接口；跨领域公共接口（如登录）可作为前置依赖调用，但不重复计入其他领域脚本的“被测接口”统计。
3. 若某领域下按服务再分组（如 `asdm-admin-services-core (端口 8880)`、`asdm-admin-services-sso (端口 8881)`），脚本内用注释或函数名前缀标明所属服务。

### 统一环境与变量约定
在每个脚本顶部定义并可被环境变量覆盖：

```bash
BASE_URL="${ASDM_BASE_URL:-https://asdm-sit.leansoftx.com}"
CORE_BASE="${BASE_URL}"
SSO_BASE="${BASE_URL}"
# 其他服务按 JSON 中路径前缀区分；如部署为独立域名，可通过环境变量覆盖
TOKEN="${ASDM_TOKEN:-}"
PAT="${ASDM_PAT:-}"
INTERNAL_TOKEN="${ASDM_INTERNAL_TOKEN:-}"
OPEN_ACCESS_TOKEN="${ASDM_OPEN_ACCESS_TOKEN:-}"
CITIC_SECRET="${ASDM_CITIC_SECRET:-}"
```

- 不使用 localhost 端口；所有请求 URL 为 `${BASE_URL}` + JSON 中的 `path`。
- 登录接口：`POST ${CORE_BASE}/api/auth/login`，请求体使用环境变量 `ASDM_LOGIN_EMAIL` / `ASDM_LOGIN_PASSWORD`，默认值可设为文档示例（如 `user@example.com` / `Admin@123`），但必须在脚本中提示“SIT 环境请用真实账号覆盖”。
- 登录成功后用 `jq -r '.data.token'` 提取 token 写入 `TOKEN`；若已提供 `ASDM_TOKEN` 则跳过登录。
- 需要 PAT 的接口使用 `Authorization: Bearer ${PAT}` 或查询参数 `asdmPat` / 请求头 `X-Asdm-Pat`，严格按 JSON 中该接口的 header/query 定义。

### 幂等性设计原则（必须遵守）
1. **读接口（GET）**：直接调用并校验 HTTP 状态码与响应 JSON 顶层结构（`code`、`message`、`data` 存在性），可重复执行。
2. **创建类接口（POST 创建资源）**：
   - 采用“先查询/后创建/再清理”或“唯一后缀 + 固定清理”策略。
   - 资源名称/邮箱等唯一字段使用固定前缀 + 运行 ID（如 `test_$(date +%s)_$RANDOM`），避免冲突；脚本退出时通过 `trap` 清理已创建资源（若存在删除接口）。
   - 若接口本身支持幂等键（如 `requestId`），传入固定或可复现的 requestId。
3. **更新类接口（PUT/PATCH）**：先 GET 当前状态，再 PUT 为目标状态，最后可恢复原状态（若安全）；断言更新后的字段值。
4. **删除类接口（DELETE）**：先确保资源存在（不存在则创建或跳过并标记 SKIP），删除后再次 DELETE 应返回成功或“已不存在”的幂等结果；不得因重复删除导致脚本失败。
5. **批量/映射类接口**：使用固定测试用户/映射范围，执行前先查询并记录，执行后回滚或删除本次新增映射；对 `batch-upsert` 使用固定 `requestId`。
6. **认证/SSO 跳转类接口**：仅校验重定向状态码（301/302）或公开接口返回结构，不跟随跳转产生副作用；设备码/令牌交换类使用一次性 code，重复执行时重新获取 code。
7. **公开接口**（`register-status`、`verify`、`login` 等）：只读校验，重复执行安全；`register` 若会创建用户，使用唯一邮箱并在脚本中说明“SIT 环境可能禁用注册，按 `register-status` 结果决定 SKIP”。
8. 所有写操作失败时输出响应体，便于排查；脚本整体返回码：全部通过=0，有失败=1，全部跳过=0 并打印 SKIP 汇总。

### 脚本结构规范
每个领域脚本采用以下结构：

```bash
#!/usr/bin/env bash
set -euo pipefail

# ===== 环境变量与公共函数 =====
BASE_URL="${ASDM_BASE_URL:-https://asdm-sit.leansoftx.com}"
...
PASS=0; FAIL=0; SKIP=0
log_pass(){ ...; }; log_fail(){ ...; }; log_skip(){ ...; }
api_call(){ # method path [body] [extra_curl_args...]
  # 统一 curl -sS -w "\n%{http_code}"，分离 body 与 status
}
assert_http(){ ...; }
assert_json(){ ...; } # 用 jq -e 校验字段存在/值
login_if_needed(){ ...; }
cleanup(){ ...; }
trap cleanup EXIT

# ===== 被测接口用例 =====
test_xxx(){ ...; }

main(){
  login_if_needed
  test_xxx
  ...
  echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP"
  [[ $FAIL -eq 0 ]]
}
main "$@"
```

要求：
- 使用 `curl` + `jq`，不依赖 Postman/newman；若环境无 `jq` 则脚本开头检测并提示安装。
- 每个接口至少一个用例函数，函数名体现“领域_接口名”，如 `auth_login`、`admin_users_list`。
- 对 JSON 中标注【推断】的请求/响应字段，断言只校验确定存在的顶层结构，不断言推断字段的具体值。
- 对需要路径参数的接口，使用固定测试 ID（如 `1`）或先查询列表取第一个 ID；若列表为空则 SKIP 并说明。
- 请求头严格按 JSON 定义：需要 JWT 的加 `Authorization: Bearer ${TOKEN}`；内部接口加 `X-Internal-Token: ${INTERNAL_TOKEN}`；Citic 加 `X-Citic-Secret`；OpenAccess 加 `X-Open-Access-Token`；PAT 接口按 JSON 中 `asdmPat` 查询参数或 `X-Asdm-Pat` 头。
- 不把真实密码、token 硬编码进脚本；敏感值全部走环境变量，默认值仅用于文档示例并打印警告。

### 输出要求
1. 先输出一份**领域清单表**：领域名称、包含的服务、接口数量、脚本文件名（如 `test_auth_domain.sh`、`test_user_org_domain.sh`）。
2. 再为每个领域输出完整 shell 脚本，脚本之间可共用一个 `common.sh`（登录、断言、api_call 等公共函数），但每个领域脚本必须能独立运行（通过 `source ./common.sh`，若不存在则内联公共函数或提示）。
3. 每个脚本末尾输出 PASS/FAIL/SKIP 汇总，并以非零退出码表示失败。
4. 对因 SIT 环境限制（如注册关闭、SSO 需人工跳转、外部 Citic 不可达）而无法稳定执行的接口，脚本中标记 SKIP 并写明原因，不强行断言。
5. 最后给出运行说明：如何设置 `ASDM_BASE_URL`、`ASDM_LOGIN_EMAIL`、`ASDM_LOGIN_PASSWORD`、`ASDM_TOKEN`、`ASDM_PAT` 等变量，如何批量执行所有领域脚本并汇总结果。
6. 脚本输出目录 `asdm-api-test`

### 质量校验清单（生成后自检）
- [ ] 每个顶层业务领域都有对应脚本，接口无遗漏（按 JSON 中 `request.method` + `url.path` 计数核对）。
- [ ] 所有 URL 均基于 `https://asdm-sit.leansoftx.com/`，无 localhost 端口残留。
- [ ] 重复执行同一脚本两次，第二次结果与第一次一致（无唯一键冲突、无重复删除失败）。
- [ ] 写操作均有清理或回滚路径，`trap` 覆盖异常退出。
- [ ] 鉴权头/查询参数与 JSON 定义一致，未混用 JWT 与 PAT。
- [ ] 断言只依赖确定字段，不断言【推断】字段的具体值。
- [ ] 脚本无硬编码敏感信息，环境变量缺失时有明确提示。

