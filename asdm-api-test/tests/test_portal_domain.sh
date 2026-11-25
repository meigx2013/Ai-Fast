#!/usr/bin/env bash
# ============================================================================
# 门户与内容域 — 幂等自动化测试（由 gen/generate.js 从 api.json 生成，勿手工修改）
# 重新生成: node gen/generate.js
# 覆盖服务: core, portal-backend
# 接口总数: 97（读 64 直测 / 写 28 受控[含配对清理 9] / 永久跳过 5）
# 环境变量: ASDM_BASE_URL / ASDM_LOGIN_EMAIL / ASDM_LOGIN_PASSWORD / ASDM_TOKEN /
#           ASDM_PAT / ASDM_INTERNAL_TOKEN / ASDM_OPEN_ACCESS_TOKEN / ASDM_CITIC_SECRET /
#           ASDM_ALLOW_WRITES=1（执行写操作）/ ASDM_TEST_<参数名>（路径参数覆盖）
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ===== 被测接口用例 =====
# seq697 asdm-admin-services-core (端口 8880)/门户智能体空间 | auth=public
portal_get_ai_portal_agent_spaces() {
  local label="GET /_ai/portal/agent-spaces — 摘要：智能体空间目录（匿名可见） 说明：返回智能体空间目录。匿名仅返回平台级（scope=PLATFORM）；"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/agent-spaces" "" "page=1&size=12"
  expect_read_ok "$label" 200
}

# seq698 asdm-admin-services-core (端口 8880)/门户智能体空间 | auth=public
portal_get_ai_portal_agent_spaces_workspaceId() {
  local label="GET /_ai/portal/agent-spaces/:workspaceId — 摘要：智能体空间详情（公开，按 scope 鉴权） 说明：返回单个智能体空间详情。平台级匿名可读；项目级仅本人可读项目可"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/agent-spaces/$(path_id workspaceId)" "" ""
  expect_read_ok "$label" 200
}

# seq699 asdm-admin-services-core (端口 8880)/门户智能体空间 | auth=public
portal_get_ai_portal_agent_spaces_workspaceId_resources() {
  local label="GET /_ai/portal/agent-spaces/:workspaceId/resources — 摘要：智能体空间资源构成（公开，按 scope 鉴权） 说明：返回单个智能体空间的资源构成（按 kind 分组的工具集/"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/agent-spaces/$(path_id workspaceId)/resources" "" ""
  expect_read_ok "$label" 200
}

# seq700 asdm-admin-services-core (端口 8880)/排行榜 | auth=public
portal_get_ai_portal_leaderboard() {
  local label="GET /_ai/portal/leaderboard — 摘要：查询排行榜 说明：按类型和时间范围查询排行榜数据，支持无限滚动分页"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/leaderboard" "" "type=string&range=string&offset=0&limit=15"
  expect_read_ok "$label" 200
}

# seq701 asdm-admin-services-core (端口 8880)/最佳实践管理（平台管理员） | auth=jwt
portal_get_api_admin_articles() {
  local label="GET /_api/admin/articles — 摘要：全平台最佳实践列表 说明：支持关键词/状态/标签/分类筛选与排序，分页返回，不含已逻辑删除文章"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/admin/articles" "" "sort=time"
  expect_read_ok "$label" 200
}

# seq702 asdm-admin-services-core (端口 8880)/最佳实践管理（平台管理员） | auth=jwt
portal_post_api_admin_articles_id_restore() {
  log_skip "POST /_api/admin/articles/:id/restore — 永久跳过：路径含状态变更/清理类操作段（restore），避免破坏环境"
}

# seq703 asdm-admin-services-core (端口 8880)/最佳实践管理（平台管理员） | auth=jwt（无配对删除接口，失败请人工核查数据残留）
portal_post_api_admin_articles_batch_delete() {
  local label="POST /_api/admin/articles/batch-delete — 摘要：批量删除最佳实践 说明：仅逻辑删除文章，不删除关联资源。单次最多 200 篇"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/_api/admin/articles/batch-delete" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq704 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public
portal_get_ai_portal_browse() {
  local label="GET /_ai/portal/browse — 摘要：Browse resources with filters, sort, and pagination 说明：Re"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/browse" "" "sort=download_count&page=0&size=16"
  expect_read_ok "$label" 200
}

# seq705 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public
portal_get_ai_portal_browse_hot_downloads() {
  local label="GET /_ai/portal/browse/hot-downloads — 摘要：Get hot downloads (top downloaded in last 30 days) 说明：Ret"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/browse/hot-downloads" "" "limit=8"
  expect_read_ok "$label" 200
}

# seq706 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public
portal_get_ai_portal_browse_hot_recommendations() {
  local label="GET /_ai/portal/browse/hot-recommendations — 摘要：Get hot recommendations (top viewed in last 7 days) 说明：Re"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/browse/hot-recommendations" "" "limit=8"
  expect_read_ok "$label" 200
}

# seq707 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public
portal_get_ai_portal_browse_new_arrivals() {
  local label="GET /_ai/portal/browse/new-arrivals — 摘要：Get new arrivals (sorted by date_created desc) 说明：Returns"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/browse/new-arrivals" "" "limit=8"
  expect_read_ok "$label" 200
}

# seq708 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public
portal_get_ai_portal_browse_top_liked() {
  local label="GET /_ai/portal/browse/top-liked — 摘要：Get top liked resources (口碑佳作 / Acclaimed Works) 说明：Retur"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/browse/top-liked" "" "limit=8"
  expect_read_ok "$label" 200
}

# seq709 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public
portal_get_ai_portal_categories() {
  local label="GET /_ai/portal/categories — 摘要：Get all asset categories 说明：Returns all asset categories"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/categories" "" ""
  expect_read_ok "$label" 200
}

# seq710 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public
portal_get_ai_portal_featured() {
  local label="GET /_ai/portal/featured — 摘要：Get featured resources for homepage 说明：Returns featured ("
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/featured" "" "limit=20"
  expect_read_ok "$label" 200
}

# seq711 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public
portal_get_ai_portal_featured_best_practices() {
  local label="GET /_ai/portal/featured/best-practices — 摘要：Get featured best practices 说明：Returns featured resources"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/featured/best-practices" "" "limit=6"
  expect_read_ok "$label" 200
}

# seq712 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public（配对清理: POST /_ai/portal/resources/:guid/favorite）
portal_post_ai_portal_resources_guid_favorite() {
  local label="POST /_ai/portal/resources/:guid/favorite — 摘要：Favorite a resource 说明：Records a favorite for the specifi"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  req public POST "/_ai/portal/resources/$(path_id guid)/favorite" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_ai/portal/resources/:guid/favorite
  req public DELETE "/_ai/portal/resources/${rid}/favorite" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req public DELETE "/_ai/portal/resources/${rid}/favorite" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq713 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public
portal_delete_ai_portal_resources_guid_favorite() {
  local label="DELETE /_ai/portal/resources/:guid/favorite — 摘要：Unfavorite a resource 说明：Removes the user's favorite for"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req public DELETE "/_ai/portal/resources/${DUMMY_ID}/favorite" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq714 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public（配对清理: POST /_ai/portal/resources/:guid/like）
portal_post_ai_portal_resources_guid_like() {
  local label="POST /_ai/portal/resources/:guid/like — 摘要：Like a resource 说明：Records a like for the specified resou"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  req public POST "/_ai/portal/resources/$(path_id guid)/like" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_ai/portal/resources/:guid/like
  req public DELETE "/_ai/portal/resources/${rid}/like" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req public DELETE "/_ai/portal/resources/${rid}/like" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq715 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public
portal_delete_ai_portal_resources_guid_like() {
  local label="DELETE /_ai/portal/resources/:guid/like — 摘要：Unlike a resource 说明：Removes the user's like for the spec"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req public DELETE "/_ai/portal/resources/${DUMMY_ID}/like" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq716 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public
portal_get_ai_portal_stats() {
  local label="GET /_ai/portal/stats — 摘要：Get homepage statistics 说明：Returns aggregated platform st"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/stats" "" ""
  expect_read_ok "$label" 200
}

# seq717 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public
portal_get_ai_portal_user_favorites() {
  local label="GET /_ai/portal/user/favorites — 摘要：Get user favorites with pagination 说明：Returns paginated l"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/user/favorites" "" "page=0&size=12"
  expect_read_ok "$label" 200
}

# seq718 asdm-admin-services-core (端口 8880)/Portal Homepage | auth=public
portal_get_ai_portal_user_new_favorites() {
  local label="GET /_ai/portal/user/new-favorites — 摘要：Get user's latest favorites 说明：Merges the current user's"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/user/new-favorites" "" ""
  expect_read_ok "$label" 200
}

# seq719 asdm-admin-services-core (端口 8880)/Portal Resource Detail | auth=public
portal_get_ai_portal_resource_guid_download() {
  local label="GET /_ai/portal/resource/:guid/download — 摘要：Download resource package for portal 说明：Download the asse"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/resource/$(path_id guid)/download" "" ""
  expect_read_ok "$label" 200
}

# seq720 asdm-admin-services-core (端口 8880)/Portal Resource Detail | auth=public
portal_get_ai_portal_resource_type_guid() {
  local label="GET /_ai/portal/resource/:type/:guid — 摘要：Get resource detail for portal 说明：Returns complete detail"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/resource/$(path_id type)/$(path_id guid)" "" ""
  expect_read_ok "$label" 200
}

# seq721 asdm-admin-services-core (端口 8880)/Portal Resource Detail | auth=public
portal_get_ai_portal_resource_type_guid_related() {
  local label="GET /_ai/portal/resource/:type/:guid/related — 摘要：Get related resources for portal detail page 说明：Returns r"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/resource/$(path_id type)/$(path_id guid)/related" "" "limit=4"
  expect_read_ok "$label" 200
}

# seq722 asdm-admin-services-core (端口 8880)/Portal Resource Detail | auth=public
portal_get_ai_portal_resource_agent_configType_guid() {
  local label="GET /_ai/portal/resource/agent/:configType/:guid — 摘要：Get agent installation guide for a resource 说明：Returns th"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/resource/agent/$(path_id configType)/$(path_id guid)" "" "agent=string"
  expect_read_ok "$label" 200
}

# seq723 asdm-admin-services-core (端口 8880)/Portal Settings | auth=public
portal_get_ai_portal_settings_feature_flags_public() {
  local label="GET /_ai/portal/settings/feature-flags/public — 摘要：Get public feature flags 说明：Returns public feature flags"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/settings/feature-flags/public" "" ""
  expect_read_ok "$label" 200
}

# seq724 asdm-admin-services-core (端口 8880)/Portal Settings | auth=public
portal_get_ai_portal_settings_installation_field() {
  local label="GET /_ai/portal/settings/installation-field — 摘要：Get ASDM installation field URL 说明：Returns the installati"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/settings/installation-field" "" ""
  expect_read_ok "$label" 200
}

# seq725 asdm-admin-services-core (端口 8880)/PortalCenter | auth=public
portal_get_ai_portal_my_ai_token_today() {
  local label="GET /_ai/portal/my/ai-token-today — 所属控制器：).</p> 完整路径：GET /_ai/portal/my/ai-token-today（服务：asdm-"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/my/ai-token-today" "" ""
  expect_read_ok "$label" 200
}

# seq726 asdm-admin-services-core (端口 8880)/PortalCenter | auth=public
portal_get_ai_portal_my_all_contribution() {
  local label="GET /_ai/portal/my/all-contribution — 所属控制器：).</p> 完整路径：GET /_ai/portal/my/all-contribution（服务：asd"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/my/all-contribution" "" "page=1&size=20"
  expect_read_ok "$label" 200
}

# seq727 asdm-admin-services-core (端口 8880)/PortalCenter | auth=public
portal_get_ai_portal_my_all_view_history() {
  local label="GET /_ai/portal/my/all-view-history — 所属控制器：).</p> 完整路径：GET /_ai/portal/my/all-view-history（服务：asd"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/my/all-view-history" "" "page=1&size=20&resourceType=all"
  expect_read_ok "$label" 200
}

# seq728 asdm-admin-services-core (端口 8880)/PortalCenter | auth=public
portal_get_ai_portal_my_resource_count() {
  local label="GET /_ai/portal/my/resource-count — 所属控制器：).</p> 完整路径：GET /_ai/portal/my/resource-count（服务：asdm-"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/my/resource-count" "" "type=4"
  expect_read_ok "$label" 200
}

# seq729 asdm-admin-services-core (端口 8880)/PortalCenter | auth=public
portal_get_ai_portal_my_resource_download() {
  local label="GET /_ai/portal/my/resource-download — 所属控制器：).</p> 完整路径：GET /_ai/portal/my/resource-download（服务：as"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/my/resource-download" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq730 asdm-admin-services-core (端口 8880)/PortalCenter | auth=public
portal_get_ai_portal_my_resource_install() {
  local label="GET /_ai/portal/my/resource-install — 所属控制器：).</p> 完整路径：GET /_ai/portal/my/resource-install（服务：asd"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/my/resource-install" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq731 asdm-admin-services-core (端口 8880)/PortalCenter | auth=public
portal_get_ai_portal_my_resource_type_count() {
  local label="GET /_ai/portal/my/resource-type-count — 所属控制器：).</p> 完整路径：GET /_ai/portal/my/resource-type-count（服务："
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/my/resource-type-count" "" "type=4"
  expect_read_ok "$label" 200
}

# seq732 asdm-admin-services-core (端口 8880)/PortalCenter | auth=public
portal_get_ai_portal_my_resource_upload() {
  local label="GET /_ai/portal/my/resource-upload — 所属控制器：).</p> 完整路径：GET /_ai/portal/my/resource-upload（服务：asdm"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/my/resource-upload" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq733 asdm-admin-services-core (端口 8880)/PortalCenter | auth=public
portal_get_ai_portal_my_resource_view() {
  local label="GET /_ai/portal/my/resource-view — 所属控制器：).</p> 完整路径：GET /_ai/portal/my/resource-view（服务：asdm-a"
  need_auth public "$label" || return 0
  req public GET "/_ai/portal/my/resource-view" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq734 asdm-admin-services-portal-backend (端口 8889)/分类管理 | auth=none
portal_get_api_portal_categories() {
  local label="GET /_api/portal/categories — 摘要：分类列表 完整路径：GET /_api/portal/categories（服务：asdm-admin-servi"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/categories" "" ""
  expect_read_ok "$label" 200
}

# seq735 asdm-admin-services-portal-backend (端口 8889)/分类管理 | auth=none（配对清理: POST /_api/portal/categories/:id）
portal_post_api_portal_categories() {
  local label="POST /_api/portal/categories — 摘要：创建分类 说明：name 唯一，冲突返回 409"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "description": "example text"
}
JSONEOF
)"
  req none POST "/_api/portal/categories" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/portal/categories/:id
  req none DELETE "/_api/portal/categories/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/_api/portal/categories/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq736 asdm-admin-services-portal-backend (端口 8889)/分类管理 | auth=none（无配对删除接口，失败请人工核查数据残留）
portal_put_api_portal_categories_id() {
  local label="PUT /_api/portal/categories/:id — 摘要：更新分类 完整路径：PUT /_api/portal/categories/:id（服务：asdm-admin-s"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "description": "example text"
}
JSONEOF
)"
  req none PUT "/_api/portal/categories/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq737 asdm-admin-services-portal-backend (端口 8889)/分类管理 | auth=none
portal_delete_api_portal_categories_id() {
  local label="DELETE /_api/portal/categories/:id — 摘要：删除分类 说明：若仍有文章引用返回 409"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req none DELETE "/_api/portal/categories/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq738 asdm-admin-services-portal-backend (端口 8889)/浏览历史 | auth=none（配对清理: POST /_api/portal/history）
portal_post_api_portal_history() {
  local label="POST /_api/portal/history — 摘要：Record browse history 说明：Record or update a browse histor"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "resourceType": "string",
  "resourceId": "string"
}
JSONEOF
)"
  req none POST "/_api/portal/history" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/portal/history
  req none DELETE "/_api/portal/history" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/_api/portal/history" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq739 asdm-admin-services-portal-backend (端口 8889)/浏览历史 | auth=none
portal_delete_api_portal_history() {
  log_skip "DELETE /_api/portal/history — 永久跳过：静态路径整体删除，无法限定删除范围"
}

# seq740 asdm-admin-services-portal-backend (端口 8889)/浏览历史 | auth=none
portal_get_api_portal_history() {
  local label="GET /_api/portal/history — 摘要：Query browse history 说明：Query the current user's browse h"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/history" "" "limit=20&offset=0"
  expect_read_ok "$label" 200
}

# seq741 asdm-admin-services-portal-backend (端口 8889)/浏览历史 | auth=none
portal_delete_api_portal_history_batch() {
  log_skip "DELETE /_api/portal/history/batch — 永久跳过：静态路径整体删除，无法限定删除范围"
}

# seq742 asdm-admin-services-portal-backend (端口 8889)/浏览历史 | auth=none
portal_get_api_portal_history_setting() {
  local label="GET /_api/portal/history/setting — 摘要：Get tracking setting 说明：Get the browse history tracking s"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/history/setting" "" ""
  expect_read_ok "$label" 200
}

# seq743 asdm-admin-services-portal-backend (端口 8889)/浏览历史 | auth=none（无配对删除接口，失败请人工核查数据残留）
portal_put_api_portal_history_setting() {
  local label="PUT /_api/portal/history/setting — 摘要：Update tracking setting 说明：Enable or disable browse histo"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none PUT "/_api/portal/history/setting" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq744 asdm-admin-services-portal-backend (端口 8889)/门户智能体空间 | auth=none
portal_get_api_portal_agent_spaces() {
  local label="GET /_api/portal/agent-spaces — 摘要：智能体空间目录（匿名可见） 说明：代理 core GET /_ai/portal/agent-spaces：匿名仅"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/agent-spaces" "" ""
  expect_read_ok "$label" 200
}

# seq745 asdm-admin-services-portal-backend (端口 8889)/门户智能体空间 | auth=none
portal_get_api_portal_agent_spaces_workspaceId() {
  local label="GET /_api/portal/agent-spaces/:workspaceId — 摘要：智能体空间详情 说明：代理 core GET /_ai/portal/agent-spaces/{workspac"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/agent-spaces/$(path_id workspaceId)" "" ""
  expect_read_ok "$label" 200
}

# seq746 asdm-admin-services-portal-backend (端口 8889)/门户智能体空间 | auth=none（无配对删除接口，失败请人工核查数据残留）
portal_post_api_portal_agent_spaces_workspaceId_ensure_instance() {
  local label="POST /_api/portal/agent-spaces/:workspaceId/ensure-instance — 摘要：确保智能体空间实例（登录） 说明：代理 AgentOrbit ensure-instance，返回 Twin 详情"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  req none POST "/_api/portal/agent-spaces/$(path_id workspaceId)/ensure-instance" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq747 asdm-admin-services-portal-backend (端口 8889)/门户智能体空间 | auth=none（无配对删除接口，失败请人工核查数据残留）
portal_post_api_portal_agent_spaces_workspaceId_enter_member() {
  local label="POST /_api/portal/agent-spaces/:workspaceId/enter-member — 摘要：进入智能体空间（登录） 说明：代理 AgentOrbit enter-member，返回 embeddingUrl"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none POST "/_api/portal/agent-spaces/$(path_id workspaceId)/enter-member" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq748 asdm-admin-services-portal-backend (端口 8889)/门户智能体空间 | auth=none
portal_get_api_portal_agent_spaces_workspaceId_resources() {
  local label="GET /_api/portal/agent-spaces/:workspaceId/resources — 摘要：智能体空间资源构成 说明：代理 core GET /_ai/portal/agent-spaces/{worksp"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/agent-spaces/$(path_id workspaceId)/resources" "" ""
  expect_read_ok "$label" 200
}

# seq749 asdm-admin-services-portal-backend (端口 8889)/门户资源 | auth=none
portal_get_api_portal_resources() {
  local label="GET /_api/portal/resources — 摘要：分页浏览社区资源 说明：代理 core GET /_ai/portal/browse（FT-8718）。登录用户按"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/resources" "" ""
  expect_read_ok "$label" 200
}

# seq750 asdm-admin-services-portal-backend (端口 8889)/图片上传 | auth=none（无配对删除接口，失败请人工核查数据残留）
portal_post_api_portal_images_upload() {
  local label="POST /_api/portal/images/upload — 摘要：上传图片 说明：支持 jpg/png/gif/webp，最大 10MB；内部 m2m 调用 file-servic"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  req none POST "/_api/portal/images/upload" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq751 asdm-admin-services-portal-backend (端口 8889)/文章标签 | auth=none
portal_get_api_portal_tags_mine() {
  local label="GET /_api/portal/tags/mine — 摘要：我用过的标签 说明：返回当前登录用户在未删除文章上用过的标签，按使用次数降序；适合一次拉取后本地过滤"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/tags/mine" "" ""
  expect_read_ok "$label" 200
}

# seq752 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none（配对清理: POST /_api/portal/articles/:id）
portal_post_api_portal_articles() {
  local label="POST /_api/portal/articles — 摘要：创建文章 说明：status 可为 draft 或 published"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "title": "example__RUN_ID__",
 "content": "example text",
 "summary": "example text",
 "categoryId": 1,
 "status": "string"
}
JSONEOF
)"
  req none POST "/_api/portal/articles" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/portal/articles/:id
  req none DELETE "/_api/portal/articles/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/_api/portal/articles/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq753 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_get_api_portal_articles() {
  local label="GET /_api/portal/articles — 摘要：全局已发布文章列表 说明：仅返回 status=published 且未删除的文章，按 createdAt DES"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/articles" "" ""
  expect_read_ok "$label" 200
}

# seq754 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_get_api_portal_articles_id() {
  local label="GET /_api/portal/articles/:id — 摘要：文章详情 说明：公开可读；已删除文章仅作者可预览"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/articles/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq755 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none（无配对删除接口，失败请人工核查数据残留）
portal_put_api_portal_articles_id() {
  local label="PUT /_api/portal/articles/:id — 摘要：更新文章 说明：仅作者可操作"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "title": "example__RUN_ID__",
 "content": "example text",
 "summary": "example text",
 "categoryId": 1,
 "status": "string"
}
JSONEOF
)"
  req none PUT "/_api/portal/articles/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq756 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_delete_api_portal_articles_id() {
  local label="DELETE /_api/portal/articles/:id — 摘要：删除文章（逻辑删除） 说明：status→deleted，写入 status_before_delete；置 de"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req none DELETE "/_api/portal/articles/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq757 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_get_api_portal_articles_id_edit() {
  local label="GET /_api/portal/articles/:id/edit — 摘要：获取编辑数据 说明：仅作者可访问"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/articles/$(path_id id)/edit" "" ""
  expect_read_ok "$label" 200
}

# seq758 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none（配对清理: POST /_api/portal/articles/:id/favorite）
portal_post_api_portal_articles_id_favorite() {
  local label="POST /_api/portal/articles/:id/favorite — 摘要：收藏 说明：INSERT IGNORE 幂等"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  req none POST "/_api/portal/articles/$(path_id id)/favorite" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/portal/articles/:id/favorite
  req none DELETE "/_api/portal/articles/${rid}/favorite" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/_api/portal/articles/${rid}/favorite" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq759 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_delete_api_portal_articles_id_favorite() {
  local label="DELETE /_api/portal/articles/:id/favorite — 摘要：取消收藏 说明：幂等"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req none DELETE "/_api/portal/articles/${DUMMY_ID}/favorite" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq760 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none（配对清理: POST /_api/portal/articles/:id/like）
portal_post_api_portal_articles_id_like() {
  local label="POST /_api/portal/articles/:id/like — 摘要：点赞 说明：INSERT IGNORE 幂等"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  req none POST "/_api/portal/articles/$(path_id id)/like" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/portal/articles/:id/like
  req none DELETE "/_api/portal/articles/${rid}/like" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/_api/portal/articles/${rid}/like" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq761 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_delete_api_portal_articles_id_like() {
  local label="DELETE /_api/portal/articles/:id/like — 摘要：取消点赞 说明：幂等"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req none DELETE "/_api/portal/articles/${DUMMY_ID}/like" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq762 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none（配对清理: POST /_api/portal/articles/:id/pin）
portal_post_api_portal_articles_id_pin() {
  local label="POST /_api/portal/articles/:id/pin — 摘要：置顶文章 说明：运营精选，首页热门列表优先展示并打「热门推荐」角标"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  req none POST "/_api/portal/articles/$(path_id id)/pin" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/portal/articles/:id/pin
  req none DELETE "/_api/portal/articles/${rid}/pin" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/_api/portal/articles/${rid}/pin" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq763 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_delete_api_portal_articles_id_pin() {
  local label="DELETE /_api/portal/articles/:id/pin — 摘要：取消置顶 完整路径：DELETE /_api/portal/articles/:id/pin（服务：asdm-ad"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req none DELETE "/_api/portal/articles/${DUMMY_ID}/pin" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq764 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_post_api_portal_articles_id_restore() {
  log_skip "POST /_api/portal/articles/:id/restore — 永久跳过：路径含状态变更/清理类操作段（restore），避免破坏环境"
}

# seq765 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none（配对清理: POST /_api/portal/articles/:id/favorite）
portal_post_api_portal_articles_id_view() {
  local label="POST /_api/portal/articles/:id/view — 摘要：上报阅读量 说明：PV +1，不去重"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  req none POST "/_api/portal/articles/$(path_id id)/view" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/portal/articles/:id/favorite
  req none DELETE "/_api/portal/articles/${rid}/favorite" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/_api/portal/articles/${rid}/favorite" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq766 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_get_api_portal_articles_author_counts() {
  local label="GET /_api/portal/articles/author-counts — 摘要：发布过最佳实践的人数 说明：返回去重作者数；不限 status，已删除文章也计入"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/articles/author-counts" "" ""
  expect_read_ok "$label" 200
}

# seq767 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_get_api_portal_articles_by_resource() {
  local label="GET /_api/portal/articles/by-resource — 摘要：按资源 GUID 查询关联最佳实践 说明：根据 article_resource_links.resource_g"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/articles/by-resource" "" "resourceGuids=string"
  expect_read_ok "$label" 200
}

# seq768 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_get_api_portal_articles_counts() {
  local label="GET /_api/portal/articles/counts — 摘要：全局已发布文章数量 说明：返回 status=published 且未删除的文章总数"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/articles/counts" "" ""
  expect_read_ok "$label" 200
}

# seq769 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_get_api_portal_articles_hot() {
  local label="GET /_api/portal/articles/hot — 摘要：热门最佳实践 说明：按 article_stats 点赞数、阅读数降序取 Top N（默认 3）；首条 hotRe"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/articles/hot" "" ""
  expect_read_ok "$label" 200
}

# seq770 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_get_api_portal_articles_my() {
  local label="GET /_api/portal/articles/my — 摘要：我的文章列表 说明：返回当前用户的文章；不传 status 时含已逻辑删除；status=deleted 仅返回已"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/articles/my" "" ""
  expect_read_ok "$label" 200
}

# seq771 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_get_api_portal_articles_my_counts() {
  local label="GET /_api/portal/articles/my/counts — 摘要：我的文章数量统计 说明：按 status 返回当前用户各状态文章数量及总数（含已删除）；type 用于按发布时间窗"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/articles/my/counts" "" ""
  expect_read_ok "$label" 200
}

# seq772 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_get_api_portal_articles_my_favorites() {
  local label="GET /_api/portal/articles/my/favorites — 摘要：我的收藏文章列表 说明：返回当前用户收藏的已发布文章，按收藏时间倒序排列"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/articles/my/favorites" "" ""
  expect_read_ok "$label" 200
}

# seq773 asdm-admin-services-portal-backend (端口 8889)/文章管理 | auth=none
portal_get_api_portal_articles_search() {
  local label="GET /_api/portal/articles/search — 摘要：全文搜索文章 说明：默认 MySQL 模糊匹配 title/summary/tags；asdm.portal.se"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/articles/search" "" ""
  expect_read_ok "$label" 200
}

# seq774 asdm-admin-services-portal-backend (端口 8889)/知识中心 | auth=none
portal_get_api_portal_knowledge_graphs() {
  local label="GET /_api/portal/knowledge/graphs — 摘要：用户可见图目录 说明：需登录（Authorization: Bearer JWT/PAT）。按项目权限过滤可加载图"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/knowledge/graphs" "" ""
  expect_read_ok "$label" 200
}

# seq775 asdm-admin-services-portal-backend (端口 8889)/知识中心 | auth=none
portal_get_api_portal_knowledge_items_itemId_artifacts() {
  local label="GET /_api/portal/knowledge/items/:itemId/artifacts — 摘要：条目产物列表（C5） 说明：type ∈ file|codebase|ddl，非法值返回 40205；url 类型"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/knowledge/items/$(path_id itemId)/artifacts" "" "type=string"
  expect_read_ok "$label" 200
}

# seq776 asdm-admin-services-portal-backend (端口 8889)/知识中心 | auth=none
portal_get_api_portal_knowledge_items_itemId_artifacts_file_artifactId() {
  local label="GET /_api/portal/knowledge/items/:itemId/artifacts/file/:artifactId/content — 摘要：文件产物内容（C6） 说明：文本预览；path 为压缩包内条目路径（可选）"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/knowledge/items/$(path_id itemId)/artifacts/file/$(path_id artifactId)/content" "" ""
  expect_read_ok "$label" 200
}

# seq777 asdm-admin-services-portal-backend (端口 8889)/知识中心 | auth=none
portal_get_api_portal_knowledge_projects() {
  local label="GET /_api/portal/knowledge/projects — 摘要：项目列表（C1） 说明：分页参数 page（从 1 起，默认 1）/ size（默认 6）；筛选参数 keywor"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/knowledge/projects" "" "page=1&size=6"
  expect_read_ok "$label" 200
}

# seq778 asdm-admin-services-portal-backend (端口 8889)/知识中心 | auth=none
portal_get_api_portal_knowledge_projects_projectId() {
  local label="GET /_api/portal/knowledge/projects/:projectId — 摘要：项目详情（C2） 完整路径：GET /_api/portal/knowledge/projects/:projec"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/knowledge/projects/$(path_id projectId)" "" ""
  expect_read_ok "$label" 200
}

# seq779 asdm-admin-services-portal-backend (端口 8889)/知识中心 | auth=none
portal_get_api_portal_knowledge_projects_projectId_spaces() {
  local label="GET /_api/portal/knowledge/projects/:projectId/spaces — 摘要：项目下知识空间列表（C3） 完整路径：GET /_api/portal/knowledge/projects/:p"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/knowledge/projects/$(path_id projectId)/spaces" "" ""
  expect_read_ok "$label" 200
}

# seq780 asdm-admin-services-portal-backend (端口 8889)/知识中心 | auth=none
portal_get_api_portal_knowledge_spaces_spaceId_access() {
  local label="GET /_api/portal/knowledge/spaces/:spaceId/access — 摘要：知识空间访问校验 说明：需登录。校验当前用户是否有权访问该空间所属项目。"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/knowledge/spaces/$(path_id spaceId)/access" "" ""
  expect_read_ok "$label" 200
}

# seq781 asdm-admin-services-portal-backend (端口 8889)/知识中心 | auth=none
portal_get_api_portal_knowledge_spaces_spaceId_artifacts() {
  local label="GET /_api/portal/knowledge/spaces/:spaceId/artifacts — 摘要：空间级批量文件产物（图模块） 说明：一次性返回空间内所有 graph 条目的 file 产物（按条目分组），替代逐"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/knowledge/spaces/$(path_id spaceId)/artifacts" "" "type=string"
  expect_read_ok "$label" 200
}

# seq782 asdm-admin-services-portal-backend (端口 8889)/知识中心 | auth=none
portal_get_api_portal_knowledge_spaces_spaceId_items() {
  local label="GET /_api/portal/knowledge/spaces/:spaceId/items — 摘要：空间条目列表（C4） 说明：includeGraph=true 时返回 type=graph 条目（图模块需要，知"
  need_auth none "$label" || return 0
  req none GET "/_api/portal/knowledge/spaces/$(path_id spaceId)/items" "" "includeGraph=false"
  expect_read_ok "$label" 200
}

# seq783 asdm-admin-services-portal-backend (端口 8889)/最佳实践管理（平台管理员） | auth=none
portal_get_api_admin_articles_2() {
  local label="GET /_api/admin/articles — 摘要：全平台最佳实践列表 说明：支持关键词/状态/标签/分类筛选与排序，分页返回，不含已逻辑删除文章"
  need_auth none "$label" || return 0
  req none GET "/_api/admin/articles" "" "sort=time"
  expect_read_ok "$label" 200
}

# seq784 asdm-admin-services-portal-backend (端口 8889)/最佳实践管理（平台管理员） | auth=none
portal_post_api_admin_articles_id_restore_2() {
  log_skip "POST /_api/admin/articles/:id/restore — 永久跳过：路径含状态变更/清理类操作段（restore），避免破坏环境"
}

# seq785 asdm-admin-services-portal-backend (端口 8889)/最佳实践管理（平台管理员） | auth=none（无配对删除接口，失败请人工核查数据残留）
portal_post_api_admin_articles_batch_delete_2() {
  local label="POST /_api/admin/articles/batch-delete — 摘要：批量删除最佳实践 说明：仅逻辑删除文章（status→deleted），不删除关联资源。单次最多 200 篇"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "ids": [
    1
  ]
}
JSONEOF
)"
  req none POST "/_api/admin/articles/batch-delete" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq786 asdm-admin-services-portal-backend (端口 8889)/AI 最佳实践 | auth=none
portal_get_ai_practices_id() {
  local label="GET /_ai/practices/:id — 摘要：获取最佳实践 Markdown 说明：仅返回已发布文章；可选 agent 用于生成关联资源的 asdm cli 安"
  need_auth none "$label" || return 0
  req none GET "/_ai/practices/$(path_id id)" "" "agent=codebuddy"
  expect_read_ok "$label" 200
}

# seq787 asdm-admin-services-portal-backend (端口 8889)/ES Connector Stub | auth=none（无配对删除接口，失败请人工核查数据残留）
portal_post_api_es_document() {
  local label="POST /api/es/document — 摘要：插入文档 完整路径：POST /api/es/document（服务：asdm-admin-services-po"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "indexName": "example",
  "id": "string",
  "document": "string"
}
JSONEOF
)"
  req none POST "/api/es/document" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq788 asdm-admin-services-portal-backend (端口 8889)/ES Connector Stub | auth=none（无配对删除接口，失败请人工核查数据残留）
portal_put_api_es_document() {
  local label="PUT /api/es/document — 摘要：更新文档 完整路径：PUT /api/es/document（服务：asdm-admin-services-por"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "indexName": "example",
  "id": "string",
  "document": "string"
}
JSONEOF
)"
  req none PUT "/api/es/document" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq789 asdm-admin-services-portal-backend (端口 8889)/ES Connector Stub | auth=none
portal_get_api_es_document_indexName_id() {
  local label="GET /api/es/document/:indexName/:id — 摘要：根据ID查询文档 完整路径：GET /api/es/document/:indexName/:id（服务：asdm"
  need_auth none "$label" || return 0
  req none GET "/api/es/document/$(path_id indexName)/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq790 asdm-admin-services-portal-backend (端口 8889)/ES Connector Stub | auth=none
portal_delete_api_es_document_indexName_id() {
  local label="DELETE /api/es/document/:indexName/:id — 摘要：删除文档 完整路径：DELETE /api/es/document/:indexName/:id（服务：asdm-"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req none DELETE "/api/es/document/${DUMMY_ID}/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq791 asdm-admin-services-portal-backend (端口 8889)/ES Connector Stub | auth=none
portal_get_api_es_mapping_indexName() {
  local label="GET /api/es/mapping/:indexName — 摘要：查询索引 Mapping 完整路径：GET /api/es/mapping/:indexName（服务：asdm-"
  need_auth none "$label" || return 0
  req none GET "/api/es/mapping/$(path_id indexName)" "" ""
  expect_read_ok "$label" 200
}

# seq792 asdm-admin-services-portal-backend (端口 8889)/ES Connector Stub | auth=none（无配对删除接口，失败请人工核查数据残留）
portal_post_api_es_search() {
  local label="POST /api/es/search — 摘要：搜索文档（整段 ES DSL） 完整路径：POST /api/es/search（服务：asdm-admin-se"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "indexName": "example",
  "queryString": "string",
  "start": 1,
  "rows": 1
}
JSONEOF
)"
  req none POST "/api/es/search" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq793 asdm-admin-services-portal-backend (端口 8889)/ES Connector Stub Health | auth=none
portal_get_health() {
  local label="GET /health — 摘要：健康检查 完整路径：GET /health（服务：asdm-admin-services-portal-backe"
  need_auth none "$label" || return 0
  req none GET "/health" "" ""
  expect_read_ok "$label" 200
}

# ===== 入口 =====
main() {
  set +e   # 单用例失败不中断
  echo ""
  echo "========== 门户与内容域 (97 apis) =========="
  login_if_needed || true
  portal_get_ai_portal_agent_spaces || true
  portal_get_ai_portal_agent_spaces_workspaceId || true
  portal_get_ai_portal_agent_spaces_workspaceId_resources || true
  portal_get_ai_portal_leaderboard || true
  portal_get_api_admin_articles || true
  portal_post_api_admin_articles_id_restore || true
  portal_post_api_admin_articles_batch_delete || true
  portal_get_ai_portal_browse || true
  portal_get_ai_portal_browse_hot_downloads || true
  portal_get_ai_portal_browse_hot_recommendations || true
  portal_get_ai_portal_browse_new_arrivals || true
  portal_get_ai_portal_browse_top_liked || true
  portal_get_ai_portal_categories || true
  portal_get_ai_portal_featured || true
  portal_get_ai_portal_featured_best_practices || true
  portal_post_ai_portal_resources_guid_favorite || true
  portal_delete_ai_portal_resources_guid_favorite || true
  portal_post_ai_portal_resources_guid_like || true
  portal_delete_ai_portal_resources_guid_like || true
  portal_get_ai_portal_stats || true
  portal_get_ai_portal_user_favorites || true
  portal_get_ai_portal_user_new_favorites || true
  portal_get_ai_portal_resource_guid_download || true
  portal_get_ai_portal_resource_type_guid || true
  portal_get_ai_portal_resource_type_guid_related || true
  portal_get_ai_portal_resource_agent_configType_guid || true
  portal_get_ai_portal_settings_feature_flags_public || true
  portal_get_ai_portal_settings_installation_field || true
  portal_get_ai_portal_my_ai_token_today || true
  portal_get_ai_portal_my_all_contribution || true
  portal_get_ai_portal_my_all_view_history || true
  portal_get_ai_portal_my_resource_count || true
  portal_get_ai_portal_my_resource_download || true
  portal_get_ai_portal_my_resource_install || true
  portal_get_ai_portal_my_resource_type_count || true
  portal_get_ai_portal_my_resource_upload || true
  portal_get_ai_portal_my_resource_view || true
  portal_get_api_portal_categories || true
  portal_post_api_portal_categories || true
  portal_put_api_portal_categories_id || true
  portal_delete_api_portal_categories_id || true
  portal_post_api_portal_history || true
  portal_delete_api_portal_history || true
  portal_get_api_portal_history || true
  portal_delete_api_portal_history_batch || true
  portal_get_api_portal_history_setting || true
  portal_put_api_portal_history_setting || true
  portal_get_api_portal_agent_spaces || true
  portal_get_api_portal_agent_spaces_workspaceId || true
  portal_post_api_portal_agent_spaces_workspaceId_ensure_instance || true
  portal_post_api_portal_agent_spaces_workspaceId_enter_member || true
  portal_get_api_portal_agent_spaces_workspaceId_resources || true
  portal_get_api_portal_resources || true
  portal_post_api_portal_images_upload || true
  portal_get_api_portal_tags_mine || true
  portal_post_api_portal_articles || true
  portal_get_api_portal_articles || true
  portal_get_api_portal_articles_id || true
  portal_put_api_portal_articles_id || true
  portal_delete_api_portal_articles_id || true
  portal_get_api_portal_articles_id_edit || true
  portal_post_api_portal_articles_id_favorite || true
  portal_delete_api_portal_articles_id_favorite || true
  portal_post_api_portal_articles_id_like || true
  portal_delete_api_portal_articles_id_like || true
  portal_post_api_portal_articles_id_pin || true
  portal_delete_api_portal_articles_id_pin || true
  portal_post_api_portal_articles_id_restore || true
  portal_post_api_portal_articles_id_view || true
  portal_get_api_portal_articles_author_counts || true
  portal_get_api_portal_articles_by_resource || true
  portal_get_api_portal_articles_counts || true
  portal_get_api_portal_articles_hot || true
  portal_get_api_portal_articles_my || true
  portal_get_api_portal_articles_my_counts || true
  portal_get_api_portal_articles_my_favorites || true
  portal_get_api_portal_articles_search || true
  portal_get_api_portal_knowledge_graphs || true
  portal_get_api_portal_knowledge_items_itemId_artifacts || true
  portal_get_api_portal_knowledge_items_itemId_artifacts_file_artifactId || true
  portal_get_api_portal_knowledge_projects || true
  portal_get_api_portal_knowledge_projects_projectId || true
  portal_get_api_portal_knowledge_projects_projectId_spaces || true
  portal_get_api_portal_knowledge_spaces_spaceId_access || true
  portal_get_api_portal_knowledge_spaces_spaceId_artifacts || true
  portal_get_api_portal_knowledge_spaces_spaceId_items || true
  portal_get_api_admin_articles_2 || true
  portal_post_api_admin_articles_id_restore_2 || true
  portal_post_api_admin_articles_batch_delete_2 || true
  portal_get_ai_practices_id || true
  portal_post_api_es_document || true
  portal_put_api_es_document || true
  portal_get_api_es_document_indexName_id || true
  portal_delete_api_es_document_indexName_id || true
  portal_get_api_es_mapping_indexName || true
  portal_post_api_es_search || true
  portal_get_health || true
  finish
}
main "$@"
