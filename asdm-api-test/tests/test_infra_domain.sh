#!/usr/bin/env bash
# ============================================================================
# 基础设施域 — 幂等自动化测试（由 gen/generate.js 从 api.json 生成，勿手工修改）
# 重新生成: node gen/generate.js
# 覆盖服务: core, file-service, mcp-hosting, telemetry
# 接口总数: 152（读 104 直测 / 写 39 受控[含配对清理 5] / 永久跳过 9）
# 环境变量: ASDM_BASE_URL / ASDM_LOGIN_EMAIL / ASDM_LOGIN_PASSWORD / ASDM_TOKEN /
#           ASDM_PAT / ASDM_INTERNAL_TOKEN / ASDM_OPEN_ACCESS_TOKEN / ASDM_CITIC_SECRET /
#           ASDM_ALLOW_WRITES=1（执行写操作）/ ASDM_TEST_<参数名>（路径参数覆盖）
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ===== 被测接口用例 =====
# seq794 asdm-admin-services-core (端口 8880)/AosDispatch | auth=internal（无配对删除接口，失败请人工核查数据残留）
infra_post_internal_aos_graph_build_dispatch() {
  local label="POST /internal/aos/graph-build-dispatch — 所属控制器：C03/C04/C05 — idempotent Jenkins dispatch, reconcile a"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "asdmRunId": "string",
  "dispatchRequestId": "string",
  "executionContextRef": "string",
  "suiteManifestRef": "string",
  "taskCredentialDeliveryRef": "string",
  "asdmAttemptId": "string",
  "pipelineServerRef": "string",
  "selectedSourceIds": [
    "string"
  ],
  "suiteDescriptor": "string",
  "bindingRevision": 1
}
JSONEOF
)"
  req internal POST "/internal/aos/graph-build-dispatch" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq795 asdm-admin-services-core (端口 8880)/AosDispatch | auth=internal
infra_get_internal_aos_graph_build_dispatch_requestId() {
  local label="GET /internal/aos/graph-build-dispatch/:requestId — 所属控制器：C03/C04/C05 — idempotent Jenkins dispatch, reconcile a"
  need_auth internal "$label" || return 0
  req internal GET "/internal/aos/graph-build-dispatch/$(path_id requestId)" "" ""
  expect_read_ok "$label" 200
}

# seq796 asdm-admin-services-core (端口 8880)/AosDispatch | auth=internal（无配对删除接口，失败请人工核查数据残留）
infra_post_internal_aos_graph_build_dispatch_requestId_cancel() {
  local label="POST /internal/aos/graph-build-dispatch/:requestId/cancel — 所属控制器：C03/C04/C05 — idempotent Jenkins dispatch, reconcile a"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "asdmRunId": "string",
  "reason": "string"
}
JSONEOF
)"
  req internal POST "/internal/aos/graph-build-dispatch/$(path_id requestId)/cancel" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq797 asdm-admin-services-core (端口 8880)/AosJenkinsCredentialChannel | auth=internal（无配对删除接口，失败请人工核查数据残留）
infra_post_internal_aos_jenkins_credential_channel() {
  local label="POST /internal/aos/jenkins-credential-channel — 所属控制器：M2M-only: reuse the platform server without sending an"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req internal POST "/internal/aos/jenkins-credential-channel" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq798 asdm-admin-services-core (端口 8880)/AosPermission | auth=internal（无配对删除接口，失败请人工核查数据残留）
infra_post_api_aos_permissions_check() {
  local label="POST /api/aos/permissions/check — 所属控制器：C01 (live user permission) and C02 (async execution re"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "action": "string",
  "resource": {
    "type": "string",
    "contextId": "string",
    "projectId": "string",
    "resourceId": "string",
    "scope": "string"
  },
  "runId": "string"
}
JSONEOF
)"
  req internal POST "/api/aos/permissions/check" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq799 asdm-admin-services-core (端口 8880)/AosPermission | auth=internal（无配对删除接口，失败请人工核查数据残留）
infra_post_internal_aos_contexts_items_verify() {
  local label="POST /internal/aos/contexts/items/verify — 所属控制器：C01 (live user permission) and C02 (async execution re"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "contextId": "string",
  "itemIds": [
    "string"
  ]
}
JSONEOF
)"
  req internal POST "/internal/aos/contexts/items/verify" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq800 asdm-admin-services-core (端口 8880)/AosPermission | auth=internal（无配对删除接口，失败请人工核查数据残留）
infra_post_internal_aos_contexts_items_verify_production() {
  local label="POST /internal/aos/contexts/items/verify-production — 所属控制器：C01 (live user permission) and C02 (async execution re"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "contextId": "string",
  "itemIds": [
    "string"
  ]
}
JSONEOF
)"
  req internal POST "/internal/aos/contexts/items/verify-production" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq801 asdm-admin-services-core (端口 8880)/AosPermission | auth=internal（无配对删除接口，失败请人工核查数据残留）
infra_post_internal_aos_permissions_check_execution() {
  local label="POST /internal/aos/permissions/check-execution — 所属控制器：C01 (live user permission) and C02 (async execution re"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "executionContextRef": "string",
  "runId": "string"
}
JSONEOF
)"
  req internal POST "/internal/aos/permissions/check-execution" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq802 asdm-admin-services-core (端口 8880)/CLI Feature Flags | auth=jwt
infra_get_api_feature_flags_key() {
  local label="GET /_api/feature-flags/:key — 摘要：Get a single feature flag tri-state value (CLI read-only)"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/feature-flags/$(path_id key)" "" ""
  expect_read_ok "$label" 200
}

# seq803 asdm-admin-services-core (端口 8880)/CLI Release | auth=public
infra_get_api_cli_releases() {
  local label="GET /_api/cli/releases — 摘要：List all CLI releases (admin) 完整路径：GET /_api/cli/releases"
  need_auth public "$label" || return 0
  req public GET "/_api/cli/releases" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq804 asdm-admin-services-core (端口 8880)/CLI Release | auth=public
infra_post_api_cli_releases() {
  log_skip "POST /_api/cli/releases — 需要 multipart 文件上传，无法幂等自动执行（摘要：Upload a new CLI release binary 完整路径：POST /_api/cli/relea）"
}

# seq805 asdm-admin-services-core (端口 8880)/CLI Release | auth=public
infra_delete_api_cli_releases_id() {
  local label="DELETE /_api/cli/releases/:id — 摘要：Delete a CLI release permanently (admin) 完整路径：DELETE /_ap"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req public DELETE "/_api/cli/releases/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq806 asdm-admin-services-core (端口 8880)/CLI Release | auth=public（无配对删除接口，失败请人工核查数据残留）
infra_post_api_cli_releases_id_republish() {
  local label="POST /_api/cli/releases/:id/republish — 摘要：Republish a withdrawn CLI release (admin) 完整路径：POST /_api"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  req public POST "/_api/cli/releases/$(path_id id)/republish" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq807 asdm-admin-services-core (端口 8880)/CLI Release | auth=public（无配对删除接口，失败请人工核查数据残留）
infra_post_api_cli_releases_id_withdraw() {
  local label="POST /_api/cli/releases/:id/withdraw — 摘要：Withdraw a CLI release (admin) 完整路径：POST /_api/cli/releas"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "withdrawnReason": "string"
}
JSONEOF
)"
  req public POST "/_api/cli/releases/$(path_id id)/withdraw" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq808 asdm-admin-services-core (端口 8880)/CLI Release | auth=public
infra_get_api_cli_releases_download() {
  local label="GET /_api/cli/releases/download — 摘要：Download CLI binary (public endpoint) 完整路径：GET /_api/cli/"
  need_auth public "$label" || return 0
  req public GET "/_api/cli/releases/download" "" "platform=string"
  expect_read_ok "$label" 200
}

# seq809 asdm-admin-services-core (端口 8880)/CLI Release | auth=public
infra_get_api_cli_releases_latest_all() {
  local label="GET /_api/cli/releases/latest-all — 摘要：Get latest CLI version info including withdrawn releases"
  need_auth public "$label" || return 0
  req public GET "/_api/cli/releases/latest-all" "" ""
  expect_read_ok "$label" 200
}

# seq810 asdm-admin-services-core (端口 8880)/CLI Release | auth=public
infra_get_api_cli_releases_latest() {
  local label="GET /_api/cli/releases/latest — 摘要：Get latest CLI version info (public endpoint) 完整路径：GET /_"
  need_auth public "$label" || return 0
  req public GET "/_api/cli/releases/latest" "" ""
  expect_read_ok "$label" 200
}

# seq811 asdm-admin-services-core (端口 8880)/Context Webhook | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_post_api_webhook_collections_collectionGuid() {
  local label="POST /api/webhook/collections/:collectionGuid — 摘要：Collection-level webhook 说明：Process webhook for entire co"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/webhook/collections/$(path_id collectionGuid)" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq812 asdm-admin-services-core (端口 8880)/Context Webhook | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_post_api_webhook_contexts_contextGuid() {
  local label="POST /api/webhook/contexts/:contextGuid — 摘要：Context-level webhook 说明：Process webhook for specific con"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/webhook/contexts/$(path_id contextGuid)" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq813 asdm-admin-services-core (端口 8880)/Context Webhook | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_post_api_webhook_items_itemGuid() {
  local label="POST /api/webhook/items/:itemGuid — 摘要：Item-level webhook 说明：Process webhook for specific contex"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/webhook/items/$(path_id itemGuid)" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq814 asdm-admin-services-core (端口 8880)/Context Webhook | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_post_api_webhook_projects_projectGuid() {
  local label="POST /api/webhook/projects/:projectGuid — 摘要：Project-level webhook 说明：Process webhook for specific pro"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/webhook/projects/$(path_id projectGuid)" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq815 asdm-admin-services-core (端口 8880)/Feature Flag Allowlist | auth=jwt（配对清理: POST /api/feature-flags/:flagKey/allowlist/:userId）
infra_post_api_feature_flags_flagKey_allowlist() {
  local label="POST /api/feature-flags/:flagKey/allowlist — 摘要：Batch add users to allowlist 说明：Add up to 20 users to a f"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "userIds": [
    1
  ]
}
JSONEOF
)"
  req jwt POST "/api/feature-flags/$(path_id flagKey)/allowlist" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/feature-flags/:flagKey/allowlist/:userId
  req jwt DELETE "/api/feature-flags/${rid}/allowlist/$(path_id userId)" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/feature-flags/${rid}/allowlist/$(path_id userId)" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq816 asdm-admin-services-core (端口 8880)/Feature Flag Allowlist | auth=jwt
infra_delete_api_feature_flags_flagKey_allowlist_userId() {
  local label="DELETE /api/feature-flags/:flagKey/allowlist/:userId — 摘要：Remove user from allowlist 说明：Remove a user from a specif"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/feature-flags/${DUMMY_ID}/allowlist/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq817 asdm-admin-services-core (端口 8880)/Feature Flag Allowlist | auth=jwt
infra_get_api_feature_flags_allowlist() {
  local label="GET /api/feature-flags/allowlist — 摘要：Query allowlist entries 说明：Paginated query of feature fla"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/feature-flags/allowlist" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq818 asdm-admin-services-core (端口 8880)/Feature Flag Allowlist | auth=jwt
infra_get_api_feature_flags_allowlist_stats() {
  local label="GET /api/feature-flags/allowlist/stats — 摘要：Get allowlist statistics 说明：Get total number of distinct"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/feature-flags/allowlist/stats" "" ""
  expect_read_ok "$label" 200
}

# seq819 asdm-admin-services-core (端口 8880)/Feature Flags | auth=jwt
infra_get_api_feature_flags() {
  local label="GET /api/feature-flags — 摘要：Get feature flags (paged) 说明：Admin endpoint to list manag"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/feature-flags" "" "page=0&size=10"
  expect_read_ok "$label" 200
}

# seq820 asdm-admin-services-core (端口 8880)/Feature Flags | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_put_api_feature_flags_flagKey() {
  local label="PUT /api/feature-flags/:flagKey — 摘要：Update feature flag 说明：Admin endpoint to update a single"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt PUT "/api/feature-flags/$(path_id flagKey)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq821 asdm-admin-services-core (端口 8880)/Feature Flags | auth=jwt
infra_get_api_feature_flags_public() {
  local label="GET /api/feature-flags/public — 摘要：Get public feature flags 说明：Public endpoint for frontend"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/feature-flags/public" "" ""
  expect_read_ok "$label" 200
}

# seq822 asdm-admin-services-core (端口 8880)/File Path Convert | auth=jwt
infra_get_ai_avfs_projectUid_business_entityId_relativePath() {
  local label="GET /_ai/avfs/:projectUid/:business/:entityId/:*relativePath — 摘要：Resolve AVFS semantic path to file content 说明：Converts /_"
  need_auth jwt "$label" || return 0
  req jwt GET "/_ai/avfs/$(path_id projectUid)/$(path_id business)/$(path_id entityId)/$(path_id relativePath)" "" ""
  expect_read_ok "$label" 200
}

# seq823 asdm-admin-services-core (端口 8880)/File Proxy | auth=public
infra_get_api_files_fileId_content() {
  local label="GET /api/files/:fileId/content — 摘要：Direct file content (1.3.4) 说明：Returns raw bytes inline."
  need_auth public "$label" || return 0
  req public GET "/api/files/$(path_id fileId)/content" "" ""
  expect_read_ok "$label" 200
}

# seq824 asdm-admin-services-core (端口 8880)/File Proxy | auth=public
infra_get_api_files_fileId_download() {
  local label="GET /api/files/:fileId/download — 摘要：Download file (1.3.4) 说明：Attachment download. Omit path f"
  need_auth public "$label" || return 0
  req public GET "/api/files/$(path_id fileId)/download" "" ""
  expect_read_ok "$label" 200
}

# seq825 asdm-admin-services-core (端口 8880)/File Proxy | auth=public
infra_get_api_files_fileId_versions_versionNo_content() {
  local label="GET /api/files/:fileId/versions/:versionNo/content — 摘要：Direct file content for a specific version (1.3.4) 说明：Con"
  need_auth public "$label" || return 0
  req public GET "/api/files/$(path_id fileId)/versions/$(path_id versionNo)/content" "" ""
  expect_read_ok "$label" 200
}

# seq826 asdm-admin-services-core (端口 8880)/File Proxy | auth=public
infra_get_api_files_fileId_versions_versionNo_download() {
  local label="GET /api/files/:fileId/versions/:versionNo/download — 摘要：Download file for a specific version (1.3.4) 完整路径：GET /ap"
  need_auth public "$label" || return 0
  req public GET "/api/files/$(path_id fileId)/versions/$(path_id versionNo)/download" "" ""
  expect_read_ok "$label" 200
}

# seq827 asdm-admin-services-core (端口 8880)/File Proxy | auth=public
infra_get_api_files_mappingGuid_entries() {
  local label="GET /api/files/:mappingGuid/entries — 摘要：List entries of an archive mapping 完整路径：GET /api/files/:m"
  need_auth public "$label" || return 0
  req public GET "/api/files/$(path_id mappingGuid)/entries" "" ""
  expect_read_ok "$label" 200
}

# seq828 asdm-admin-services-core (端口 8880)/File Proxy | auth=public
infra_get_api_files_content() {
  local label="GET /api/files/content — 摘要：Direct file content by file:// URI 说明：Parses a file://{uu"
  need_auth public "$label" || return 0
  req public GET "/api/files/content" "" "uri=string"
  expect_read_ok "$label" 200
}

# seq829 asdm-admin-services-core (端口 8880)/Internal Metrics | auth=internal
infra_get_internal_metrics_overview() {
  local label="GET /internal/metrics/overview — 摘要：Get business metrics overview by scope for internal aggre"
  need_auth internal "$label" || return 0
  req internal GET "/internal/metrics/overview" "" "scope=string&page=1&pageSize=10&trendDays=7"
  expect_read_ok "$label" 200
}

# seq830 asdm-admin-services-core (端口 8880)/InternalFeatureFlag | auth=internal
infra_get_internal_feature_flags_flagKey() {
  local label="GET /internal/feature-flags/:flagKey — 所属控制器：}), so callers must send a valid {@code X-Internal-Tok"
  need_auth internal "$label" || return 0
  req internal GET "/internal/feature-flags/$(path_id flagKey)" "" ""
  expect_read_ok "$label" 200
}

# seq831 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_context_results_id_entries() {
  local label="GET /internal/knowledge/context-results/:id/entries — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/context-results/$(path_id id)/entries" "" ""
  expect_read_ok "$label" 200
}

# seq832 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_context_results_id_preview() {
  local label="GET /internal/knowledge/context-results/:id/preview — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/context-results/$(path_id id)/preview" "" ""
  expect_read_ok "$label" 200
}

# seq833 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_contexts_contextId_artifact_counts() {
  local label="GET /internal/knowledge/contexts/:contextId/artifact-counts — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/contexts/$(path_id contextId)/artifact-counts" "" ""
  expect_read_ok "$label" 200
}

# seq834 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_contexts_contextId_items_itemId_ddl() {
  local label="GET /internal/knowledge/contexts/:contextId/items/:itemId/ddl — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/contexts/$(path_id contextId)/items/$(path_id itemId)/ddl" "" ""
  expect_read_ok "$label" 200
}

# seq835 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_contexts_contextId_items_itemId_file_uplo() {
  local label="GET /internal/knowledge/contexts/:contextId/items/:itemId/file-uploads — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/contexts/$(path_id contextId)/items/$(path_id itemId)/file-uploads" "" ""
  expect_read_ok "$label" 200
}

# seq836 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_contexts_contextId_items_itemId_file_uplo_2() {
  local label="GET /internal/knowledge/contexts/:contextId/items/:itemId/file-uploads/:uploadId/entries — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/contexts/$(path_id contextId)/items/$(path_id itemId)/file-uploads/$(path_id uploadId)/entries" "" ""
  expect_read_ok "$label" 200
}

# seq837 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_contexts_contextId_items_itemId_file_uplo_3() {
  local label="GET /internal/knowledge/contexts/:contextId/items/:itemId/file-uploads/:uploadId/preview — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/contexts/$(path_id contextId)/items/$(path_id itemId)/file-uploads/$(path_id uploadId)/preview" "" ""
  expect_read_ok "$label" 200
}

# seq838 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_contexts_id() {
  local label="GET /internal/knowledge/contexts/:id — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/contexts/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq839 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_contexts_id_items() {
  local label="GET /internal/knowledge/contexts/:id/items — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/contexts/$(path_id id)/items" "" ""
  expect_read_ok "$label" 200
}

# seq840 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_graphs() {
  local label="GET /internal/knowledge/graphs — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/graphs" "" ""
  expect_read_ok "$label" 200
}

# seq841 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_items_itemId() {
  local label="GET /internal/knowledge/items/:itemId — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/items/$(path_id itemId)" "" ""
  expect_read_ok "$label" 200
}

# seq842 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_items_itemId_context_results() {
  local label="GET /internal/knowledge/items/:itemId/context-results — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/items/$(path_id itemId)/context-results" "" ""
  expect_read_ok "$label" 200
}

# seq843 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_projects() {
  local label="GET /internal/knowledge/projects — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/projects" "" ""
  expect_read_ok "$label" 200
}

# seq844 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_projects_id() {
  local label="GET /internal/knowledge/projects/:id — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/projects/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq845 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_projects_id_contexts() {
  local label="GET /internal/knowledge/projects/:id/contexts — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/projects/$(path_id id)/contexts" "" ""
  expect_read_ok "$label" 200
}

# seq846 asdm-admin-services-core (端口 8880)/InternalKnowledge | auth=internal
infra_get_internal_knowledge_projects_search() {
  local label="GET /internal/knowledge/projects/search — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/knowledge/projects/search" "" "page=1&size=12"
  expect_read_ok "$label" 200
}

# seq847 asdm-admin-services-core (端口 8880)/InternalSkill | auth=internal
infra_get_internal_skills_download() {
  local label="GET /internal/skills/download — 所属控制器：}， 由 {@code InternalTokenInterceptor} 用 {@code X-Inter"
  need_auth internal "$label" || return 0
  req internal GET "/internal/skills/download" "" "registryId=string&mode=local"
  expect_read_ok "$label" 200
}

# seq848 asdm-admin-services-core (端口 8880)/InternalUser | auth=internal
infra_get_internal_users_userId() {
  local label="GET /internal/users/:userId — 所属控制器：m2m user lookup for portal-backend and other internal"
  need_auth internal "$label" || return 0
  req internal GET "/internal/users/$(path_id userId)" "" ""
  expect_read_ok "$label" 200
}

# seq849 asdm-admin-services-core (端口 8880)/InternalUser | auth=internal
infra_get_internal_users_batch() {
  local label="GET /internal/users/batch — 所属控制器：m2m user lookup for portal-backend and other internal"
  need_auth internal "$label" || return 0
  req internal GET "/internal/users/batch" "" ""
  expect_read_ok "$label" 200
}

# seq850 asdm-admin-services-core (端口 8880)/InternalUser | auth=internal
infra_get_internal_users_user_scope_users() {
  local label="GET /internal/users/user-scope/users — 所属控制器：m2m user lookup for portal-backend and other internal"
  need_auth internal "$label" || return 0
  req internal GET "/internal/users/user-scope/users" "" ""
  expect_read_ok "$label" 200
}

# seq851 asdm-admin-services-core (端口 8880)/Metrics | auth=jwt
infra_get_api_metrics_organization() {
  local label="GET /api/metrics/organization — 完整路径：GET /api/metrics/organization（服务：asdm-admin-services-co"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/metrics/organization" "" "collectionId=string&page=0&pageSize=10"
  expect_read_ok "$label" 200
}

# seq852 asdm-admin-services-core (端口 8880)/Metrics | auth=jwt
infra_get_api_metrics_organization_charts() {
  local label="GET /api/metrics/organization/charts — 完整路径：GET /api/metrics/organization/charts（服务：asdm-admin-serv"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/metrics/organization/charts" "" "collectionId=string&days=7"
  expect_read_ok "$label" 200
}

# seq853 asdm-admin-services-core (端口 8880)/Metrics | auth=jwt
infra_get_api_metrics_server() {
  local label="GET /api/metrics/server — 完整路径：GET /api/metrics/server（服务：asdm-admin-services-core，端口"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/metrics/server" "" "page=0&pageSize=10"
  expect_read_ok "$label" 200
}

# seq854 asdm-admin-services-core (端口 8880)/Migration | auth=jwt
infra_get_api_migration_manifest_removal_preview() {
  local label="GET /api/migration/manifest-removal/preview — 所属控制器：REST controller for resource migration from local disk"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/migration/manifest-removal/preview" "" ""
  expect_read_ok "$label" 200
}

# seq855 asdm-admin-services-core (端口 8880)/Migration | auth=jwt
infra_post_api_migration_manifest_removal_start() {
  log_skip "POST /api/migration/manifest-removal/start — 永久跳过：路径含状态变更/清理类操作段（migration/start），避免破坏环境"
}

# seq856 asdm-admin-services-core (端口 8880)/Migration | auth=jwt
infra_get_api_migration_preview() {
  local label="GET /api/migration/preview — 所属控制器：REST controller for resource migration from local disk"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/migration/preview" "" ""
  expect_read_ok "$label" 200
}

# seq857 asdm-admin-services-core (端口 8880)/Migration | auth=jwt
infra_post_api_migration_start() {
  log_skip "POST /api/migration/start — 永久跳过：路径含状态变更/清理类操作段（migration/start），避免破坏环境"
}

# seq858 asdm-admin-services-core (端口 8880)/Notification | auth=jwt
infra_delete_api_notifications() {
  log_skip "DELETE /api/notifications — 永久跳过：静态路径整体删除，无法限定删除范围"
}

# seq859 asdm-admin-services-core (端口 8880)/Notification | auth=jwt
infra_get_api_notifications() {
  local label="GET /api/notifications — 摘要：List notifications for the current user 完整路径：GET /api/not"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/notifications" "" "page=0&size=10"
  expect_read_ok "$label" 200
}

# seq860 asdm-admin-services-core (端口 8880)/Notification | auth=jwt
infra_get_api_notifications_id() {
  local label="GET /api/notifications/:id — 摘要：Get notification detail 完整路径：GET /api/notifications/:id（服"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/notifications/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq861 asdm-admin-services-core (端口 8880)/Notification | auth=jwt
infra_delete_api_notifications_id() {
  local label="DELETE /api/notifications/:id — 摘要：Delete a notification 完整路径：DELETE /api/notifications/:id（"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/notifications/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq862 asdm-admin-services-core (端口 8880)/Notification | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_put_api_notifications_id_read() {
  local label="PUT /api/notifications/:id/read — 摘要：Mark a notification as read 完整路径：PUT /api/notifications/:"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt PUT "/api/notifications/$(path_id id)/read" "" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq863 asdm-admin-services-core (端口 8880)/Notification | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_put_api_notifications_read_all() {
  local label="PUT /api/notifications/read-all — 摘要：Mark all notifications as read 完整路径：PUT /api/notification"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt PUT "/api/notifications/read-all" "" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq864 asdm-admin-services-core (端口 8880)/Notification | auth=jwt
infra_get_api_notifications_unread_count() {
  local label="GET /api/notifications/unread-count — 摘要：Get unread notification count 完整路径：GET /api/notifications"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/notifications/unread-count" "" ""
  expect_read_ok "$label" 200
}

# seq865 asdm-admin-services-core (端口 8880)/Pipeline Servers | auth=jwt
infra_get_api_pipeline_servers() {
  local label="GET /api/pipeline-servers — 摘要：List global repository settings 完整路径：GET /api/pipeline-se"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline-servers" "" ""
  expect_read_ok "$label" 200
}

# seq866 asdm-admin-services-core (端口 8880)/Pipeline Servers | auth=jwt（配对清理: POST /api/pipeline-servers/:id）
infra_post_api_pipeline_servers() {
  local label="POST /api/pipeline-servers — 摘要：Create global repository setting 完整路径：POST /api/pipeline-"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "uname": "example",
 "level": "string",
 "settingType": "string",
 "pipelineType": "string",
 "collectionId": "string",
 "projectId": "string",
 "userId": "string",
 "value": {
  "key": "value"
 }
}
JSONEOF
)"
  req jwt POST "/api/pipeline-servers" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/pipeline-servers/:id
  req jwt DELETE "/api/pipeline-servers/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/pipeline-servers/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq867 asdm-admin-services-core (端口 8880)/Pipeline Servers | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_put_api_pipeline_servers_id() {
  local label="PUT /api/pipeline-servers/:id — 摘要：Update global repository setting 完整路径：PUT /api/pipeline-s"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "uname": "example",
 "level": "string",
 "settingType": "string",
 "pipelineType": "string",
 "collectionId": "string",
 "projectId": "string",
 "userId": "string",
 "value": {
  "key": "value"
 }
}
JSONEOF
)"
  req jwt PUT "/api/pipeline-servers/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq868 asdm-admin-services-core (端口 8880)/Pipeline Servers | auth=jwt
infra_delete_api_pipeline_servers_id() {
  local label="DELETE /api/pipeline-servers/:id — 摘要：Delete global repository setting 完整路径：DELETE /api/pipelin"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/pipeline-servers/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq869 asdm-admin-services-core (端口 8880)/Pipeline Servers | auth=jwt
infra_get_api_pipeline_servers_jenkinsfile_options() {
  local label="GET /api/pipeline-servers/jenkinsfile-options — 摘要：列出 classpath:pipelines/ 下指定分组（context | workspace | aos-i"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline-servers/jenkinsfile-options" "" "group=string"
  expect_read_ok "$label" 200
}

# seq870 asdm-admin-services-core (端口 8880)/ProjectMetrics | auth=jwt
infra_get_api_metrics_project_summary() {
  local label="GET /_api/metrics/project/summary — 完整路径：GET /_api/metrics/project/summary（服务：asdm-admin-service"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/metrics/project/summary" "" "projectId=string"
  expect_read_ok "$label" 200
}

# seq871 asdm-admin-services-core (端口 8880)/ProjectMetrics | auth=jwt
infra_get_api_metrics_project_toolsets() {
  local label="GET /_api/metrics/project/toolsets — 完整路径：GET /_api/metrics/project/toolsets（服务：asdm-admin-servic"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/metrics/project/toolsets" "" "projectId=string&page=0&pageSize=10"
  expect_read_ok "$label" 200
}

# seq872 asdm-admin-services-core (端口 8880)/ProjectMetrics | auth=jwt
infra_get_api_metrics_project_usage() {
  local label="GET /_api/metrics/project/usage — 完整路径：GET /_api/metrics/project/usage（服务：asdm-admin-services-"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/metrics/project/usage" "" "projectId=string"
  expect_read_ok "$label" 200
}

# seq873 asdm-admin-services-core (端口 8880)/Settings | auth=jwt
infra_get_api_settings() {
  local label="GET /api/settings — 摘要：Get all settings 说明：Returns a list of all configuration s"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/settings" "" ""
  expect_read_ok "$label" 200
}

# seq874 asdm-admin-services-core (端口 8880)/Settings | auth=jwt（配对清理: POST /api/settings/:id）
infra_post_api_settings() {
  local label="POST /api/settings — 摘要：Create server setting 说明：Creates a new server-level confi"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "uname": "example",
 "level": "string",
 "settingType": "string",
 "pipelineType": "string",
 "collectionId": "string",
 "projectId": "string",
 "userId": "string",
 "value": {
  "key": "value"
 }
}
JSONEOF
)"
  req jwt POST "/api/settings" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/settings/:id
  req jwt DELETE "/api/settings/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/settings/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq875 asdm-admin-services-core (端口 8880)/Settings | auth=jwt
infra_get_api_settings_id() {
  local label="GET /api/settings/:id — 摘要：Get setting by ID 说明：Returns a single setting by its ID"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/settings/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq876 asdm-admin-services-core (端口 8880)/Settings | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_put_api_settings_id() {
  local label="PUT /api/settings/:id — 摘要：Update setting by ID 说明：Updates a config setting by ID. R"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt PUT "/api/settings/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq877 asdm-admin-services-core (端口 8880)/Settings | auth=jwt
infra_delete_api_settings_id() {
  local label="DELETE /api/settings/:id — 摘要：Delete a non-server setting by ID 说明：Deletes a collection"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/settings/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq878 asdm-admin-services-core (端口 8880)/Settings | auth=jwt
infra_get_api_settings_api_config_settings() {
  local label="GET /api/settings/api/config/settings — 摘要：Merged config settings 说明：Resolve effective settings for"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/settings/api/config/settings" "" ""
  expect_read_ok "$label" 200
}

# seq879 asdm-admin-services-core (端口 8880)/Settings | auth=jwt
infra_get_api_settings_collection_collectionId() {
  local label="GET /api/settings/collection/:collectionId — 摘要：Get settings by collection ID 说明：Returns settings for a s"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/settings/collection/$(path_id collectionId)" "" ""
  expect_read_ok "$label" 200
}

# seq880 asdm-admin-services-core (端口 8880)/Settings | auth=jwt
infra_get_api_settings_flyway_info() {
  local label="GET /api/settings/flyway-info — 摘要：Get Flyway migration info 说明：Returns the latest Flyway mi"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/settings/flyway-info" "" ""
  expect_read_ok "$label" 200
}

# seq881 asdm-admin-services-core (端口 8880)/Settings | auth=jwt
infra_get_api_settings_installation_field() {
  local label="GET /api/settings/installation-field — 摘要：Get ASDM installation field URL 说明：Returns the installati"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/settings/installation-field" "" ""
  expect_read_ok "$label" 200
}

# seq882 asdm-admin-services-core (端口 8880)/Settings | auth=jwt
infra_get_api_settings_installation_field_default() {
  local label="GET /api/settings/installation-field-default — 摘要：Get ASDM installation field default URL 说明：Returns the pe"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/settings/installation-field-default" "" ""
  expect_read_ok "$label" 200
}

# seq883 asdm-admin-services-core (端口 8880)/Settings | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_put_api_settings_installation_field_default() {
  local label="PUT /api/settings/installation-field-default — 摘要：Set ASDM installation field default URL 说明：Persists the f"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt PUT "/api/settings/installation-field-default" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq884 asdm-admin-services-core (端口 8880)/Settings | auth=jwt
infra_get_api_settings_level_level() {
  local label="GET /api/settings/level/:level — 摘要：Get settings by level 说明：Returns settings filtered by lev"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/settings/level/$(path_id level)" "" ""
  expect_read_ok "$label" 200
}

# seq885 asdm-admin-services-core (端口 8880)/Settings | auth=jwt
infra_get_api_settings_project_projectId() {
  local label="GET /api/settings/project/:projectId — 摘要：Get settings by project ID 说明：Returns settings for a spec"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/settings/project/$(path_id projectId)" "" ""
  expect_read_ok "$label" 200
}

# seq886 asdm-admin-services-core (端口 8880)/Settings | auth=jwt
infra_get_api_settings_uname_uname() {
  local label="GET /api/settings/uname/:uname — 摘要：Get setting by uname 说明：Returns a single setting by its u"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/settings/uname/$(path_id uname)" "" ""
  expect_read_ok "$label" 200
}

# seq887 asdm-admin-services-core (端口 8880)/Settings | auth=jwt
infra_get_api_settings_user_userId() {
  local label="GET /api/settings/user/:userId — 摘要：Get settings by user ID 说明：Returns settings for a specifi"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/settings/user/$(path_id userId)" "" ""
  expect_read_ok "$label" 200
}

# seq888 asdm-admin-services-core (端口 8880)/Stats | auth=jwt
infra_get_api_metrics_stats_collection_collectionId() {
  local label="GET /api/metrics/stats/collection/:collectionId — 摘要：Get collection-level statistics 说明：Returns counts for wor"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/metrics/stats/collection/$(path_id collectionId)" "" ""
  expect_read_ok "$label" 200
}

# seq889 asdm-admin-services-core (端口 8880)/Stats | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_post_api_metrics_stats_collections() {
  local label="POST /api/metrics/stats/collections — 摘要：Get aggregated collection statistics 说明：Aggregates counts"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "collectionIds": [
    "string"
  ]
}
JSONEOF
)"
  req jwt POST "/api/metrics/stats/collections" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq890 asdm-admin-services-core (端口 8880)/System | auth=public
infra_get_api_system_version() {
  local label="GET /api/system/version — 摘要：Get backend build version 说明：Returns the build version/co"
  need_auth public "$label" || return 0
  req public GET "/api/system/version" "" ""
  expect_read_ok "$label" 200
}

# seq891 asdm-admin-services-core (端口 8880)/TelemetryTest | auth=jwt
infra_get_api_telemetry_test_context() {
  local label="GET /api/telemetry/test-context — 所属控制器：Test controller for telemetry m2m communication. Accep"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/telemetry/test-context" "" ""
  expect_read_ok "$label" 200
}

# seq892 asdm-admin-services-core (端口 8880)/TelemetryTest | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_post_api_telemetry_test_events() {
  local label="POST /api/telemetry/test-events — 所属控制器：Test controller for telemetry m2m communication. Accep"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/telemetry/test-events" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq893 asdm-admin-services-core (端口 8880)/URL Config | auth=public
infra_get_api_url_config_docs() {
  local label="GET /api/url-config/docs — 摘要：Get all doc URL configs 说明：Public: returns URL configurat"
  need_auth public "$label" || return 0
  req public GET "/api/url-config/docs" "" ""
  expect_read_ok "$label" 200
}

# seq894 asdm-admin-services-file-service (端口 8887)/生命周期 | auth=internal
infra_get_internal_lifecycle_dry_run() {
  local label="GET /internal/lifecycle/dry-run — 摘要：清理预演（Dry Run） 说明：列出超过保留期的软删除文件候选，不执行物理删除。"
  need_auth internal "$label" || return 0
  req internal GET "/internal/lifecycle/dry-run" "" "retentionDays=30"
  expect_read_ok "$label" 200
}

# seq895 asdm-admin-services-file-service (端口 8887)/生命周期 | auth=internal（无配对删除接口，失败请人工核查数据残留）
infra_post_internal_lifecycle_run() {
  local label="POST /internal/lifecycle/run — 摘要：执行生命周期物理清理 说明：删除超过保留期的软删除对象在 S3 中的数据，并将元数据标记为 PURGED。"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  req internal POST "/internal/lifecycle/run" "" "retentionDays=30&dryRun=false"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq896 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_get_internal_files() {
  local label="GET /internal/files — 摘要：文件列表 说明：按物理桶 + 业务 prefix 列出 ACTIVE 文件。"
  need_auth internal "$label" || return 0
  req internal GET "/internal/files" "" "prefix=string"
  expect_read_ok "$label" 200
}

# seq897 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_get_internal_files_uuid() {
  local label="GET /internal/files/:uuid — 摘要：文件详情 说明：查询指定文件对象元数据；压缩包类型会附带 entries（含各条目 uuid）。uuid 全局唯一"
  need_auth internal "$label" || return 0
  req internal GET "/internal/files/$(path_id uuid)" "" ""
  expect_read_ok "$label" 200
}

# seq898 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_delete_internal_files_uuid() {
  local label="DELETE /internal/files/:uuid — 完整路径：DELETE /internal/files/:uuid（服务：asdm-admin-services-fil"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req internal DELETE "/internal/files/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq899 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_get_internal_files_uuid_download() {
  local label="GET /internal/files/:uuid/download — 摘要：附件下载 说明：使用全局 uuid 下载文件（attachment）。无需 X-Internal-Token。"
  need_auth internal "$label" || return 0
  req internal GET "/internal/files/$(path_id uuid)/download" "" ""
  expect_read_ok "$label" 200
}

# seq900 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_get_internal_files_uuid_entries() {
  local label="GET /internal/files/:uuid/entries — 完整路径：GET /internal/files/:uuid/entries（服务：asdm-admin-service"
  need_auth internal "$label" || return 0
  req internal GET "/internal/files/$(path_id uuid)/entries" "" ""
  expect_read_ok "$label" 200
}

# seq901 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_get_internal_files_uuid_preview() {
  local label="GET /internal/files/:uuid/preview — 摘要：在线预览 说明：使用全局 uuid 预览文件字节流（inline）。无需 X-Internal-Token。"
  need_auth internal "$label" || return 0
  req internal GET "/internal/files/$(path_id uuid)/preview" "" ""
  expect_read_ok "$label" 200
}

# seq902 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_post_internal_files_uuid_upload_archive() {
  log_skip "POST /internal/files/:uuid/upload-archive — 需要 multipart 文件上传，无法幂等自动执行（完整路径：POST /internal/files/:uuid/upload-archive（服务：asdm-admin）"
}

# seq903 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_get_internal_files_uuid_versions() {
  local label="GET /internal/files/:uuid/versions — 完整路径：GET /internal/files/:uuid/versions（服务：asdm-admin-servic"
  need_auth internal "$label" || return 0
  req internal GET "/internal/files/$(path_id uuid)/versions" "" ""
  expect_read_ok "$label" 200
}

# seq904 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_post_internal_files_uuid_versions() {
  log_skip "POST /internal/files/:uuid/versions — 需要 multipart 文件上传，无法幂等自动执行（完整路径：POST /internal/files/:uuid/versions（服务：asdm-admin-servi）"
}

# seq905 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_get_internal_files_uuid_versions_version_download() {
  local label="GET /internal/files/:uuid/versions/:version/download — 完整路径：GET /internal/files/:uuid/versions/:version/download（服务"
  need_auth internal "$label" || return 0
  req internal GET "/internal/files/$(path_id uuid)/versions/$(path_id version)/download" "" ""
  expect_read_ok "$label" 200
}

# seq906 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_get_internal_files_uuid_versions_version_preview() {
  local label="GET /internal/files/:uuid/versions/:version/preview — 完整路径：GET /internal/files/:uuid/versions/:version/preview（服务："
  need_auth internal "$label" || return 0
  req internal GET "/internal/files/$(path_id uuid)/versions/$(path_id version)/preview" "" ""
  expect_read_ok "$label" 200
}

# seq907 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_get_internal_files_bucket() {
  local label="GET /internal/files/bucket — 摘要：查询存储配置 说明：返回默认物理桶、允许的 buckets/prefixes 白名单。"
  need_auth internal "$label" || return 0
  req internal GET "/internal/files/bucket" "" ""
  expect_read_ok "$label" 200
}

# seq908 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal（配对清理: POST /internal/files/:uuid）
infra_post_internal_files_resolve_uri() {
  local label="POST /internal/files/resolve-uri — 完整路径：POST /internal/files/resolve-uri（服务：asdm-admin-services"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req internal POST "/internal/files/resolve-uri" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /internal/files/:uuid
  req internal DELETE "/internal/files/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req internal DELETE "/internal/files/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq909 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_get_internal_files_smoke() {
  local label="GET /internal/files/smoke — 摘要：冒烟测试 说明：检查文件服务进程是否可用，不访问 DB/S3。"
  need_auth internal "$label" || return 0
  req internal GET "/internal/files/smoke" "" ""
  expect_read_ok "$label" 200
}

# seq910 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_post_internal_files_upload_archive() {
  log_skip "POST /internal/files/upload-archive — 需要 multipart 文件上传，无法幂等自动执行（摘要：压缩包上传 说明：新建 uuid；extractArchive=true（默认）时解压为 v1。须指定 prefi）"
}

# seq911 asdm-admin-services-file-service (端口 8887)/文件管理 | auth=internal
infra_post_internal_files_upload() {
  log_skip "POST /internal/files/upload — 需要 multipart 文件上传，无法幂等自动执行（摘要：单文件上传 完整路径：POST /internal/files/upload（服务：asdm-admin-serv）"
}

# seq912 asdm-admin-services-mcp-hosting (端口 8885)/MCP Routes | auth=public
infra_get_api_mcp_hosting_routes() {
  local label="GET /_api/mcp-hosting/routes — 摘要：List Routes 说明：List all MCP route records"
  need_auth public "$label" || return 0
  req public GET "/_api/mcp-hosting/routes" "" ""
  expect_read_ok "$label" 200
}

# seq913 asdm-admin-services-mcp-hosting (端口 8885)/MCP Routes | auth=public（配对清理: POST /_api/mcp-hosting/routes/:id）
infra_post_api_mcp_hosting_routes() {
  local label="POST /_api/mcp-hosting/routes — 摘要：Create Route 说明：Register a new MCP route"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "mcpServerId": "string",
 "instanceGuid": "string",
 "targetUrl": "https://example.com",
 "name": "example__RUN_ID__"
}
JSONEOF
)"
  req public POST "/_api/mcp-hosting/routes" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/mcp-hosting/routes/:id
  req public DELETE "/_api/mcp-hosting/routes/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req public DELETE "/_api/mcp-hosting/routes/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq914 asdm-admin-services-mcp-hosting (端口 8885)/MCP Routes | auth=public
infra_get_api_mcp_hosting_routes_id() {
  local label="GET /_api/mcp-hosting/routes/:id — 摘要：Get Route 说明：Get details of a specific MCP route"
  need_auth public "$label" || return 0
  req public GET "/_api/mcp-hosting/routes/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq915 asdm-admin-services-mcp-hosting (端口 8885)/MCP Routes | auth=public（无配对删除接口，失败请人工核查数据残留）
infra_put_api_mcp_hosting_routes_id() {
  local label="PUT /_api/mcp-hosting/routes/:id — 摘要：Update Route 说明：Update an existing MCP route"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "targetUrl": "https://example.com",
 "enabled": true,
 "name": "example__RUN_ID__"
}
JSONEOF
)"
  req public PUT "/_api/mcp-hosting/routes/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq916 asdm-admin-services-mcp-hosting (端口 8885)/MCP Routes | auth=public
infra_delete_api_mcp_hosting_routes_id() {
  local label="DELETE /_api/mcp-hosting/routes/:id — 摘要：Delete Route 说明：Delete a MCP route (does not affect the t"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req public DELETE "/_api/mcp-hosting/routes/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq917 asdm-admin-services-mcp-hosting (端口 8885)/MCP Routes | auth=public
infra_get_api_mcp_hosting_routes_resolve() {
  local label="GET /_api/mcp-hosting/routes/resolve — 摘要：Resolve Route 说明：Get route by mcpServerId and instanceGui"
  need_auth public "$label" || return 0
  req public GET "/_api/mcp-hosting/routes/resolve" "" "mcpServerId=string&instanceGuid=string"
  expect_read_ok "$label" 200
}

# seq918 asdm-admin-services-telemetry (端口 8886)/Dashboard | auth=jwt
infra_get_api_telemetry_dashboard_agent_effectiveness() {
  local label="GET /_api/telemetry/dashboard/agent-effectiveness — 所属控制器：} paths except the explicitly-public event-reporting p"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/dashboard/agent-effectiveness" "" "range=7d"
  expect_read_ok "$label" 200
}

# seq919 asdm-admin-services-telemetry (端口 8886)/Dashboard | auth=jwt
infra_get_api_telemetry_dashboard_overview() {
  local label="GET /_api/telemetry/dashboard/overview — 所属控制器：} paths except the explicitly-public event-reporting p"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/dashboard/overview" "" "range=7d"
  expect_read_ok "$label" 200
}

# seq920 asdm-admin-services-telemetry (端口 8886)/Dashboard | auth=jwt
infra_get_api_telemetry_dashboard_recent_events() {
  local label="GET /_api/telemetry/dashboard/recent-events — 所属控制器：} paths except the explicitly-public event-reporting p"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/dashboard/recent-events" "" "range=30d"
  expect_read_ok "$label" 200
}

# seq921 asdm-admin-services-telemetry (端口 8886)/Dashboard | auth=jwt
infra_get_api_telemetry_dashboard_recent_events_filter_options() {
  local label="GET /_api/telemetry/dashboard/recent-events/filter-options — 所属控制器：} paths except the explicitly-public event-reporting p"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/dashboard/recent-events/filter-options" "" "range=30d"
  expect_read_ok "$label" 200
}

# seq922 asdm-admin-services-telemetry (端口 8886)/Dashboard | auth=jwt
infra_get_api_telemetry_dashboard_sessions() {
  local label="GET /_api/telemetry/dashboard/sessions — 所属控制器：} paths except the explicitly-public event-reporting p"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/dashboard/sessions" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq923 asdm-admin-services-telemetry (端口 8886)/Dashboard | auth=jwt
infra_get_api_telemetry_dashboard_sessions_id_raw() {
  local label="GET /_api/telemetry/dashboard/sessions/:id/raw — 所属控制器：} paths except the explicitly-public event-reporting p"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/dashboard/sessions/$(path_id id)/raw" "" ""
  expect_read_ok "$label" 200
}

# seq924 asdm-admin-services-telemetry (端口 8886)/Dashboard | auth=jwt
infra_get_api_telemetry_dashboard_sessions_by_session_id_sessionId_raw() {
  local label="GET /_api/telemetry/dashboard/sessions/by-session-id/:sessionId/raw — 所属控制器：} paths except the explicitly-public event-reporting p"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/dashboard/sessions/by-session-id/$(path_id sessionId)/raw" "" ""
  expect_read_ok "$label" 200
}

# seq925 asdm-admin-services-telemetry (端口 8886)/DashboardCacheAdmin | auth=jwt
infra_post_api_telemetry_dashboard_cache_rebuild() {
  log_skip "POST /_api/telemetry/dashboard-cache/rebuild — 永久跳过：路径含状态变更/清理类操作段（rebuild），避免破坏环境"
}

# seq926 asdm-admin-services-telemetry (端口 8886)/DashboardCacheAdmin | auth=jwt
infra_get_api_telemetry_dashboard_cache_status() {
  local label="GET /_api/telemetry/dashboard-cache/status — 所属控制器：}) requires a valid JWT or the internal token, and eve"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/dashboard-cache/status" "" ""
  expect_read_ok "$label" 200
}

# seq927 asdm-admin-services-telemetry (端口 8886)/Metrics | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_post_api_telemetry_metrics_resources_download_counts() {
  local label="POST /_api/telemetry/metrics/resources/download-counts — 所属控制器：} 已由 {@code WebConfig} 挂上 internalToken -&gt; jwt -&gt"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "registryIds": [
    "string"
  ],
  "startAt": "string",
  "endAt": "string"
}
JSONEOF
)"
  req jwt POST "/_api/telemetry/metrics/resources/download-counts" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq928 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_post_api_telemetry_batch() {
  local label="POST /_api/telemetry/batch — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/_api/telemetry/batch" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq929 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_context() {
  local label="GET /_api/telemetry/context — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/context" "" ""
  expect_read_ok "$label" 200
}

# seq930 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_post_api_telemetry_events() {
  local label="POST /_api/telemetry/events — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/_api/telemetry/events" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq931 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_events_download_count() {
  local label="GET /_api/telemetry/events/download-count — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/events/download-count" "" "registryId=string"
  expect_read_ok "$label" 200
}

# seq932 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt（无配对删除接口，失败请人工核查数据残留）
infra_post_api_telemetry_events_my_others_heat_count() {
  local label="POST /_api/telemetry/events/my/others-heat-count — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "userGuid": "string",
  "type": 1,
  "resourceIds": [
    "string"
  ]
}
JSONEOF
)"
  req jwt POST "/_api/telemetry/events/my/others-heat-count" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq933 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_events_my_resource_count() {
  local label="GET /_api/telemetry/events/my/resource-count — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/events/my/resource-count" "" "type=4"
  expect_read_ok "$label" 200
}

# seq934 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_events_my_resource_download() {
  local label="GET /_api/telemetry/events/my/resource-download — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/events/my/resource-download" "" ""
  expect_read_ok "$label" 200
}

# seq935 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_events_my_resource_install() {
  local label="GET /_api/telemetry/events/my/resource-install — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/events/my/resource-install" "" "resourceType=all"
  expect_read_ok "$label" 200
}

# seq936 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_events_my_resource_type_count() {
  local label="GET /_api/telemetry/events/my/resource-type-count — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/events/my/resource-type-count" "" "type=4"
  expect_read_ok "$label" 200
}

# seq937 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_events_my_resource_upload() {
  local label="GET /_api/telemetry/events/my/resource-upload — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/events/my/resource-upload" "" ""
  expect_read_ok "$label" 200
}

# seq938 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_events_my_resource_view() {
  local label="GET /_api/telemetry/events/my/resource-view — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/events/my/resource-view" "" ""
  expect_read_ok "$label" 200
}

# seq939 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_health() {
  local label="GET /_api/telemetry/health — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/health" "" ""
  expect_read_ok "$label" 200
}

# seq940 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_leaderboard_aggregate() {
  local label="GET /_api/telemetry/leaderboard/aggregate — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/leaderboard/aggregate" "" "eventType=string&dimension=string&startAt=string&endAt=string"
  expect_read_ok "$label" 200
}

# seq941 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_metrics() {
  local label="GET /_api/telemetry/metrics — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/metrics" "" ""
  expect_read_ok "$label" 200
}

# seq942 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_resources_page_view_count() {
  local label="GET /_api/telemetry/resources/page-view-count — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/resources/page-view-count" "" "days=90"
  expect_read_ok "$label" 200
}

# seq943 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_resources_top_downloaded() {
  local label="GET /_api/telemetry/resources/top-downloaded — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/resources/top-downloaded" "" ""
  expect_read_ok "$label" 200
}

# seq944 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_resources_top_viewed() {
  local label="GET /_api/telemetry/resources/top-viewed — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/resources/top-viewed" "" ""
  expect_read_ok "$label" 200
}

# seq945 asdm-admin-services-telemetry (端口 8886)/Telemetry | auth=jwt
infra_get_api_telemetry_rollup_daily() {
  local label="GET /_api/telemetry/rollup/daily — 所属控制器：Telemetry Controller - FT-041 Data Reporting 2.0 REST"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/telemetry/rollup/daily" "" "date=2026-01-01"
  expect_read_ok "$label" 200
}

# ===== 入口 =====
main() {
  set +e   # 单用例失败不中断
  echo ""
  echo "========== 基础设施域 (152 apis) =========="
  login_if_needed || true
  infra_post_internal_aos_graph_build_dispatch || true
  infra_get_internal_aos_graph_build_dispatch_requestId || true
  infra_post_internal_aos_graph_build_dispatch_requestId_cancel || true
  infra_post_internal_aos_jenkins_credential_channel || true
  infra_post_api_aos_permissions_check || true
  infra_post_internal_aos_contexts_items_verify || true
  infra_post_internal_aos_contexts_items_verify_production || true
  infra_post_internal_aos_permissions_check_execution || true
  infra_get_api_feature_flags_key || true
  infra_get_api_cli_releases || true
  infra_post_api_cli_releases || true
  infra_delete_api_cli_releases_id || true
  infra_post_api_cli_releases_id_republish || true
  infra_post_api_cli_releases_id_withdraw || true
  infra_get_api_cli_releases_download || true
  infra_get_api_cli_releases_latest_all || true
  infra_get_api_cli_releases_latest || true
  infra_post_api_webhook_collections_collectionGuid || true
  infra_post_api_webhook_contexts_contextGuid || true
  infra_post_api_webhook_items_itemGuid || true
  infra_post_api_webhook_projects_projectGuid || true
  infra_post_api_feature_flags_flagKey_allowlist || true
  infra_delete_api_feature_flags_flagKey_allowlist_userId || true
  infra_get_api_feature_flags_allowlist || true
  infra_get_api_feature_flags_allowlist_stats || true
  infra_get_api_feature_flags || true
  infra_put_api_feature_flags_flagKey || true
  infra_get_api_feature_flags_public || true
  infra_get_ai_avfs_projectUid_business_entityId_relativePath || true
  infra_get_api_files_fileId_content || true
  infra_get_api_files_fileId_download || true
  infra_get_api_files_fileId_versions_versionNo_content || true
  infra_get_api_files_fileId_versions_versionNo_download || true
  infra_get_api_files_mappingGuid_entries || true
  infra_get_api_files_content || true
  infra_get_internal_metrics_overview || true
  infra_get_internal_feature_flags_flagKey || true
  infra_get_internal_knowledge_context_results_id_entries || true
  infra_get_internal_knowledge_context_results_id_preview || true
  infra_get_internal_knowledge_contexts_contextId_artifact_counts || true
  infra_get_internal_knowledge_contexts_contextId_items_itemId_ddl || true
  infra_get_internal_knowledge_contexts_contextId_items_itemId_file_uplo || true
  infra_get_internal_knowledge_contexts_contextId_items_itemId_file_uplo_2 || true
  infra_get_internal_knowledge_contexts_contextId_items_itemId_file_uplo_3 || true
  infra_get_internal_knowledge_contexts_id || true
  infra_get_internal_knowledge_contexts_id_items || true
  infra_get_internal_knowledge_graphs || true
  infra_get_internal_knowledge_items_itemId || true
  infra_get_internal_knowledge_items_itemId_context_results || true
  infra_get_internal_knowledge_projects || true
  infra_get_internal_knowledge_projects_id || true
  infra_get_internal_knowledge_projects_id_contexts || true
  infra_get_internal_knowledge_projects_search || true
  infra_get_internal_skills_download || true
  infra_get_internal_users_userId || true
  infra_get_internal_users_batch || true
  infra_get_internal_users_user_scope_users || true
  infra_get_api_metrics_organization || true
  infra_get_api_metrics_organization_charts || true
  infra_get_api_metrics_server || true
  infra_get_api_migration_manifest_removal_preview || true
  infra_post_api_migration_manifest_removal_start || true
  infra_get_api_migration_preview || true
  infra_post_api_migration_start || true
  infra_delete_api_notifications || true
  infra_get_api_notifications || true
  infra_get_api_notifications_id || true
  infra_delete_api_notifications_id || true
  infra_put_api_notifications_id_read || true
  infra_put_api_notifications_read_all || true
  infra_get_api_notifications_unread_count || true
  infra_get_api_pipeline_servers || true
  infra_post_api_pipeline_servers || true
  infra_put_api_pipeline_servers_id || true
  infra_delete_api_pipeline_servers_id || true
  infra_get_api_pipeline_servers_jenkinsfile_options || true
  infra_get_api_metrics_project_summary || true
  infra_get_api_metrics_project_toolsets || true
  infra_get_api_metrics_project_usage || true
  infra_get_api_settings || true
  infra_post_api_settings || true
  infra_get_api_settings_id || true
  infra_put_api_settings_id || true
  infra_delete_api_settings_id || true
  infra_get_api_settings_api_config_settings || true
  infra_get_api_settings_collection_collectionId || true
  infra_get_api_settings_flyway_info || true
  infra_get_api_settings_installation_field || true
  infra_get_api_settings_installation_field_default || true
  infra_put_api_settings_installation_field_default || true
  infra_get_api_settings_level_level || true
  infra_get_api_settings_project_projectId || true
  infra_get_api_settings_uname_uname || true
  infra_get_api_settings_user_userId || true
  infra_get_api_metrics_stats_collection_collectionId || true
  infra_post_api_metrics_stats_collections || true
  infra_get_api_system_version || true
  infra_get_api_telemetry_test_context || true
  infra_post_api_telemetry_test_events || true
  infra_get_api_url_config_docs || true
  infra_get_internal_lifecycle_dry_run || true
  infra_post_internal_lifecycle_run || true
  infra_get_internal_files || true
  infra_get_internal_files_uuid || true
  infra_delete_internal_files_uuid || true
  infra_get_internal_files_uuid_download || true
  infra_get_internal_files_uuid_entries || true
  infra_get_internal_files_uuid_preview || true
  infra_post_internal_files_uuid_upload_archive || true
  infra_get_internal_files_uuid_versions || true
  infra_post_internal_files_uuid_versions || true
  infra_get_internal_files_uuid_versions_version_download || true
  infra_get_internal_files_uuid_versions_version_preview || true
  infra_get_internal_files_bucket || true
  infra_post_internal_files_resolve_uri || true
  infra_get_internal_files_smoke || true
  infra_post_internal_files_upload_archive || true
  infra_post_internal_files_upload || true
  infra_get_api_mcp_hosting_routes || true
  infra_post_api_mcp_hosting_routes || true
  infra_get_api_mcp_hosting_routes_id || true
  infra_put_api_mcp_hosting_routes_id || true
  infra_delete_api_mcp_hosting_routes_id || true
  infra_get_api_mcp_hosting_routes_resolve || true
  infra_get_api_telemetry_dashboard_agent_effectiveness || true
  infra_get_api_telemetry_dashboard_overview || true
  infra_get_api_telemetry_dashboard_recent_events || true
  infra_get_api_telemetry_dashboard_recent_events_filter_options || true
  infra_get_api_telemetry_dashboard_sessions || true
  infra_get_api_telemetry_dashboard_sessions_id_raw || true
  infra_get_api_telemetry_dashboard_sessions_by_session_id_sessionId_raw || true
  infra_post_api_telemetry_dashboard_cache_rebuild || true
  infra_get_api_telemetry_dashboard_cache_status || true
  infra_post_api_telemetry_metrics_resources_download_counts || true
  infra_post_api_telemetry_batch || true
  infra_get_api_telemetry_context || true
  infra_post_api_telemetry_events || true
  infra_get_api_telemetry_events_download_count || true
  infra_post_api_telemetry_events_my_others_heat_count || true
  infra_get_api_telemetry_events_my_resource_count || true
  infra_get_api_telemetry_events_my_resource_download || true
  infra_get_api_telemetry_events_my_resource_install || true
  infra_get_api_telemetry_events_my_resource_type_count || true
  infra_get_api_telemetry_events_my_resource_upload || true
  infra_get_api_telemetry_events_my_resource_view || true
  infra_get_api_telemetry_health || true
  infra_get_api_telemetry_leaderboard_aggregate || true
  infra_get_api_telemetry_metrics || true
  infra_get_api_telemetry_resources_page_view_count || true
  infra_get_api_telemetry_resources_top_downloaded || true
  infra_get_api_telemetry_resources_top_viewed || true
  infra_get_api_telemetry_rollup_daily || true
  finish
}
main "$@"
