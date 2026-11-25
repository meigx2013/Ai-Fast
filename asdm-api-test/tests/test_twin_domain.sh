#!/usr/bin/env bash
# ============================================================================
# 数字分身域 — 幂等自动化测试（由 gen/generate.js 从 api.json 生成，勿手工修改）
# 重新生成: node gen/generate.js
# 覆盖服务: agentorbit
# 接口总数: 55（读 23 直测 / 写 30 受控[含配对清理 4] / 永久跳过 2）
# 环境变量: ASDM_BASE_URL / ASDM_LOGIN_EMAIL / ASDM_LOGIN_PASSWORD / ASDM_TOKEN /
#           ASDM_PAT / ASDM_INTERNAL_TOKEN / ASDM_OPEN_ACCESS_TOKEN / ASDM_CITIC_SECRET /
#           ASDM_ALLOW_WRITES=1（执行写操作）/ ASDM_TEST_<参数名>（路径参数覆盖）
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ===== 被测接口用例 =====
# seq946 asdm-admin-services-agentorbit (端口 8884)/AgentOrbitConfig | auth=jwt
twin_get_api_agentorbit_config() {
  local label="GET /api/agentorbit/config — 完整路径：GET /api/agentorbit/config（服务：asdm-admin-services-agent"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/config" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq947 asdm-admin-services-agentorbit (端口 8884)/AgentOrbitConfig | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_put_api_agentorbit_config() {
  local label="PUT /api/agentorbit/config — 完整路径：PUT /api/agentorbit/config（服务：asdm-admin-services-agent"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "serverUrl": "https://example.com",
 "authMode": "string",
 "clientKey": "string",
 "clientId": "string",
 "infrastructureImageId": "string",
 "name": "example__RUN_ID__",
 "isActive": true,
 "enableThirdPartyAgent": true,
 "idleTimeoutMinutes": 1,
 "llmApiKey": "string"
}
JSONEOF
)"
  req jwt PUT "/api/agentorbit/config" "$body" "userId=1"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq948 asdm-admin-services-agentorbit (端口 8884)/AgentOrbitConfig | auth=jwt
twin_get_api_agentorbit_config_active() {
  local label="GET /api/agentorbit/config/active — 完整路径：GET /api/agentorbit/config/active（服务：asdm-admin-service"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/config/active" "" ""
  expect_read_ok "$label" 200
}

# seq949 asdm-admin-services-agentorbit (端口 8884)/AgentOrbitConfig | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_config_authenticate() {
  local label="POST /api/agentorbit/config/authenticate — 完整路径：POST /api/agentorbit/config/authenticate（服务：asdm-admin-"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/agentorbit/config/authenticate" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq950 asdm-admin-services-agentorbit (端口 8884)/AgentOrbitConfig | auth=jwt
twin_get_api_agentorbit_config_client_key() {
  local label="GET /api/agentorbit/config/client-key — 完整路径：GET /api/agentorbit/config/client-key（服务：asdm-admin-ser"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/config/client-key" "" ""
  expect_read_ok "$label" 200
}

# seq951 asdm-admin-services-agentorbit (端口 8884)/AgentOrbitConfig | auth=jwt
twin_get_api_agentorbit_config_digidev_prompts() {
  local label="GET /api/agentorbit/config/digidev-prompts — 完整路径：GET /api/agentorbit/config/digidev-prompts（服务：asdm-admi"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/config/digidev-prompts" "" ""
  expect_read_ok "$label" 200
}

# seq952 asdm-admin-services-agentorbit (端口 8884)/AgentOrbitConfig | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_config_infrastructure_images() {
  local label="POST /api/agentorbit/config/infrastructure-images — 完整路径：POST /api/agentorbit/config/infrastructure-images（服务：as"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "serverUrl": "https://example.com",
 "authMode": "string",
 "clientKey": "string",
 "clientId": "string",
 "infrastructureImageId": "string",
 "name": "example__RUN_ID__",
 "isActive": true,
 "enableThirdPartyAgent": true,
 "idleTimeoutMinutes": 1,
 "llmApiKey": "string"
}
JSONEOF
)"
  req jwt POST "/api/agentorbit/config/infrastructure-images" "$body" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq953 asdm-admin-services-agentorbit (端口 8884)/AgentOrbitConfig | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_config_test() {
  local label="POST /api/agentorbit/config/test — 完整路径：POST /api/agentorbit/config/test（服务：asdm-admin-services"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "serverUrl": "https://example.com",
 "authMode": "string",
 "clientKey": "string",
 "clientId": "string",
 "infrastructureImageId": "string",
 "name": "example__RUN_ID__",
 "isActive": true,
 "enableThirdPartyAgent": true,
 "idleTimeoutMinutes": 1,
 "llmApiKey": "string"
}
JSONEOF
)"
  req jwt POST "/api/agentorbit/config/test" "$body" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq954 asdm-admin-services-agentorbit (端口 8884)/CollectionAgentConfig | auth=jwt
twin_get_api_agentorbit_collections_collectionId_agent_config_enabled() {
  local label="GET /api/agentorbit/collections/:collectionId/agent-config-enabled — 完整路径：GET /api/agentorbit/collections/:collectionId/agent-con"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/collections/$(path_id collectionId)/agent-config-enabled" "" ""
  expect_read_ok "$label" 200
}

# seq955 asdm-admin-services-agentorbit (端口 8884)/CollectionAgentConfig | auth=jwt
twin_get_api_agentorbit_collections_collectionId_agent_config() {
  local label="GET /api/agentorbit/collections/:collectionId/agent-config — 完整路径：GET /api/agentorbit/collections/:collectionId/agent-con"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/collections/$(path_id collectionId)/agent-config" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq956 asdm-admin-services-agentorbit (端口 8884)/CollectionAgentConfig | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_put_api_agentorbit_collections_collectionId_agent_config() {
  local label="PUT /api/agentorbit/collections/:collectionId/agent-config — 完整路径：PUT /api/agentorbit/collections/:collectionId/agent-con"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "allowOnlineWorkspace": true,
  "allowPersonalTwin": true,
  "agentTotalQuota": 1,
  "allowPersonalTwinSharedKey": true,
  "onlineWorkspaceCodebuddyKey": "string",
  "onlineWorkspaceOpencodeProviders": "string",
  "personalTwinCodebuddyKey": "string",
  "personalTwinOpencodeProviders": "string",
  "projectTwinCodebuddyKey": "string",
  "projectTwinDefaultImageId": "string",
  "images": {
    "key": "value"
  }
}
JSONEOF
)"
  req jwt PUT "/api/agentorbit/collections/$(path_id collectionId)/agent-config" "$body" "userId=1"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq957 asdm-admin-services-agentorbit (端口 8884)/ContextTwin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_contexts_contextId_ensure_instance() {
  local label="POST /api/agentorbit/contexts/:contextId/ensure-instance — 所属控制器：FT-8803: Context Space AgentOrbit online analysis - co"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/agentorbit/contexts/$(path_id contextId)/ensure-instance" "$body" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq958 asdm-admin-services-agentorbit (端口 8884)/ContextTwin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_contexts_contextId_enter_member() {
  local label="POST /api/agentorbit/contexts/:contextId/enter-member — 所属控制器：FT-8803: Context Space AgentOrbit online analysis - co"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "username": "example__RUN_ID__",
 "agentType": "string"
}
JSONEOF
)"
  req jwt POST "/api/agentorbit/contexts/$(path_id contextId)/enter-member" "$body" "userId=1&jwtUsername=example"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq959 asdm-admin-services-agentorbit (端口 8884)/ContextTwin | auth=jwt
twin_get_api_agentorbit_contexts_contextId_status() {
  local label="GET /api/agentorbit/contexts/:contextId/status — 所属控制器：FT-8803: Context Space AgentOrbit online analysis - co"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/contexts/$(path_id contextId)/status" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq960 asdm-admin-services-agentorbit (端口 8884)/ContextTwin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_contexts_contextId_sync_projects() {
  local label="POST /api/agentorbit/contexts/:contextId/sync-projects — 所属控制器：FT-8803: Context Space AgentOrbit online analysis - co"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/agentorbit/contexts/$(path_id contextId)/sync-projects" "" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq961 asdm-admin-services-agentorbit (端口 8884)/ContextTwin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_contexts_import_artifact() {
  local label="POST /api/agentorbit/contexts/import-artifact — 所属控制器：FT-8803: Context Space AgentOrbit online analysis - co"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/agentorbit/contexts/import-artifact" "$body" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq962 asdm-admin-services-agentorbit (端口 8884)/InternalTwinCascade | auth=internal（无配对删除接口，失败请人工核查数据残留）
twin_post_internal_twins_by_workspaces() {
  local label="POST /internal/twins/by-workspaces — 所属控制器：m2m cascade-delete / migrate for core when project/wor"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req internal POST "/internal/twins/by-workspaces" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq963 asdm-admin-services-agentorbit (端口 8884)/InternalTwinCascade | auth=internal（无配对删除接口，失败请人工核查数据残留）
twin_post_internal_twins_cascade_delete() {
  local label="POST /internal/twins/cascade-delete — 所属控制器：m2m cascade-delete / migrate for core when project/wor"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "scope": "string",
  "workspaceId": 1,
  "contextId": "string",
  "projectId": 1,
  "collectionId": 1,
  "collectionIds": [
    1
  ],
  "projectIds": [
    1
  ]
}
JSONEOF
)"
  req internal POST "/internal/twins/cascade-delete" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq964 asdm-admin-services-agentorbit (端口 8884)/InternalTwinCascade | auth=internal（无配对删除接口，失败请人工核查数据残留）
twin_post_internal_twins_merge_collection_agent() {
  local label="POST /internal/twins/merge-collection-agent — 所属控制器：m2m cascade-delete / migrate for core when project/wor"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "fromCollectionId": 1,
  "toCollectionId": 1
}
JSONEOF
)"
  req internal POST "/internal/twins/merge-collection-agent" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq965 asdm-admin-services-agentorbit (端口 8884)/InternalTwinCascade | auth=internal（无配对删除接口，失败请人工核查数据残留）
twin_post_internal_twins_migrate_project_collection() {
  local label="POST /internal/twins/migrate-project-collection — 所属控制器：m2m cascade-delete / migrate for core when project/wor"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "projectId": 1,
  "fromCollectionId": 1,
  "toCollectionId": 1
}
JSONEOF
)"
  req internal POST "/internal/twins/migrate-project-collection" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq966 asdm-admin-services-agentorbit (端口 8884)/InternalTwinCascade | auth=internal（无配对删除接口，失败请人工核查数据残留）
twin_post_internal_twins_refresh_skills() {
  local label="POST /internal/twins/refresh-skills — 所属控制器：m2m cascade-delete / migrate for core when project/wor"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  req internal POST "/internal/twins/refresh-skills" "" "workspaceId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq967 asdm-admin-services-agentorbit (端口 8884)/InternalTwinCascade | auth=internal（无配对删除接口，失败请人工核查数据残留）
twin_post_internal_twins_sync_workspace_name() {
  local label="POST /internal/twins/sync-workspace-name — 所属控制器：m2m cascade-delete / migrate for core when project/wor"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "workspaceId": 1,
 "name": "example__RUN_ID__"
}
JSONEOF
)"
  req internal POST "/internal/twins/sync-workspace-name" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq968 asdm-admin-services-agentorbit (端口 8884)/OrganizationAgentConfig | auth=jwt
twin_get_api_agentorbit_collections_collectionId_organization_agent_co() {
  local label="GET /api/agentorbit/collections/:collectionId/organization-agent-config — 完整路径：GET /api/agentorbit/collections/:collectionId/organizat"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/collections/$(path_id collectionId)/organization-agent-config" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq969 asdm-admin-services-agentorbit (端口 8884)/OrganizationAgentConfig | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_put_api_agentorbit_collections_collectionId_organization_agent_co() {
  local label="PUT /api/agentorbit/collections/:collectionId/organization-agent-config — 完整路径：PUT /api/agentorbit/collections/:collectionId/organizat"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "workspaceConfigs": [
    "string"
  ],
  "defaultTwinQuotaPerUser": 1,
  "twinUserOverrides": [
    "string"
  ],
  "onlineWorkspaceCodebuddyKey": "string",
  "onlineWorkspaceOpencodeProviders": "string",
  "personalTwinCodebuddyKey": "string",
  "personalTwinOpencodeProviders": "string",
  "projectTwinCodebuddyKey": "string",
  "projectTwinDefaultImageId": "string",
  "defaultInstanceCpu": 1,
  "defaultInstanceMemory": 1,
  "defaultInstanceResourcesSpecified": true,
  "projectId": 1,
  "allowWorkspace": true,
  "defaultImageId": "string",
  "userId": 1,
  "twinQuota": 1
}
JSONEOF
)"
  req jwt PUT "/api/agentorbit/collections/$(path_id collectionId)/organization-agent-config" "$body" "userId=1"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq970 asdm-admin-services-agentorbit (端口 8884)/PatStatus | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_user_auto_create_personal_pat() {
  local label="POST /api/agentorbit/user/auto-create-personal-pat — 所属控制器：Controller for personal PAT status operations and auto"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/agentorbit/user/auto-create-personal-pat" "" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq971 asdm-admin-services-agentorbit (端口 8884)/PatStatus | auth=jwt
twin_get_api_agentorbit_user_personal_pat_status() {
  local label="GET /api/agentorbit/user/personal-pat-status — 所属控制器：Controller for personal PAT status operations and auto"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/user/personal-pat-status" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq972 asdm-admin-services-agentorbit (端口 8884)/ProjectTwin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_projects_projectId_ensure_instance() {
  local label="POST /api/agentorbit/projects/:projectId/ensure-instance — 所属控制器：FT-10655: Project-level AgentOrbit twin instance manag"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/agentorbit/projects/$(path_id projectId)/ensure-instance" "$body" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq973 asdm-admin-services-agentorbit (端口 8884)/ProjectTwin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_projects_projectId_enter_member() {
  local label="POST /api/agentorbit/projects/:projectId/enter-member — 所属控制器：FT-10655: Project-level AgentOrbit twin instance manag"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "username": "example__RUN_ID__",
 "agentType": "string"
}
JSONEOF
)"
  req jwt POST "/api/agentorbit/projects/$(path_id projectId)/enter-member" "$body" "userId=1&jwtUsername=example"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq974 asdm-admin-services-agentorbit (端口 8884)/ProjectTwin | auth=jwt
twin_get_api_agentorbit_projects_projectId_status() {
  local label="GET /api/agentorbit/projects/:projectId/status — 所属控制器：FT-10655: Project-level AgentOrbit twin instance manag"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/projects/$(path_id projectId)/status" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq975 asdm-admin-services-agentorbit (端口 8884)/StoppedPvc | auth=jwt
twin_get_api_agentorbit_admin_stopped_pvcs() {
  local label="GET /api/agentorbit/admin/stopped-pvcs — 所属控制器：Admin controller for managing stopped instances with P"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/admin/stopped-pvcs" "" ""
  expect_read_ok "$label" 200
}

# seq976 asdm-admin-services-agentorbit (端口 8884)/StoppedPvc | auth=jwt
twin_delete_api_agentorbit_admin_stopped_pvcs_id() {
  local label="DELETE /api/agentorbit/admin/stopped-pvcs/:id — 所属控制器：Admin controller for managing stopped instances with P"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/agentorbit/admin/stopped-pvcs/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq977 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt
twin_get_api_agentorbit_twins() {
  local label="GET /api/agentorbit/twins — 完整路径：GET /api/agentorbit/twins（服务：asdm-admin-services-agento"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/twins" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq978 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt（配对清理: POST /api/agentorbit/twins/:id）
twin_post_api_agentorbit_twins() {
  local label="POST /api/agentorbit/twins — 完整路径：POST /api/agentorbit/twins（服务：asdm-admin-services-agent"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "instanceName": "example",
  "deploymentType": "string",
  "workspaceId": 1,
  "type": "string",
  "collectionId": 1,
  "projectId": 1,
  "imageId": "string",
  "keyType": "string"
}
JSONEOF
)"
  req jwt POST "/api/agentorbit/twins" "$body" "userId=1"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/agentorbit/twins/:id
  req jwt DELETE "/api/agentorbit/twins/${rid}" "" "userId=1"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/agentorbit/twins/${rid}" "" "userId=1"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq979 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt
twin_delete_api_agentorbit_twins_id() {
  local label="DELETE /api/agentorbit/twins/:id — 完整路径：DELETE /api/agentorbit/twins/:id（服务：asdm-admin-services"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/agentorbit/twins/${DUMMY_ID}" "" "userId=1"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq980 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt
twin_get_api_agentorbit_twins_id_embedding_url() {
  local label="GET /api/agentorbit/twins/:id/embedding-url — 完整路径：GET /api/agentorbit/twins/:id/embedding-url（服务：asdm-adm"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/twins/$(path_id id)/embedding-url" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq981 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_twins_id_ensure_ready() {
  local label="POST /api/agentorbit/twins/:id/ensure-ready — 完整路径：POST /api/agentorbit/twins/:id/ensure-ready（服务：asdm-adm"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/agentorbit/twins/$(path_id id)/ensure-ready" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq982 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_twins_id_enter_member() {
  local label="POST /api/agentorbit/twins/:id/enter-member — 完整路径：POST /api/agentorbit/twins/:id/enter-member（服务：asdm-adm"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "username": "example__RUN_ID__",
 "agentType": "string"
}
JSONEOF
)"
  req jwt POST "/api/agentorbit/twins/$(path_id id)/enter-member" "$body" "userId=1&jwtUsername=example"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq983 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_twins_id_send_command() {
  local label="POST /api/agentorbit/twins/:id/send-command — 完整路径：POST /api/agentorbit/twins/:id/send-command（服务：asdm-adm"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "commandType": "string",
  "sessionId": "string",
  "path": "/tmp/example"
}
JSONEOF
)"
  req jwt POST "/api/agentorbit/twins/$(path_id id)/send-command" "$body" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq984 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt
twin_post_api_agentorbit_twins_id_start() {
  log_skip "POST /api/agentorbit/twins/:id/start — 永久跳过：路径含状态变更/清理类操作段（start），避免破坏环境"
}

# seq985 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt
twin_post_api_agentorbit_twins_id_stop() {
  log_skip "POST /api/agentorbit/twins/:id/stop — 永久跳过：路径含状态变更/清理类操作段（stop），避免破坏环境"
}

# seq986 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_post_api_agentorbit_twins_id_sync() {
  local label="POST /api/agentorbit/twins/:id/sync — 完整路径：POST /api/agentorbit/twins/:id/sync（服务：asdm-admin-servi"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/agentorbit/twins/$(path_id id)/sync" "" "userId=1"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq987 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt
twin_get_api_agentorbit_twins_id_type() {
  local label="GET /api/agentorbit/twins/:id/type — 完整路径：GET /api/agentorbit/twins/:id/type（服务：asdm-admin-servic"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/twins/$(path_id id)/type" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq988 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt
twin_get_api_agentorbit_twins_by_instance_instanceId() {
  local label="GET /api/agentorbit/twins/by-instance/:instanceId — 完整路径：GET /api/agentorbit/twins/by-instance/:instanceId（服务：as"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/twins/by-instance/$(path_id instanceId)" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq989 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt
twin_get_api_agentorbit_twins_by_workspace_workspaceId() {
  local label="GET /api/agentorbit/twins/by-workspace/:workspaceId — 完整路径：GET /api/agentorbit/twins/by-workspace/:workspaceId（服务："
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/twins/by-workspace/$(path_id workspaceId)" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq990 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt
twin_get_api_agentorbit_twins_capabilities() {
  local label="GET /api/agentorbit/twins/capabilities — 完整路径：GET /api/agentorbit/twins/capabilities（服务：asdm-admin-se"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/twins/capabilities" "" ""
  expect_read_ok "$label" 200
}

# seq991 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt
twin_get_api_agentorbit_twins_default() {
  local label="GET /api/agentorbit/twins/default — 完整路径：GET /api/agentorbit/twins/default（服务：asdm-admin-service"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/twins/default" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq992 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt（配对清理: POST /api/agentorbit/twins/:id）
twin_post_api_agentorbit_twins_ensure_default() {
  local label="POST /api/agentorbit/twins/ensure-default — 完整路径：POST /api/agentorbit/twins/ensure-default（服务：asdm-admin"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/agentorbit/twins/ensure-default" "" "userId=1"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/agentorbit/twins/:id
  req jwt DELETE "/api/agentorbit/twins/${rid}" "" "userId=1"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/agentorbit/twins/${rid}" "" "userId=1"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq993 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt（配对清理: POST /api/agentorbit/twins/:id）
twin_post_api_agentorbit_twins_from_workspace() {
  local label="POST /api/agentorbit/twins/from-workspace — 完整路径：POST /api/agentorbit/twins/from-workspace（服务：asdm-admin"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "workspaceId": 1
}
JSONEOF
)"
  req jwt POST "/api/agentorbit/twins/from-workspace" "$body" "userId=1"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/agentorbit/twins/:id
  req jwt DELETE "/api/agentorbit/twins/${rid}" "" "userId=1"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/agentorbit/twins/${rid}" "" "userId=1"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq994 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt
twin_get_api_agentorbit_twins_page() {
  local label="GET /api/agentorbit/twins/page — 完整路径：GET /api/agentorbit/twins/page（服务：asdm-admin-services-a"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/twins/page" "" "userId=1&page=1&pageSize=20"
  expect_read_ok "$label" 200
}

# seq995 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt
twin_get_api_agentorbit_twins_personal_quota() {
  local label="GET /api/agentorbit/twins/personal-quota — 完整路径：GET /api/agentorbit/twins/personal-quota（服务：asdm-admin-"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/twins/personal-quota" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq996 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt（配对清理: POST /api/agentorbit/twins/:id）
twin_post_api_agentorbit_twins_personal() {
  local label="POST /api/agentorbit/twins/personal — 完整路径：POST /api/agentorbit/twins/personal（服务：asdm-admin-servi"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/agentorbit/twins/personal" "" "userId=1"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/agentorbit/twins/:id
  req jwt DELETE "/api/agentorbit/twins/${rid}" "" "userId=1"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/agentorbit/twins/${rid}" "" "userId=1"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq997 asdm-admin-services-agentorbit (端口 8884)/Twin | auth=jwt
twin_get_api_agentorbit_twins_poll_instance_status() {
  local label="GET /api/agentorbit/twins/poll-instance-status — 完整路径：GET /api/agentorbit/twins/poll-instance-status（服务：asdm-"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/twins/poll-instance-status" "" "instanceId=string&type=k8s&userId=1"
  expect_read_ok "$label" 200
}

# seq998 asdm-admin-services-agentorbit (端口 8884)/UserAgentKey | auth=jwt
twin_get_api_agentorbit_user_agent_keys() {
  local label="GET /api/agentorbit/user/agent-keys — 完整路径：GET /api/agentorbit/user/agent-keys（服务：asdm-admin-servi"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/user/agent-keys" "" "userId=1"
  expect_read_ok "$label" 200
}

# seq999 asdm-admin-services-agentorbit (端口 8884)/UserAgentKey | auth=jwt（无配对删除接口，失败请人工核查数据残留）
twin_put_api_agentorbit_user_agent_keys() {
  local label="PUT /api/agentorbit/user/agent-keys — 完整路径：PUT /api/agentorbit/user/agent-keys（服务：asdm-admin-servi"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "personalTwinCodebuddyKey": "string",
  "personalTwinOpencodeProviders": "string",
  "personalPat": "string"
}
JSONEOF
)"
  req jwt PUT "/api/agentorbit/user/agent-keys" "$body" "userId=1"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq1000 asdm-admin-services-agentorbit (端口 8884)/UserAgentKey | auth=jwt
twin_get_api_agentorbit_user_personal_twin_remaining_quotas() {
  local label="GET /api/agentorbit/user/personal-twin-remaining-quotas — 完整路径：GET /api/agentorbit/user/personal-twin-remaining-quotas"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/agentorbit/user/personal-twin-remaining-quotas" "" "userId=1"
  expect_read_ok "$label" 200
}

# ===== 入口 =====
main() {
  set +e   # 单用例失败不中断
  echo ""
  echo "========== 数字分身域 (55 apis) =========="
  login_if_needed || true
  twin_get_api_agentorbit_config || true
  twin_put_api_agentorbit_config || true
  twin_get_api_agentorbit_config_active || true
  twin_post_api_agentorbit_config_authenticate || true
  twin_get_api_agentorbit_config_client_key || true
  twin_get_api_agentorbit_config_digidev_prompts || true
  twin_post_api_agentorbit_config_infrastructure_images || true
  twin_post_api_agentorbit_config_test || true
  twin_get_api_agentorbit_collections_collectionId_agent_config_enabled || true
  twin_get_api_agentorbit_collections_collectionId_agent_config || true
  twin_put_api_agentorbit_collections_collectionId_agent_config || true
  twin_post_api_agentorbit_contexts_contextId_ensure_instance || true
  twin_post_api_agentorbit_contexts_contextId_enter_member || true
  twin_get_api_agentorbit_contexts_contextId_status || true
  twin_post_api_agentorbit_contexts_contextId_sync_projects || true
  twin_post_api_agentorbit_contexts_import_artifact || true
  twin_post_internal_twins_by_workspaces || true
  twin_post_internal_twins_cascade_delete || true
  twin_post_internal_twins_merge_collection_agent || true
  twin_post_internal_twins_migrate_project_collection || true
  twin_post_internal_twins_refresh_skills || true
  twin_post_internal_twins_sync_workspace_name || true
  twin_get_api_agentorbit_collections_collectionId_organization_agent_co || true
  twin_put_api_agentorbit_collections_collectionId_organization_agent_co || true
  twin_post_api_agentorbit_user_auto_create_personal_pat || true
  twin_get_api_agentorbit_user_personal_pat_status || true
  twin_post_api_agentorbit_projects_projectId_ensure_instance || true
  twin_post_api_agentorbit_projects_projectId_enter_member || true
  twin_get_api_agentorbit_projects_projectId_status || true
  twin_get_api_agentorbit_admin_stopped_pvcs || true
  twin_delete_api_agentorbit_admin_stopped_pvcs_id || true
  twin_get_api_agentorbit_twins || true
  twin_post_api_agentorbit_twins || true
  twin_delete_api_agentorbit_twins_id || true
  twin_get_api_agentorbit_twins_id_embedding_url || true
  twin_post_api_agentorbit_twins_id_ensure_ready || true
  twin_post_api_agentorbit_twins_id_enter_member || true
  twin_post_api_agentorbit_twins_id_send_command || true
  twin_post_api_agentorbit_twins_id_start || true
  twin_post_api_agentorbit_twins_id_stop || true
  twin_post_api_agentorbit_twins_id_sync || true
  twin_get_api_agentorbit_twins_id_type || true
  twin_get_api_agentorbit_twins_by_instance_instanceId || true
  twin_get_api_agentorbit_twins_by_workspace_workspaceId || true
  twin_get_api_agentorbit_twins_capabilities || true
  twin_get_api_agentorbit_twins_default || true
  twin_post_api_agentorbit_twins_ensure_default || true
  twin_post_api_agentorbit_twins_from_workspace || true
  twin_get_api_agentorbit_twins_page || true
  twin_get_api_agentorbit_twins_personal_quota || true
  twin_post_api_agentorbit_twins_personal || true
  twin_get_api_agentorbit_twins_poll_instance_status || true
  twin_get_api_agentorbit_user_agent_keys || true
  twin_put_api_agentorbit_user_agent_keys || true
  twin_get_api_agentorbit_user_personal_twin_remaining_quotas || true
  finish
}
main "$@"
