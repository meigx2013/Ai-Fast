#!/usr/bin/env bash
# ============================================================================
# 工作空间域 — 幂等自动化测试（由 gen/generate.js 从 api.json 生成，勿手工修改）
# 重新生成: node gen/generate.js
# 覆盖服务: agentorbit, core
# 接口总数: 94（读 47 直测 / 写 38 受控[含配对清理 8] / 永久跳过 9）
# 环境变量: ASDM_BASE_URL / ASDM_LOGIN_EMAIL / ASDM_LOGIN_PASSWORD / ASDM_TOKEN /
#           ASDM_PAT / ASDM_INTERNAL_TOKEN / ASDM_OPEN_ACCESS_TOKEN / ASDM_CITIC_SECRET /
#           ASDM_ALLOW_WRITES=1（执行写操作）/ ASDM_TEST_<参数名>（路径参数覆盖）
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ===== 被测接口用例 =====
# seq171 asdm-admin-services-agentorbit (端口 8884)/InstanceDaemon | auth=jwt（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_agentorbit_instances_instanceId_users_asdmUserId_en() {
  local label="POST /api/agentorbit/instances/:instanceId/users/:asdmUserId/ensure-daemon-ready — 完整路径：POST /api/agentorbit/instances/:instanceId/users/:asdmU"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/agentorbit/instances/$(path_id instanceId)/users/$(path_id asdmUserId)/ensure-daemon-ready" "" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq172 asdm-admin-services-agentorbit (端口 8884)/InstanceValidation | auth=jwt（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_agentorbit_instances_check_twin() {
  local label="POST /api/agentorbit/instances/check-twin — 所属控制器：Validation and context endpoints for digital twin crea"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "collectionId": 1,
  "projectId": 1,
  "userId": 1,
  "keyType": "string",
  "imageId": "string"
}
JSONEOF
)"
  req jwt POST "/api/agentorbit/instances/check-twin" "$body" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq173 asdm-admin-services-agentorbit (端口 8884)/InstanceValidation | auth=jwt（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_agentorbit_instances_check_workspace() {
  local label="POST /api/agentorbit/instances/check-workspace — 所属控制器：Validation and context endpoints for digital twin crea"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "collectionId": 1,
  "projectId": 1,
  "imageId": "string",
  "scope": "string"
}
JSONEOF
)"
  req jwt POST "/api/agentorbit/instances/check-workspace" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq174 asdm-admin-services-agentorbit (端口 8884)/InstanceValidation | auth=jwt
workspace_get_api_agentorbit_instances_context_info() {
  local label="GET /api/agentorbit/instances/context-info — 所属控制器：Validation and context endpoints for digital twin crea"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/instances/context-info" "" "projectId=1&userId=1"
  expect_read_ok "$label" 200
}

# seq175 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal（无配对删除接口，失败请人工核查数据残留）
workspace_post_internal_workspaces() {
  local label="POST /internal/workspaces — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req internal POST "/internal/workspaces" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq176 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_get_internal_workspaces() {
  local label="GET /internal/workspaces — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  need_auth internal "$label" || return 0
  req internal GET "/internal/workspaces" "" ""
  expect_read_ok "$label" 200
}

# seq177 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_get_internal_workspaces_instanceId() {
  local label="GET /internal/workspaces/:instanceId — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  need_auth internal "$label" || return 0
  req internal GET "/internal/workspaces/$(path_id instanceId)" "" ""
  expect_read_ok "$label" 200
}

# seq178 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal（无配对删除接口，失败请人工核查数据残留）
workspace_post_internal_workspaces_instanceId() {
  local label="POST /internal/workspaces/:instanceId — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  req internal POST "/internal/workspaces/$(path_id instanceId)" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq179 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_get_internal_workspaces_instanceId_artifact_context() {
  local label="GET /internal/workspaces/:instanceId/artifact-context — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  need_auth internal "$label" || return 0
  req internal GET "/internal/workspaces/$(path_id instanceId)/artifact-context" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq180 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_post_internal_workspaces_instanceId_artifacts() {
  log_skip "POST /internal/workspaces/:instanceId/artifacts — 需要 multipart 文件上传，无法幂等自动执行（所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通）"
}

# seq181 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_get_internal_workspaces_instanceId_artifacts() {
  local label="GET /internal/workspaces/:instanceId/artifacts — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  need_auth internal "$label" || return 0
  req internal GET "/internal/workspaces/$(path_id instanceId)/artifacts" "" "userId=1&artifactId=string"
  expect_read_ok "$label" 200
}

# seq182 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_get_internal_workspaces_instanceId_artifacts_download() {
  local label="GET /internal/workspaces/:instanceId/artifacts/download — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  need_auth internal "$label" || return 0
  req internal GET "/internal/workspaces/$(path_id instanceId)/artifacts/download" "" "userId=1&path=%2Ftmp%2Fexample"
  expect_read_ok "$label" 200
}

# seq183 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal（配对清理: POST /internal/workspaces/:instanceId/projects/:projectId）
workspace_post_internal_workspaces_instanceId_connect() {
  local label="POST /internal/workspaces/:instanceId/connect — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req internal POST "/internal/workspaces/$(path_id instanceId)/connect" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /internal/workspaces/:instanceId/projects/:projectId
  req internal DELETE "/internal/workspaces/${rid}/projects/$(path_id projectId)" "" "userId=1"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req internal DELETE "/internal/workspaces/${rid}/projects/$(path_id projectId)" "" "userId=1"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq184 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_get_internal_workspaces_instanceId_connection_status() {
  local label="GET /internal/workspaces/:instanceId/connection-status — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  need_auth internal "$label" || return 0
  req internal GET "/internal/workspaces/$(path_id instanceId)/connection-status" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq185 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal（配对清理: POST /internal/workspaces/:instanceId/projects/:projectId）
workspace_post_internal_workspaces_instanceId_enter() {
  local label="POST /internal/workspaces/:instanceId/enter — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req internal POST "/internal/workspaces/$(path_id instanceId)/enter" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /internal/workspaces/:instanceId/projects/:projectId
  req internal DELETE "/internal/workspaces/${rid}/projects/$(path_id projectId)" "" "userId=1"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req internal DELETE "/internal/workspaces/${rid}/projects/$(path_id projectId)" "" "userId=1"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq186 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_post_internal_workspaces_instanceId_generation_stop() {
  log_skip "POST /internal/workspaces/:instanceId/generation/stop — 永久跳过：路径含状态变更/清理类操作段（stop），避免破坏环境"
}

# seq187 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal（配对清理: POST /internal/workspaces/:instanceId/projects/:projectId）
workspace_post_internal_workspaces_instanceId_projects() {
  local label="POST /internal/workspaces/:instanceId/projects — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req internal POST "/internal/workspaces/$(path_id instanceId)/projects" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /internal/workspaces/:instanceId/projects/:projectId
  req internal DELETE "/internal/workspaces/${rid}/projects/$(path_id projectId)" "" "userId=1"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req internal DELETE "/internal/workspaces/${rid}/projects/$(path_id projectId)" "" "userId=1"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq188 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_get_internal_workspaces_instanceId_projects() {
  local label="GET /internal/workspaces/:instanceId/projects — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  need_auth internal "$label" || return 0
  req internal GET "/internal/workspaces/$(path_id instanceId)/projects" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq189 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_get_internal_workspaces_instanceId_projects_projectId() {
  local label="GET /internal/workspaces/:instanceId/projects/:projectId — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  need_auth internal "$label" || return 0
  req internal GET "/internal/workspaces/$(path_id instanceId)/projects/$(path_id projectId)" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq190 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_delete_internal_workspaces_instanceId_projects_projectId() {
  local label="DELETE /internal/workspaces/:instanceId/projects/:projectId — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req internal DELETE "/internal/workspaces/${DUMMY_ID}/projects/${DUMMY_ID}" "" "userId=1"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq191 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_post_internal_workspaces_instanceId_restart() {
  log_skip "POST /internal/workspaces/:instanceId/restart — 永久跳过：路径含状态变更/清理类操作段（restart），避免破坏环境"
}

# seq192 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal（配对清理: POST /internal/workspaces/:instanceId/projects/:projectId）
workspace_post_internal_workspaces_instanceId_sessions() {
  local label="POST /internal/workspaces/:instanceId/sessions — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req internal POST "/internal/workspaces/$(path_id instanceId)/sessions" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /internal/workspaces/:instanceId/projects/:projectId
  req internal DELETE "/internal/workspaces/${rid}/projects/$(path_id projectId)" "" "userId=1"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req internal DELETE "/internal/workspaces/${rid}/projects/$(path_id projectId)" "" "userId=1"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq193 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_get_internal_workspaces_instanceId_sessions() {
  local label="GET /internal/workspaces/:instanceId/sessions — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  need_auth internal "$label" || return 0
  req internal GET "/internal/workspaces/$(path_id instanceId)/sessions" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq194 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal（无配对删除接口，失败请人工核查数据残留）
workspace_post_internal_workspaces_instanceId_sessions_sessionId() {
  local label="POST /internal/workspaces/:instanceId/sessions/:sessionId — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  req internal POST "/internal/workspaces/$(path_id instanceId)/sessions/$(path_id sessionId)" "" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq195 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_get_internal_workspaces_instanceId_sessions_sessionId_histor() {
  local label="GET /internal/workspaces/:instanceId/sessions/:sessionId/history — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  need_auth internal "$label" || return 0
  req internal GET "/internal/workspaces/$(path_id instanceId)/sessions/$(path_id sessionId)/history" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq196 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal（无配对删除接口，失败请人工核查数据残留）
workspace_post_internal_workspaces_instanceId_sessions_sessionId_model() {
  local label="POST /internal/workspaces/:instanceId/sessions/:sessionId/model — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req internal POST "/internal/workspaces/$(path_id instanceId)/sessions/$(path_id sessionId)/model" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq197 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_get_internal_workspaces_instanceId_sessions_sessionId_models() {
  local label="GET /internal/workspaces/:instanceId/sessions/:sessionId/models — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  need_auth internal "$label" || return 0
  req internal GET "/internal/workspaces/$(path_id instanceId)/sessions/$(path_id sessionId)/models" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq198 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal（无配对删除接口，失败请人工核查数据残留）
workspace_post_internal_workspaces_instanceId_sessions_switch() {
  local label="POST /internal/workspaces/:instanceId/sessions/switch — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req internal POST "/internal/workspaces/$(path_id instanceId)/sessions/switch" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq199 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_post_internal_workspaces_instanceId_stop() {
  log_skip "POST /internal/workspaces/:instanceId/stop — 永久跳过：路径含状态变更/清理类操作段（stop），避免破坏环境"
}

# seq200 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal（配对清理: POST /internal/workspaces/:instanceId/projects/:projectId）
workspace_post_internal_workspaces_instanceId_workspace_artifacts() {
  local label="POST /internal/workspaces/:instanceId/workspace-artifacts — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  req internal POST "/internal/workspaces/$(path_id instanceId)/workspace-artifacts" "" "userId=1&path=%2Ftmp%2Fexample"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /internal/workspaces/:instanceId/projects/:projectId
  req internal DELETE "/internal/workspaces/${rid}/projects/$(path_id projectId)" "" "userId=1"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req internal DELETE "/internal/workspaces/${rid}/projects/$(path_id projectId)" "" "userId=1"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq201 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_get_internal_workspaces_workspaceId_images() {
  local label="GET /internal/workspaces/:workspaceId/images — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  need_auth internal "$label" || return 0
  req internal GET "/internal/workspaces/$(path_id workspaceId)/images" "" ""
  expect_read_ok "$label" 200
}

# seq202 asdm-admin-services-agentorbit (端口 8884)/InternalWorkspaceOpenAccess | auth=internal
workspace_get_internal_workspaces_workspaces_workspaceId_access() {
  local label="GET /internal/workspaces/workspaces/:workspaceId/access — 所属控制器：} 生效）。 调用方（core）在固定请求头 {@code X-Open-Access-Token} 校验通"
  need_auth internal "$label" || return 0
  req internal GET "/internal/workspaces/workspaces/$(path_id workspaceId)/access" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq203 asdm-admin-services-agentorbit (端口 8884)/WorkspaceInstance | auth=jwt（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_agentorbit_workspaces_workspaceId_clone_default_pro() {
  local label="POST /api/agentorbit/workspaces/:workspaceId/clone-default-project — 完整路径：POST /api/agentorbit/workspaces/:workspaceId/clone-defa"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/agentorbit/workspaces/$(path_id workspaceId)/clone-default-project" "" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq204 asdm-admin-services-agentorbit (端口 8884)/WorkspaceInstance | auth=jwt（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_agentorbit_workspaces_workspaceId_ensure_instance() {
  local label="POST /api/agentorbit/workspaces/:workspaceId/ensure-instance — 完整路径：POST /api/agentorbit/workspaces/:workspaceId/ensure-ins"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/agentorbit/workspaces/$(path_id workspaceId)/ensure-instance" "$body" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq205 asdm-admin-services-agentorbit (端口 8884)/WorkspaceInstance | auth=jwt（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_agentorbit_workspaces_workspaceId_enter_member() {
  local label="POST /api/agentorbit/workspaces/:workspaceId/enter-member — 完整路径：POST /api/agentorbit/workspaces/:workspaceId/enter-memb"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "username": "example__RUN_ID__",
 "agentType": "string"
}
JSONEOF
)"
  req jwt POST "/api/agentorbit/workspaces/$(path_id workspaceId)/enter-member" "$body" "userId=1&jwtUsername=example"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq206 asdm-admin-services-agentorbit (端口 8884)/WorkspaceInstance | auth=jwt（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_agentorbit_workspaces_workspaceId_prune_unbound_rep() {
  local label="POST /api/agentorbit/workspaces/:workspaceId/prune-unbound-repositories — 完整路径：POST /api/agentorbit/workspaces/:workspaceId/prune-unbo"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/agentorbit/workspaces/$(path_id workspaceId)/prune-unbound-repositories" "" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq207 asdm-admin-services-core (端口 8880)/在线智能体空间开放 API | auth=jwt
workspace_get_api_v1_agentorbit_workspace_artifacts_artifactId() {
  local label="GET /api/v1/agentorbit/workspace-artifacts/:artifactId — 摘要：下载智能体空间制品（按 artifactId） 完整路径：GET /api/v1/agentorbit/works"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/agentorbit/workspace-artifacts/$(path_id artifactId)" "" ""
  expect_read_ok "$label" 200
}

# seq208 asdm-admin-services-core (端口 8880)/Agent Tasks | auth=jwt（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_agent_tasks() {
  local label="POST /api/agent-tasks — 摘要：提交通用任务（契约模式 / CODING 报文模式） 说明：认证：body asdm_pat 优先，Authori"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/agent-tasks" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq209 asdm-admin-services-core (端口 8880)/Agent Tasks | auth=jwt
workspace_get_api_agent_tasks_taskId() {
  local label="GET /api/agent-tasks/:taskId — 摘要：查询通用任务 说明：认证：asdm_pat（query 或 Authorization）；权限：任务归属项目 RE"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agent-tasks/$(path_id taskId)" "" ""
  expect_read_ok "$label" 200
}

# seq210 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=openaccess（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_v1_agentorbit_workspaces() {
  local label="POST /api/v1/agentorbit/workspaces — 摘要：创建在线智能体空间实例 完整路径：POST /api/v1/agentorbit/workspaces（服务：as"
  writes_allowed "$label" || return 0
  need_auth openaccess "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req openaccess POST "/api/v1/agentorbit/workspaces" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq211 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_get_api_v1_agentorbit_workspaces() {
  local label="GET /api/v1/agentorbit/workspaces — 摘要：查询全部在线智能体空间（不限用户） 完整路径：GET /api/v1/agentorbit/workspaces（"
  need_auth public "$label" || return 0
  req public GET "/api/v1/agentorbit/workspaces" "" ""
  expect_read_ok "$label" 200
}

# seq212 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_get_api_v1_agentorbit_workspaces_instanceId() {
  local label="GET /api/v1/agentorbit/workspaces/:instanceId — 摘要：查询在线智能体空间实例信息 完整路径：GET /api/v1/agentorbit/workspaces/:ins"
  need_auth public "$label" || return 0
  req public GET "/api/v1/agentorbit/workspaces/$(path_id instanceId)" "" ""
  expect_read_ok "$label" 200
}

# seq213 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_v1_agentorbit_workspaces_instanceId() {
  local label="POST /api/v1/agentorbit/workspaces/:instanceId — 摘要：删除实例 完整路径：POST /api/v1/agentorbit/workspaces/:instanceId（"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  req public POST "/api/v1/agentorbit/workspaces/$(path_id instanceId)" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq214 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_post_api_v1_agentorbit_workspaces_instanceId_artifacts() {
  log_skip "POST /api/v1/agentorbit/workspaces/:instanceId/artifacts — 需要 multipart 文件上传，无法幂等自动执行（摘要：上传制品（写入实例工作目录） 完整路径：POST /api/v1/agentorbit/workspaces/:i）"
}

# seq215 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_get_api_v1_agentorbit_workspaces_instanceId_artifacts() {
  local label="GET /api/v1/agentorbit/workspaces/:instanceId/artifacts — 摘要：下载文件（按相对 _default 路径） 完整路径：GET /api/v1/agentorbit/workspa"
  need_auth public "$label" || return 0
  req public GET "/api/v1/agentorbit/workspaces/$(path_id instanceId)/artifacts" "" "path=%2Ftmp%2Fexample"
  expect_read_ok "$label" 200
}

# seq216 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=pat（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_v1_agentorbit_workspaces_instanceId_connect() {
  local label="POST /api/v1/agentorbit/workspaces/:instanceId/connect — 摘要：获取连接信息（ACP HTTP/WS 地址 + iframe URL；必带 X-Asdm-Pat） 完整路径：PO"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req pat POST "/api/v1/agentorbit/workspaces/$(path_id instanceId)/connect" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq217 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_get_api_v1_agentorbit_workspaces_instanceId_connection_statu() {
  local label="GET /api/v1/agentorbit/workspaces/:instanceId/connection-status — 摘要：查询指定用户在实例上的活跃连接状态 完整路径：GET /api/v1/agentorbit/workspaces/"
  need_auth public "$label" || return 0
  req public GET "/api/v1/agentorbit/workspaces/$(path_id instanceId)/connection-status" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq218 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=pat（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_v1_agentorbit_workspaces_instanceId_enter() {
  local label="POST /api/v1/agentorbit/workspaces/:instanceId/enter — 摘要：进入实例（返回成员环境与嵌入地址；必带 X-Asdm-Pat） 完整路径：POST /api/v1/agentor"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req pat POST "/api/v1/agentorbit/workspaces/$(path_id instanceId)/enter" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq219 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_post_api_v1_agentorbit_workspaces_instanceId_generation_stop() {
  log_skip "POST /api/v1/agentorbit/workspaces/:instanceId/generation/stop — 永久跳过：路径含状态变更/清理类操作段（stop），避免破坏环境"
}

# seq220 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_get_api_v1_agentorbit_workspaces_instanceId_projects() {
  local label="GET /api/v1/agentorbit/workspaces/:instanceId/projects — 摘要：查询实例内成员项目列表 完整路径：GET /api/v1/agentorbit/workspaces/:insta"
  need_auth public "$label" || return 0
  req public GET "/api/v1/agentorbit/workspaces/$(path_id instanceId)/projects" "" ""
  expect_read_ok "$label" 200
}

# seq221 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_v1_agentorbit_workspaces_instanceId_projects() {
  local label="POST /api/v1/agentorbit/workspaces/:instanceId/projects — 摘要：创建实例内成员项目 完整路径：POST /api/v1/agentorbit/workspaces/:instan"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req public POST "/api/v1/agentorbit/workspaces/$(path_id instanceId)/projects" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq222 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_get_api_v1_agentorbit_workspaces_instanceId_projects_project() {
  local label="GET /api/v1/agentorbit/workspaces/:instanceId/projects/:projectId — 摘要：查询实例内成员项目详情 完整路径：GET /api/v1/agentorbit/workspaces/:insta"
  need_auth public "$label" || return 0
  req public GET "/api/v1/agentorbit/workspaces/$(path_id instanceId)/projects/$(path_id projectId)" "" ""
  expect_read_ok "$label" 200
}

# seq223 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_v1_agentorbit_workspaces_instanceId_projects_projec() {
  local label="POST /api/v1/agentorbit/workspaces/:instanceId/projects/:projectId — 摘要：删除实例内成员项目 完整路径：POST /api/v1/agentorbit/workspaces/:instan"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req public POST "/api/v1/agentorbit/workspaces/$(path_id instanceId)/projects/$(path_id projectId)" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq224 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_post_api_v1_agentorbit_workspaces_instanceId_restart() {
  log_skip "POST /api/v1/agentorbit/workspaces/:instanceId/restart — 永久跳过：路径含状态变更/清理类操作段（restart），避免破坏环境"
}

# seq225 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_get_api_v1_agentorbit_workspaces_instanceId_sessions() {
  local label="GET /api/v1/agentorbit/workspaces/:instanceId/sessions — 摘要：查询会话列表 完整路径：GET /api/v1/agentorbit/workspaces/:instanceId"
  need_auth public "$label" || return 0
  req public GET "/api/v1/agentorbit/workspaces/$(path_id instanceId)/sessions" "" ""
  expect_read_ok "$label" 200
}

# seq226 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_v1_agentorbit_workspaces_instanceId_sessions() {
  local label="POST /api/v1/agentorbit/workspaces/:instanceId/sessions — 摘要：创建会话 完整路径：POST /api/v1/agentorbit/workspaces/:instanceId/"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req public POST "/api/v1/agentorbit/workspaces/$(path_id instanceId)/sessions" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq227 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_v1_agentorbit_workspaces_instanceId_sessions_sessio() {
  local label="POST /api/v1/agentorbit/workspaces/:instanceId/sessions/:sessionId — 摘要：删除会话 完整路径：POST /api/v1/agentorbit/workspaces/:instanceId/"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req public POST "/api/v1/agentorbit/workspaces/$(path_id instanceId)/sessions/$(path_id sessionId)" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq228 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_get_api_v1_agentorbit_workspaces_instanceId_sessions_session() {
  local label="GET /api/v1/agentorbit/workspaces/:instanceId/sessions/:sessionId/history — 摘要：查询会话历史消息（无需保持 ACP 连接） 完整路径：GET /api/v1/agentorbit/workspa"
  need_auth public "$label" || return 0
  req public GET "/api/v1/agentorbit/workspaces/$(path_id instanceId)/sessions/$(path_id sessionId)/history" "" ""
  expect_read_ok "$label" 200
}

# seq229 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_v1_agentorbit_workspaces_instanceId_sessions_sessio_2() {
  local label="POST /api/v1/agentorbit/workspaces/:instanceId/sessions/:sessionId/model — 摘要：切换会话所用模型 完整路径：POST /api/v1/agentorbit/workspaces/:instanc"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req public POST "/api/v1/agentorbit/workspaces/$(path_id instanceId)/sessions/$(path_id sessionId)/model" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq230 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_get_api_v1_agentorbit_workspaces_instanceId_sessions_session_2() {
  local label="GET /api/v1/agentorbit/workspaces/:instanceId/sessions/:sessionId/models — 摘要：获取会话可用模型列表 完整路径：GET /api/v1/agentorbit/workspaces/:instan"
  need_auth public "$label" || return 0
  req public GET "/api/v1/agentorbit/workspaces/$(path_id instanceId)/sessions/$(path_id sessionId)/models" "" ""
  expect_read_ok "$label" 200
}

# seq231 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_v1_agentorbit_workspaces_instanceId_sessions_switch() {
  local label="POST /api/v1/agentorbit/workspaces/:instanceId/sessions/switch — 摘要：切换会话 完整路径：POST /api/v1/agentorbit/workspaces/:instanceId/"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req public POST "/api/v1/agentorbit/workspaces/$(path_id instanceId)/sessions/switch" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq232 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_post_api_v1_agentorbit_workspaces_instanceId_stop() {
  log_skip "POST /api/v1/agentorbit/workspaces/:instanceId/stop — 永久跳过：路径含状态变更/清理类操作段（stop），避免破坏环境"
}

# seq233 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public（无配对删除接口，失败请人工核查数据残留）
workspace_post_api_v1_agentorbit_workspaces_instanceId_workspace_artif() {
  local label="POST /api/v1/agentorbit/workspaces/:instanceId/workspace-artifacts — 摘要：上传制品到智能体空间（从项目工作区） 完整路径：POST /api/v1/agentorbit/workspace"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req public POST "/api/v1/agentorbit/workspaces/$(path_id instanceId)/workspace-artifacts" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq234 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_get_api_v1_agentorbit_workspaces_instanceId_workspace_artifa() {
  local label="GET /api/v1/agentorbit/workspaces/:instanceId/workspace-artifacts/:artifactId — 摘要：下载智能体空间制品（AGENTORBIT 来源，实例内寻址） 完整路径：GET /api/v1/agentorbi"
  need_auth public "$label" || return 0
  req public GET "/api/v1/agentorbit/workspaces/$(path_id instanceId)/workspace-artifacts/$(path_id artifactId)" "" ""
  expect_read_ok "$label" 200
}

# seq235 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_get_api_v1_agentorbit_workspaces_workspaceId_images() {
  local label="GET /api/v1/agentorbit/workspaces/:workspaceId/images — 摘要：查询智能体空间可用镜像列表 完整路径：GET /api/v1/agentorbit/workspaces/:wor"
  need_auth public "$label" || return 0
  req public GET "/api/v1/agentorbit/workspaces/$(path_id workspaceId)/images" "" ""
  expect_read_ok "$label" 200
}

# seq236 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_get_api_v1_agentorbit_workspaces_workspaceId_workspace_artif() {
  local label="GET /api/v1/agentorbit/workspaces/:workspaceId/workspace-artifacts — 摘要：获取智能体空间制品列表（按 workspaceId） 完整路径：GET /api/v1/agentorbit/wo"
  need_auth public "$label" || return 0
  req public GET "/api/v1/agentorbit/workspaces/$(path_id workspaceId)/workspace-artifacts" "" ""
  expect_read_ok "$label" 200
}

# seq237 asdm-admin-services-core (端口 8880)/AgentOrbit Open Workspace | auth=public
workspace_get_api_v1_agentorbit_workspaces_artifacts_artifactId() {
  local label="GET /api/v1/agentorbit/workspaces/artifacts/:artifactId — 摘要：下载智能体空间制品（按 artifactId） 完整路径：GET /api/v1/agentorbit/works"
  need_auth public "$label" || return 0
  req public GET "/api/v1/agentorbit/workspaces/artifacts/$(path_id artifactId)" "" ""
  expect_read_ok "$label" 200
}

# seq238 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt（配对清理: POST /api/workspaces/:id）
workspace_post_api_workspaces() {
  local label="POST /api/workspaces — 摘要：Create a workspace 说明：Creates a new workspace"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/workspaces" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/workspaces/:id
  req jwt DELETE "/api/workspaces/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/workspaces/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq239 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces() {
  local label="GET /api/workspaces — 摘要：Get all workspaces 说明：Returns a list of all workspaces, o"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces" "" "page=0&size=10"
  expect_read_ok "$label" 200
}

# seq240 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_id() {
  local label="GET /api/workspaces/:id — 摘要：Get workspace by ID 说明：Returns a single workspace by its"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq241 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt（无配对删除接口，失败请人工核查数据残留）
workspace_put_api_workspaces_id() {
  local label="PUT /api/workspaces/:id — 摘要：Update a workspace 说明：Updates fields of an existing works"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt PUT "/api/workspaces/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq242 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_delete_api_workspaces_id() {
  local label="DELETE /api/workspaces/:id — 摘要：Delete a workspace 说明：Deletes a workspace and keeps run h"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/workspaces/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq243 asdm-admin-services-core (端口 8880)/Workspace | auth=internal
workspace_post_api_workspaces_workspaceId_artifacts_receive() {
  log_skip "POST /api/workspaces/:workspaceId/artifacts-receive — 需要 multipart 文件上传，无法幂等自动执行（摘要：Receive artifact package upload 说明：Accepts an artifact ar）"
}

# seq244 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_workspaceId_artifacts() {
  local label="GET /api/workspaces/:workspaceId/artifacts — 摘要：Get workspace artifacts 说明：Returns all artifacts for a wo"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/$(path_id workspaceId)/artifacts" "" ""
  expect_read_ok "$label" 200
}

# seq245 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_workspaceId_git_clone() {
  local label="GET /api/workspaces/:workspaceId/git-clone — 摘要：Resolve authenticated Git clone URL for CODE workspace 说明"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/$(path_id workspaceId)/git-clone" "" ""
  expect_read_ok "$label" 200
}

# seq246 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_workspaceId_git_clones() {
  local label="GET /api/workspaces/:workspaceId/git-clones — 摘要：List authenticated Git clone info for ALL repositories of"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/$(path_id workspaceId)/git-clones" "" ""
  expect_read_ok "$label" 200
}

# seq247 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_workspaceId_linked_contexts() {
  local label="GET /api/workspaces/:workspaceId/linked-contexts — 摘要：List contexts linked to a workspace 说明：仅返回 workspace_reso"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/$(path_id workspaceId)/linked-contexts" "" ""
  expect_read_ok "$label" 200
}

# seq248 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_workspaceId_project() {
  local label="GET /api/workspaces/:workspaceId/project — 摘要：Get project by workspace ID 说明：Returns the project associ"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/$(path_id workspaceId)/project" "" ""
  expect_read_ok "$label" 200
}

# seq249 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_workspaceId_resource_links() {
  local label="GET /api/workspaces/:workspaceId/resource-links — 摘要：Get workspace resource links 说明：Returns all links from wo"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/$(path_id workspaceId)/resource-links" "" ""
  expect_read_ok "$label" 200
}

# seq250 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt（配对清理: POST /api/workspaces/:workspaceId/resource-links/:linkId）
workspace_post_api_workspaces_workspaceId_resource_links() {
  local label="POST /api/workspaces/:workspaceId/resource-links — 摘要：Add workspace resource link 说明：Creates one row in workspa"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/workspaces/$(path_id workspaceId)/resource-links" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/workspaces/:workspaceId/resource-links/:linkId
  req jwt DELETE "/api/workspaces/${rid}/resource-links/$(path_id linkId)" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/workspaces/${rid}/resource-links/$(path_id linkId)" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq251 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_delete_api_workspaces_workspaceId_resource_links_linkId() {
  local label="DELETE /api/workspaces/:workspaceId/resource-links/:linkId — 摘要：Delete workspace resource link 说明：Deletes one row in work"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/workspaces/${DUMMY_ID}/resource-links/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq252 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt（无配对删除接口，失败请人工核查数据残留）
workspace_put_api_workspaces_workspaceId_resource_links_linkId_version() {
  local label="PUT /api/workspaces/:workspaceId/resource-links/:linkId/version — 摘要：Update workspace resource link version 说明：FT-10879 (P2-9)"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt PUT "/api/workspaces/$(path_id workspaceId)/resource-links/$(path_id linkId)/version" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq253 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_workspaceId_resources_manifest() {
  local label="GET /api/workspaces/:workspaceId/resources-manifest — 摘要：Get workspace resource manifest 说明：Returns all specs, too"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/$(path_id workspaceId)/resources-manifest" "" ""
  expect_read_ok "$label" 200
}

# seq254 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_workspaceId_run_history() {
  local label="GET /api/workspaces/:workspaceId/run-history — 摘要：Get run history by workspace ID 说明：Returns run history fo"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/$(path_id workspaceId)/run-history" "" "page=0&size=10"
  expect_read_ok "$label" 200
}

# seq255 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_workspaceId_toolsets_commands() {
  local label="GET /api/workspaces/:workspaceId/toolsets-commands — 摘要：Get workspace toolsets and commands 说明：默认：workspace_resou"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/$(path_id workspaceId)/toolsets-commands" "" ""
  expect_read_ok "$label" 200
}

# seq256 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_collection_collectionId() {
  local label="GET /api/workspaces/collection/:collectionId — 摘要：Get workspaces by collection ID 说明：Returns a list of work"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/collection/$(path_id collectionId)" "" ""
  expect_read_ok "$label" 200
}

# seq257 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_guid_guid() {
  local label="GET /api/workspaces/guid/:guid — 摘要：Get workspace by GUID 说明：Returns a single workspace by it"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/guid/$(path_id guid)" "" ""
  expect_read_ok "$label" 200
}

# seq258 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_owner_ownerId() {
  local label="GET /api/workspaces/owner/:ownerId — 摘要：Get workspaces by owner ID 说明：Returns a list of workspace"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/owner/$(path_id ownerId)" "" ""
  expect_read_ok "$label" 200
}

# seq259 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_project_projectId() {
  local label="GET /api/workspaces/project/:projectId — 摘要：Get workspaces by project ID 说明：Returns a list of workspa"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/project/$(path_id projectId)" "" ""
  expect_read_ok "$label" 200
}

# seq260 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_project_projectId_summaries() {
  local label="GET /api/workspaces/project/:projectId/summaries — 摘要：Get project workspace summaries (paginated) 说明：Returns pa"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/project/$(path_id projectId)/summaries" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq261 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_run_histories_resourceId_artifact_downloa() {
  local label="GET /api/workspaces/run-histories/:resourceId/artifact-download — 摘要：Download workspace artifact as zip 说明：Packs all files fro"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/run-histories/$(path_id resourceId)/artifact-download" "" ""
  expect_read_ok "$label" 200
}

# seq262 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt（配对清理: POST /api/workspaces/:id）
workspace_post_api_workspaces_run_history() {
  local label="POST /api/workspaces/run-history — 摘要：Create run history record 说明：Creates a new run history re"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/workspaces/run-history" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/workspaces/:id
  req jwt DELETE "/api/workspaces/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/workspaces/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq263 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt（无配对删除接口，失败请人工核查数据残留）
workspace_put_api_workspaces_run_history_id() {
  local label="PUT /api/workspaces/run-history/:id — 摘要：Update run history record 说明：Updates an existing run hist"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt PUT "/api/workspaces/run-history/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq264 asdm-admin-services-core (端口 8880)/Workspace | auth=jwt
workspace_get_api_workspaces_status_status() {
  local label="GET /api/workspaces/status/:status — 摘要：Get workspaces by status 说明：Returns a list of workspaces"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/workspaces/status/$(path_id status)" "" ""
  expect_read_ok "$label" 200
}

# ===== 入口 =====
main() {
  set +e   # 单用例失败不中断
  echo ""
  echo "========== 工作空间域 (94 apis) =========="
  login_if_needed || true
  workspace_post_api_agentorbit_instances_instanceId_users_asdmUserId_en || true
  workspace_post_api_agentorbit_instances_check_twin || true
  workspace_post_api_agentorbit_instances_check_workspace || true
  workspace_get_api_agentorbit_instances_context_info || true
  workspace_post_internal_workspaces || true
  workspace_get_internal_workspaces || true
  workspace_get_internal_workspaces_instanceId || true
  workspace_post_internal_workspaces_instanceId || true
  workspace_get_internal_workspaces_instanceId_artifact_context || true
  workspace_post_internal_workspaces_instanceId_artifacts || true
  workspace_get_internal_workspaces_instanceId_artifacts || true
  workspace_get_internal_workspaces_instanceId_artifacts_download || true
  workspace_post_internal_workspaces_instanceId_connect || true
  workspace_get_internal_workspaces_instanceId_connection_status || true
  workspace_post_internal_workspaces_instanceId_enter || true
  workspace_post_internal_workspaces_instanceId_generation_stop || true
  workspace_post_internal_workspaces_instanceId_projects || true
  workspace_get_internal_workspaces_instanceId_projects || true
  workspace_get_internal_workspaces_instanceId_projects_projectId || true
  workspace_delete_internal_workspaces_instanceId_projects_projectId || true
  workspace_post_internal_workspaces_instanceId_restart || true
  workspace_post_internal_workspaces_instanceId_sessions || true
  workspace_get_internal_workspaces_instanceId_sessions || true
  workspace_post_internal_workspaces_instanceId_sessions_sessionId || true
  workspace_get_internal_workspaces_instanceId_sessions_sessionId_histor || true
  workspace_post_internal_workspaces_instanceId_sessions_sessionId_model || true
  workspace_get_internal_workspaces_instanceId_sessions_sessionId_models || true
  workspace_post_internal_workspaces_instanceId_sessions_switch || true
  workspace_post_internal_workspaces_instanceId_stop || true
  workspace_post_internal_workspaces_instanceId_workspace_artifacts || true
  workspace_get_internal_workspaces_workspaceId_images || true
  workspace_get_internal_workspaces_workspaces_workspaceId_access || true
  workspace_post_api_agentorbit_workspaces_workspaceId_clone_default_pro || true
  workspace_post_api_agentorbit_workspaces_workspaceId_ensure_instance || true
  workspace_post_api_agentorbit_workspaces_workspaceId_enter_member || true
  workspace_post_api_agentorbit_workspaces_workspaceId_prune_unbound_rep || true
  workspace_get_api_v1_agentorbit_workspace_artifacts_artifactId || true
  workspace_post_api_agent_tasks || true
  workspace_get_api_agent_tasks_taskId || true
  workspace_post_api_v1_agentorbit_workspaces || true
  workspace_get_api_v1_agentorbit_workspaces || true
  workspace_get_api_v1_agentorbit_workspaces_instanceId || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId_artifacts || true
  workspace_get_api_v1_agentorbit_workspaces_instanceId_artifacts || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId_connect || true
  workspace_get_api_v1_agentorbit_workspaces_instanceId_connection_statu || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId_enter || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId_generation_stop || true
  workspace_get_api_v1_agentorbit_workspaces_instanceId_projects || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId_projects || true
  workspace_get_api_v1_agentorbit_workspaces_instanceId_projects_project || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId_projects_projec || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId_restart || true
  workspace_get_api_v1_agentorbit_workspaces_instanceId_sessions || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId_sessions || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId_sessions_sessio || true
  workspace_get_api_v1_agentorbit_workspaces_instanceId_sessions_session || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId_sessions_sessio_2 || true
  workspace_get_api_v1_agentorbit_workspaces_instanceId_sessions_session_2 || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId_sessions_switch || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId_stop || true
  workspace_post_api_v1_agentorbit_workspaces_instanceId_workspace_artif || true
  workspace_get_api_v1_agentorbit_workspaces_instanceId_workspace_artifa || true
  workspace_get_api_v1_agentorbit_workspaces_workspaceId_images || true
  workspace_get_api_v1_agentorbit_workspaces_workspaceId_workspace_artif || true
  workspace_get_api_v1_agentorbit_workspaces_artifacts_artifactId || true
  workspace_post_api_workspaces || true
  workspace_get_api_workspaces || true
  workspace_get_api_workspaces_id || true
  workspace_put_api_workspaces_id || true
  workspace_delete_api_workspaces_id || true
  workspace_post_api_workspaces_workspaceId_artifacts_receive || true
  workspace_get_api_workspaces_workspaceId_artifacts || true
  workspace_get_api_workspaces_workspaceId_git_clone || true
  workspace_get_api_workspaces_workspaceId_git_clones || true
  workspace_get_api_workspaces_workspaceId_linked_contexts || true
  workspace_get_api_workspaces_workspaceId_project || true
  workspace_get_api_workspaces_workspaceId_resource_links || true
  workspace_post_api_workspaces_workspaceId_resource_links || true
  workspace_delete_api_workspaces_workspaceId_resource_links_linkId || true
  workspace_put_api_workspaces_workspaceId_resource_links_linkId_version || true
  workspace_get_api_workspaces_workspaceId_resources_manifest || true
  workspace_get_api_workspaces_workspaceId_run_history || true
  workspace_get_api_workspaces_workspaceId_toolsets_commands || true
  workspace_get_api_workspaces_collection_collectionId || true
  workspace_get_api_workspaces_guid_guid || true
  workspace_get_api_workspaces_owner_ownerId || true
  workspace_get_api_workspaces_project_projectId || true
  workspace_get_api_workspaces_project_projectId_summaries || true
  workspace_get_api_workspaces_run_histories_resourceId_artifact_downloa || true
  workspace_post_api_workspaces_run_history || true
  workspace_put_api_workspaces_run_history_id || true
  workspace_get_api_workspaces_status_status || true
  finish
}
main "$@"
