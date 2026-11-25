#!/usr/bin/env bash
# ============================================================================
# 认证授权域 — 幂等自动化测试（由 gen/generate.js 从 api.json 生成，勿手工修改）
# 重新生成: node gen/generate.js
# 覆盖服务: core, sso
# 接口总数: 53（读 32 直测 / 写 18 受控[含配对清理 6] / 永久跳过 3）
# 环境变量: ASDM_BASE_URL / ASDM_LOGIN_EMAIL / ASDM_LOGIN_PASSWORD / ASDM_TOKEN /
#           ASDM_PAT / ASDM_INTERNAL_TOKEN / ASDM_OPEN_ACCESS_TOKEN / ASDM_CITIC_SECRET /
#           ASDM_ALLOW_WRITES=1（执行写操作）/ ASDM_TEST_<参数名>（路径参数覆盖）
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ===== 被测接口用例 =====
# seq1 asdm-admin-services-core (端口 8880)/Authentication | auth=jwt
auth_post_api_auth_change_password() {
  log_skip "POST /api/auth/change-password — 永久跳过：修改真实账号密码，禁止自动执行"
}

# seq2 asdm-admin-services-core (端口 8880)/Authentication | auth=public
auth_post_api_auth_login() {
  # 登录前置：已由 login_if_needed() 覆盖（失败会在控制台与汇总中体现）
  if [[ -n "$TOKEN" ]]; then
    log_pass "POST /api/auth/login — 已由 login_if_needed 覆盖（ASDM_TOKEN 或登录成功）"
  else
    log_skip "POST /api/auth/login — 登录失败，见 login_if_needed 输出"
  fi
}

# seq3 asdm-admin-services-core (端口 8880)/Authentication | auth=jwt
auth_get_api_auth_me() {
  local label="GET /api/auth/me — 摘要：Get Current User 说明：Get current logged-in user info based"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/me" "" ""
  expect_read_ok "$label" 200
}

# seq4 asdm-admin-services-core (端口 8880)/Authentication | auth=jwt（无配对删除接口，失败请人工核查数据残留）
auth_put_api_auth_me() {
  local label="PUT /api/auth/me — 摘要：Update Current User Profile 说明：Update current user's firs"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "firstName": "example",
  "lastName": "example",
  "status": 1
}
JSONEOF
)"
  req jwt PUT "/api/auth/me" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq5 asdm-admin-services-core (端口 8880)/Authentication | auth=public
auth_post_api_auth_register() {
  log_skip "POST /api/auth/register — 永久跳过：创建真实用户且无自清理接口（SIT 注册通常禁用，可用 register-status 预检）"
}

# seq6 asdm-admin-services-core (端口 8880)/Authentication | auth=public
auth_get_api_auth_register_status() {
  local label="GET /api/auth/register-status — 摘要：Registration availability 说明：Public: whether self-service"
  need_auth public "$label" || return 0
  req public GET "/api/auth/register-status" "" ""
  expect_read_ok "$label" 200
}

# seq7 asdm-admin-services-core (端口 8880)/Authentication | auth=jwt
auth_get_api_auth_session() {
  local label="GET /api/auth/session — 摘要：Get Current Session 说明：Get current logged-in user info an"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/session" "" ""
  expect_read_ok "$label" 200
}

# seq8 asdm-admin-services-core (端口 8880)/Authentication | auth=public
auth_get_api_auth_verify() {
  local label="GET /api/auth/verify — 完整路径：GET /api/auth/verify（服务：asdm-admin-services-core，端口 888"
  need_auth public "$label" || return 0
  req public GET "/api/auth/verify" "" ""
  expect_read_ok "$label" 200
}

# seq9 asdm-admin-services-core (端口 8880)/DeviceAuth | auth=public（无配对删除接口，失败请人工核查数据残留）
auth_post_api_auth_device_bind_state() {
  local label="POST /api/auth/device/bind-state — 完整路径：POST /api/auth/device/bind-state（服务：asdm-admin-services"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "state": "string"
}
JSONEOF
)"
  req public POST "/api/auth/device/bind-state" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq10 asdm-admin-services-core (端口 8880)/DeviceAuth | auth=public（无配对删除接口，失败请人工核查数据残留）
auth_post_api_auth_device_code() {
  local label="POST /api/auth/device/code — 完整路径：POST /api/auth/device/code（服务：asdm-admin-services-core，"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "platform": "string"
}
JSONEOF
)"
  req public POST "/api/auth/device/code" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq11 asdm-admin-services-core (端口 8880)/DeviceAuth | auth=public（无配对删除接口，失败请人工核查数据残留）
auth_post_api_auth_device_token() {
  local label="POST /api/auth/device/token — 完整路径：POST /api/auth/device/token（服务：asdm-admin-services-core"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "platform": "string",
  "deviceCode": "string"
}
JSONEOF
)"
  req public POST "/api/auth/device/token" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq12 asdm-admin-services-core (端口 8880)/PersonalAccessToken | auth=jwt（配对清理: POST /api/auth/personal-access-tokens/:id）
auth_post_api_auth_personal_access_tokens() {
  local label="POST /api/auth/personal-access-tokens — 完整路径：POST /api/auth/personal-access-tokens（服务：asdm-admin-ser"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "expiresAt": "2099-01-01T00:00:00"
}
JSONEOF
)"
  req jwt POST "/api/auth/personal-access-tokens" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/auth/personal-access-tokens/:id
  req jwt DELETE "/api/auth/personal-access-tokens/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/auth/personal-access-tokens/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq13 asdm-admin-services-core (端口 8880)/PersonalAccessToken | auth=jwt
auth_get_api_auth_personal_access_tokens() {
  local label="GET /api/auth/personal-access-tokens — 完整路径：GET /api/auth/personal-access-tokens（服务：asdm-admin-serv"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/personal-access-tokens" "" "page=0&pageSize=0&status=string"
  expect_read_ok "$label" 200
}

# seq14 asdm-admin-services-core (端口 8880)/PersonalAccessToken | auth=jwt
auth_delete_api_auth_personal_access_tokens_id() {
  local label="DELETE /api/auth/personal-access-tokens/:id — 完整路径：DELETE /api/auth/personal-access-tokens/:id（服务：asdm-adm"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/auth/personal-access-tokens/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq15 asdm-admin-services-core (端口 8880)/PersonalAccessToken | auth=jwt
auth_post_api_auth_personal_access_tokens_id_reset() {
  log_skip "POST /api/auth/personal-access-tokens/:id/reset — 永久跳过：路径含状态变更/清理类操作段（reset），避免破坏环境"
}

# seq16 asdm-admin-services-core (端口 8880)/PersonalAccessToken | auth=pat（配对清理: POST /api/auth/personal-access-tokens/:id）
auth_post_api_auth_personal_access_tokens_exchange() {
  local label="POST /api/auth/personal-access-tokens/exchange — 完整路径：POST /api/auth/personal-access-tokens/exchange（服务：asdm-"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  req pat POST "/api/auth/personal-access-tokens/exchange" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/auth/personal-access-tokens/:id
  req jwt DELETE "/api/auth/personal-access-tokens/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/auth/personal-access-tokens/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq17 asdm-admin-services-core (端口 8880)/PersonalAccessToken | auth=public（配对清理: POST /api/auth/personal-access-tokens/:id）
auth_post_api_auth_personal_access_tokens_lookup() {
  local label="POST /api/auth/personal-access-tokens/lookup — 完整路径：POST /api/auth/personal-access-tokens/lookup（服务：asdm-ad"
  writes_allowed "$label" || return 0
  need_auth public "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req public POST "/api/auth/personal-access-tokens/lookup" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/auth/personal-access-tokens/:id
  req jwt DELETE "/api/auth/personal-access-tokens/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/auth/personal-access-tokens/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq18 asdm-admin-services-core (端口 8880)/Project Role Management | auth=jwt
auth_get_api_projects_projectId_members() {
  local label="GET /_api/projects/:projectId/members — 摘要：Get project member list 说明：Returns all members of a proje"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/projects/$(path_id projectId)/members" "" ""
  expect_read_ok "$label" 200
}

# seq19 asdm-admin-services-core (端口 8880)/Project Role Management | auth=jwt（配对清理: POST /_api/projects/:projectId/members/batch）
auth_post_api_projects_projectId_members_batch() {
  local label="POST /_api/projects/:projectId/members/batch — 摘要：Batch grant project roles 说明：Grant project roles to one o"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "userIds": [
    1
  ],
  "role": "string",
  "managedResourceTypes": [
    "string"
  ]
}
JSONEOF
)"
  req jwt POST "/_api/projects/$(path_id projectId)/members/batch" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/projects/:projectId/members/batch
  req jwt DELETE "/_api/projects/${rid}/members/batch" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/_api/projects/${rid}/members/batch" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq20 asdm-admin-services-core (端口 8880)/Project Role Management | auth=jwt
auth_delete_api_projects_projectId_members_batch() {
  local label="DELETE /_api/projects/:projectId/members/batch — 摘要：Batch remove project roles 说明：Remove project roles from o"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/_api/projects/${DUMMY_ID}/members/batch" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq21 asdm-admin-services-core (端口 8880)/Project Role Management | auth=jwt
auth_get_api_projects_projectId_members_search() {
  local label="GET /_api/projects/:projectId/members/search — 摘要：Search project members 说明：Search contributor and readonly"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/projects/$(path_id projectId)/members/search" "" "search=string&page=0&size=10"
  expect_read_ok "$label" 200
}

# seq22 asdm-admin-services-core (端口 8880)/Project Top Role | auth=jwt
auth_get_api_auth_projects_uid_projectUid_top_role() {
  local label="GET /_api/auth/projects/uid/:projectUid/top-role — 摘要：Get current user's top role in project 说明：Returns the hig"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/auth/projects/uid/$(path_id projectUid)/top-role" "" ""
  expect_read_ok "$label" 200
}

# seq23 asdm-admin-services-core (端口 8880)/Rule Mapping Preview | auth=jwt（无配对删除接口，失败请人工核查数据残留）
auth_post_api_admin_users_userId_org_admin_reachability_check() {
  local label="POST /_api/admin/users/:userId/org-admin-reachability:check — 摘要：Check org-admin reachability per collection (super-admin)"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{}
JSONEOF
)"
  req jwt POST "/_api/admin/users/$(path_id userId)/org-admin-reachability:check" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq24 asdm-admin-services-core (端口 8880)/Rule Mapping Preview | auth=jwt（无配对删除接口，失败请人工核查数据残留）
auth_post_api_admin_users_userId_rule_mappings_preview() {
  local label="POST /_api/admin/users/:userId/rule-mappings:preview — 摘要：Preview rule mapping batch (super-admin) 完整路径：POST /_api/"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "requestId": "asdm-shell-idem-fixed",
 "firstName": "example",
 "lastName": "example",
 "confirmReachabilityReconcile": true,
 "action": "string",
 "mappingId": 1,
 "ruleName": "example",
 "collectionId": "string",
 "projectId": "string",
 "managedResourceTypes": [
  "string"
 ],
 "clientRowId": "string"
}
JSONEOF
)"
  req jwt POST "/_api/admin/users/$(path_id userId)/rule-mappings:preview" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq25 asdm-admin-services-core (端口 8880)/Rule Mapping Preview | auth=jwt（无配对删除接口，失败请人工核查数据残留）
auth_post_api_users_userId_org_admin_reachability_check() {
  local label="POST /_api/users/:userId/org-admin-reachability:check — 摘要：Check org-admin reachability per collection (org/project"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{}
JSONEOF
)"
  req jwt POST "/_api/users/$(path_id userId)/org-admin-reachability:check" "$body" "collectionId=string"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq26 asdm-admin-services-core (端口 8880)/Rule Mapping Preview | auth=jwt（无配对删除接口，失败请人工核查数据残留）
auth_post_api_users_userId_rule_mappings_preview() {
  local label="POST /_api/users/:userId/rule-mappings:preview — 摘要：Preview scoped rule mapping batch (org/project admin) 完整路"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "requestId": "asdm-shell-idem-fixed",
 "firstName": "example",
 "lastName": "example",
 "confirmReachabilityReconcile": true,
 "action": "string",
 "mappingId": 1,
 "ruleName": "example",
 "collectionId": "string",
 "projectId": "string",
 "managedResourceTypes": [
  "string"
 ],
 "clientRowId": "string"
}
JSONEOF
)"
  req jwt POST "/_api/users/$(path_id userId)/rule-mappings:preview" "$body" "collectionId=string"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq27 asdm-admin-services-core (端口 8880)/SSO用户管理 | auth=jwt（配对清理: POST /api/users-sso/:id）
auth_post_api_users_sso() {
  local label="POST /api/users-sso — 摘要：创建SSO预创建用户 说明：创建一个新的SSO预创建用户记录"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "iamLoginNo": "string",
 "email": "auto___RUN_ID__@example.com",
 "username": "example__RUN_ID__",
 "provisionMappings": [
  "string"
 ]
}
JSONEOF
)"
  req jwt POST "/api/users-sso" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/users-sso/:id
  req jwt DELETE "/api/users-sso/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/users-sso/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq28 asdm-admin-services-core (端口 8880)/SSO用户管理 | auth=jwt
auth_get_api_users_sso() {
  local label="GET /api/users-sso — 摘要：查询SSO用户列表 说明：分页查询SSO预创建用户列表"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/users-sso" "" "page=0&size=20"
  expect_read_ok "$label" 200 301 302
}

# seq29 asdm-admin-services-core (端口 8880)/SSO用户管理 | auth=jwt
auth_get_api_users_sso_id() {
  local label="GET /api/users-sso/:id — 摘要：查询单个SSO用户 说明：根据ID查询单个SSO用户记录"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/users-sso/$(path_id id)" "" ""
  expect_read_ok "$label" 200 301 302
}

# seq30 asdm-admin-services-core (端口 8880)/SSO用户管理 | auth=jwt（无配对删除接口，失败请人工核查数据残留）
auth_put_api_users_sso_id() {
  local label="PUT /api/users-sso/:id — 摘要：更新SSO用户 说明：更新SSO预创建用户信息（仅支持PENDING状态）"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "iamLoginNo": "string",
 "username": "example__RUN_ID__"
}
JSONEOF
)"
  req jwt PUT "/api/users-sso/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq31 asdm-admin-services-core (端口 8880)/SSO用户管理 | auth=jwt
auth_delete_api_users_sso_id() {
  local label="DELETE /api/users-sso/:id — 摘要：删除SSO用户 说明：删除SSO预创建用户记录（仅支持PENDING状态）"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/users-sso/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq32 asdm-admin-services-core (端口 8880)/User Permissions | auth=jwt
auth_get_api_auth_collections() {
  local label="GET /api/auth/collections — 摘要：Get Accessible Collections 说明：Get all collections accessi"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/collections" "" ""
  expect_read_ok "$label" 200
}

# seq33 asdm-admin-services-core (端口 8880)/User Permissions | auth=jwt
auth_get_api_auth_collections_collectionId_access() {
  local label="GET /api/auth/collections/:collectionId/access — 摘要：Check Collection Access 说明：Check if current user has acce"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/collections/$(path_id collectionId)/access" "" ""
  expect_read_ok "$label" 200
}

# seq34 asdm-admin-services-core (端口 8880)/User Permissions | auth=jwt
auth_get_api_auth_collections_collectionId_admin_access() {
  local label="GET /api/auth/collections/:collectionId/admin-access — 摘要：Check Collection Admin Access 说明：Check if current user ha"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/collections/$(path_id collectionId)/admin-access" "" ""
  expect_read_ok "$label" 200
}

# seq35 asdm-admin-services-core (端口 8880)/User Permissions | auth=jwt
auth_get_api_auth_collections_collectionId_users() {
  local label="GET /api/auth/collections/:collectionId/users — 摘要：Get Users for Collection (Paged) 说明：Get all users who hav"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/collections/$(path_id collectionId)/users" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq36 asdm-admin-services-core (端口 8880)/User Permissions | auth=jwt
auth_get_api_auth_collections_collectionId_users_distinct() {
  local label="GET /api/auth/collections/:collectionId/users/distinct — 摘要：Search Distinct Collection Users (Paged) 说明：Search dedupl"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/collections/$(path_id collectionId)/users/distinct" "" "page=0&size=20&excludeOverridden=false"
  expect_read_ok "$label" 200
}

# seq37 asdm-admin-services-core (端口 8880)/User Permissions | auth=jwt
auth_get_api_auth_projects() {
  local label="GET /api/auth/projects — 摘要：Get Accessible Projects 说明：Get all projects accessible by"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/projects" "" ""
  expect_read_ok "$label" 200
}

# seq38 asdm-admin-services-core (端口 8880)/User Permissions | auth=jwt
auth_get_api_auth_projects_projectId_access() {
  local label="GET /api/auth/projects/:projectId/access — 摘要：Check Project Access 说明：Check if current user has access"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/projects/$(path_id projectId)/access" "" ""
  expect_read_ok "$label" 200
}

# seq39 asdm-admin-services-core (端口 8880)/User Permissions | auth=jwt
auth_get_api_auth_projects_projectId_permissions() {
  local label="GET /api/auth/projects/:projectId/permissions — 摘要：Get Project Permissions 说明：Get current user's permissions"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/projects/$(path_id projectId)/permissions" "" ""
  expect_read_ok "$label" 200
}

# seq40 asdm-admin-services-core (端口 8880)/User Permissions | auth=jwt
auth_get_api_auth_projects_projectId_top_role() {
  local label="GET /api/auth/projects/:projectId/top-role — 摘要：Get Current User Top Role In Project 说明：Get current logge"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/projects/$(path_id projectId)/top-role" "" ""
  expect_read_ok "$label" 200
}

# seq41 asdm-admin-services-core (端口 8880)/User Permissions | auth=jwt
auth_get_api_auth_projects_projectId_users() {
  local label="GET /api/auth/projects/:projectId/users — 摘要：Get Users for Project (Paged) 说明：Get all users who have a"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/projects/$(path_id projectId)/users" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq42 asdm-admin-services-core (端口 8880)/User Permissions | auth=jwt
auth_get_api_auth_resources() {
  local label="GET /api/auth/resources — 摘要：Get Accessible Resources 说明：Get all collections and proje"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/resources" "" ""
  expect_read_ok "$label" 200
}

# seq43 asdm-admin-services-core (端口 8880)/User Permissions | auth=jwt
auth_get_api_auth_users() {
  local label="GET /api/auth/users — 摘要：Get All Users 说明：Get all users with optional filtering by"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/auth/users" "" ""
  expect_read_ok "$label" 200
}

# seq44 asdm-admin-services-core (端口 8880)/User Roles | auth=jwt
auth_get_api_auth_roles() {
  local label="GET /_api/auth/roles — 摘要：Get current user's roles by source type 完整路径：GET /_api/au"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/auth/roles" "" "page=0&size=20&sourceType=string"
  expect_read_ok "$label" 200
}

# seq45 asdm-admin-services-sso (端口 8881)/AssoCredentialInternal | auth=jwt
auth_get_internal_sso_asso_credential() {
  local label="GET /internal/sso/asso-credential — 完整路径：GET /internal/sso/asso-credential（服务：asdm-admin-service"
  need_auth jwt "$label" || return 0
  req jwt GET "/internal/sso/asso-credential" "" ""
  expect_read_ok "$label" 200 301 302
}

# seq46 asdm-admin-services-sso (端口 8881)/Sso | auth=none
auth_get_api_sso_callback() {
  local label="GET /api/sso/callback — 所属控制器：IT (default) environment SSO endpoints. The business l"
  need_auth none "$label" || return 0
  req none GET "/api/sso/callback" "" "code=string"
  expect_read_ok "$label" 200 301 302
}

# seq47 asdm-admin-services-sso (端口 8881)/Sso | auth=none
auth_get_api_sso_login_redirect() {
  local label="GET /api/sso/login-redirect — 所属控制器：IT (default) environment SSO endpoints. The business l"
  need_auth none "$label" || return 0
  req none GET "/api/sso/login-redirect" "" ""
  expect_read_ok "$label" 200 301 302
}

# seq48 asdm-admin-services-sso (端口 8881)/Sso | auth=none
auth_get_api_sso_logout_redirect() {
  local label="GET /api/sso/logout-redirect — 所属控制器：IT (default) environment SSO endpoints. The business l"
  need_auth none "$label" || return 0
  req none GET "/api/sso/logout-redirect" "" ""
  expect_read_ok "$label" 200 301 302
}

# seq49 asdm-admin-services-sso (端口 8881)/Sso | auth=none
auth_get_api_sso_unified_logout() {
  local label="GET /api/sso/unified-logout — 所属控制器：IT (default) environment SSO endpoints. The business l"
  need_auth none "$label" || return 0
  req none GET "/api/sso/unified-logout" "" ""
  expect_read_ok "$label" 200 301 302
}

# seq50 asdm-admin-services-sso (端口 8881)/SsoLt | auth=none
auth_get_api_sso_callback_2() {
  local label="GET /_api/sso/callback — 所属控制器：LT environment SSO endpoints. Mirrors {@link SsoContro"
  need_auth none "$label" || return 0
  req none GET "/_api/sso/callback" "" "code=string"
  expect_read_ok "$label" 200 301 302
}

# seq51 asdm-admin-services-sso (端口 8881)/SsoLt | auth=none
auth_get_api_sso_login_redirect_2() {
  local label="GET /_api/sso/login-redirect — 所属控制器：LT environment SSO endpoints. Mirrors {@link SsoContro"
  need_auth none "$label" || return 0
  req none GET "/_api/sso/login-redirect" "" ""
  expect_read_ok "$label" 200 301 302
}

# seq52 asdm-admin-services-sso (端口 8881)/SsoLt | auth=none
auth_get_api_sso_logout_redirect_2() {
  local label="GET /_api/sso/logout-redirect — 所属控制器：LT environment SSO endpoints. Mirrors {@link SsoContro"
  need_auth none "$label" || return 0
  req none GET "/_api/sso/logout-redirect" "" ""
  expect_read_ok "$label" 200 301 302
}

# seq53 asdm-admin-services-sso (端口 8881)/SsoLt | auth=none
auth_get_api_sso_unified_logout_2() {
  local label="GET /_api/sso/unified-logout — 所属控制器：LT environment SSO endpoints. Mirrors {@link SsoContro"
  need_auth none "$label" || return 0
  req none GET "/_api/sso/unified-logout" "" ""
  expect_read_ok "$label" 200 301 302
}

# ===== 入口 =====
main() {
  set +e   # 单用例失败不中断
  echo ""
  echo "========== 认证授权域 (53 apis) =========="
  login_if_needed || true
  auth_post_api_auth_change_password || true
  auth_post_api_auth_login || true
  auth_get_api_auth_me || true
  auth_put_api_auth_me || true
  auth_post_api_auth_register || true
  auth_get_api_auth_register_status || true
  auth_get_api_auth_session || true
  auth_get_api_auth_verify || true
  auth_post_api_auth_device_bind_state || true
  auth_post_api_auth_device_code || true
  auth_post_api_auth_device_token || true
  auth_post_api_auth_personal_access_tokens || true
  auth_get_api_auth_personal_access_tokens || true
  auth_delete_api_auth_personal_access_tokens_id || true
  auth_post_api_auth_personal_access_tokens_id_reset || true
  auth_post_api_auth_personal_access_tokens_exchange || true
  auth_post_api_auth_personal_access_tokens_lookup || true
  auth_get_api_projects_projectId_members || true
  auth_post_api_projects_projectId_members_batch || true
  auth_delete_api_projects_projectId_members_batch || true
  auth_get_api_projects_projectId_members_search || true
  auth_get_api_auth_projects_uid_projectUid_top_role || true
  auth_post_api_admin_users_userId_org_admin_reachability_check || true
  auth_post_api_admin_users_userId_rule_mappings_preview || true
  auth_post_api_users_userId_org_admin_reachability_check || true
  auth_post_api_users_userId_rule_mappings_preview || true
  auth_post_api_users_sso || true
  auth_get_api_users_sso || true
  auth_get_api_users_sso_id || true
  auth_put_api_users_sso_id || true
  auth_delete_api_users_sso_id || true
  auth_get_api_auth_collections || true
  auth_get_api_auth_collections_collectionId_access || true
  auth_get_api_auth_collections_collectionId_admin_access || true
  auth_get_api_auth_collections_collectionId_users || true
  auth_get_api_auth_collections_collectionId_users_distinct || true
  auth_get_api_auth_projects || true
  auth_get_api_auth_projects_projectId_access || true
  auth_get_api_auth_projects_projectId_permissions || true
  auth_get_api_auth_projects_projectId_top_role || true
  auth_get_api_auth_projects_projectId_users || true
  auth_get_api_auth_resources || true
  auth_get_api_auth_users || true
  auth_get_api_auth_roles || true
  auth_get_internal_sso_asso_credential || true
  auth_get_api_sso_callback || true
  auth_get_api_sso_login_redirect || true
  auth_get_api_sso_logout_redirect || true
  auth_get_api_sso_unified_logout || true
  auth_get_api_sso_callback_2 || true
  auth_get_api_sso_login_redirect_2 || true
  auth_get_api_sso_logout_redirect_2 || true
  auth_get_api_sso_unified_logout_2 || true
  finish
}
main "$@"
