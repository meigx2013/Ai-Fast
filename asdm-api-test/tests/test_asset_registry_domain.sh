#!/usr/bin/env bash
# ============================================================================
# 资产注册域 — 幂等自动化测试（由 gen/generate.js 从 api.json 生成，勿手工修改）
# 重新生成: node gen/generate.js
# 覆盖服务: core
# 接口总数: 88（读 43 直测 / 写 32 受控[含配对清理 4] / 永久跳过 13）
# 环境变量: ASDM_BASE_URL / ASDM_LOGIN_EMAIL / ASDM_LOGIN_PASSWORD / ASDM_TOKEN /
#           ASDM_PAT / ASDM_INTERNAL_TOKEN / ASDM_OPEN_ACCESS_TOKEN / ASDM_CITIC_SECRET /
#           ASDM_ALLOW_WRITES=1（执行写操作）/ ASDM_TEST_<参数名>（路径参数覆盖）
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ===== 被测接口用例 =====
# seq382 asdm-admin-services-core (端口 8880)/资源库管理 | auth=jwt（配对清理: POST /api/repos/:id）
asset_registry_post_api_repos() {
  local label="POST /api/repos — 摘要：创建资源库 说明：创建新的资源库配置"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "assetLevel": "string",
  "organizationUid": "string",
  "projectUid": "string",
  "configType": "string",
  "repositorySourceType": "string",
  "baseUrl": "https://example.com",
  "repositoryAuthMethod": "string",
  "token": "string",
  "repositoryName": "example",
  "defaultBranch": "string"
}
JSONEOF
)"
  req jwt POST "/api/repos" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/repos/:id
  req jwt DELETE "/api/repos/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/repos/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq383 asdm-admin-services-core (端口 8880)/资源库管理 | auth=jwt
asset_registry_get_api_repos() {
  local label="GET /api/repos — 摘要：查询所有资源库 说明：获取所有资源库列表"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repos" "" ""
  expect_read_ok "$label" 200
}

# seq384 asdm-admin-services-core (端口 8880)/资源库管理 | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_put_api_repos_id() {
  local label="PUT /api/repos/:id — 摘要：更新资源库 说明：更新现有资源库配置"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "assetLevel": "string",
  "configType": "string",
  "repositorySourceType": "string",
  "baseUrl": "https://example.com",
  "repositoryAuthMethod": "string",
  "token": "string",
  "repositoryName": "example",
  "defaultBranch": "string",
  "status": "string"
}
JSONEOF
)"
  req jwt PUT "/api/repos/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq385 asdm-admin-services-core (端口 8880)/资源库管理 | auth=jwt
asset_registry_delete_api_repos_id() {
  local label="DELETE /api/repos/:id — 摘要：删除资源库 说明：删除资源库及其所有关联关系"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/repos/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq386 asdm-admin-services-core (端口 8880)/资源库管理 | auth=jwt
asset_registry_get_api_repos_id() {
  local label="GET /api/repos/:id — 摘要：查询资源库详情 说明：根据 ID 获取资源库详细信息"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repos/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq387 asdm-admin-services-core (端口 8880)/资源库管理 | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_post_api_repos_id_authorize() {
  local label="POST /api/repos/:id/authorize — 摘要：授权资源库 说明：将资源库授权给组织或项目"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "assetLevel": "string",
  "collectionUids": [
    "string"
  ],
  "projects": [
    "string"
  ],
  "collectionUid": "string",
  "projectUid": "string"
}
JSONEOF
)"
  req jwt POST "/api/repos/$(path_id id)/authorize" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq388 asdm-admin-services-core (端口 8880)/资源库管理 | auth=jwt
asset_registry_get_api_repos_id_authorized_assets() {
  local label="GET /api/repos/:id/authorized-assets — 摘要：查询已授权的组织/项目 说明：根据资源库 ID 和关联级别查询已授权的组织或项目列表"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repos/$(path_id id)/authorized-assets" "" "assetLevel=string"
  expect_read_ok "$label" 200
}

# seq389 asdm-admin-services-core (端口 8880)/资源库管理 | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_post_api_repos_id_check() {
  local label="POST /api/repos/:id/check — 摘要：检测资源库可用性 说明：检测资源库是否可正常访问"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/repos/$(path_id id)/check" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq390 asdm-admin-services-core (端口 8880)/资源库管理 | auth=jwt
asset_registry_get_api_repos_by_config_type() {
  local label="GET /api/repos/by-config-type — 摘要：按配置类型查询项目关联的资源库 说明：根据配置类型和项目 UID 查询关联的资源库，返回 ID 和 name"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repos/by-config-type" "" "configType=string"
  expect_read_ok "$label" 200
}

# seq391 asdm-admin-services-core (端口 8880)/资源库管理 | auth=jwt
asset_registry_get_api_repos_by_scope() {
  local label="GET /api/repos/by-scope — 摘要：根据范围查询资源库 说明：根据组织 UID 和项目 UID 查询有权限访问的资源库，用于资源管理页面"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repos/by-scope" "" ""
  expect_read_ok "$label" 200
}

# seq392 asdm-admin-services-core (端口 8880)/资源库管理 | auth=jwt
asset_registry_get_api_repos_filter() {
  local label="GET /api/repos/filter — 摘要：按级别和状态查询资源库 说明：根据关联级别和状态筛选资源库"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repos/filter" "" ""
  expect_read_ok "$label" 200
}

# seq393 asdm-admin-services-core (端口 8880)/Asset Category Management | auth=jwt（配对清理: POST /_api/categories/:id）
asset_registry_post_api_categories() {
  local label="POST /_api/categories — 摘要：Create category 说明：Create a new global resource category"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "description": "example text"
}
JSONEOF
)"
  req jwt POST "/_api/categories" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/categories/:id
  req jwt DELETE "/_api/categories/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/_api/categories/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq394 asdm-admin-services-core (端口 8880)/Asset Category Management | auth=jwt
asset_registry_get_api_categories() {
  local label="GET /_api/categories — 摘要：Query category list 说明：Get the global category list for a"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/categories" "" "configType=string"
  expect_read_ok "$label" 200
}

# seq395 asdm-admin-services-core (端口 8880)/Asset Category Management | auth=jwt
asset_registry_delete_api_categories_id() {
  local label="DELETE /_api/categories/:id — 摘要：Delete category 说明：Delete a global category (system categ"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/_api/categories/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq396 asdm-admin-services-core (端口 8880)/Asset Category Management | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_put_api_categories_sort() {
  local label="PUT /_api/categories/sort — 摘要：Batch update category sort 说明：Update category sort order"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt PUT "/_api/categories/sort" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq397 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（配对清理: POST /api/v1/asset-registry-info/:id）
asset_registry_post_api_v1_asset_registry_info() {
  local label="POST /api/v1/asset-registry-info — 摘要：Create asset registry info 完整路径：POST /api/v1/asset-regist"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "registryLevel": "string",
 "registryId": "string",
 "configType": "string",
 "affiliatedOrganization": "string",
 "affiliatedProject": "string",
 "guid": "string",
 "name": "example__RUN_ID__",
 "description": "example text",
 "version": "1.0.0",
 "downloadUrl": "https://example.com",
 "path": "/tmp/example",
 "entryPoint": "string",
 "commands": "string",
 "scenario": "string",
 "isShare": true,
 "category": "string",
 "tags": [
  "string"
 ],
 "readmeMdContent": "example text"
}
JSONEOF
)"
  req jwt POST "/api/v1/asset-registry-info" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/v1/asset-registry-info/:id
  req jwt DELETE "/api/v1/asset-registry-info/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/v1/asset-registry-info/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq398 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info() {
  local label="GET /api/v1/asset-registry-info — 摘要：Get all asset registry info 完整路径：GET /api/v1/asset-regist"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info" "" ""
  expect_read_ok "$label" 200
}

# seq399 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info_id() {
  local label="GET /api/v1/asset-registry-info/:id — 摘要：Get asset registry info by ID 完整路径：GET /api/v1/asset-regi"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq400 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_put_api_v1_asset_registry_info_id() {
  local label="PUT /api/v1/asset-registry-info/:id — 摘要：Update asset registry info 完整路径：PUT /api/v1/asset-registr"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "id": 1,
 "registryLevel": "string",
 "registryId": "string",
 "configType": "string",
 "affiliatedOrganization": "string",
 "affiliatedProject": "string",
 "guid": "string",
 "name": "example__RUN_ID__",
 "description": "example text",
 "version": "1.0.0",
 "downloadUrl": "https://example.com",
 "path": "/tmp/example",
 "entryPoint": "string",
 "commands": "string",
 "scenario": "string",
 "isShare": true,
 "category": "string",
 "tags": [
  "string"
 ],
 "readmeMdContent": "example text",
 "isFeatured": 1
}
JSONEOF
)"
  req jwt PUT "/api/v1/asset-registry-info/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq401 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_delete_api_v1_asset_registry_info_id() {
  local label="DELETE /api/v1/asset-registry-info/:id — 摘要：Delete (soft) asset registry info by ID 完整路径：DELETE /api/"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/v1/asset-registry-info/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq402 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info_admin_resources() {
  local label="GET /api/v1/asset-registry-info/admin/resources — 摘要：管理员分页查询资源（支持 status 过滤） 完整路径：GET /api/v1/asset-registry-i"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info/admin/resources" "" "status=active&page=0&size=20"
  expect_read_ok "$label" 200
}

# seq403 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info_asset_stats_download_cou() {
  local label="GET /api/v1/asset-registry-info/asset-stats/download-count/by-guid/:guid — 摘要：Get download count by GUID from asset_stats 说明：Reads down"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info/asset-stats/download-count/by-guid/$(path_id guid)" "" ""
  expect_read_ok "$label" 200
}

# seq404 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_put_api_v1_asset_registry_info_by_guid_guid() {
  local label="PUT /api/v1/asset-registry-info/by-guid/:guid — 摘要：Update asset registry info by GUID 完整路径：PUT /api/v1/asset"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "id": 1,
 "registryLevel": "string",
 "registryId": "string",
 "configType": "string",
 "affiliatedOrganization": "string",
 "affiliatedProject": "string",
 "guid": "string",
 "name": "example__RUN_ID__",
 "description": "example text",
 "version": "1.0.0",
 "downloadUrl": "https://example.com",
 "path": "/tmp/example",
 "entryPoint": "string",
 "commands": "string",
 "scenario": "string",
 "isShare": true,
 "category": "string",
 "tags": [
  "string"
 ],
 "readmeMdContent": "example text",
 "isFeatured": 1
}
JSONEOF
)"
  req jwt PUT "/api/v1/asset-registry-info/by-guid/$(path_id guid)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq405 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_delete_api_v1_asset_registry_info_by_guid_guid() {
  local label="DELETE /api/v1/asset-registry-info/by-guid/:guid — 摘要：Delete (soft) asset registry info by GUID 完整路径：DELETE /ap"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/v1/asset-registry-info/by-guid/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq406 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info_by_guid_guid_pending() {
  local label="GET /api/v1/asset-registry-info/by-guid/:guid/pending — 摘要：Get my current draft (pending / rejected) 说明：FT-10880: cr"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info/by-guid/$(path_id guid)/pending" "" ""
  expect_read_ok "$label" 200
}

# seq407 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_post_api_v1_asset_registry_info_by_guid_guid_pending_ap() {
  local label="POST /api/v1/asset-registry-info/by-guid/:guid/pending/approve — 摘要：Approve the pending submission 说明：FT-10880: apply the pen"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/v1/asset-registry-info/by-guid/$(path_id guid)/pending/approve" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq408 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_post_api_v1_asset_registry_info_by_guid_guid_pending_re() {
  local label="POST /api/v1/asset-registry-info/by-guid/:guid/pending/reject — 摘要：Reject the pending submission 说明：FT-10880: keep the submi"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/v1/asset-registry-info/by-guid/$(path_id guid)/pending/reject" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq409 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_post_api_v1_asset_registry_info_by_guid_guid_pending_wi() {
  local label="POST /api/v1/asset-registry-info/by-guid/:guid/pending/withdraw — 摘要：Withdraw my pending submission 说明：FT-10880: creator only."
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/v1/asset-registry-info/by-guid/$(path_id guid)/pending/withdraw" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq410 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_post_api_v1_asset_registry_info_by_guid_guid_promote_to() {
  local label="POST /api/v1/asset-registry-info/by-guid/:guid/promote-to-platform — 摘要：Promote asset to platform level 说明：Promotes an org-level"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/v1/asset-registry-info/by-guid/$(path_id guid)/promote-to-platform" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq411 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info_by_guid_guid_references() {
  local label="GET /api/v1/asset-registry-info/by-guid/:guid/references — 摘要：Check resource references by GUID 完整路径：GET /api/v1/asset-"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info/by-guid/$(path_id guid)/references" "" ""
  expect_read_ok "$label" 200
}

# seq412 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_post_api_v1_asset_registry_info_by_guid_guid_restore() {
  log_skip "POST /api/v1/asset-registry-info/by-guid/:guid/restore — 永久跳过：路径含状态变更/清理类操作段（restore），避免破坏环境"
}

# seq413 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_post_api_v1_asset_registry_info_by_guid_guid_versions_v() {
  local label="POST /api/v1/asset-registry-info/by-guid/:guid/versions/:version/off-shelf — 摘要：Take a version off shelf 说明：FT-10879: set the given versi"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/v1/asset-registry-info/by-guid/$(path_id guid)/versions/$(path_id version)/off-shelf" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq414 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_post_api_v1_asset_registry_info_by_guid_guid_versions_v_2() {
  log_skip "POST /api/v1/asset-registry-info/by-guid/:guid/versions/:version/restore — 永久跳过：路径含状态变更/清理类操作段（restore），避免破坏环境"
}

# seq415 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info_by_level_registryLevel() {
  local label="GET /api/v1/asset-registry-info/by-level/:registryLevel — 摘要：Find by registry level 完整路径：GET /api/v1/asset-registry-in"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info/by-level/$(path_id registryLevel)" "" ""
  expect_read_ok "$label" 200
}

# seq416 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info_by_organization_organiza() {
  local label="GET /api/v1/asset-registry-info/by-organization/:organization — 摘要：Find by affiliated organization 完整路径：GET /api/v1/asset-re"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info/by-organization/$(path_id organization)" "" ""
  expect_read_ok "$label" 200
}

# seq417 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info_by_project_project() {
  local label="GET /api/v1/asset-registry-info/by-project/:project — 摘要：Find by affiliated project 完整路径：GET /api/v1/asset-registr"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info/by-project/$(path_id project)" "" "configType=string"
  expect_read_ok "$label" 200
}

# seq418 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_put_api_v1_asset_registry_info_category() {
  local label="PUT /api/v1/asset-registry-info/category — 摘要：Update asset category by GUID 完整路径：PUT /api/v1/asset-regi"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt PUT "/api/v1/asset-registry-info/category" "" "assetGuid=string&assetCategory=string&collectionUid=string&projectUid=string"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq419 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info_download_stats_by_guid_g() {
  local label="GET /api/v1/asset-registry-info/download-stats/by-guid/:guid — 摘要：Get download count by GUID 完整路径：GET /api/v1/asset-registr"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info/download-stats/by-guid/$(path_id guid)" "" ""
  expect_read_ok "$label" 200
}

# seq420 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info_exists() {
  local label="GET /api/v1/asset-registry-info/exists — 摘要：Check if asset registry exists 完整路径：GET /api/v1/asset-reg"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info/exists" "" "registryId=string&configType=string"
  expect_read_ok "$label" 200
}

# seq421 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_put_api_v1_asset_registry_info_featured() {
  local label="PUT /api/v1/asset-registry-info/featured — 摘要：Toggle asset featured status by GUID 说明：Toggles the is_fe"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt PUT "/api/v1/asset-registry-info/featured" "" "guid=string"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq422 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_put_api_v1_asset_registry_info_featured_batch() {
  local label="PUT /api/v1/asset-registry-info/featured/batch — 摘要：Batch set featured status 说明：Sets the featured status (is"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "guids": [
    "string"
  ],
  "isFeatured": 1
}
JSONEOF
)"
  req jwt PUT "/api/v1/asset-registry-info/featured/batch" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq423 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info_pending() {
  local label="GET /api/v1/asset-registry-info/pending — 摘要：List all pending submissions 说明：FT-10880: single batch qu"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info/pending" "" ""
  expect_read_ok "$label" 200
}

# seq424 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info_server_level() {
  local label="GET /api/v1/asset-registry-info/server-level — 摘要：Find server-level assets with optional filters (paginated"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info/server-level" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq425 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_put_api_v1_asset_registry_info_share_status() {
  local label="PUT /api/v1/asset-registry-info/share-status — 摘要：Update share status by GUID 完整路径：PUT /api/v1/asset-regist"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt PUT "/api/v1/asset-registry-info/share-status" "" "guid=string&isShare=true"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq426 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_post_api_v1_asset_registry_info_sync_repositoryId() {
  local label="POST /api/v1/asset-registry-info/sync/:repositoryId — 摘要：Sync assets from online repository 完整路径：POST /api/v1/asse"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/v1/asset-registry-info/sync/$(path_id repositoryId)" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq427 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt（配对清理: POST /api/v1/asset-registry-info/tag）
asset_registry_post_api_v1_asset_registry_info_tag() {
  local label="POST /api/v1/asset-registry-info/tag — 摘要：Create asset tag by GUID 完整路径：POST /api/v1/asset-registry"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/v1/asset-registry-info/tag" "" "assetGuid=string&assetTag=string&collectionUid=string&projectUid=string"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/v1/asset-registry-info/tag
  req jwt DELETE "/api/v1/asset-registry-info/tag" "" "assetGuid=string&assetTag=string&collectionUid=string&projectUid=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/v1/asset-registry-info/tag" "" "assetGuid=string&assetTag=string&collectionUid=string&projectUid=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq428 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_delete_api_v1_asset_registry_info_tag() {
  log_skip "DELETE /api/v1/asset-registry-info/tag — 永久跳过：静态路径整体删除，无法限定删除范围"
}

# seq429 asdm-admin-services-core (端口 8880)/Asset Registry Info | auth=jwt
asset_registry_get_api_v1_asset_registry_info_version() {
  local label="GET /api/v1/asset-registry-info/version — 摘要：Get version by registry ID and config type 完整路径：GET /api/"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-registry-info/version" "" "registryId=string&configType=string"
  expect_read_ok "$label" 200
}

# seq430 asdm-admin-services-core (端口 8880)/Asset Share Scope Management | auth=jwt
asset_registry_delete_api_v1_asset_share_scope_scopeId() {
  local label="DELETE /api/v1/asset-share-scope/:scopeId — 摘要：Delete a single share scope 完整路径：DELETE /api/v1/asset-sha"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/v1/asset-share-scope/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq431 asdm-admin-services-core (端口 8880)/Asset Share Scope Management | auth=jwt
asset_registry_get_api_v1_asset_share_scope_asset_assetGuid() {
  local label="GET /api/v1/asset-share-scope/asset/:assetGuid — 摘要：Query share scopes by asset GUID 完整路径：GET /api/v1/asset-s"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-share-scope/asset/$(path_id assetGuid)" "" ""
  expect_read_ok "$label" 200
}

# seq432 asdm-admin-services-core (端口 8880)/Asset Share Scope Management | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_put_api_v1_asset_share_scope_asset_assetGuid() {
  local label="PUT /api/v1/asset-share-scope/asset/:assetGuid — 摘要：Set share scopes by asset GUID 完整路径：PUT /api/v1/asset-sha"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt PUT "/api/v1/asset-share-scope/asset/$(path_id assetGuid)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq433 asdm-admin-services-core (端口 8880)/Asset Share Scope Management | auth=jwt
asset_registry_get_api_v1_asset_share_scope_asset_guid_guid() {
  local label="GET /api/v1/asset-share-scope/asset/guid/:guid — 摘要：Query share scopes by asset GUID 完整路径：GET /api/v1/asset-s"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/asset-share-scope/asset/guid/$(path_id guid)" "" ""
  expect_read_ok "$label" 200
}

# seq434 asdm-admin-services-core (端口 8880)/Asset Share Scope Management | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_put_api_v1_asset_share_scope_asset_guid_guid() {
  local label="PUT /api/v1/asset-share-scope/asset/guid/:guid — 摘要：Set share scopes by asset GUID 完整路径：PUT /api/v1/asset-sha"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt PUT "/api/v1/asset-share-scope/asset/guid/$(path_id guid)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq435 asdm-admin-services-core (端口 8880)/CodeBuddy Plugins | auth=public
asset_registry_get_api_codebuddy_plugins() {
  local label="GET /_api/codebuddy/plugins — 摘要：获取插件列表 说明：返回市场内插件列表（调试与后续 Web 迭代使用）。"
  need_auth public "$label" || return 0
  req public GET "/_api/codebuddy/plugins" "" ""
  expect_read_ok "$label" 200
}

# seq436 asdm-admin-services-core (端口 8880)/CodeBuddy Plugins | auth=public
asset_registry_get_api_codebuddy_plugins_pluginId() {
  local label="GET /_api/codebuddy/plugins/:pluginId — 摘要：获取插件详情 说明：复用 ResourceDetailResponse 字段，补充 pluginId/market"
  need_auth public "$label" || return 0
  req public GET "/_api/codebuddy/plugins/$(path_id pluginId)" "" ""
  expect_read_ok "$label" 200
}

# seq437 asdm-admin-services-core (端口 8880)/CodeBuddy Plugins | auth=public
asset_registry_get_api_codebuddy_plugins_pluginId_files() {
  local label="GET /_api/codebuddy/plugins/:pluginId/files — 摘要：下载插件包 ZIP 说明：toolset/spec/skill 复用原 ZIP 并做目录映射；mcp 动态生成轻量"
  need_auth public "$label" || return 0
  req public GET "/_api/codebuddy/plugins/$(path_id pluginId)/files" "" ""
  expect_read_ok "$label" 200
}

# seq438 asdm-admin-services-core (端口 8880)/CodeBuddy Plugins | auth=public
asset_registry_get_api_codebuddy_plugins_marketplace_json() {
  local label="GET /_api/codebuddy/plugins/marketplace.json — 摘要：获取插件市场索引（marketplace.json） 说明：聚合 server 级 Active 资源生成市场索引"
  need_auth public "$label" || return 0
  req public GET "/_api/codebuddy/plugins/marketplace.json" "" "cache=true"
  expect_read_ok "$label" 200
}

# seq439 asdm-admin-services-core (端口 8880)/Install Document | auth=jwt
asset_registry_post_api_install_doc() {
  log_skip "POST /_api/install-doc — 需要 multipart 文件上传，无法幂等自动执行（摘要：Upload install document 说明：Upload a markdown (.md) file a）"
}

# seq440 asdm-admin-services-core (端口 8880)/Install Document | auth=jwt
asset_registry_get_api_install_doc() {
  local label="GET /_api/install-doc — 摘要：List install documents 说明：Paginated list of install docum"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/install-doc" "" "page=0&size=10"
  expect_read_ok "$label" 200
}

# seq441 asdm-admin-services-core (端口 8880)/Install Document | auth=jwt
asset_registry_delete_api_install_doc_guid() {
  local label="DELETE /_api/install-doc/:guid — 摘要：Delete install document 说明：Delete an install document and"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/_api/install-doc/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq442 asdm-admin-services-core (端口 8880)/Install Document | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_put_api_install_doc_guid_activate() {
  local label="PUT /_api/install-doc/:guid/activate — 摘要：Activate install document 说明：Set a document to active. Au"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt PUT "/_api/install-doc/$(path_id guid)/activate" "" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq443 asdm-admin-services-core (端口 8880)/Install Document | auth=jwt
asset_registry_post_api_install_doc_upload_package() {
  log_skip "POST /_api/install-doc/upload-package — 需要 multipart 文件上传，无法幂等自动执行（摘要：Upload install resource package 说明：Upload a zip package c）"
}

# seq444 asdm-admin-services-core (端口 8880)/MCP Toolset | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_post_api_mcp_toolsets_query() {
  local label="POST /api/mcp/toolsets/query — 摘要：Query and download toolset by slash command 说明：Queries to"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "slashCommand": "string",
  "projectUid": "string"
}
JSONEOF
)"
  req jwt POST "/api/mcp/toolsets/query" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq445 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_get_api_repo_owner_repo() {
  local label="GET /api/repo/:owner/:repo — 摘要：Get GitHub repository file list (async) 说明：Returns the fi"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repo/$(path_id owner)/$(path_id repo)" "" "recursive=false"
  expect_read_ok "$label" 200
}

# seq446 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_delete_api_repo_cache() {
  log_skip "DELETE /api/repo/cache — 永久跳过：静态路径整体删除，无法限定删除范围"
}

# seq447 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_get_api_repo_contexts_registry() {
  local label="GET /api/repo/contexts-registry — 摘要：Get contexts-registry.json content (async) 说明：Returns the"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repo/contexts-registry" "" ""
  expect_read_ok "$label" 200
}

# seq448 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_get_api_repo_core_assets() {
  local label="GET /api/repo/core-assets — 摘要：Get asdm-core-assets file list (async) 说明：Returns the fil"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repo/core-assets" "" "recursive=true"
  expect_read_ok "$label" 200
}

# seq449 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_get_api_repo_download() {
  local label="GET /api/repo/download — 摘要：Download asset zip file by guid 说明：Returns the zip file c"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repo/download" "" "guid=string&mode=local"
  expect_read_ok "$label" 200
}

# seq450 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_get_api_repo_mcps_registry() {
  local label="GET /api/repo/mcps-registry — 摘要：Get mcps-registry.json content (async) 说明：Returns the mcp"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repo/mcps-registry" "" ""
  expect_read_ok "$label" 200
}

# seq451 asdm-admin-services-core (端口 8880)/Repository | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_post_api_repo_mcps_registry_add_meta() {
  local label="POST /api/repo/mcps-registry/add-meta — 摘要：Create MCP metadata (no file upload) 说明：FT-8363: Create a"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/repo/mcps-registry/add-meta" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq452 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_post_api_repo_mcps_registry_add() {
  log_skip "POST /api/repo/mcps-registry/add — 需要 multipart 文件上传，无法幂等自动执行（摘要：Upload MCP zip file 说明：Upload an MCP zip file to artifact）"
}

# seq453 asdm-admin-services-core (端口 8880)/Repository | auth=public
asset_registry_get_api_repo_mcps_registry_shoplist() {
  local label="GET /api/repo/mcps-registry/shoplist — 摘要：Get MCP shop list (server-level MCPs only) 说明：Returns all"
  need_auth public "$label" || return 0
  req public GET "/api/repo/mcps-registry/shoplist" "" ""
  expect_read_ok "$label" 200
}

# seq454 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_get_api_repo_mcps_registry_typed() {
  local label="GET /api/repo/mcps-registry/typed — 摘要：Get mcps-registry.json content as typed object (async) 说明"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repo/mcps-registry/typed" "" "projectUid=string"
  expect_read_ok "$label" 200
}

# seq455 asdm-admin-services-core (端口 8880)/Repository | auth=jwt（无配对删除接口，失败请人工核查数据残留）
asset_registry_put_api_repo_mcps_registry_update() {
  local label="PUT /api/repo/mcps-registry/update — 摘要：Update an existing MCP resource by GUID 说明：FT-10880: iden"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt PUT "/api/repo/mcps-registry/update" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq456 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_get_api_repo_skills_registry() {
  local label="GET /api/repo/skills-registry — 摘要：Get skills-registry.json content (async) 说明：Returns the s"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repo/skills-registry" "" ""
  expect_read_ok "$label" 200
}

# seq457 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_post_api_repo_skills_registry_add() {
  log_skip "POST /api/repo/skills-registry/add — 需要 multipart 文件上传，无法幂等自动执行（摘要：Upload skill zip file 说明：Upload a skill zip file to artif）"
}

# seq458 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_get_api_repo_skills_registry_typed() {
  local label="GET /api/repo/skills-registry/typed — 摘要：Get skills-registry.json content as typed object (async)"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repo/skills-registry/typed" "" "projectUid=string"
  expect_read_ok "$label" 200
}

# seq459 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_put_api_repo_skills_registry_update() {
  log_skip "PUT /api/repo/skills-registry/update — 需要 multipart 文件上传，无法幂等自动执行（摘要：Update skill with new ZIP file 说明：Update an existing skil）"
}

# seq460 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_get_api_repo_specs_registry() {
  local label="GET /api/repo/specs-registry — 摘要：Get specs-registry.json content (async) 说明：Returns the sp"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repo/specs-registry" "" ""
  expect_read_ok "$label" 200
}

# seq461 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_post_api_repo_specs_registry_add() {
  log_skip "POST /api/repo/specs-registry/add — 需要 multipart 文件上传，无法幂等自动执行（摘要：Upload spec zip file 说明：Upload a spec zip file to artifac）"
}

# seq462 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_get_api_repo_specs_registry_typed() {
  local label="GET /api/repo/specs-registry/typed — 摘要：Get specs-registry.json content as typed object (async) 说"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repo/specs-registry/typed" "" "projectUid=string"
  expect_read_ok "$label" 200
}

# seq463 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_put_api_repo_specs_registry_update() {
  log_skip "PUT /api/repo/specs-registry/update — 需要 multipart 文件上传，无法幂等自动执行（摘要：Update spec with new ZIP file 说明：Update an existing spec）"
}

# seq464 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_get_api_repo_storage_config() {
  local label="GET /api/repo/storage-config — 摘要：Get storage configuration 说明：Returns current storage mode"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repo/storage-config" "" ""
  expect_read_ok "$label" 200
}

# seq465 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_get_api_repo_toolsets_registry() {
  local label="GET /api/repo/toolsets-registry — 摘要：Get toolsets-registry.json content (async) 说明：Returns the"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repo/toolsets-registry" "" ""
  expect_read_ok "$label" 200
}

# seq466 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_post_api_repo_toolsets_registry_add() {
  log_skip "POST /api/repo/toolsets-registry/add — 需要 multipart 文件上传，无法幂等自动执行（摘要：Upload toolset zip file 说明：Upload a toolset zip file to a）"
}

# seq467 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_get_api_repo_toolsets_registry_typed() {
  local label="GET /api/repo/toolsets-registry/typed — 摘要：Get toolsets-registry.json content as typed object (async"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/repo/toolsets-registry/typed" "" "projectUid=string"
  expect_read_ok "$label" 200
}

# seq468 asdm-admin-services-core (端口 8880)/Repository | auth=jwt
asset_registry_put_api_repo_toolsets_registry_update() {
  log_skip "PUT /api/repo/toolsets-registry/update — 需要 multipart 文件上传，无法幂等自动执行（摘要：Update toolset with new ZIP file 说明：Update an existing to）"
}

# seq469 asdm-admin-services-core (端口 8880)/Tag Suggestion | auth=jwt
asset_registry_get_api_tags_suggest() {
  local label="GET /_api/tags/suggest — 摘要：获取标签建议 说明：根据关键词和资源配置类型获取标签建议，按使用频率降序排列"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/tags/suggest" "" "configType=string&limit=10"
  expect_read_ok "$label" 200
}

# ===== 入口 =====
main() {
  set +e   # 单用例失败不中断
  echo ""
  echo "========== 资产注册域 (88 apis) =========="
  login_if_needed || true
  asset_registry_post_api_repos || true
  asset_registry_get_api_repos || true
  asset_registry_put_api_repos_id || true
  asset_registry_delete_api_repos_id || true
  asset_registry_get_api_repos_id || true
  asset_registry_post_api_repos_id_authorize || true
  asset_registry_get_api_repos_id_authorized_assets || true
  asset_registry_post_api_repos_id_check || true
  asset_registry_get_api_repos_by_config_type || true
  asset_registry_get_api_repos_by_scope || true
  asset_registry_get_api_repos_filter || true
  asset_registry_post_api_categories || true
  asset_registry_get_api_categories || true
  asset_registry_delete_api_categories_id || true
  asset_registry_put_api_categories_sort || true
  asset_registry_post_api_v1_asset_registry_info || true
  asset_registry_get_api_v1_asset_registry_info || true
  asset_registry_get_api_v1_asset_registry_info_id || true
  asset_registry_put_api_v1_asset_registry_info_id || true
  asset_registry_delete_api_v1_asset_registry_info_id || true
  asset_registry_get_api_v1_asset_registry_info_admin_resources || true
  asset_registry_get_api_v1_asset_registry_info_asset_stats_download_cou || true
  asset_registry_put_api_v1_asset_registry_info_by_guid_guid || true
  asset_registry_delete_api_v1_asset_registry_info_by_guid_guid || true
  asset_registry_get_api_v1_asset_registry_info_by_guid_guid_pending || true
  asset_registry_post_api_v1_asset_registry_info_by_guid_guid_pending_ap || true
  asset_registry_post_api_v1_asset_registry_info_by_guid_guid_pending_re || true
  asset_registry_post_api_v1_asset_registry_info_by_guid_guid_pending_wi || true
  asset_registry_post_api_v1_asset_registry_info_by_guid_guid_promote_to || true
  asset_registry_get_api_v1_asset_registry_info_by_guid_guid_references || true
  asset_registry_post_api_v1_asset_registry_info_by_guid_guid_restore || true
  asset_registry_post_api_v1_asset_registry_info_by_guid_guid_versions_v || true
  asset_registry_post_api_v1_asset_registry_info_by_guid_guid_versions_v_2 || true
  asset_registry_get_api_v1_asset_registry_info_by_level_registryLevel || true
  asset_registry_get_api_v1_asset_registry_info_by_organization_organiza || true
  asset_registry_get_api_v1_asset_registry_info_by_project_project || true
  asset_registry_put_api_v1_asset_registry_info_category || true
  asset_registry_get_api_v1_asset_registry_info_download_stats_by_guid_g || true
  asset_registry_get_api_v1_asset_registry_info_exists || true
  asset_registry_put_api_v1_asset_registry_info_featured || true
  asset_registry_put_api_v1_asset_registry_info_featured_batch || true
  asset_registry_get_api_v1_asset_registry_info_pending || true
  asset_registry_get_api_v1_asset_registry_info_server_level || true
  asset_registry_put_api_v1_asset_registry_info_share_status || true
  asset_registry_post_api_v1_asset_registry_info_sync_repositoryId || true
  asset_registry_post_api_v1_asset_registry_info_tag || true
  asset_registry_delete_api_v1_asset_registry_info_tag || true
  asset_registry_get_api_v1_asset_registry_info_version || true
  asset_registry_delete_api_v1_asset_share_scope_scopeId || true
  asset_registry_get_api_v1_asset_share_scope_asset_assetGuid || true
  asset_registry_put_api_v1_asset_share_scope_asset_assetGuid || true
  asset_registry_get_api_v1_asset_share_scope_asset_guid_guid || true
  asset_registry_put_api_v1_asset_share_scope_asset_guid_guid || true
  asset_registry_get_api_codebuddy_plugins || true
  asset_registry_get_api_codebuddy_plugins_pluginId || true
  asset_registry_get_api_codebuddy_plugins_pluginId_files || true
  asset_registry_get_api_codebuddy_plugins_marketplace_json || true
  asset_registry_post_api_install_doc || true
  asset_registry_get_api_install_doc || true
  asset_registry_delete_api_install_doc_guid || true
  asset_registry_put_api_install_doc_guid_activate || true
  asset_registry_post_api_install_doc_upload_package || true
  asset_registry_post_api_mcp_toolsets_query || true
  asset_registry_get_api_repo_owner_repo || true
  asset_registry_delete_api_repo_cache || true
  asset_registry_get_api_repo_contexts_registry || true
  asset_registry_get_api_repo_core_assets || true
  asset_registry_get_api_repo_download || true
  asset_registry_get_api_repo_mcps_registry || true
  asset_registry_post_api_repo_mcps_registry_add_meta || true
  asset_registry_post_api_repo_mcps_registry_add || true
  asset_registry_get_api_repo_mcps_registry_shoplist || true
  asset_registry_get_api_repo_mcps_registry_typed || true
  asset_registry_put_api_repo_mcps_registry_update || true
  asset_registry_get_api_repo_skills_registry || true
  asset_registry_post_api_repo_skills_registry_add || true
  asset_registry_get_api_repo_skills_registry_typed || true
  asset_registry_put_api_repo_skills_registry_update || true
  asset_registry_get_api_repo_specs_registry || true
  asset_registry_post_api_repo_specs_registry_add || true
  asset_registry_get_api_repo_specs_registry_typed || true
  asset_registry_put_api_repo_specs_registry_update || true
  asset_registry_get_api_repo_storage_config || true
  asset_registry_get_api_repo_toolsets_registry || true
  asset_registry_post_api_repo_toolsets_registry_add || true
  asset_registry_get_api_repo_toolsets_registry_typed || true
  asset_registry_put_api_repo_toolsets_registry_update || true
  asset_registry_get_api_tags_suggest || true
  finish
}
main "$@"
