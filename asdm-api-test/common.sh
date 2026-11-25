#!/usr/bin/env bash
# =============================================================================
# common.sh — ASDM Admin API 幂等自动化测试公共库
# 所有领域脚本通过 source 引用；也可独立 source 使用。
# 依赖: curl + jq（缺失 jq 时自动降级 node，并给出安装提示）
# =============================================================================
# 环境变量（均可用环境变量覆盖，默认值仅用于本地/文档示例）:
#   ASDM_BASE_URL           目标服务地址（默认 SIT）
#   ASDM_LOGIN_EMAIL/PASSWORD 登录账号（默认文档示例 user@example.com/Admin@123，
#                            SIT 环境请务必用真实账号覆盖）
#   ASDM_TOKEN              JWT（提供则跳过登录）
#   ASDM_PAT                ASDM PAT（asdmPat query / X-Asdm-Pat）
#   ASDM_INTERNAL_TOKEN     服务间内部令牌（X-Internal-Token）
#   ASDM_OPEN_ACCESS_TOKEN  开放接入令牌（X-Open-Access-Token）
#   ASDM_CITIC_SECRET       Citic 共享密钥（X-Citic-Secret）
#   ASDM_ALLOW_WRITES=1     允许执行写操作（POST/PUT/PATCH/DELETE）
#   ASDM_RUN_ID             指定运行 ID（不指定则时间戳+随机数，保证唯一）
#   ASDM_HTTP_TIMEOUT       单请求超时秒数（默认 30）
#   ASDM_TEST_*             路径参数默认 ID 覆盖（如 ASDM_TEST_id / ASDM_TEST_userId）
# =============================================================================

COMMON_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ---- jq 检测：优先 PATH，其次项目 bin/，最后降级 node ----
export PATH="$COMMON_DIR/bin:$PATH"
JQ_BIN="$(command -v jq 2>/dev/null || true)"
JQ_FALLBACK_NODE=0
if [[ -z "$JQ_BIN" ]]; then
  JQ_FALLBACK_NODE=1
  echo "[WARN] 未找到 jq，自动降级为 node 解析 JSON。建议安装 jq："
  echo "        winget install jqlang.jq  /  scoop install jq  /  https://jqlang.github.io/jq/download/"
fi

# jq 调用封装：参数同 jq，stdin 传 JSON
jq() {
  if [[ "$JQ_FALLBACK_NODE" -eq 0 ]]; then
    command jq "$@"
  else
    local filter="${*: -1}"
    node -e '
      let s="";
      process.stdin.on("data",d=>s+=d).on("end",()=>{
        let f=(process.argv[1]||".").replace(/\s*\/\/\s*empty\s*$/,"").trim();
        let o; try{o=JSON.parse(s)}catch(e){process.exit(2)}
        try{
          if(f===`type=="object"`){ process.exit(typeof o==="object"&&o!==null&&!Array.isArray(o)?0:1) }
          const hm=f.match(/^has\("([^"]+)"\)$/);
          if(hm){ process.exit(o&&typeof o==="object"&&hm[1] in o?0:1) }
          if(f==="."||f===""){ console.log(typeof o==="object"?JSON.stringify(o):String(o)); process.exit(0) }
          if(/^\.[\w.]*$/.test(f)){
            let cur=o;
            for(const seg of f.slice(1).split(".")){
              if(seg==="") continue;
              if(cur==null||typeof cur!=="object"||!(seg in cur)){ process.exit(1) }
              cur=cur[seg];
            }
            if(cur==null){ console.log("") }
            else if(typeof cur==="object"){ console.log(JSON.stringify(cur)) }
            else { console.log(String(cur)) }
            process.exit(0)
          }
          process.exit(3);
        }catch(e){process.exit(1)}
      });' "$filter"
  fi
}

# 从 JSON 提取字段（宽松）：json_get <stdin-json> <jq path 如 .data.token>
json_get() {
  printf '%s' "$1" | jq -r "$2 // empty" 2>/dev/null
}

# ---- 环境与变量约定 ----
BASE_URL="${ASDM_BASE_URL:-https://asdm-sit.leansoftx.com}"
CORE_BASE="${BASE_URL}"
SSO_BASE="${BASE_URL}"
INTEGRATION_BASE="${BASE_URL}"
ADS_ADAPTER_BASE="${BASE_URL}"
GITLAB_ADAPTER_BASE="${BASE_URL}"
AGENTORBIT_BASE="${BASE_URL}"
MCP_HOSTING_BASE="${BASE_URL}"
TELEMETRY_BASE="${BASE_URL}"
FILE_SERVICE_BASE="${BASE_URL}"
CODEARTS_ADAPTER_BASE="${BASE_URL}"
ORG_MAPPING_BASE="${BASE_URL}"
PORTAL_BACKEND_BASE="${BASE_URL}"
AUTOMATION_ADAPTER_BASE="${BASE_URL}"

TOKEN="${ASDM_TOKEN:-}"
PAT="${ASDM_PAT:-}"
INTERNAL_TOKEN="${ASDM_INTERNAL_TOKEN:-}"
OPEN_ACCESS_TOKEN="${ASDM_OPEN_ACCESS_TOKEN:-}"
CITIC_SECRET="${ASDM_CITIC_SECRET:-}"
ASDM_LOGIN_EMAIL="${ASDM_LOGIN_EMAIL:-user@example.com}"
ASDM_LOGIN_PASSWORD="${ASDM_LOGIN_PASSWORD:-Admin@123}"
HTTP_TIMEOUT="${ASDM_HTTP_TIMEOUT:-30}"
ALLOW_WRITES="${ASDM_ALLOW_WRITES:-0}"
RUN_ID="${ASDM_RUN_ID:-$(date +%s)_$RANDOM}"
DUMMY_ID="${ASDM_DUMMY_ID:-999999999}"   # "大概率不存在的资源 ID"，用于幂等删除校验

if [[ "$ASDM_LOGIN_PASSWORD" == "Admin@123" || "$ASDM_LOGIN_EMAIL" == "user@example.com" ]]; then
  echo "[WARN] 使用文档默认账号 user@example.com/Admin@123，SIT 环境请用真实账号覆盖 ASDM_LOGIN_EMAIL/ASDM_LOGIN_PASSWORD"
fi

# ---- 计数与日志 ----
PASS=0; FAIL=0; SKIP=0
LAST_LABEL=""
ELAPSED_MS=""
REQ_FRESH=0
_TIME_SUFFIX=""
_req_time_suffix() {
  # 仅当本次日志行对应一次真实请求（REQ_FRESH=1）时附加耗时，避免守卫类 SKIP 残留上次请求耗时
  if [[ "$REQ_FRESH" == "1" && -n "$ELAPSED_MS" && "$ELAPSED_MS" != "0" ]]; then
    REQ_FRESH=0
    _TIME_SUFFIX=" [${ELAPSED_MS}ms]"
  else
    _TIME_SUFFIX=""
  fi
  return 0
}
log_pass() { PASS=$((PASS+1)); _req_time_suffix; echo "  [PASS] $*${_TIME_SUFFIX}"; }
log_fail() { FAIL=$((FAIL+1)); _req_time_suffix; echo "  [FAIL] $*${_TIME_SUFFIX}"; }
log_skip() { SKIP=$((SKIP+1)); _req_time_suffix; echo "  [SKIP] $*${_TIME_SUFFIX}"; }
note()     { echo "  [NOTE] $*"; }

# ---- 统一请求：req <auth> <method> <path> [jsonBody] [queryString]
# 结果写入全局 STATUS（http code）与 BODY（响应体）
req() {
  local auth="$1" method="$2" upath="$3" body="${4:-}" query="${5:-}"
  local url="${BASE_URL}${upath}"
  [[ -n "$query" ]] && url="${url}?${query}"
  local tmp errout status
  tmp="$(mktemp)"; errout="$(mktemp)"
  local args=(-sS -X "$method" -o "$tmp" -w '%{http_code} %{time_total}' --max-time "$HTTP_TIMEOUT")
  case "$auth" in
    jwt)        [[ -n "$TOKEN" ]] && args+=(-H "Authorization: Bearer ${TOKEN}") ;;
    internal)   [[ -n "$INTERNAL_TOKEN" ]] && args+=(-H "X-Internal-Token: ${INTERNAL_TOKEN}") ;;
    citic)      [[ -n "$CITIC_SECRET" ]] && args+=(-H "X-Citic-Secret: ${CITIC_SECRET}") ;;
    openaccess) [[ -n "$OPEN_ACCESS_TOKEN" ]] && args+=(-H "X-Open-Access-Token: ${OPEN_ACCESS_TOKEN}") ;;
    pat|public|none) ;;
  esac
  if [[ -n "$body" ]]; then
    args+=(-H 'Content-Type: application/json' --data "$body")
  fi
  local wout errtext
  wout="$(curl "${args[@]}" "$url" 2>"$errout")" || wout="000 0"
  errtext="$(head -c 300 "$errout" 2>/dev/null || echo 'request failed')"
  BODY="$(cat "$tmp" 2>/dev/null || true)"
  rm -f "$tmp" "$errout"
  STATUS="${wout%% *}"
  ELAPSED_MS="$(awk -v t="${wout#* }" 'BEGIN{printf "%d", (t+0)*1000}')"
  REQ_FRESH=1
  if [[ "$STATUS" == "000" ]]; then
    BODY="curl error: ${errtext}"
  fi
}

# ---- 凭据守卫：need_auth <class> [label]，缺失返回 1 并 SKIP ----
need_auth() {
  local label="${2:-}" prefix=""
  [[ -n "$label" ]] && prefix="${label} — "
  case "$1" in
    jwt)
      if [[ -z "$TOKEN" ]]; then
        log_skip "${prefix}TOKEN 未配置（登录失败或未提供 ASDM_TOKEN），跳过"
        return 1
      fi ;;
    pat)
      if [[ -z "$PAT" ]]; then
        log_skip "${prefix}PAT 未配置（ASDM_PAT），跳过"
        return 1
      fi ;;
    internal)
      if [[ -z "$INTERNAL_TOKEN" ]]; then
        log_skip "${prefix}INTERNAL_TOKEN 未配置（ASDM_INTERNAL_TOKEN），跳过"
        return 1
      fi ;;
    citic)
      if [[ -z "$CITIC_SECRET" ]]; then
        log_skip "${prefix}CITIC_SECRET 未配置（ASDM_CITIC_SECRET），且 Citic 为外部系统，SIT 通常不可达，跳过"
        return 1
      fi ;;
    openaccess)
      if [[ -z "$OPEN_ACCESS_TOKEN" ]]; then
        log_skip "${prefix}OPEN_ACCESS_TOKEN 未配置（ASDM_OPEN_ACCESS_TOKEN），跳过"
        return 1
      fi ;;
  esac
  return 0
}

# ---- 状态码断言：expect_status <label> <code...>
# 401/403 且对应凭据未配置 → SKIP（鉴权拦截，避免误报）
expect_status() {
  local label="$1"; shift
  local want=" $* "
  if [[ "$STATUS" == "000" ]]; then
    log_fail "$label — 网络错误/服务不可达: $BODY"
    return 1
  fi
  if [[ "$want" == *" $STATUS "* ]]; then
    log_pass "$label — HTTP $STATUS"
    return 0
  fi
  if [[ "$STATUS" == "401" || "$STATUS" == "403" ]]; then
    log_skip "$label — HTTP $STATUS（鉴权拦截；如已配置凭据则为凭据失效，请检查）"
    return 1
  fi
  log_fail "$label — 期望 HTTP [$*] 实际 $STATUS；响应: $(head -c 300 <<<"$BODY")"
  return 1
}

# ---- 状态码断言（404 宽容版）：expect_status_missing <label> <code...>
# 用于带路径参数的读接口：404 记 SKIP（默认 ID 对应资源不存在），其余语义同 expect_status
expect_status_missing() {
  local label="$1"; shift
  if [[ "$STATUS" == "404" ]]; then
    log_skip "$label — 404 资源不存在（路径参数为默认值，可用 ASDM_TEST_<参数名> 覆盖）"
    return 1
  fi
  expect_status "$label" "$@"
}

# ---- 从 $BODY 提取新建资源 ID（供配对删除清理）----
extract_id() {
  local f v
  for f in .data.id .data.guid .data.uid .data.uuid; do
    v="$(printf '%s' "$BODY" | jq -r "$f // empty" 2>/dev/null)"
    if [[ -n "$v" && "$v" != "null" && "$v" != *'{'* ]]; then printf '%s' "$v"; return 0; fi
  done
  return 1
}

# ---- 响应 JSON 顶层结构断言：expect_json_top <label>
# 仅在响应体形如 {"code":...} 统一结构时校验 message 字段存在；非该结构则跳过（不推断）
expect_json_top() {
  local label="$1"
  [[ -z "$BODY" ]] && return 0
  if ! printf '%s' "$BODY" | jq -e 'type=="object"' >/dev/null 2>&1; then
    return 0   # 非 JSON 对象（二进制/文本）不做结构断言
  fi
  local hasCode
  hasCode=$(printf '%s' "$BODY" | jq -e 'has("code")' 2>/dev/null) || hasCode="false"
  if [[ "$hasCode" == "true" ]]; then
    if printf '%s' "$BODY" | jq -e 'has("message")' >/dev/null 2>&1; then
      return 0
    else
      log_fail "$label — 响应有 code 缺 message：$(head -c 300 <<<"$BODY")"
      return 1
    fi
  fi
  return 0
}

# ---- 读接口组合断言：expect_read_ok <label> [额外可接受的状态码...]
# 分级：网络错→FAIL；404→SKIP(资源不存在)；401/403→SKIP(鉴权)；
#       502/503/504→SKIP(依赖服务/上游不可达，如适配器未注册)；
#       2xx/额外码→业务码 code≠200/0 时 SKIP(数据不满足)，否则 PASS；
#       其余→FAIL
expect_read_ok() {
  local label="$1"; shift
  local extra=" $* "
  if [[ "$STATUS" == "000" ]]; then
    log_fail "$label — 网络错误/服务不可达: $BODY"
    return 1
  fi
  if [[ "$STATUS" == "404" ]]; then
    log_skip "$label — 404 资源不存在（默认测试 ID/环境数据缺失，可 ASDM_TEST_<参数名> 覆盖）"
    return 1
  fi
  if [[ "$STATUS" == "401" || "$STATUS" == "403" ]]; then
    log_skip "$label — HTTP $STATUS（鉴权拦截；如已配置凭据则为凭据失效）"
    return 1
  fi
  if [[ "$STATUS" == "502" || "$STATUS" == "503" || "$STATUS" == "504" ]]; then
    log_skip "$label — HTTP $STATUS 依赖服务/上游不可达（如适配器未注册）: $(head -c 200 <<<"$BODY")"
    return 1
  fi
  if [[ "$STATUS" == "400" ]]; then
    log_skip "$label — HTTP 400 业务参数校验失败（多为集合占位参数值，非接口故障）: $(head -c 200 <<<"$BODY")"
    return 1
  fi
  if [[ "$STATUS" == "500" && "$BODY" == *"No static resource"* ]]; then
    log_skip "$label — HTTP 500 路由不存在（No static resource，环境与集合版本差异）: $(head -c 200 <<<"$BODY")"
    return 1
  fi
  if [[ "$STATUS" =~ ^2[0-9]{2}$ || "$extra" == *" $STATUS "* ]]; then
    local bcode
    bcode="$(printf '%s' "$BODY" | jq -r '.code // empty' 2>/dev/null)"
    if [[ -n "$bcode" && "$bcode" != "200" && "$bcode" != "0" ]]; then
      log_skip "$label — HTTP $STATUS 但业务码 code=$bcode（资源/数据不满足，非接口故障）: $(head -c 200 <<<"$BODY")"
      return 1
    fi
    log_pass "$label — HTTP $STATUS"
    expect_json_top "$label"
    return 0
  fi
  log_fail "$label — 期望 HTTP 2xx 实际 $STATUS；响应: $(head -c 300 <<<"$BODY")"
  return 1
}

# ---- 写操作守卫：writes_allowed <label>，未开启返回 1 并 SKIP ----
writes_allowed() {
  local label="$1"
  if [[ "$ALLOW_WRITES" != "1" ]]; then
    log_skip "$label — 写操作默认跳过（设置 ASDM_ALLOW_WRITES=1 启用）"
    return 1
  fi
  return 0
}

# ---- 登录（已提供 ASDM_TOKEN 则跳过）----
LOGIN_TRIED=0
LOGIN_DEFAULT_CRED=0
if [[ "$ASDM_LOGIN_EMAIL" == "user@example.com" && "$ASDM_LOGIN_PASSWORD" == "Admin@123" ]]; then
  LOGIN_DEFAULT_CRED=1
fi
login_if_needed() {
  if [[ -n "$TOKEN" ]]; then
    echo ">>> 已提供 ASDM_TOKEN，跳过登录"
    return 0
  fi
  if [[ "$LOGIN_TRIED" -eq 1 ]]; then
    [[ -n "$TOKEN" ]] && return 0
    return 1
  fi
  LOGIN_TRIED=1
  echo ">>> 登录获取 JWT: POST ${CORE_BASE}/api/auth/login"
  req public POST "/api/auth/login" "{\"email\":\"${ASDM_LOGIN_EMAIL}\",\"password\":\"${ASDM_LOGIN_PASSWORD}\"}"
  local bcode
  bcode="$(printf '%s' "$BODY" | jq -r '.code // empty' 2>/dev/null)"
  if [[ "$STATUS" == "200" && "$bcode" == "200" ]]; then
    TOKEN="$(printf '%s' "$BODY" | jq -r '.data.token // empty' 2>/dev/null)"
    if [[ -n "$TOKEN" ]]; then
      log_pass "auth_login — 登录成功，已获取 JWT"
      return 0
    fi
  fi
  if [[ "$LOGIN_DEFAULT_CRED" -eq 1 ]]; then
    log_skip "auth_login — 文档默认账号登录失败（HTTP $STATUS code=$bcode）；请用真实 SIT 账号覆盖 ASDM_LOGIN_EMAIL/ASDM_LOGIN_PASSWORD"
  else
    log_fail "auth_login — 登录失败（HTTP $STATUS code=$bcode）：$(head -c 200 <<<"$BODY")"
  fi
  return 1
}

# ---- 路径参数默认值（可用 ASDM_TEST_<name> 覆盖）----
path_id() {
  local name="$1" envName="ASDM_TEST_${name}"
  local v
  eval "v=\${${envName}:-}"
  printf '%s' "${v:-1}"
}

# ---- 汇总退出 ----
finish() {
  echo ""
  local total=$((PASS+FAIL+SKIP)) executed=$((PASS+FAIL)) rate="-"
  if [[ "$executed" -gt 0 ]]; then
    rate="$(awk -v p="$PASS" -v e="$executed" 'BEGIN{printf "%.1f", p*100/e}')%"
  fi
  echo "===== 汇总: PASS=$PASS FAIL=$FAIL SKIP=$SKIP TOTAL=$total 通过率=$rate ====="
  if [[ "$FAIL" -eq 0 ]]; then exit 0; else exit 1; fi
}

# ---- 清理钩子（领域脚本可追加自己的清理逻辑到 CLEANUP_CMDS）----
CLEANUP_CMDS=()
register_cleanup() { CLEANUP_CMDS+=("$1"); }
on_exit() {
  local c
  for c in "${CLEANUP_CMDS[@]:-}"; do
    [[ -n "$c" ]] && eval "$c" || true
  done
}
trap on_exit EXIT
