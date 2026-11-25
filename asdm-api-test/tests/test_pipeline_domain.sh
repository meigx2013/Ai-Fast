#!/usr/bin/env bash
# ============================================================================
# 流水线域 — 幂等自动化测试（由 gen/generate.js 从 api.json 生成，勿手工修改）
# 重新生成: node gen/generate.js
# 覆盖服务: core
# 接口总数: 22（读 16 直测 / 写 4 受控[含配对清理 0] / 永久跳过 2）
# 环境变量: ASDM_BASE_URL / ASDM_LOGIN_EMAIL / ASDM_LOGIN_PASSWORD / ASDM_TOKEN /
#           ASDM_PAT / ASDM_INTERNAL_TOKEN / ASDM_OPEN_ACCESS_TOKEN / ASDM_CITIC_SECRET /
#           ASDM_ALLOW_WRITES=1（执行写操作）/ ASDM_TEST_<参数名>（路径参数覆盖）
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ===== 被测接口用例 =====
# seq360 asdm-admin-services-core (端口 8880)/Artifact Mapping | auth=public
pipeline_get_api_skills_mapping() {
  local label="GET /api/skills/mapping — 摘要：查询 Skill fileId 说明：CLI 根据 registryId 获取对应 fileId"
  need_auth public "$label" || return 0
  req public GET "/api/skills/mapping" "" "registryId=string"
  expect_read_ok "$label" 200
}

# seq361 asdm-admin-services-core (端口 8880)/Artifact Mapping | auth=public
pipeline_get_api_specs_mapping() {
  local label="GET /api/specs/mapping — 摘要：查询 Spec fileId 说明：CLI 根据 registryId + mode 获取对应 fileId。mo"
  need_auth public "$label" || return 0
  req public GET "/api/specs/mapping" "" "registryId=string&mode=local"
  expect_read_ok "$label" 200
}

# seq362 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_get_api_pipeline_artifacts_artifactId_files_fileName() {
  local label="GET /api/pipeline/artifacts/:artifactId/files/:fileName — 摘要：Download artifact and extract a specific file by artifact"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline/artifacts/$(path_id artifactId)/files/$(path_id fileName)" "" ""
  expect_read_ok "$label" 200
}

# seq363 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_delete_api_pipeline_cache() {
  log_skip "DELETE /api/pipeline/cache — 永久跳过：静态路径整体删除，无法限定删除范围"
}

# seq364 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_get_api_pipeline_context_sync_histories_historyId_artifacts_a() {
  local label="GET /api/pipeline/context-sync-histories/:historyId/artifacts/:artifactName/all-markdown — 摘要：Extract all markdown files from artifact by context sync"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline/context-sync-histories/$(path_id historyId)/artifacts/$(path_id artifactName)/all-markdown" "" ""
  expect_read_ok "$label" 200
}

# seq365 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_get_api_pipeline_context_sync_histories_historyId_workflow_ru() {
  local label="GET /api/pipeline/context-sync-histories/:historyId/workflow-run-status — 摘要：Get workflow run status by context sync history ID 说明：Res"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline/context-sync-histories/$(path_id historyId)/workflow-run-status" "" ""
  expect_read_ok "$label" 200
}

# seq366 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt（无配对删除接口，失败请人工核查数据残留）
pipeline_post_api_pipeline_contexts_sync() {
  local label="POST /api/pipeline/contexts/sync — 摘要：Trigger ASDM Context Space Sync workflow 说明：Triggers the"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "repoUrl": "https://example.com",
  "branch": "string",
  "serverId": 1,
  "collectionId": 1,
  "projectId": "string",
  "pipelineType": "string",
  "contextItemId": 1,
  "contextId": 1,
  "toolsetId": "string",
  "toolsetCommand": "string",
  "toolsetBindings": [
    {
      "toolsetId": "string",
      "toolsetCommand": "string"
    }
  ],
  "gitCloneToken": "string",
  "sourceUrl": "https://example.com"
}
JSONEOF
)"
  req jwt POST "/api/pipeline/contexts/sync" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq367 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_get_api_pipeline_promote_files() {
  local label="GET /api/pipeline/promote-files — 摘要：List promote files 说明：Lists available promote files in co"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline/promote-files" "" "serverId=1&pipelineType=string"
  expect_read_ok "$label" 200
}

# seq368 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_get_api_pipeline_sync_tasks() {
  local label="GET /api/pipeline/sync-tasks — 摘要：List context sync tasks 说明：Returns paginated list of cont"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline/sync-tasks" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq369 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_get_api_pipeline_sync_tasks_id() {
  local label="GET /api/pipeline/sync-tasks/:id — 摘要：Get sync task by ID 说明：Returns details of a specific sync"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline/sync-tasks/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq370 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt（无配对删除接口，失败请人工核查数据残留）
pipeline_post_api_pipeline_sync_tasks_id_retry() {
  local label="POST /api/pipeline/sync-tasks/:id/retry — 摘要：Retry a failed sync task 说明：Retriggers the pipeline for a"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/pipeline/sync-tasks/$(path_id id)/retry" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq371 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_get_api_pipeline_workflow_runs_runId() {
  local label="GET /api/pipeline/workflow-runs/:runId — 摘要：Get workflow run status by run ID 说明：Returns the status o"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline/workflow-runs/$(path_id runId)" "" ""
  expect_read_ok "$label" 200
}

# seq372 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_get_api_pipeline_workflow_runs_runId_artifacts() {
  local label="GET /api/pipeline/workflow-runs/:runId/artifacts — 摘要：List artifacts for a workflow run 说明：Returns all artifact"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline/workflow-runs/$(path_id runId)/artifacts" "" ""
  expect_read_ok "$label" 200
}

# seq373 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_get_api_pipeline_workflow_runs_runId_artifacts_artifactName() {
  local label="GET /api/pipeline/workflow-runs/:runId/artifacts/:artifactName — 摘要：Download artifact by name from a workflow run 说明：Download"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline/workflow-runs/$(path_id runId)/artifacts/$(path_id artifactName)" "" ""
  expect_read_ok "$label" 200
}

# seq374 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_get_api_pipeline_workflow_runs_runId_artifacts_artifactName_a() {
  local label="GET /api/pipeline/workflow-runs/:runId/artifacts/:artifactName/all-markdown — 摘要：Extract all markdown files from artifact and merge them 说"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline/workflow-runs/$(path_id runId)/artifacts/$(path_id artifactName)/all-markdown" "" ""
  expect_read_ok "$label" 200
}

# seq375 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_get_api_pipeline_workflow_runs_runId_artifacts_artifactName_f() {
  local label="GET /api/pipeline/workflow-runs/:runId/artifacts/:artifactName/files/:fileName — 摘要：Download artifact and extract a specific file by artifact"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline/workflow-runs/$(path_id runId)/artifacts/$(path_id artifactName)/files/$(path_id fileName)" "" ""
  expect_read_ok "$label" 200
}

# seq376 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt（无配对删除接口，失败请人工核查数据残留）
pipeline_patch_api_pipeline_workflow_runs_runId_rename() {
  local label="PATCH /api/pipeline/workflow-runs/:runId/rename — 摘要：Rename a workflow run 说明：Renames a GitHub Action workflow"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt PATCH "/api/pipeline/workflow-runs/$(path_id runId)/rename" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq377 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_get_api_pipeline_workspace_run_histories_historyId_artifacts_() {
  local label="GET /api/pipeline/workspace-run-histories/:historyId/artifacts/:artifactName/files/:fileName — 摘要：Extract artifact file by workspaceRunHistory ID 说明：Resolv"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline/workspace-run-histories/$(path_id historyId)/artifacts/$(path_id artifactName)/files/$(path_id fileName)" "" ""
  expect_read_ok "$label" 200
}

# seq378 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt
pipeline_get_api_pipeline_workspace_run_histories_historyId_workflow_r() {
  local label="GET /api/pipeline/workspace-run-histories/:historyId/workflow-run-status — 摘要：Get workflow run status by workspaceRunHistory ID 说明：Reso"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/pipeline/workspace-run-histories/$(path_id historyId)/workflow-run-status" "" ""
  expect_read_ok "$label" 200
}

# seq379 asdm-admin-services-core (端口 8880)/Pipeline | auth=jwt（无配对删除接口，失败请人工核查数据残留）
pipeline_post_api_pipeline_workspace_execute() {
  local label="POST /api/pipeline/workspace/execute — 摘要：Trigger ASDM Workspace Execution workflow 说明：Triggers the"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "workspaceId": "string",
  "promptText": "string",
  "toolsetId": "string",
  "commandId": "string",
  "workspaceGitUrl": "https://example.com",
  "workspaceGitBranch": "string",
  "workspaceGitBranchTarget": "string",
  "workspaceGitToken": "string",
  "gitPushBaseUrl": "https://example.com",
  "verbose": true,
  "outputFormat": "string",
  "serverId": 1,
  "projectId": "string",
  "distributeResources": true
}
JSONEOF
)"
  req jwt POST "/api/pipeline/workspace/execute" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq380 asdm-admin-services-core (端口 8880)/Toolset Upload | auth=public
pipeline_get_api_toolsets_mapping() {
  local label="GET /api/toolsets/mapping — 摘要：查询工具集 fileId 说明：CLI 根据 registryId + mode 获取对应 fileId"
  need_auth public "$label" || return 0
  req public GET "/api/toolsets/mapping" "" "registryId=string&mode=local"
  expect_read_ok "$label" 200
}

# seq381 asdm-admin-services-core (端口 8880)/Toolset Upload | auth=public
pipeline_post_api_toolsets_upload() {
  log_skip "POST /api/toolsets/upload — 需要 multipart 文件上传，无法幂等自动执行（摘要：上传工具集 ZIP 说明：双 ZIP 存储 — 原包条目化 + Stub ZIP）"
}

# ===== 入口 =====
main() {
  set +e   # 单用例失败不中断
  echo ""
  echo "========== 流水线域 (22 apis) =========="
  login_if_needed || true
  pipeline_get_api_skills_mapping || true
  pipeline_get_api_specs_mapping || true
  pipeline_get_api_pipeline_artifacts_artifactId_files_fileName || true
  pipeline_delete_api_pipeline_cache || true
  pipeline_get_api_pipeline_context_sync_histories_historyId_artifacts_a || true
  pipeline_get_api_pipeline_context_sync_histories_historyId_workflow_ru || true
  pipeline_post_api_pipeline_contexts_sync || true
  pipeline_get_api_pipeline_promote_files || true
  pipeline_get_api_pipeline_sync_tasks || true
  pipeline_get_api_pipeline_sync_tasks_id || true
  pipeline_post_api_pipeline_sync_tasks_id_retry || true
  pipeline_get_api_pipeline_workflow_runs_runId || true
  pipeline_get_api_pipeline_workflow_runs_runId_artifacts || true
  pipeline_get_api_pipeline_workflow_runs_runId_artifacts_artifactName || true
  pipeline_get_api_pipeline_workflow_runs_runId_artifacts_artifactName_a || true
  pipeline_get_api_pipeline_workflow_runs_runId_artifacts_artifactName_f || true
  pipeline_patch_api_pipeline_workflow_runs_runId_rename || true
  pipeline_get_api_pipeline_workspace_run_histories_historyId_artifacts_ || true
  pipeline_get_api_pipeline_workspace_run_histories_historyId_workflow_r || true
  pipeline_post_api_pipeline_workspace_execute || true
  pipeline_get_api_toolsets_mapping || true
  pipeline_post_api_toolsets_upload || true
  finish
}
main "$@"
