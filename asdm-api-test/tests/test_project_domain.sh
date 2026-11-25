#!/usr/bin/env bash
# ============================================================================
# 项目管理域 — 幂等自动化测试（由 gen/generate.js 从 api.json 生成，勿手工修改）
# 重新生成: node gen/generate.js
# 覆盖服务: core
# 接口总数: 36（读 19 直测 / 写 17 受控[含配对清理 4] / 永久跳过 0）
# 环境变量: ASDM_BASE_URL / ASDM_LOGIN_EMAIL / ASDM_LOGIN_PASSWORD / ASDM_TOKEN /
#           ASDM_PAT / ASDM_INTERNAL_TOKEN / ASDM_OPEN_ACCESS_TOKEN / ASDM_CITIC_SECRET /
#           ASDM_ALLOW_WRITES=1（执行写操作）/ ASDM_TEST_<参数名>（路径参数覆盖）
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ===== 被测接口用例 =====
# seq135 asdm-admin-services-core (端口 8880)/Org Landing | auth=jwt
project_get_api_project_org_landing_collectionUid() {
  local label="GET /api/project/org-landing/:collectionUid — 摘要：Get organization landing page data 说明：Aggregated data inc"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/org-landing/$(path_id collectionUid)" "" ""
  expect_read_ok "$label" 200
}

# seq136 asdm-admin-services-core (端口 8880)/Org Landing | auth=jwt
project_get_api_project_org_landing_collectionUid_projects() {
  local label="GET /api/project/org-landing/:collectionUid/projects — 摘要：Get org subtree projects with pagination 说明：Paginated act"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/org-landing/$(path_id collectionUid)/projects" "" "page=0&size=12"
  expect_read_ok "$label" 200
}

# seq137 asdm-admin-services-core (端口 8880)/Project | auth=jwt（配对清理: POST /api/project/collections/:id）
project_post_api_project_collections() {
  local label="POST /api/project/collections — 摘要：Create a new project collection 说明：Create a new project c"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "description": "example text",
 "collectionUid": "string",
 "parentId": 1,
 "collectionSettings": {
  "storagePath": "/tmp/example",
  "autoBackup": true,
  "retentionDays": 1
 }
}
JSONEOF
)"
  req jwt POST "/api/project/collections" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/project/collections/:id
  req jwt DELETE "/api/project/collections/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/project/collections/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq138 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_collections() {
  local label="GET /api/project/collections — 摘要：Get all project collections 说明：Returns a list of project"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/collections" "" ""
  expect_read_ok "$label" 200
}

# seq139 asdm-admin-services-core (端口 8880)/Project | auth=jwt（无配对删除接口，失败请人工核查数据残留）
project_patch_api_project_collections_collectionUid_description() {
  local label="PATCH /api/project/collections/:collectionUid/description — 摘要：Update organization description 说明：Update the description"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "description": "example text"
}
JSONEOF
)"
  req jwt PATCH "/api/project/collections/$(path_id collectionUid)/description" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq140 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_collections_id() {
  local label="GET /api/project/collections/:id — 摘要：Get project collection by ID 说明：Returns a single project"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/collections/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq141 asdm-admin-services-core (端口 8880)/Project | auth=jwt（无配对删除接口，失败请人工核查数据残留）
project_put_api_project_collections_id() {
  local label="PUT /api/project/collections/:id — 摘要：Update a project collection 说明：Update collection name. Or"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__"
}
JSONEOF
)"
  req jwt PUT "/api/project/collections/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq142 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_delete_api_project_collections_id() {
  local label="DELETE /api/project/collections/:id — 摘要：Delete project collection 说明：Soft delete organization. Su"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/project/collections/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq143 asdm-admin-services-core (端口 8880)/Project | auth=jwt（无配对删除接口，失败请人工核查数据残留）
project_post_api_project_collections_id_activate() {
  local label="POST /api/project/collections/:id/activate — 摘要：Activate removed organization 说明：Restore a soft-deleted o"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/project/collections/$(path_id id)/activate" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq144 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_collections_id_delete_preview() {
  local label="GET /api/project/collections/:id/delete-preview — 摘要：Delete organization preview 说明：Preview child/descendant/p"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/collections/$(path_id id)/delete-preview" "" ""
  expect_read_ok "$label" 200
}

# seq145 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_collections_create_quota() {
  local label="GET /api/project/collections/create-quota — 摘要：Check create-organization quota 说明：Check whether current"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/collections/create-quota" "" ""
  expect_read_ok "$label" 200
}

# seq146 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_collections_uid_collectionUid() {
  local label="GET /api/project/collections/uid/:collectionUid — 摘要：Get project collection by collection UID 说明：Returns a sin"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/collections/uid/$(path_id collectionUid)" "" ""
  expect_read_ok "$label" 200
}

# seq147 asdm-admin-services-core (端口 8880)/Project | auth=jwt（配对清理: POST /api/project/projects/:id）
project_post_api_project_projects() {
  local label="POST /api/project/projects — 摘要：Create a new project 说明：Create a new project under a coll"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "collectionId": "string",
 "name": "example__RUN_ID__",
 "projectUid": "string"
}
JSONEOF
)"
  req jwt POST "/api/project/projects" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/project/projects/:id
  req jwt DELETE "/api/project/projects/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/project/projects/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq148 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_projects() {
  local label="GET /api/project/projects — 摘要：Get all projects 说明：Returns a list of projects. Use ?stat"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/projects" "" ""
  expect_read_ok "$label" 200
}

# seq149 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_projects_id() {
  local label="GET /api/project/projects/:id — 摘要：Get project by ID 说明：Returns a single project by its ID"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/projects/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq150 asdm-admin-services-core (端口 8880)/Project | auth=jwt（无配对删除接口，失败请人工核查数据残留）
project_put_api_project_projects_id() {
  local label="PUT /api/project/projects/:id — 摘要：Update a project 说明：Update project name, dates and status"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "status": "string",
 "startDate": "2026-01-01",
 "endDate": "2026-01-01"
}
JSONEOF
)"
  req jwt PUT "/api/project/projects/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq151 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_delete_api_project_projects_id() {
  local label="DELETE /api/project/projects/:id — 摘要：Delete a project 说明：Soft delete a project by setting stat"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/project/projects/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq152 asdm-admin-services-core (端口 8880)/Project | auth=jwt（配对清理: POST /api/project/projects/:id/settings/:settingId）
project_post_api_project_projects_id_activate() {
  local label="POST /api/project/projects/:id/activate — 摘要：Activate removed project 说明：Restore a soft-deleted projec"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/project/projects/$(path_id id)/activate" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/project/projects/:id/settings/:settingId
  req jwt DELETE "/api/project/projects/${rid}/settings/$(path_id settingId)" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/project/projects/${rid}/settings/$(path_id settingId)" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq153 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_projects_id_git_clones() {
  local label="GET /api/project/projects/:id/git-clones — 摘要：Resolve authenticated Git clone URLs for a project's dire"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/projects/$(path_id id)/git-clones" "" ""
  expect_read_ok "$label" 200
}

# seq154 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_projects_id_qa_service() {
  local label="GET /api/project/projects/:id/qa-service — 摘要：查询项目问答服务开关 说明：读取项目级问答服务开关（决定该项目能否创建项目实例）。支持 JWT（校验集合访问）与"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/projects/$(path_id id)/qa-service" "" ""
  expect_read_ok "$label" 200
}

# seq155 asdm-admin-services-core (端口 8880)/Project | auth=jwt（无配对删除接口，失败请人工核查数据残留）
project_put_api_project_projects_id_qa_service() {
  local label="PUT /api/project/projects/:id/qa-service — 摘要：更新项目问答服务开关 说明：更新项目级问答服务开关（决定该项目能否创建项目实例）。需要集合管理权限。"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt PUT "/api/project/projects/$(path_id id)/qa-service" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq156 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_projects_id_settings() {
  local label="GET /api/project/projects/:id/settings — 摘要：获取项目仓库列表 说明：获取项目下 project_repo 类型仓库列表，token 脱敏返回"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/projects/$(path_id id)/settings" "" ""
  expect_read_ok "$label" 200
}

# seq157 asdm-admin-services-core (端口 8880)/Project | auth=jwt（配对清理: POST /api/project/projects/:id/settings/:settingId）
project_post_api_project_projects_id_settings() {
  local label="POST /api/project/projects/:id/settings — 摘要：创建项目仓库 说明：创建项目下 project_repo 类型仓库（单条创建）"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "repositorySourceType": "string",
  "baseUrl": "https://example.com",
  "gitPushBaseUrl": "https://example.com",
  "token": "string",
  "repositoryAuthType": "string",
  "repositoryName": "example",
  "defaultBranch": "string",
  "status": "string"
}
JSONEOF
)"
  req jwt POST "/api/project/projects/$(path_id id)/settings" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/project/projects/:id/settings/:settingId
  req jwt DELETE "/api/project/projects/${rid}/settings/$(path_id settingId)" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/project/projects/${rid}/settings/$(path_id settingId)" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq158 asdm-admin-services-core (端口 8880)/Project | auth=jwt（无配对删除接口，失败请人工核查数据残留）
project_put_api_project_projects_id_settings_settingId() {
  local label="PUT /api/project/projects/:id/settings/:settingId — 摘要：修改项目仓库 说明：按 project_repositories.id 单条修改（不支持批量）"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "repositorySourceType": "string",
  "baseUrl": "https://example.com",
  "gitPushBaseUrl": "https://example.com",
  "token": "string",
  "repositoryAuthType": "string",
  "repositoryName": "example",
  "defaultBranch": "string",
  "status": "string"
}
JSONEOF
)"
  req jwt PUT "/api/project/projects/$(path_id id)/settings/$(path_id settingId)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq159 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_delete_api_project_projects_id_settings_settingId() {
  local label="DELETE /api/project/projects/:id/settings/:settingId — 摘要：删除项目仓库 说明：按 project_repositories.id 软删除（置为 Removed）"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/project/projects/${DUMMY_ID}/settings/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq160 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_projects_id_settings_settingId_branches() {
  local label="GET /api/project/projects/:id/settings/:settingId/branches — 摘要：列出项目仓库分支 说明：按已保存的源类型、仓库路径与凭据执行 JGit ls-remote heads，返回远端分"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/projects/$(path_id id)/settings/$(path_id settingId)/branches" "" ""
  expect_read_ok "$label" 200
}

# seq161 asdm-admin-services-core (端口 8880)/Project | auth=jwt（无配对删除接口，失败请人工核查数据残留）
project_post_api_project_projects_id_settings_settingId_check_availabi() {
  local label="POST /api/project/projects/:id/settings/:settingId/check-availability — 摘要：检测项目仓库可用性 说明：按已保存的源类型、仓库路径与凭据执行 Git 远端探测（JGit ls-remote），"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/project/projects/$(path_id id)/settings/$(path_id settingId)/check-availability" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq162 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_projects_id_stats() {
  local label="GET /api/project/projects/:id/stats — 摘要：Get project statistics 说明：Returns statistics for a projec"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/projects/$(path_id id)/stats" "" ""
  expect_read_ok "$label" 200
}

# seq163 asdm-admin-services-core (端口 8880)/Project | auth=jwt（无配对删除接口，失败请人工核查数据残留）
project_patch_api_project_projects_projectUid_description() {
  local label="PATCH /api/project/projects/:projectUid/description — 摘要：Update project description 说明：Update the description/summ"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "description": "example text"
}
JSONEOF
)"
  req jwt PATCH "/api/project/projects/$(path_id projectUid)/description" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq164 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_projects_collection_collectionId() {
  local label="GET /api/project/projects/collection/:collectionId — 摘要：Get projects by collection ID 说明：Returns a list of projec"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/projects/collection/$(path_id collectionId)" "" ""
  expect_read_ok "$label" 200
}

# seq165 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_projects_uid_projectUid() {
  local label="GET /api/project/projects/uid/:projectUid — 摘要：Get project by project UID 说明：Returns a single project by"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/projects/uid/$(path_id projectUid)" "" ""
  expect_read_ok "$label" 200
}

# seq166 asdm-admin-services-core (端口 8880)/Project | auth=jwt
project_get_api_project_settings_lookup() {
  local label="GET /api/project/settings/lookup — 摘要：根据 Git Remote URL 查询项目仓库 ID 说明：通过 git remote URL 自动解析仓库源类"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/settings/lookup" "" "gitRemoteUrl=https%3A%2F%2Fexample.com"
  expect_read_ok "$label" 200
}

# seq167 asdm-admin-services-core (端口 8880)/Project Landing | auth=jwt
project_get_api_project_landing_projectUid() {
  local label="GET /api/project/landing/:projectUid — 摘要：Get project landing page data 说明：Aggregated data includin"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/landing/$(path_id projectUid)" "" ""
  expect_read_ok "$label" 200
}

# seq168 asdm-admin-services-core (端口 8880)/Project Organization Move | auth=jwt（无配对删除接口，失败请人工核查数据残留）
project_post_api_projects_id_move_org() {
  local label="POST /_api/projects/:id/move-org — 摘要：Execute project organization move 说明：Moves project and mi"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "targetCollectionId": 1
}
JSONEOF
)"
  req jwt POST "/_api/projects/$(path_id id)/move-org" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq169 asdm-admin-services-core (端口 8880)/Project Organization Move | auth=jwt（无配对删除接口，失败请人工核查数据残留）
project_post_api_projects_id_move_org_preview() {
  local label="POST /_api/projects/:id/move-org/preview — 摘要：Preview project organization move 说明：preview; super-admin"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "targetCollectionId": 1
}
JSONEOF
)"
  req jwt POST "/_api/projects/$(path_id id)/move-org/preview" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq170 asdm-admin-services-core (端口 8880)/Project resources | auth=jwt
project_get_api_project_projects_uid_projectUid_resources() {
  local label="GET /api/project/projects/uid/:projectUid/resources — 摘要：查询项目下资源聚合 说明：当前仅返回该项目可用的 toolsets（固定从 classpath:mock-data"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/project/projects/uid/$(path_id projectUid)/resources" "" ""
  expect_read_ok "$label" 200
}

# ===== 入口 =====
main() {
  set +e   # 单用例失败不中断
  echo ""
  echo "========== 项目管理域 (36 apis) =========="
  login_if_needed || true
  project_get_api_project_org_landing_collectionUid || true
  project_get_api_project_org_landing_collectionUid_projects || true
  project_post_api_project_collections || true
  project_get_api_project_collections || true
  project_patch_api_project_collections_collectionUid_description || true
  project_get_api_project_collections_id || true
  project_put_api_project_collections_id || true
  project_delete_api_project_collections_id || true
  project_post_api_project_collections_id_activate || true
  project_get_api_project_collections_id_delete_preview || true
  project_get_api_project_collections_create_quota || true
  project_get_api_project_collections_uid_collectionUid || true
  project_post_api_project_projects || true
  project_get_api_project_projects || true
  project_get_api_project_projects_id || true
  project_put_api_project_projects_id || true
  project_delete_api_project_projects_id || true
  project_post_api_project_projects_id_activate || true
  project_get_api_project_projects_id_git_clones || true
  project_get_api_project_projects_id_qa_service || true
  project_put_api_project_projects_id_qa_service || true
  project_get_api_project_projects_id_settings || true
  project_post_api_project_projects_id_settings || true
  project_put_api_project_projects_id_settings_settingId || true
  project_delete_api_project_projects_id_settings_settingId || true
  project_get_api_project_projects_id_settings_settingId_branches || true
  project_post_api_project_projects_id_settings_settingId_check_availabi || true
  project_get_api_project_projects_id_stats || true
  project_patch_api_project_projects_projectUid_description || true
  project_get_api_project_projects_collection_collectionId || true
  project_get_api_project_projects_uid_projectUid || true
  project_get_api_project_settings_lookup || true
  project_get_api_project_landing_projectUid || true
  project_post_api_projects_id_move_org || true
  project_post_api_projects_id_move_org_preview || true
  project_get_api_project_projects_uid_projectUid_resources || true
  finish
}
main "$@"
