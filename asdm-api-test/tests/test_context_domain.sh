#!/usr/bin/env bash
# ============================================================================
# 上下文库域 — 幂等自动化测试（由 gen/generate.js 从 api.json 生成，勿手工修改）
# 重新生成: node gen/generate.js
# 覆盖服务: core
# 接口总数: 95（读 64 直测 / 写 28 受控[含配对清理 10] / 永久跳过 3）
# 环境变量: ASDM_BASE_URL / ASDM_LOGIN_EMAIL / ASDM_LOGIN_PASSWORD / ASDM_TOKEN /
#           ASDM_PAT / ASDM_INTERNAL_TOKEN / ASDM_OPEN_ACCESS_TOKEN / ASDM_CITIC_SECRET /
#           ASDM_ALLOW_WRITES=1（执行写操作）/ ASDM_TEST_<参数名>（路径参数覆盖）
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ===== 被测接口用例 =====
# seq265 asdm-admin-services-core (端口 8880)/Context Analysis (Admin) | auth=jwt（无配对删除接口，失败请人工核查数据残留）
context_post_api_admin_library_context_analysis_trigger_contextId() {
  local label="POST /api/admin/library/context-analysis/trigger/:contextId — 摘要：Trigger context analysis pipeline 说明：Manually trigger the"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/admin/library/context-analysis/trigger/$(path_id contextId)" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq266 asdm-admin-services-core (端口 8880)/Context Webhook Settings | auth=jwt
context_get_api_library_contexts_contextId_webhook() {
  local label="GET /api/library/contexts/:contextId/webhook — 摘要：Get webhook configuration 说明：Retrieve webhook settings fo"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/webhook" "" ""
  expect_read_ok "$label" 200
}

# seq267 asdm-admin-services-core (端口 8880)/Context Webhook Settings | auth=jwt（无配对删除接口，失败请人工核查数据残留）
context_put_api_library_contexts_contextId_webhook() {
  local label="PUT /api/library/contexts/:contextId/webhook — 摘要：Create or update webhook configuration 说明：Configure webho"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "contextItemId": 1,
  "platform": "string",
  "repositoryUrl": "https://example.com",
  "branch": "string",
  "enabled": true
}
JSONEOF
)"
  req jwt PUT "/api/library/contexts/$(path_id contextId)/webhook" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq268 asdm-admin-services-core (端口 8880)/Context Webhook Settings | auth=jwt
context_delete_api_library_contexts_contextId_webhook() {
  local label="DELETE /api/library/contexts/:contextId/webhook — 摘要：Delete webhook configuration 说明：Delete webhook settings f"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/library/contexts/${DUMMY_ID}/webhook" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq269 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_context_items_contextItemId_context_results() {
  local label="GET /api/library/context-items/:contextItemId/context-results — 摘要：Get context results by context item ID 说明：Returns a list"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/context-items/$(path_id contextItemId)/context-results" "" ""
  expect_read_ok "$label" 200
}

# seq270 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_context_items_contextItemId_sync_history() {
  local label="GET /api/library/context-items/:contextItemId/sync-history — 摘要：Get sync history by context item ID 说明：Returns a list of"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/context-items/$(path_id contextItemId)/sync-history" "" ""
  expect_read_ok "$label" 200
}

# seq271 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_context_items_id() {
  local label="GET /api/library/context-items/:id — 摘要：Get context item by ID 说明：Returns a single context item b"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/context-items/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq272 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_context_items_guid_guid() {
  local label="GET /api/library/context-items/guid/:guid — 摘要：Get context item by GUID 说明：Returns a single context item"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/context-items/guid/$(path_id guid)" "" ""
  expect_read_ok "$label" 200
}

# seq273 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_context_items_sync_status_syncStatus() {
  local label="GET /api/library/context-items/sync-status/:syncStatus — 摘要：Get context items by sync status 说明：Returns a list of con"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/context-items/sync-status/$(path_id syncStatus)" "" ""
  expect_read_ok "$label" 200
}

# seq274 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_context_results() {
  local label="GET /api/library/context-results — 摘要：Get all context results 说明：Returns a list of all context"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/context-results" "" ""
  expect_read_ok "$label" 200
}

# seq275 asdm-admin-services-core (端口 8880)/Library | auth=jwt（配对清理: POST /api/library/context-results/:id）
context_post_api_library_context_results() {
  local label="POST /api/library/context-results — 摘要：Create a context result 说明：Creates a new context result"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "id": "string",
  "guid": "string",
  "contextId": "string",
  "contextName": "example",
  "contextItemId": "string",
  "syncHistoryId": "string",
  "artifactName": "example",
  "fileName": "/tmp/example",
  "fileContent": "/tmp/example",
  "fileMappingId": "/tmp/example",
  "createdAt": "string",
  "createdBy": "string"
}
JSONEOF
)"
  req jwt POST "/api/library/context-results" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/library/context-results/:id
  req jwt DELETE "/api/library/context-results/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/library/context-results/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq276 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_context_results_id() {
  local label="GET /api/library/context-results/:id — 摘要：Get context result by ID 说明：Returns a single context resu"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/context-results/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq277 asdm-admin-services-core (端口 8880)/Library | auth=jwt（无配对删除接口，失败请人工核查数据残留）
context_put_api_library_context_results_id() {
  local label="PUT /api/library/context-results/:id — 摘要：Update a context result 说明：Updates an existing context re"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "id": "string",
  "guid": "string",
  "contextId": "string",
  "contextName": "example",
  "contextItemId": "string",
  "syncHistoryId": "string",
  "artifactName": "example",
  "fileName": "/tmp/example",
  "fileContent": "/tmp/example",
  "fileMappingId": "/tmp/example",
  "createdAt": "string",
  "createdBy": "string"
}
JSONEOF
)"
  req jwt PUT "/api/library/context-results/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq278 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_delete_api_library_context_results_id() {
  local label="DELETE /api/library/context-results/:id — 摘要：Delete a context result 说明：Deletes an existing context re"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/library/context-results/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq279 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_context_results_id_download() {
  local label="GET /api/library/context-results/:id/download — 摘要：Download a file from context result 说明：Streams a single f"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/context-results/$(path_id id)/download" "" ""
  expect_read_ok "$label" 200
}

# seq280 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_context_results_id_entries() {
  local label="GET /api/library/context-results/:id/entries — 摘要：List archive entries for a context result 说明：Returns the"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/context-results/$(path_id id)/entries" "" ""
  expect_read_ok "$label" 200
}

# seq281 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_context_results_id_preview() {
  local label="GET /api/library/context-results/:id/preview — 摘要：Preview UTF-8 text of a file from context result 说明：Retur"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/context-results/$(path_id id)/preview" "" ""
  expect_read_ok "$label" 200
}

# seq282 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_context_results_id_share_file_url() {
  local label="GET /api/library/context-results/:id/share-file-url — 摘要：Get public share path for a context result file 说明：Legacy"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/context-results/$(path_id id)/share-file-url" "" ""
  expect_read_ok "$label" 200
}

# seq283 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_context_results_guid_guid() {
  local label="GET /api/library/context-results/guid/:guid — 摘要：Get context result by GUID 说明：Returns a single context re"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/context-results/guid/$(path_id guid)" "" ""
  expect_read_ok "$label" 200
}

# seq284 asdm-admin-services-core (端口 8880)/Library | auth=jwt（配对清理: POST /api/library/contexts/:contextId）
context_post_api_library_contexts() {
  local label="POST /api/library/contexts — 摘要：Create context 说明：创建上下文空间，仅需填写必要参数：name、collectionId、proj"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "description": "example text",
 "collectionId": 1,
 "projectId": 1,
 "ownerId": 1
}
JSONEOF
)"
  req jwt POST "/api/library/contexts" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/library/contexts/:contextId
  req jwt DELETE "/api/library/contexts/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/library/contexts/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq285 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts() {
  local label="GET /api/library/contexts — 摘要：Get all contexts (paginated) 说明：Returns a paginated list"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts" "" "page=1&size=20"
  expect_read_ok "$label" 200
}

# seq286 asdm-admin-services-core (端口 8880)/Library | auth=jwt（无配对删除接口，失败请人工核查数据残留）
context_put_api_library_contexts_contextId() {
  local label="PUT /api/library/contexts/:contextId — 摘要：Update context 说明：Update context name and description"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "description": "example text",
 "collectionId": 1,
 "projectId": 1,
 "ownerId": 1
}
JSONEOF
)"
  req jwt PUT "/api/library/contexts/$(path_id contextId)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq287 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_delete_api_library_contexts_contextId() {
  local label="DELETE /api/library/contexts/:contextId — 摘要：Delete context 说明：Delete a context space by ID"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/library/contexts/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq288 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_analysis() {
  local label="GET /api/library/contexts/:contextId/_analysis — 摘要：Get latest context analysis result 完整路径：GET /api/library/"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/_analysis" "" ""
  expect_read_ok "$label" 200
}

# seq289 asdm-admin-services-core (端口 8880)/Library | auth=jwt（配对清理: POST /api/library/contexts/:contextId/webhook）
context_post_api_library_contexts_contextId_analyze() {
  local label="POST /api/library/contexts/:contextId/_analyze — 摘要：Manually trigger context analysis (for retry) 完整路径：POST /"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/library/contexts/$(path_id contextId)/_analyze" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/library/contexts/:contextId/webhook
  req jwt DELETE "/api/library/contexts/${rid}/webhook" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/library/contexts/${rid}/webhook" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq290 asdm-admin-services-core (端口 8880)/Library | auth=jwt（配对清理: POST /api/library/contexts/:contextId/webhook）
context_post_api_library_contexts_contextId_activate() {
  local label="POST /api/library/contexts/:contextId/activate — 摘要：Activate context 说明：Restore a soft-deleted context space"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/library/contexts/$(path_id contextId)/activate" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/library/contexts/:contextId/webhook
  req jwt DELETE "/api/library/contexts/${rid}/webhook" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/library/contexts/${rid}/webhook" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq291 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_artifact_download() {
  local label="GET /api/library/contexts/:contextId/artifact-download — 摘要：Download context items artifacts as zip 说明：将上下文空间下各子项产物打包"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/artifact-download" "" "excludeGraph=false"
  expect_read_ok "$label" 200
}

# seq292 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_post_api_library_contexts_contextId_artifacts_upload() {
  log_skip "POST /api/library/contexts/:contextId/artifacts/upload — 需要 multipart 文件上传，无法幂等自动执行（摘要：Upload context artifacts as zip 说明：接收 ZIP（内部结构 {itemName}）"
}

# seq293 asdm-admin-services-core (端口 8880)/Library | auth=jwt（配对清理: POST /api/library/contexts/:contextId/context-items/:itemId）
context_post_api_library_contexts_contextId_context_items() {
  local label="POST /api/library/contexts/:contextId/context-items — 摘要：Create context item 说明：在上下文空间中新增条目（codebase/document/file"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "type": "codebase",
 "promoteFilePath": "/tmp/example",
 "toolsetBindings": [
  {
   "toolsetId": "string",
   "toolsetCommand": "string"
  }
 ],
 "updateToolsetId": "string",
 "updateToolsetCommand": "2026-01-01",
 "projectRepositoryId": 1,
 "branch": "string",
 "connectionUri": "string",
 "syncStatus": "string",
 "buildMode": "string"
}
JSONEOF
)"
  req jwt POST "/api/library/contexts/$(path_id contextId)/context-items" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/library/contexts/:contextId/context-items/:itemId
  req jwt DELETE "/api/library/contexts/${rid}/context-items/$(path_id itemId)" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/library/contexts/${rid}/context-items/$(path_id itemId)" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq294 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_context_items() {
  local label="GET /api/library/contexts/:contextId/context-items — 摘要：Get context items by context ID 说明：Returns a list of cont"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/context-items" "" ""
  expect_read_ok "$label" 200
}

# seq295 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_context_items_contextItemId() {
  local label="GET /api/library/contexts/:contextId/context-items/:contextItemId/ddl — 摘要：Get database DDL for context item 说明：获取已保存的数据库表结构 DDL"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/context-items/$(path_id contextItemId)/ddl" "" ""
  expect_read_ok "$label" 200
}

# seq296 asdm-admin-services-core (端口 8880)/Library | auth=jwt（配对清理: POST /api/library/contexts/:contextId/context-items/:itemId/file-uploads/:uploadId）
context_post_api_library_contexts_contextId_context_items_contextItemI() {
  local label="POST /api/library/contexts/:contextId/context-items/:contextItemId/fetch-ddl — 摘要：Fetch and save database DDL 说明：从数据库连接获取表结构 DDL 并保存"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/library/contexts/$(path_id contextId)/context-items/$(path_id contextItemId)/fetch-ddl" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/library/contexts/:contextId/context-items/:itemId/file-uploads/:uploadId
  req jwt DELETE "/api/library/contexts/${rid}/context-items/$(path_id itemId)/file-uploads/$(path_id uploadId)" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/library/contexts/${rid}/context-items/$(path_id itemId)/file-uploads/$(path_id uploadId)" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq297 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_delete_api_library_contexts_contextId_context_items_itemId() {
  local label="DELETE /api/library/contexts/:contextId/context-items/:itemId — 摘要：Delete context item 说明：删除上下文空间中的项目"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/library/contexts/${DUMMY_ID}/context-items/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq298 asdm-admin-services-core (端口 8880)/Library | auth=jwt（无配对删除接口，失败请人工核查数据残留）
context_put_api_library_contexts_contextId_context_items_itemId() {
  local label="PUT /api/library/contexts/:contextId/context-items/:itemId — 摘要：Update context item 说明：更新上下文空间中的项目"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "type": "codebase",
 "promoteFilePath": "/tmp/example",
 "toolsetBindings": [
  {
   "toolsetId": "string",
   "toolsetCommand": "string"
  }
 ],
 "updateToolsetId": "string",
 "updateToolsetCommand": "2026-01-01",
 "projectRepositoryId": 1,
 "branch": "string",
 "connectionUri": "string",
 "buildMode": "string"
}
JSONEOF
)"
  req jwt PUT "/api/library/contexts/$(path_id contextId)/context-items/$(path_id itemId)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq299 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_post_api_library_contexts_contextId_context_items_itemId_file() {
  log_skip "POST /api/library/contexts/:contextId/context-items/:itemId/file — 需要 multipart 文件上传，无法幂等自动执行（摘要：Upload file for file-type or graph-type context item 说明：为）"
}

# seq300 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_context_items_itemId_file_u() {
  local label="GET /api/library/contexts/:contextId/context-items/:itemId/file-uploads — 摘要：List file uploads for file-type context item 说明：返回 type=f"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/context-items/$(path_id itemId)/file-uploads" "" ""
  expect_read_ok "$label" 200
}

# seq301 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_delete_api_library_contexts_contextId_context_items_itemId_fil() {
  local label="DELETE /api/library/contexts/:contextId/context-items/:itemId/file-uploads/:uploadId — 摘要：Delete a specific file upload for file-type context item"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/library/contexts/${DUMMY_ID}/context-items/${DUMMY_ID}/file-uploads/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq302 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_context_items_itemId_file_u_2() {
  local label="GET /api/library/contexts/:contextId/context-items/:itemId/file-uploads/:uploadId/entries — 摘要：List file upload entries for a specific upload 说明：返回某次上传（"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/context-items/$(path_id itemId)/file-uploads/$(path_id uploadId)/entries" "" ""
  expect_read_ok "$label" 200
}

# seq303 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_context_items_itemId_file_u_3() {
  local label="GET /api/library/contexts/:contextId/context-items/:itemId/file-uploads/:uploadId/preview — 摘要：Preview uploaded file content 说明：Returns UTF-8 text previ"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/context-items/$(path_id itemId)/file-uploads/$(path_id uploadId)/preview" "" ""
  expect_read_ok "$label" 200
}

# seq304 asdm-admin-services-core (端口 8880)/Library | auth=jwt（配对清理: POST /api/library/contexts/:contextId/context-items/:itemId/file-uploads/:uploadId）
context_post_api_library_contexts_contextId_context_items_itemId_graph() {
  local label="POST /api/library/contexts/:contextId/context-items/:itemId/graph-build — 摘要：Manually trigger graph build pipeline for a graph item 完整"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/library/contexts/$(path_id contextId)/context-items/$(path_id itemId)/graph-build" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/library/contexts/:contextId/context-items/:itemId/file-uploads/:uploadId
  req jwt DELETE "/api/library/contexts/${rid}/context-items/$(path_id itemId)/file-uploads/$(path_id uploadId)" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/library/contexts/${rid}/context-items/$(path_id itemId)/file-uploads/$(path_id uploadId)" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq305 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_context_items_itemId_graph_() {
  local label="GET /api/library/contexts/:contextId/context-items/:itemId/graph-build/latest — 摘要：Get latest graph build status for a graph item 完整路径：GET /"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/context-items/$(path_id itemId)/graph-build/latest" "" ""
  expect_read_ok "$label" 200
}

# seq306 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_context_results() {
  local label="GET /api/library/contexts/:contextId/context-results — 摘要：Get context results by context ID 说明：Returns a list of co"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/context-results" "" ""
  expect_read_ok "$label" 200
}

# seq307 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_context_results_file_fileNa() {
  local label="GET /api/library/contexts/:contextId/context-results/file/:fileName — 摘要：Get context results by context ID and file name 说明：Return"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/context-results/file/$(path_id fileName)" "" ""
  expect_read_ok "$label" 200
}

# seq308 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_copy_markdown() {
  local label="GET /api/library/contexts/:contextId/copy-markdown — 摘要：Get combined markdown content for a context 说明：Returns th"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/copy-markdown" "" ""
  expect_read_ok "$label" 200
}

# seq309 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_copy_url() {
  local label="GET /api/library/contexts/:contextId/copy-url — 摘要：Get shareable URL for a context 说明：Returns a shareable UR"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/copy-url" "" ""
  expect_read_ok "$label" 200
}

# seq310 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_ddl() {
  local label="GET /api/library/contexts/:contextId/ddl — 摘要：Get all database DDL for context 说明：获取上下文下所有数据库的表结构 DDL"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/ddl" "" ""
  expect_read_ok "$label" 200
}

# seq311 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_git_clones() {
  local label="GET /api/library/contexts/:contextId/git-clones — 摘要：Resolve authenticated Git clone URLs for knowledge-space"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/git-clones" "" ""
  expect_read_ok "$label" 200
}

# seq312 asdm-admin-services-core (端口 8880)/Library | auth=internal（无配对删除接口，失败请人工核查数据残留）
context_post_api_library_contexts_contextId_items_contextItemId_import() {
  local label="POST /api/library/contexts/:contextId/items/:contextItemId/import-artifact — 摘要：Import AgentOrbit artifact into a context item 说明：Receive"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req internal POST "/api/library/contexts/$(path_id contextId)/items/$(path_id contextItemId)/import-artifact" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq313 asdm-admin-services-core (端口 8880)/Library | auth=internal
context_post_api_library_contexts_contextId_items_contextItemId_import_2() {
  log_skip "POST /api/library/contexts/:contextId/items/:contextItemId/import-artifact — 需要 multipart 文件上传，无法幂等自动执行（摘要：Import AgentOrbit artifact into a context item (multipart）"
}

# seq314 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_resources_manifest() {
  local label="GET /api/library/contexts/:contextId/resources-manifest — 摘要：Get context resources manifest 说明：Returns toolsets associ"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/resources-manifest" "" ""
  expect_read_ok "$label" 200
}

# seq315 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_sync_history() {
  local label="GET /api/library/contexts/:contextId/sync-history — 摘要：Get sync history by context ID (paginated) 说明：Returns a p"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/sync-history" "" "page=1&size=20"
  expect_read_ok "$label" 200
}

# seq316 asdm-admin-services-core (端口 8880)/Library | auth=jwt（配对清理: POST /api/library/contexts/:contextId/webhook）
context_post_api_library_contexts_contextId_versions() {
  local label="POST /api/library/contexts/:contextId/versions — 摘要：Create a new context version 说明：基于指定 Active 知识空间创建新版本（新空间"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/library/contexts/$(path_id contextId)/versions" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/library/contexts/:contextId/webhook
  req jwt DELETE "/api/library/contexts/${rid}/webhook" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/library/contexts/${rid}/webhook" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq317 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_contextId_versions() {
  local label="GET /api/library/contexts/:contextId/versions — 摘要：List context versions 说明：返回指定知识空间所属版本族的版本列表（倒序，最新在上；分页，默认"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id contextId)/versions" "" "page=1&size=10"
  expect_read_ok "$label" 200
}

# seq318 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_id() {
  local label="GET /api/library/contexts/:id — 摘要：Get context by ID 说明：Returns a single library context by"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq319 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_guid_guid() {
  local label="GET /api/library/contexts/guid/:guid — 摘要：Get context by GUID 说明：Returns a single library context b"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/guid/$(path_id guid)" "" ""
  expect_read_ok "$label" 200
}

# seq320 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_contexts_status_status() {
  local label="GET /api/library/contexts/status/:status — 摘要：Get contexts by status 说明：Returns a list of library conte"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/contexts/status/$(path_id status)" "" ""
  expect_read_ok "$label" 200
}

# seq321 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_projects_projectId_accessible_contexts() {
  local label="GET /api/library/projects/:projectId/accessible-contexts — 摘要：List accessible contexts (own + shared) for a project 说明："
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/projects/$(path_id projectId)/accessible-contexts" "" ""
  expect_read_ok "$label" 200
}

# seq322 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_sync_history() {
  local label="GET /api/library/sync-history — 摘要：Get all sync history records 说明：Returns a list of all syn"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/sync-history" "" ""
  expect_read_ok "$label" 200
}

# seq323 asdm-admin-services-core (端口 8880)/Library | auth=jwt（配对清理: POST /api/library/context-results/:id）
context_post_api_library_sync_history() {
  local label="POST /api/library/sync-history — 摘要：Create a sync history record 说明：Creates a new sync histor"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "id": "string",
  "guid": "string",
  "contextId": "string",
  "contextItemId": "string",
  "repoName": "example",
  "repoUrl": "https://example.com",
  "branch": "string",
  "triggeredAt": "string",
  "triggeredBy": "string",
  "runId": 1,
  "serverId": 1,
  "workflowUrl": "https://example.com",
  "workflowStatus": "string",
  "workflowConclusion": "string",
  "status": "string",
  "triggerSource": "string",
  "commitShaBefore": "string",
  "commitShaAfter": "string",
  "versionAfter": "1.0.0",
  "errorMessage": "example text",
  "completedAt": "string",
  "duration": 1
}
JSONEOF
)"
  req jwt POST "/api/library/sync-history" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/library/context-results/:id
  req jwt DELETE "/api/library/context-results/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/library/context-results/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq324 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_sync_history_id() {
  local label="GET /api/library/sync-history/:id — 摘要：Get sync history by ID 说明：Returns a single sync history r"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/sync-history/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq325 asdm-admin-services-core (端口 8880)/Library | auth=jwt（无配对删除接口，失败请人工核查数据残留）
context_put_api_library_sync_history_id() {
  local label="PUT /api/library/sync-history/:id — 摘要：Update a sync history record 说明：Updates an existing sync"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "id": "string",
  "guid": "string",
  "contextId": "string",
  "contextItemId": "string",
  "repoName": "example",
  "repoUrl": "https://example.com",
  "branch": "string",
  "triggeredAt": "string",
  "triggeredBy": "string",
  "runId": 1,
  "serverId": 1,
  "workflowUrl": "https://example.com",
  "workflowStatus": "string",
  "workflowConclusion": "string",
  "status": "string",
  "triggerSource": "string",
  "commitShaBefore": "string",
  "commitShaAfter": "string",
  "versionAfter": "1.0.0",
  "errorMessage": "example text",
  "completedAt": "string",
  "duration": 1
}
JSONEOF
)"
  req jwt PUT "/api/library/sync-history/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq326 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_sync_history_syncHistoryId_context_results() {
  local label="GET /api/library/sync-history/:syncHistoryId/context-results — 摘要：Get context results by sync history ID 说明：Returns a list"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/sync-history/$(path_id syncHistoryId)/context-results" "" ""
  expect_read_ok "$label" 200
}

# seq327 asdm-admin-services-core (端口 8880)/Library | auth=jwt（无配对删除接口，失败请人工核查数据残留）
context_post_api_library_sync_history_context_results_batch() {
  local label="POST /api/library/sync-history/context-results/batch — 摘要：Batch get context results by sync history IDs 说明：Returns"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/library/sync-history/context-results/batch" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq328 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_sync_history_status_status() {
  local label="GET /api/library/sync-history/status/:status — 摘要：Get sync history by status 说明：Returns a list of sync hist"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/sync-history/status/$(path_id status)" "" ""
  expect_read_ok "$label" 200
}

# seq329 asdm-admin-services-core (端口 8880)/Library | auth=jwt（配对清理: POST /api/library/context-results/:id）
context_post_api_library_test_database_connection() {
  local label="POST /api/library/test-database-connection — 摘要：Test database connection 说明：测试给定的 JDBC 连接 URI 是否可连接"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "connectionUri": "string"
}
JSONEOF
)"
  req jwt POST "/api/library/test-database-connection" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/library/context-results/:id
  req jwt DELETE "/api/library/context-results/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/library/context-results/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq330 asdm-admin-services-core (端口 8880)/Library | auth=jwt
context_get_api_library_workspaces_workspaceId_latest_context_result() {
  local label="GET /api/library/workspaces/:workspaceId/latest-context-result — 摘要：Get latest context results by workspace ID 说明：按 workspace"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/library/workspaces/$(path_id workspaceId)/latest-context-result" "" ""
  expect_read_ok "$label" 200
}

# seq331 asdm-admin-services-core (端口 8880)/Library Detail | auth=public
context_get_api_v1_library_mcp_registryId_commands() {
  local label="GET /api/v1/library/mcp/:registryId/commands — 摘要：Get MCP commands by registryId 说明：Returns the mcpServers"
  need_auth public "$label" || return 0
  req public GET "/api/v1/library/mcp/$(path_id registryId)/commands" "" ""
  expect_read_ok "$label" 200
}

# seq332 asdm-admin-services-core (端口 8880)/Library Detail | auth=public
context_get_api_v1_library_mcp_aggregate() {
  local label="GET /api/v1/library/mcp/aggregate — 摘要：Get aggregated MCP mcpServers 说明：Aggregates MCPs into one"
  need_auth public "$label" || return 0
  req public GET "/api/v1/library/mcp/aggregate" "" ""
  expect_read_ok "$label" 200
}

# seq333 asdm-admin-services-core (端口 8880)/Library Detail | auth=jwt
context_get_api_v1_library_mcps_guid_detail() {
  local label="GET /api/v1/library/mcps/:guid/detail — 摘要：Get MCP detail 说明：Returns complete detail information for"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/library/mcps/$(path_id guid)/detail" "" ""
  expect_read_ok "$label" 200
}

# seq334 asdm-admin-services-core (端口 8880)/Library Detail | auth=jwt
context_get_api_v1_library_skills_guid_detail() {
  local label="GET /api/v1/library/skills/:guid/detail — 摘要：Get Skill detail 说明：Returns complete detail information f"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/library/skills/$(path_id guid)/detail" "" ""
  expect_read_ok "$label" 200
}

# seq335 asdm-admin-services-core (端口 8880)/Library Detail | auth=jwt
context_get_api_v1_library_specs_guid_detail() {
  local label="GET /api/v1/library/specs/:guid/detail — 摘要：Get Spec detail 说明：Returns complete detail information fo"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/library/specs/$(path_id guid)/detail" "" ""
  expect_read_ok "$label" 200
}

# seq336 asdm-admin-services-core (端口 8880)/Library Detail | auth=jwt
context_get_api_v1_library_toolsets_guid_detail() {
  local label="GET /api/v1/library/toolsets/:guid/detail — 摘要：Get Toolset detail 说明：Returns complete detail information"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/library/toolsets/$(path_id guid)/detail" "" ""
  expect_read_ok "$label" 200
}

# seq337 asdm-admin-services-core (端口 8880)/Public Asset Versions | auth=jwt
context_get_ai_mcps_versions() {
  local label="GET /_ai/mcps/versions — 摘要：List versions of an mcp 说明：MCP resources do not expose a"
  need_auth jwt "$label" || return 0
  req jwt GET "/_ai/mcps/versions" "" "registryId=string"
  expect_read_ok "$label" 200
}

# seq338 asdm-admin-services-core (端口 8880)/Public Asset Versions | auth=public
context_get_ai_skills_versions() {
  local label="GET /_ai/skills/versions — 摘要：List Active versions of a skill 说明：Returns Active version"
  need_auth public "$label" || return 0
  req public GET "/_ai/skills/versions" "" "registryId=string"
  expect_read_ok "$label" 200
}

# seq339 asdm-admin-services-core (端口 8880)/Public Asset Versions | auth=public
context_get_ai_specs_versions() {
  local label="GET /_ai/specs/versions — 摘要：List Active versions of a spec 说明：Returns Active version"
  need_auth public "$label" || return 0
  req public GET "/_ai/specs/versions" "" "registryId=string"
  expect_read_ok "$label" 200
}

# seq340 asdm-admin-services-core (端口 8880)/Public Asset Versions | auth=public
context_get_ai_toolsets_versions() {
  local label="GET /_ai/toolsets/versions — 摘要：List Active versions of a toolset 说明：Returns Active versi"
  need_auth public "$label" || return 0
  req public GET "/_ai/toolsets/versions" "" "registryId=string"
  expect_read_ok "$label" 200
}

# seq341 asdm-admin-services-core (端口 8880)/Public Context Result | auth=jwt
context_get_ai_context_result_token() {
  local label="GET /_ai/context-result/:token — 摘要：Get UTF-8 text for a shared context result file 说明：Return"
  need_auth jwt "$label" || return 0
  req jwt GET "/_ai/context-result/$(path_id token)" "" ""
  expect_read_ok "$label" 200
}

# seq342 asdm-admin-services-core (端口 8880)/Public Contexts | auth=jwt
context_get_ai_context_guid() {
  local label="GET /_ai/context/:guid — 摘要：Get context markdown content by GUID 说明：Returns the combi"
  need_auth jwt "$label" || return 0
  req jwt GET "/_ai/context/$(path_id guid)" "" ""
  expect_read_ok "$label" 200
}

# seq343 asdm-admin-services-core (端口 8880)/Public Contexts | auth=jwt（无配对删除接口，失败请人工核查数据残留）
context_post_ai_context_id_publish() {
  local label="POST /_ai/context/:id/publish — 摘要：Publish context 说明：Publish a context asset. Requires CONT"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/_ai/context/$(path_id id)/publish" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq344 asdm-admin-services-core (端口 8880)/Public Contexts | auth=jwt
context_get_ai_context_registry() {
  local label="GET /_ai/context/registry — 摘要：Get contexts-registry content 说明：Returns contexts filtere"
  need_auth jwt "$label" || return 0
  req jwt GET "/_ai/context/registry" "" ""
  expect_read_ok "$label" 200
}

# seq345 asdm-admin-services-core (端口 8880)/Public MCPs | auth=jwt（无配对删除接口，失败请人工核查数据残留）
context_post_ai_mcps_id_publish() {
  local label="POST /_ai/mcps/:id/publish — 摘要：Publish MCP 说明：Publish an MCP asset. Requires CONTRIB lev"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/_ai/mcps/$(path_id id)/publish" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq346 asdm-admin-services-core (端口 8880)/Public MCPs | auth=public
context_get_ai_mcps_registry() {
  local label="GET /_ai/mcps/registry — 摘要：Get mcps-registry.json content (async) 说明：Returns the mcp"
  need_auth public "$label" || return 0
  req public GET "/_ai/mcps/registry" "" ""
  expect_read_ok "$label" 200
}

# seq347 asdm-admin-services-core (端口 8880)/Public MCPs | auth=public
context_get_ai_mcps_registry_typed() {
  local label="GET /_ai/mcps/registry/typed — 摘要：Get mcps-registry.json content as typed object (async) 说明"
  need_auth public "$label" || return 0
  req public GET "/_ai/mcps/registry/typed" "" ""
  expect_read_ok "$label" 200
}

# seq348 asdm-admin-services-core (端口 8880)/Public Skills | auth=public（无配对删除接口，失败请人工核查数据残留）
context_post_ai_skills_id_publish() {
  local label="POST /_ai/skills/:id/publish — 摘要：Publish skill 说明：Publish a skill asset. Requires CONTRIB"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  req public POST "/_ai/skills/$(path_id id)/publish" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq349 asdm-admin-services-core (端口 8880)/Public Skills | auth=public
context_get_ai_skills_download() {
  local label="GET /_ai/skills/download — 摘要：Download skill zip by registryId 说明：Returns the zip file"
  need_auth public "$label" || return 0
  req public GET "/_ai/skills/download" "" "registryId=string&mode=local"
  expect_read_ok "$label" 200
}

# seq350 asdm-admin-services-core (端口 8880)/Public Skills | auth=public
context_get_ai_skills_registry() {
  local label="GET /_ai/skills/registry — 摘要：Get skills-registry.json content with user permission 说明："
  need_auth public "$label" || return 0
  req public GET "/_ai/skills/registry" "" ""
  expect_read_ok "$label" 200
}

# seq351 asdm-admin-services-core (端口 8880)/Public Skills | auth=public
context_get_ai_skills_registry_typed() {
  local label="GET /_ai/skills/registry/typed — 摘要：Get skills-registry.json content as typed object (async)"
  need_auth public "$label" || return 0
  req public GET "/_ai/skills/registry/typed" "" ""
  expect_read_ok "$label" 200
}

# seq352 asdm-admin-services-core (端口 8880)/Public Specs | auth=public（无配对删除接口，失败请人工核查数据残留）
context_post_ai_specs_id_publish() {
  local label="POST /_ai/specs/:id/publish — 摘要：Publish spec 说明：Publish a spec asset. Requires CONTRIB le"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  req public POST "/_ai/specs/$(path_id id)/publish" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq353 asdm-admin-services-core (端口 8880)/Public Specs | auth=public
context_get_ai_specs_download() {
  local label="GET /_ai/specs/download — 摘要：Download spec zip by registryId 说明：Returns the zip file c"
  need_auth public "$label" || return 0
  req public GET "/_ai/specs/download" "" "registryId=string&mode=local"
  expect_read_ok "$label" 200
}

# seq354 asdm-admin-services-core (端口 8880)/Public Specs | auth=public
context_get_ai_specs_registry() {
  local label="GET /_ai/specs/registry — 摘要：Get specs-registry.json content (async) 说明：Returns the sp"
  need_auth public "$label" || return 0
  req public GET "/_ai/specs/registry" "" ""
  expect_read_ok "$label" 200
}

# seq355 asdm-admin-services-core (端口 8880)/Public Specs | auth=public
context_get_ai_specs_registry_typed() {
  local label="GET /_ai/specs/registry/typed — 摘要：Get specs-registry.json content as typed object (async) 说"
  need_auth public "$label" || return 0
  req public GET "/_ai/specs/registry/typed" "" ""
  expect_read_ok "$label" 200
}

# seq356 asdm-admin-services-core (端口 8880)/Public Toolsets | auth=public（无配对删除接口，失败请人工核查数据残留）
context_post_ai_toolsets_id_publish() {
  local label="POST /_ai/toolsets/:id/publish — 摘要：Publish toolset 说明：Publish a toolset asset. Requires CONT"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  req public POST "/_ai/toolsets/$(path_id id)/publish" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq357 asdm-admin-services-core (端口 8880)/Public Toolsets | auth=public
context_get_ai_toolsets_download() {
  local label="GET /_ai/toolsets/download — 摘要：Download toolset zip by registryId 说明：Returns the zip fil"
  need_auth public "$label" || return 0
  req public GET "/_ai/toolsets/download" "" "registryId=string&mode=local"
  expect_read_ok "$label" 200
}

# seq358 asdm-admin-services-core (端口 8880)/Public Toolsets | auth=public
context_get_ai_toolsets_registry() {
  local label="GET /_ai/toolsets/registry — 摘要：Get toolsets-registry.json content (async) 说明：Returns the"
  need_auth public "$label" || return 0
  req public GET "/_ai/toolsets/registry" "" ""
  expect_read_ok "$label" 200
}

# seq359 asdm-admin-services-core (端口 8880)/Public Toolsets | auth=public
context_get_ai_toolsets_registry_typed() {
  local label="GET /_ai/toolsets/registry/typed — 摘要：Get toolsets-registry.json content as typed object (async"
  need_auth public "$label" || return 0
  req public GET "/_ai/toolsets/registry/typed" "" ""
  expect_read_ok "$label" 200
}

# ===== 入口 =====
main() {
  set +e   # 单用例失败不中断
  echo ""
  echo "========== 上下文库域 (95 apis) =========="
  login_if_needed || true
  context_post_api_admin_library_context_analysis_trigger_contextId || true
  context_get_api_library_contexts_contextId_webhook || true
  context_put_api_library_contexts_contextId_webhook || true
  context_delete_api_library_contexts_contextId_webhook || true
  context_get_api_library_context_items_contextItemId_context_results || true
  context_get_api_library_context_items_contextItemId_sync_history || true
  context_get_api_library_context_items_id || true
  context_get_api_library_context_items_guid_guid || true
  context_get_api_library_context_items_sync_status_syncStatus || true
  context_get_api_library_context_results || true
  context_post_api_library_context_results || true
  context_get_api_library_context_results_id || true
  context_put_api_library_context_results_id || true
  context_delete_api_library_context_results_id || true
  context_get_api_library_context_results_id_download || true
  context_get_api_library_context_results_id_entries || true
  context_get_api_library_context_results_id_preview || true
  context_get_api_library_context_results_id_share_file_url || true
  context_get_api_library_context_results_guid_guid || true
  context_post_api_library_contexts || true
  context_get_api_library_contexts || true
  context_put_api_library_contexts_contextId || true
  context_delete_api_library_contexts_contextId || true
  context_get_api_library_contexts_contextId_analysis || true
  context_post_api_library_contexts_contextId_analyze || true
  context_post_api_library_contexts_contextId_activate || true
  context_get_api_library_contexts_contextId_artifact_download || true
  context_post_api_library_contexts_contextId_artifacts_upload || true
  context_post_api_library_contexts_contextId_context_items || true
  context_get_api_library_contexts_contextId_context_items || true
  context_get_api_library_contexts_contextId_context_items_contextItemId || true
  context_post_api_library_contexts_contextId_context_items_contextItemI || true
  context_delete_api_library_contexts_contextId_context_items_itemId || true
  context_put_api_library_contexts_contextId_context_items_itemId || true
  context_post_api_library_contexts_contextId_context_items_itemId_file || true
  context_get_api_library_contexts_contextId_context_items_itemId_file_u || true
  context_delete_api_library_contexts_contextId_context_items_itemId_fil || true
  context_get_api_library_contexts_contextId_context_items_itemId_file_u_2 || true
  context_get_api_library_contexts_contextId_context_items_itemId_file_u_3 || true
  context_post_api_library_contexts_contextId_context_items_itemId_graph || true
  context_get_api_library_contexts_contextId_context_items_itemId_graph_ || true
  context_get_api_library_contexts_contextId_context_results || true
  context_get_api_library_contexts_contextId_context_results_file_fileNa || true
  context_get_api_library_contexts_contextId_copy_markdown || true
  context_get_api_library_contexts_contextId_copy_url || true
  context_get_api_library_contexts_contextId_ddl || true
  context_get_api_library_contexts_contextId_git_clones || true
  context_post_api_library_contexts_contextId_items_contextItemId_import || true
  context_post_api_library_contexts_contextId_items_contextItemId_import_2 || true
  context_get_api_library_contexts_contextId_resources_manifest || true
  context_get_api_library_contexts_contextId_sync_history || true
  context_post_api_library_contexts_contextId_versions || true
  context_get_api_library_contexts_contextId_versions || true
  context_get_api_library_contexts_id || true
  context_get_api_library_contexts_guid_guid || true
  context_get_api_library_contexts_status_status || true
  context_get_api_library_projects_projectId_accessible_contexts || true
  context_get_api_library_sync_history || true
  context_post_api_library_sync_history || true
  context_get_api_library_sync_history_id || true
  context_put_api_library_sync_history_id || true
  context_get_api_library_sync_history_syncHistoryId_context_results || true
  context_post_api_library_sync_history_context_results_batch || true
  context_get_api_library_sync_history_status_status || true
  context_post_api_library_test_database_connection || true
  context_get_api_library_workspaces_workspaceId_latest_context_result || true
  context_get_api_v1_library_mcp_registryId_commands || true
  context_get_api_v1_library_mcp_aggregate || true
  context_get_api_v1_library_mcps_guid_detail || true
  context_get_api_v1_library_skills_guid_detail || true
  context_get_api_v1_library_specs_guid_detail || true
  context_get_api_v1_library_toolsets_guid_detail || true
  context_get_ai_mcps_versions || true
  context_get_ai_skills_versions || true
  context_get_ai_specs_versions || true
  context_get_ai_toolsets_versions || true
  context_get_ai_context_result_token || true
  context_get_ai_context_guid || true
  context_post_ai_context_id_publish || true
  context_get_ai_context_registry || true
  context_post_ai_mcps_id_publish || true
  context_get_ai_mcps_registry || true
  context_get_ai_mcps_registry_typed || true
  context_post_ai_skills_id_publish || true
  context_get_ai_skills_download || true
  context_get_ai_skills_registry || true
  context_get_ai_skills_registry_typed || true
  context_post_ai_specs_id_publish || true
  context_get_ai_specs_download || true
  context_get_ai_specs_registry || true
  context_get_ai_specs_registry_typed || true
  context_post_ai_toolsets_id_publish || true
  context_get_ai_toolsets_download || true
  context_get_ai_toolsets_registry || true
  context_get_ai_toolsets_registry_typed || true
  finish
}
main "$@"
