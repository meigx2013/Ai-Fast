#!/usr/bin/env bash
# ============================================================================
# 用户与组织管理域 — 幂等自动化测试（由 gen/generate.js 从 api.json 生成，勿手工修改）
# 重新生成: node gen/generate.js
# 覆盖服务: core, org-mapping
# 接口总数: 81（读 42 直测 / 写 36 受控[含配对清理 5] / 永久跳过 3）
# 环境变量: ASDM_BASE_URL / ASDM_LOGIN_EMAIL / ASDM_LOGIN_PASSWORD / ASDM_TOKEN /
#           ASDM_PAT / ASDM_INTERNAL_TOKEN / ASDM_OPEN_ACCESS_TOKEN / ASDM_CITIC_SECRET /
#           ASDM_ALLOW_WRITES=1（执行写操作）/ ASDM_TEST_<参数名>（路径参数覆盖）
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ===== 被测接口用例 =====
# seq54 asdm-admin-services-core (端口 8880)/Admin Users | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_admin_users() {
  local label="POST /api/admin/users — 摘要：Create admin user 说明：Create a new user with account statu"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "email": "auto___RUN_ID__@example.com",
 "password": "Admin@123",
 "firstName": "example",
 "lastName": "example",
 "status": 1,
 "accountExpiresAt": "2026-01-01T10:00:00",
 "provisionMappings": [
  "string"
 ],
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
  req jwt POST "/api/admin/users" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq55 asdm-admin-services-core (端口 8880)/Admin Users | auth=jwt
user_org_get_api_admin_users() {
  local label="GET /api/admin/users — 摘要：List users (paged) 说明：Paged user list with one row per us"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/admin/users" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq56 asdm-admin-services-core (端口 8880)/Admin Users | auth=jwt
user_org_get_api_admin_users_userId() {
  local label="GET /api/admin/users/:userId — 摘要：Get user detail (admin) 说明：Get user basic info + computed"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/admin/users/$(path_id userId)" "" ""
  expect_read_ok "$label" 200
}

# seq57 asdm-admin-services-core (端口 8880)/Admin Users | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_put_api_admin_users_userId() {
  local label="PUT /api/admin/users/:userId — 摘要：Update user profile, account status and role mappings (ad"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "firstName": "example",
  "lastName": "example",
  "status": 1,
  "accountExpiresAt": "2026-01-01T10:00:00",
  "operations": [
    "string"
  ]
}
JSONEOF
)"
  req jwt PUT "/api/admin/users/$(path_id userId)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq58 asdm-admin-services-core (端口 8880)/Admin Users | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_put_api_admin_users_userId_profile_permission() {
  local label="PUT /api/admin/users/:userId/profile-permission — 摘要：Save user profile and permission mapping (admin) 说明：Save"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "firstName": "example",
  "lastName": "example",
  "ruleName": "example",
  "collectionId": "string",
  "projectId": "string",
  "accessLevel": "string",
  "mappingId": 1
}
JSONEOF
)"
  req jwt PUT "/api/admin/users/$(path_id userId)/profile-permission" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq59 asdm-admin-services-core (端口 8880)/Admin Users | auth=jwt（配对清理: POST /api/admin/users/:userId/rule-mappings/:mappingId）
user_org_post_api_admin_users_userId_remove_access() {
  local label="POST /api/admin/users/:userId/remove-access — 摘要：Remove user access (admin) 说明：Remove user_rule_mappings u"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "collectionId": "string",
  "projectId": "string"
}
JSONEOF
)"
  req jwt POST "/api/admin/users/$(path_id userId)/remove-access" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/admin/users/:userId/rule-mappings/:mappingId
  req jwt DELETE "/api/admin/users/${rid}/rule-mappings/$(path_id mappingId)" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/admin/users/${rid}/rule-mappings/$(path_id mappingId)" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq60 asdm-admin-services-core (端口 8880)/Admin Users | auth=jwt
user_org_get_api_admin_users_userId_rule_mappings() {
  local label="GET /api/admin/users/:userId/rule-mappings — 摘要：List user rule mappings (admin) 说明：Get user_rule_mappings"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/admin/users/$(path_id userId)/rule-mappings" "" ""
  expect_read_ok "$label" 200
}

# seq61 asdm-admin-services-core (端口 8880)/Admin Users | auth=jwt（配对清理: POST /api/admin/users/:userId/rule-mappings/:mappingId）
user_org_post_api_admin_users_userId_rule_mappings() {
  local label="POST /api/admin/users/:userId/rule-mappings — 摘要：Create user rule mapping (admin) 说明：Create a new user_rul"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "collectionId": "string",
  "projectId": "string",
  "ruleName": "example"
}
JSONEOF
)"
  req jwt POST "/api/admin/users/$(path_id userId)/rule-mappings" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/admin/users/:userId/rule-mappings/:mappingId
  req jwt DELETE "/api/admin/users/${rid}/rule-mappings/$(path_id mappingId)" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/admin/users/${rid}/rule-mappings/$(path_id mappingId)" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq62 asdm-admin-services-core (端口 8880)/Admin Users | auth=jwt（配对清理: POST /api/admin/users/:userId/rule-mappings/:mappingId）
user_org_post_api_admin_users_userId_rule_mappings_batch_upsert() {
  local label="POST /api/admin/users/:userId/rule-mappings:batch-upsert — 摘要：Batch upsert user role mappings (admin) 说明：Batch add/upda"
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
  req jwt POST "/api/admin/users/$(path_id userId)/rule-mappings:batch-upsert" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/admin/users/:userId/rule-mappings/:mappingId
  req jwt DELETE "/api/admin/users/${rid}/rule-mappings/$(path_id mappingId)" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/admin/users/${rid}/rule-mappings/$(path_id mappingId)" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq63 asdm-admin-services-core (端口 8880)/Admin Users | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_put_api_admin_users_userId_rule_mappings_mappingId() {
  local label="PUT /api/admin/users/:userId/rule-mappings/:mappingId — 摘要：Update user rule mapping role (admin) 说明：Update rule_name"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "ruleName": "example",
  "projectId": "string"
}
JSONEOF
)"
  req jwt PUT "/api/admin/users/$(path_id userId)/rule-mappings/$(path_id mappingId)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq64 asdm-admin-services-core (端口 8880)/Admin Users | auth=jwt
user_org_delete_api_admin_users_userId_rule_mappings_mappingId() {
  local label="DELETE /api/admin/users/:userId/rule-mappings/:mappingId — 摘要：Delete user rule mapping (admin) 说明：Delete a single user_"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/admin/users/${DUMMY_ID}/rule-mappings/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq65 asdm-admin-services-core (端口 8880)/Admin Users | auth=jwt
user_org_get_api_admin_users_me_rule_mappings() {
  local label="GET /api/admin/users/me/rule-mappings — 摘要：Get current user rule mappings 说明：Get current user's rule"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/admin/users/me/rule-mappings" "" ""
  expect_read_ok "$label" 200
}

# seq66 asdm-admin-services-core (端口 8880)/Admin Users | auth=jwt
user_org_get_api_admin_users_simple_search() {
  local label="GET /api/admin/users/simple-search — 摘要：Simple user search 说明：Search active users by keyword (ema"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/admin/users/simple-search" "" "keyword=string"
  expect_read_ok "$label" 200
}

# seq67 asdm-admin-services-core (端口 8880)/AdminResource | auth=jwt
user_org_get_api_admin_resources() {
  local label="GET /api/admin/resources — 所属控制器：Controller for admin resource aggregation queries. Sup"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/admin/resources" "" "scope=string&page=0&size=10"
  expect_read_ok "$label" 200
}

# seq68 asdm-admin-services-core (端口 8880)/AdminResource | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_admin_resources_resourceType_guid_activate() {
  local label="POST /api/admin/resources/:resourceType/:guid/activate — 所属控制器：Controller for admin resource aggregation queries. Sup"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/admin/resources/$(path_id resourceType)/$(path_id guid)/activate" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq69 asdm-admin-services-core (端口 8880)/AdminResource | auth=jwt
user_org_get_api_admin_resources_hidden_types() {
  local label="GET /api/admin/resources/hidden-types — 所属控制器：Controller for admin resource aggregation queries. Sup"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/admin/resources/hidden-types" "" ""
  expect_read_ok "$label" 200
}

# seq70 asdm-admin-services-core (端口 8880)/CollectionOpenAccessToken | auth=jwt
user_org_get_api_v1_collections_collectionId_open_access_token() {
  local label="GET /api/v1/collections/:collectionId/open-access-token — 所属控制器：组织单元设置页：服务化接口接入 Token（{@code oat_...}）管理。 <p>仅<b>组织管理员"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/v1/collections/$(path_id collectionId)/open-access-token" "" ""
  expect_read_ok "$label" 200
}

# seq71 asdm-admin-services-core (端口 8880)/CollectionOpenAccessToken | auth=jwt（配对清理: POST /api/v1/collections/:collectionId/open-access-token）
user_org_post_api_v1_collections_collectionId_open_access_token() {
  local label="POST /api/v1/collections/:collectionId/open-access-token — 所属控制器：组织单元设置页：服务化接口接入 Token（{@code oat_...}）管理。 <p>仅<b>组织管理员"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/v1/collections/$(path_id collectionId)/open-access-token" "" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/v1/collections/:collectionId/open-access-token
  req jwt DELETE "/api/v1/collections/${rid}/open-access-token" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/v1/collections/${rid}/open-access-token" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq72 asdm-admin-services-core (端口 8880)/CollectionOpenAccessToken | auth=jwt
user_org_delete_api_v1_collections_collectionId_open_access_token() {
  local label="DELETE /api/v1/collections/:collectionId/open-access-token — 所属控制器：组织单元设置页：服务化接口接入 Token（{@code oat_...}）管理。 <p>仅<b>组织管理员"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/v1/collections/${DUMMY_ID}/open-access-token" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq73 asdm-admin-services-core (端口 8880)/CollectionOpenAccessToken | auth=jwt
user_org_post_api_v1_collections_collectionId_open_access_token_reset() {
  log_skip "POST /api/v1/collections/:collectionId/open-access-token/reset — 永久跳过：路径含状态变更/清理类操作段（reset），避免破坏环境"
}

# seq74 asdm-admin-services-core (端口 8880)/Invitation | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_invitations_id_accept() {
  local label="POST /api/invitations/:id/accept — 摘要：Accept an invitation 完整路径：POST /api/invitations/:id/accep"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/invitations/$(path_id id)/accept" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq75 asdm-admin-services-core (端口 8880)/Invitation | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_invitations_id_reject() {
  local label="POST /api/invitations/:id/reject — 摘要：Reject an invitation 完整路径：POST /api/invitations/:id/rejec"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/invitations/$(path_id id)/reject" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq76 asdm-admin-services-core (端口 8880)/Invitation | auth=jwt
user_org_get_api_invitations_search_users() {
  local label="GET /api/invitations/search-users — 摘要：Search for invitable users in a collection/project scope"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/invitations/search-users" "" "collectionId=string&page=0&size=10"
  expect_read_ok "$label" 200
}

# seq77 asdm-admin-services-core (端口 8880)/Invitation Methods | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_invitations_batch() {
  local label="POST /_api/invitations/batch — 摘要：Batch create invitations (1-20 users) 完整路径：POST /_api/inv"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "entryPoint": {
    "type": "string",
    "collectionId": "string",
    "projectId": "string"
  },
  "roleMappings": [
    {
      "roleName": "example",
      "collectionId": "string",
      "projectId": "string",
      "managedResourceTypes": [
        "string"
      ]
    }
  ],
  "inviteeUserIds": [
    1
  ],
  "directAdd": true
}
JSONEOF
)"
  req jwt POST "/_api/invitations/batch" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq78 asdm-admin-services-core (端口 8880)/Invitation Methods | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_invitations_batch_cancel() {
  local label="POST /_api/invitations/batch-cancel — 摘要：Batch cancel invitations (line/multi-select/batch) 完整路径：P"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "invitationIds": [
    1
  ],
  "batchId": "string"
}
JSONEOF
)"
  req jwt POST "/_api/invitations/batch-cancel" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq79 asdm-admin-services-core (端口 8880)/Invitation Methods | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_invitations_batch_resend() {
  local label="POST /_api/invitations/batch-resend — 摘要：Batch resend invitations (line/multi-select/batch) 完整路径：P"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "invitationIds": [
    1
  ],
  "batchId": "string"
}
JSONEOF
)"
  req jwt POST "/_api/invitations/batch-resend" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq80 asdm-admin-services-core (端口 8880)/Invitation Methods | auth=jwt
user_org_get_api_invitations_received_list() {
  local label="GET /_api/invitations/received/list — 摘要：List received invitations (current user as invitee) 完整路径："
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/invitations/received/list" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq81 asdm-admin-services-core (端口 8880)/Invitation Methods | auth=jwt
user_org_get_api_invitations_sent_list() {
  local label="GET /_api/invitations/sent/list — 摘要：List sent invitations (admin only, flat or batch group mo"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/invitations/sent/list" "" "groupByBatch=false&page=0&size=20"
  expect_read_ok "$label" 200
}

# seq82 asdm-admin-services-core (端口 8880)/Organization Inheritance Policy | auth=jwt
user_org_get_api_project_collections_uid_inheritance_policy() {
  local label="GET /_api/project/collections/:uid/inheritance-policy — 摘要：Get inheritance policy 说明：Super-admin only; defaults to d"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/$(path_id uid)/inheritance-policy" "" ""
  expect_read_ok "$label" 200
}

# seq83 asdm-admin-services-core (端口 8880)/Organization Inheritance Policy | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_put_api_project_collections_uid_inheritance_policy() {
  local label="PUT /_api/project/collections/:uid/inheritance-policy — 摘要：Update inheritance policy 说明：Super-admin only; reconcile"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "collectionId": 1,
  "inheritanceMode": "string",
  "confirmReachabilityReconcile": true
}
JSONEOF
)"
  req jwt PUT "/_api/project/collections/$(path_id uid)/inheritance-policy" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq84 asdm-admin-services-core (端口 8880)/Organization Inheritance Policy | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_project_collections_uid_inheritance_policy_preview() {
  local label="POST /_api/project/collections/:uid/inheritance-policy/preview — 摘要：Preview inheritance policy change 说明：Super-admin only; pl"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "collectionId": 1,
  "inheritanceMode": "string",
  "confirmReachabilityReconcile": true
}
JSONEOF
)"
  req jwt POST "/_api/project/collections/$(path_id uid)/inheritance-policy/preview" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq85 asdm-admin-services-core (端口 8880)/Organization Members | auth=jwt
user_org_get_api_project_collections_uid_members() {
  local label="GET /_api/project/collections/:uid/members — 摘要：Partitioned organization members 说明：Returns directMembers"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/$(path_id uid)/members" "" ""
  expect_read_ok "$label" 200
}

# seq86 asdm-admin-services-core (端口 8880)/Organization Members | auth=jwt
user_org_get_api_project_collections_uid_members_inherited_admins() {
  local label="GET /_api/project/collections/:uid/members/inherited-admins — 摘要：Paged inherited org-admins 说明：Resolver-computed inherited"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/$(path_id uid)/members/inherited-admins" "" "page=0&size=20&ignorePolicyMode=false"
  expect_read_ok "$label" 200
}

# seq87 asdm-admin-services-core (端口 8880)/Organization Merge | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_project_collections_id_merge() {
  local label="POST /_api/project/collections/:id/merge — 摘要：Execute organization merge 说明：Absorb source into target t"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "targetId": 1
}
JSONEOF
)"
  req jwt POST "/_api/project/collections/$(path_id id)/merge" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq88 asdm-admin-services-core (端口 8880)/Organization Merge | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_project_collections_id_merge_preview() {
  local label="POST /_api/project/collections/:id/merge/preview — 摘要：Preview organization merge 说明：preview; super-admin only"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "targetId": 1
}
JSONEOF
)"
  req jwt POST "/_api/project/collections/$(path_id id)/merge/preview" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq89 asdm-admin-services-core (端口 8880)/Organization Move | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_project_collections_id_move() {
  local label="POST /_api/project/collections/:id/move — 摘要：Execute organization reparent 说明：Updates parent_id/path a"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "newParentId": 1,
  "includeDescendants": true
}
JSONEOF
)"
  req jwt POST "/_api/project/collections/$(path_id id)/move" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq90 asdm-admin-services-core (端口 8880)/Organization Move | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_project_collections_id_move_preview() {
  local label="POST /_api/project/collections/:id/move/preview — 摘要：Preview organization reparent 说明：preview; super-admin onl"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "newParentId": 1,
  "includeDescendants": true
}
JSONEOF
)"
  req jwt POST "/_api/project/collections/$(path_id id)/move/preview" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq91 asdm-admin-services-core (端口 8880)/Organization Tree | auth=jwt
user_org_get_api_project_collections_collectionUid_ancestors() {
  local label="GET /_api/project/collections/:collectionUid/ancestors — 摘要：Organization ancestor chain 说明：Breadcrumb ancestors root"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/$(path_id collectionUid)/ancestors" "" ""
  expect_read_ok "$label" 200
}

# seq92 asdm-admin-services-core (端口 8880)/Organization Tree | auth=jwt
user_org_get_api_project_collections_collectionUid_breadcrumb() {
  local label="GET /_api/project/collections/:collectionUid/breadcrumb — 摘要：Organization breadcrumb chain 说明：One-shot hierarchy root"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/$(path_id collectionUid)/breadcrumb" "" ""
  expect_read_ok "$label" 200
}

# seq93 asdm-admin-services-core (端口 8880)/Organization Tree | auth=jwt
user_org_get_api_project_collections_tree() {
  local label="GET /_api/project/collections/tree — 摘要：Visible organization tree 说明：Root organizations only; chi"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/tree" "" ""
  expect_read_ok "$label" 200
}

# seq94 asdm-admin-services-core (端口 8880)/Organization Tree | auth=jwt
user_org_get_api_project_collections_tree_children_collectionId() {
  local label="GET /_api/project/collections/tree/children/:collectionId — 摘要：Direct children of an organization 说明：Lazy-loaded child o"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/tree/children/$(path_id collectionId)" "" ""
  expect_read_ok "$label" 200
}

# seq95 asdm-admin-services-core (端口 8880)/Organization Tree | auth=jwt
user_org_get_api_project_collections_tree_project_cards() {
  local label="GET /_api/project/collections/tree/project-cards — 摘要：Project cards with org ancestor chain 说明：One-shot project"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/tree/project-cards" "" ""
  expect_read_ok "$label" 200
}

# seq96 asdm-admin-services-core (端口 8880)/Organization Tree | auth=jwt
user_org_get_api_project_collections_tree_projects_collectionId() {
  local label="GET /_api/project/collections/tree/projects/:collectionId — 摘要：Visible project leaves under an organization 说明：Lazy-load"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/tree/projects/$(path_id collectionId)" "" ""
  expect_read_ok "$label" 200
}

# seq97 asdm-admin-services-core (端口 8880)/Organization Tree | auth=jwt
user_org_get_api_project_collections_tree_removed() {
  local label="GET /_api/project/collections/tree/removed — 摘要：Removed organization tree (super-admin only) 说明：Read-only"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/tree/removed" "" ""
  expect_read_ok "$label" 200
}

# seq98 asdm-admin-services-core (端口 8880)/Organization Tree | auth=jwt
user_org_get_api_project_collections_tree_search() {
  local label="GET /_api/project/collections/tree/search — 摘要：Search visible organizations and projects 说明：Name search"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/tree/search" "" ""
  expect_read_ok "$label" 200
}

# seq99 asdm-admin-services-core (端口 8880)/Organization Tree | auth=jwt
user_org_get_api_project_collections_tree_stats() {
  local label="GET /_api/project/collections/tree/stats — 摘要：Organization totals 说明：Active and removed organization co"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/tree/stats" "" ""
  expect_read_ok "$label" 200
}

# seq100 asdm-admin-services-core (端口 8880)/Organization Tree | auth=jwt
user_org_get_api_project_collections_tree_subtree_collectionId() {
  local label="GET /_api/project/collections/tree/subtree/:collectionId — 摘要：Full visible subtree rooted at an organization 说明：One-sho"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/tree/subtree/$(path_id collectionId)" "" ""
  expect_read_ok "$label" 200
}

# seq101 asdm-admin-services-core (端口 8880)/Organization Tree | auth=jwt
user_org_get_api_project_collections_tree_visible_projects() {
  local label="GET /_api/project/collections/tree/visible-projects — 摘要：All visible project leaves 说明：Flat list of visible projec"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/tree/visible-projects" "" ""
  expect_read_ok "$label" 200
}

# seq102 asdm-admin-services-core (端口 8880)/OrgSync | auth=jwt
user_org_get_api_org_sync_batches() {
  local label="GET /_api/org-sync/batches — 完整路径：GET /_api/org-sync/batches（服务：asdm-admin-services-core，"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/org-sync/batches" "" "page=1&size=20"
  expect_read_ok "$label" 200
}

# seq103 asdm-admin-services-core (端口 8880)/OrgSync | auth=internal
user_org_get_api_org_sync_batches_batchId() {
  local label="GET /_api/org-sync/batches/:batchId — 完整路径：GET /_api/org-sync/batches/:batchId（服务：asdm-admin-servi"
  need_auth internal "$label" || return 0
  req internal GET "/_api/org-sync/batches/$(path_id batchId)" "" ""
  expect_read_ok "$label" 200
}

# seq104 asdm-admin-services-core (端口 8880)/OrgSync | auth=internal（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_org_sync_batches_batchId_cancel() {
  local label="POST /_api/org-sync/batches/:batchId/cancel — 完整路径：POST /_api/org-sync/batches/:batchId/cancel（服务：asdm-adm"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  req internal POST "/_api/org-sync/batches/$(path_id batchId)/cancel" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq105 asdm-admin-services-core (端口 8880)/OrgSync | auth=internal（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_org_sync_batches_batchId_confirm() {
  local label="POST /_api/org-sync/batches/:batchId/confirm — 完整路径：POST /_api/org-sync/batches/:batchId/confirm（服务：asdm-ad"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  req internal POST "/_api/org-sync/batches/$(path_id batchId)/confirm" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq106 asdm-admin-services-core (端口 8880)/OrgSync | auth=internal
user_org_get_api_org_sync_batches_batchId_preview() {
  local label="GET /_api/org-sync/batches/:batchId/preview — 完整路径：GET /_api/org-sync/batches/:batchId/preview（服务：asdm-adm"
  need_auth internal "$label" || return 0
  req internal GET "/_api/org-sync/batches/$(path_id batchId)/preview" "" ""
  expect_read_ok "$label" 200
}

# seq107 asdm-admin-services-core (端口 8880)/OrgSync | auth=internal（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_org_sync_batches_batchId_retry() {
  local label="POST /_api/org-sync/batches/:batchId/retry — 完整路径：POST /_api/org-sync/batches/:batchId/retry（服务：asdm-admi"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  req internal POST "/_api/org-sync/batches/$(path_id batchId)/retry" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq108 asdm-admin-services-core (端口 8880)/OrgSync | auth=internal
user_org_get_api_org_sync_batches_batchId_rows() {
  local label="GET /_api/org-sync/batches/:batchId/rows — 完整路径：GET /_api/org-sync/batches/:batchId/rows（服务：asdm-admin-"
  need_auth internal "$label" || return 0
  req internal GET "/_api/org-sync/batches/$(path_id batchId)/rows" "" "page=1&size=50"
  expect_read_ok "$label" 200
}

# seq109 asdm-admin-services-core (端口 8880)/OrgSync | auth=internal
user_org_get_api_org_sync_collections_by_name() {
  local label="GET /_api/org-sync/collections/by-name — 完整路径：GET /_api/org-sync/collections/by-name（服务：asdm-admin-se"
  need_auth internal "$label" || return 0
  req internal GET "/_api/org-sync/collections/by-name" "" "name=example"
  expect_read_ok "$label" 200
}

# seq110 asdm-admin-services-core (端口 8880)/OrgSync | auth=internal（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_org_sync_members_batch() {
  local label="POST /_api/org-sync/members/batch — 完整路径：POST /_api/org-sync/members/batch（服务：asdm-admin-service"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req internal POST "/_api/org-sync/members/batch" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq111 asdm-admin-services-core (端口 8880)/OrgSync | auth=internal（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_org_sync_organizations_batch() {
  local label="POST /_api/org-sync/organizations/batch — 完整路径：POST /_api/org-sync/organizations/batch（服务：asdm-admin-s"
  writes_allowed "$label" || return 0
  need_auth internal "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req internal POST "/_api/org-sync/organizations/batch" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq112 asdm-admin-services-core (端口 8880)/OrgSync | auth=jwt
user_org_post_api_org_sync_upload() {
  log_skip "POST /_api/org-sync/upload — 需要 multipart 文件上传，无法幂等自动执行（完整路径：POST /_api/org-sync/upload（服务：asdm-admin-services-core，）"
}

# seq113 asdm-admin-services-core (端口 8880)/Project Resolve | auth=jwt
user_org_get_api_project_collections_by_uid_collectionUid() {
  local label="GET /_api/project/collections/by-uid/:collectionUid — 摘要：Resolve collection by uid 说明：Organization landing: collec"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/collections/by-uid/$(path_id collectionUid)" "" ""
  expect_read_ok "$label" 200
}

# seq114 asdm-admin-services-core (端口 8880)/Project Resolve | auth=jwt
user_org_get_api_project_projects_projectUid_breadcrumb() {
  local label="GET /_api/project/projects/:projectUid/breadcrumb — 摘要：Project breadcrumb chain 说明：One-shot hierarchy: project +"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/projects/$(path_id projectUid)/breadcrumb" "" ""
  expect_read_ok "$label" 200
}

# seq115 asdm-admin-services-core (端口 8880)/Project Resolve | auth=jwt
user_org_get_api_project_projects_by_uid_projectUid() {
  local label="GET /_api/project/projects/by-uid/:projectUid — 摘要：Resolve project by uid 说明：Project landing: project + dire"
  need_auth jwt "$label" || return 0
  req jwt GET "/_api/project/projects/by-uid/$(path_id projectUid)" "" ""
  expect_read_ok "$label" 200
}

# seq116 asdm-admin-services-core (端口 8880)/SuperAdmin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_admin_super_admins() {
  local label="POST /api/admin/super-admins — 完整路径：POST /api/admin/super-admins（服务：asdm-admin-services-cor"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "email": "auto___RUN_ID__@example.com",
 "password": "Admin@123",
 "firstName": "example",
 "lastName": "example",
 "provisionMappings": [
  "string"
 ],
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
  req jwt POST "/api/admin/super-admins" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq117 asdm-admin-services-core (端口 8880)/SuperAdmin | auth=jwt
user_org_get_api_admin_super_admins() {
  local label="GET /api/admin/super-admins — 完整路径：GET /api/admin/super-admins（服务：asdm-admin-services-core"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/admin/super-admins" "" "mode=all&page=0&size=20"
  expect_read_ok "$label" 200
}

# seq118 asdm-admin-services-core (端口 8880)/SuperAdmin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_admin_super_admins_userId_demote() {
  local label="POST /api/admin/super-admins/:userId/demote — 完整路径：POST /api/admin/super-admins/:userId/demote（服务：asdm-adm"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/admin/super-admins/$(path_id userId)/demote" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq119 asdm-admin-services-core (端口 8880)/SuperAdmin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_admin_super_admins_userId_promote() {
  local label="POST /api/admin/super-admins/:userId/promote — 完整路径：POST /api/admin/super-admins/:userId/promote（服务：asdm-ad"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/admin/super-admins/$(path_id userId)/promote" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq120 asdm-admin-services-core (端口 8880)/SuperAdmin | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_admin_super_admins_userId_reset_password() {
  local label="POST /api/admin/super-admins/:userId/reset-password — 完整路径：POST /api/admin/super-admins/:userId/reset-password（服务："
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "password": "Admin@123"
}
JSONEOF
)"
  req jwt POST "/api/admin/super-admins/$(path_id userId)/reset-password" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq121 asdm-admin-services-core (端口 8880)/SuperAdmin | auth=jwt
user_org_get_api_admin_super_admins_operators() {
  local label="GET /api/admin/super-admins/operators — 完整路径：GET /api/admin/super-admins/operators（服务：asdm-admin-ser"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/admin/super-admins/operators" "" ""
  expect_read_ok "$label" 200
}

# seq122 asdm-admin-services-core (端口 8880)/Users Management | auth=jwt（无配对删除接口，失败请人工核查数据残留）
user_org_put_api_users_userId() {
  local label="PUT /api/users/:userId — 摘要：Update user basic profile (scoped) 说明：Update basic user p"
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
  req jwt PUT "/api/users/$(path_id userId)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq123 asdm-admin-services-core (端口 8880)/Users Management | auth=jwt
user_org_delete_api_users_userId_access() {
  local label="DELETE /api/users/:userId/access — 摘要：Remove user access (scoped) 说明：Remove user_rule_mappings"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/users/${DUMMY_ID}/access" "" "scopeType=string&onlyRemoveUser=false"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq124 asdm-admin-services-core (端口 8880)/Users Management | auth=jwt（配对清理: POST /api/users/:userId/access）
user_org_post_api_users_userId_rule_mappings_batch_upsert() {
  local label="POST /api/users/:userId/rule-mappings:batch-upsert — 摘要：Batch upsert user rule mappings (scoped) 说明：Batch add/upd"
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
  req jwt POST "/api/users/$(path_id userId)/rule-mappings:batch-upsert" "$body" "collectionId=string"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/users/:userId/access
  req jwt DELETE "/api/users/${rid}/access" "" "scopeType=string&onlyRemoveUser=false"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/users/${rid}/access" "" "scopeType=string&onlyRemoveUser=false"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq125 asdm-admin-services-org-mapping (端口 8889)/Organization Mapping Sync | auth=none
user_org_get_api_org_mapping_sync_status() {
  local label="GET /_api/org-mapping/sync/status — 摘要：Query the latest run status of a given sync type 完整路径：GET"
  need_auth none "$label" || return 0
  req none GET "/_api/org-mapping/sync/status" "" "syncType=ORGANIZATION"
  expect_read_ok "$label" 200
}

# seq126 asdm-admin-services-org-mapping (端口 8889)/Organization Mapping Sync | auth=none
user_org_get_api_org_mapping_sync_status_syncLogId() {
  local label="GET /_api/org-mapping/sync/status/:syncLogId — 摘要：Query sync progress by sync log id 完整路径：GET /_api/org-map"
  need_auth none "$label" || return 0
  req none GET "/_api/org-mapping/sync/status/$(path_id syncLogId)" "" ""
  expect_read_ok "$label" 200
}

# seq127 asdm-admin-services-org-mapping (端口 8889)/Organization Mapping Sync | auth=none（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_org_mapping_sync_trigger() {
  local label="POST /_api/org-mapping/sync/trigger — 摘要：Trigger a synchronization run (ORGANIZATION / MEMBER / BO"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none POST "/_api/org-mapping/sync/trigger" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq128 asdm-admin-services-org-mapping (端口 8889)/Organization Mapping Sync | auth=none
user_org_post_api_org_mapping_sync_upload() {
  log_skip "POST /_api/org-mapping/sync/upload — 需要 multipart 文件上传，无法幂等自动执行（摘要：Upload an organization or member Excel and trigger sync 完）"
}

# seq129 asdm-admin-services-org-mapping (端口 8889)/Organization Mapping Sync Log | auth=none
user_org_get_api_org_mapping_sync_logs() {
  local label="GET /_api/org-mapping/sync/logs — 摘要：List sync history with pagination and filters 完整路径：GET /_"
  need_auth none "$label" || return 0
  req none GET "/_api/org-mapping/sync/logs" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq130 asdm-admin-services-org-mapping (端口 8889)/Organization Mapping Sync Log | auth=none
user_org_get_api_org_mapping_sync_logs_syncLogId() {
  local label="GET /_api/org-mapping/sync/logs/:syncLogId — 摘要：Query a single sync run detail by id 完整路径：GET /_api/org-m"
  need_auth none "$label" || return 0
  req none GET "/_api/org-mapping/sync/logs/$(path_id syncLogId)" "" ""
  expect_read_ok "$label" 200
}

# seq131 asdm-admin-services-org-mapping (端口 8889)/Organization Mapping Sync Log | auth=none
user_org_get_api_org_mapping_sync_logs_syncLogId_failed() {
  local label="GET /_api/org-mapping/sync/logs/:syncLogId/failed — 摘要：Query failed row details of a sync run 完整路径：GET /_api/org"
  need_auth none "$label" || return 0
  req none GET "/_api/org-mapping/sync/logs/$(path_id syncLogId)/failed" "" ""
  expect_read_ok "$label" 200
}

# seq132 asdm-admin-services-org-mapping (端口 8889)/Organization Mapping Sync Log | auth=none（无配对删除接口，失败请人工核查数据残留）
user_org_post_api_org_mapping_sync_logs_syncLogId_retry() {
  local label="POST /_api/org-mapping/sync/logs/:syncLogId/retry — 摘要：Retry the failed rows of a previous run 完整路径：POST /_api/o"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none POST "/_api/org-mapping/sync/logs/$(path_id syncLogId)/retry" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq133 asdm-admin-services-org-mapping (端口 8889)/Organization Mapping Sync Log | auth=none
user_org_get_api_org_mapping_sync_logs_syncLogId_rows() {
  local label="GET /_api/org-mapping/sync/logs/:syncLogId/rows — 摘要：Query row level details of a sync run 完整路径：GET /_api/org-"
  need_auth none "$label" || return 0
  req none GET "/_api/org-mapping/sync/logs/$(path_id syncLogId)/rows" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq134 asdm-admin-services-org-mapping (端口 8889)/Organization Mapping Sync Log | auth=none
user_org_get_api_org_mapping_sync_logs_syncLogId_rows_stats() {
  local label="GET /_api/org-mapping/sync/logs/:syncLogId/rows/stats — 摘要：Query row detail statistics of a sync run 完整路径：GET /_api/"
  need_auth none "$label" || return 0
  req none GET "/_api/org-mapping/sync/logs/$(path_id syncLogId)/rows/stats" "" ""
  expect_read_ok "$label" 200
}

# ===== 入口 =====
main() {
  set +e   # 单用例失败不中断
  echo ""
  echo "========== 用户与组织管理域 (81 apis) =========="
  login_if_needed || true
  user_org_post_api_admin_users || true
  user_org_get_api_admin_users || true
  user_org_get_api_admin_users_userId || true
  user_org_put_api_admin_users_userId || true
  user_org_put_api_admin_users_userId_profile_permission || true
  user_org_post_api_admin_users_userId_remove_access || true
  user_org_get_api_admin_users_userId_rule_mappings || true
  user_org_post_api_admin_users_userId_rule_mappings || true
  user_org_post_api_admin_users_userId_rule_mappings_batch_upsert || true
  user_org_put_api_admin_users_userId_rule_mappings_mappingId || true
  user_org_delete_api_admin_users_userId_rule_mappings_mappingId || true
  user_org_get_api_admin_users_me_rule_mappings || true
  user_org_get_api_admin_users_simple_search || true
  user_org_get_api_admin_resources || true
  user_org_post_api_admin_resources_resourceType_guid_activate || true
  user_org_get_api_admin_resources_hidden_types || true
  user_org_get_api_v1_collections_collectionId_open_access_token || true
  user_org_post_api_v1_collections_collectionId_open_access_token || true
  user_org_delete_api_v1_collections_collectionId_open_access_token || true
  user_org_post_api_v1_collections_collectionId_open_access_token_reset || true
  user_org_post_api_invitations_id_accept || true
  user_org_post_api_invitations_id_reject || true
  user_org_get_api_invitations_search_users || true
  user_org_post_api_invitations_batch || true
  user_org_post_api_invitations_batch_cancel || true
  user_org_post_api_invitations_batch_resend || true
  user_org_get_api_invitations_received_list || true
  user_org_get_api_invitations_sent_list || true
  user_org_get_api_project_collections_uid_inheritance_policy || true
  user_org_put_api_project_collections_uid_inheritance_policy || true
  user_org_post_api_project_collections_uid_inheritance_policy_preview || true
  user_org_get_api_project_collections_uid_members || true
  user_org_get_api_project_collections_uid_members_inherited_admins || true
  user_org_post_api_project_collections_id_merge || true
  user_org_post_api_project_collections_id_merge_preview || true
  user_org_post_api_project_collections_id_move || true
  user_org_post_api_project_collections_id_move_preview || true
  user_org_get_api_project_collections_collectionUid_ancestors || true
  user_org_get_api_project_collections_collectionUid_breadcrumb || true
  user_org_get_api_project_collections_tree || true
  user_org_get_api_project_collections_tree_children_collectionId || true
  user_org_get_api_project_collections_tree_project_cards || true
  user_org_get_api_project_collections_tree_projects_collectionId || true
  user_org_get_api_project_collections_tree_removed || true
  user_org_get_api_project_collections_tree_search || true
  user_org_get_api_project_collections_tree_stats || true
  user_org_get_api_project_collections_tree_subtree_collectionId || true
  user_org_get_api_project_collections_tree_visible_projects || true
  user_org_get_api_org_sync_batches || true
  user_org_get_api_org_sync_batches_batchId || true
  user_org_post_api_org_sync_batches_batchId_cancel || true
  user_org_post_api_org_sync_batches_batchId_confirm || true
  user_org_get_api_org_sync_batches_batchId_preview || true
  user_org_post_api_org_sync_batches_batchId_retry || true
  user_org_get_api_org_sync_batches_batchId_rows || true
  user_org_get_api_org_sync_collections_by_name || true
  user_org_post_api_org_sync_members_batch || true
  user_org_post_api_org_sync_organizations_batch || true
  user_org_post_api_org_sync_upload || true
  user_org_get_api_project_collections_by_uid_collectionUid || true
  user_org_get_api_project_projects_projectUid_breadcrumb || true
  user_org_get_api_project_projects_by_uid_projectUid || true
  user_org_post_api_admin_super_admins || true
  user_org_get_api_admin_super_admins || true
  user_org_post_api_admin_super_admins_userId_demote || true
  user_org_post_api_admin_super_admins_userId_promote || true
  user_org_post_api_admin_super_admins_userId_reset_password || true
  user_org_get_api_admin_super_admins_operators || true
  user_org_put_api_users_userId || true
  user_org_delete_api_users_userId_access || true
  user_org_post_api_users_userId_rule_mappings_batch_upsert || true
  user_org_get_api_org_mapping_sync_status || true
  user_org_get_api_org_mapping_sync_status_syncLogId || true
  user_org_post_api_org_mapping_sync_trigger || true
  user_org_post_api_org_mapping_sync_upload || true
  user_org_get_api_org_mapping_sync_logs || true
  user_org_get_api_org_mapping_sync_logs_syncLogId || true
  user_org_get_api_org_mapping_sync_logs_syncLogId_failed || true
  user_org_post_api_org_mapping_sync_logs_syncLogId_retry || true
  user_org_get_api_org_mapping_sync_logs_syncLogId_rows || true
  user_org_get_api_org_mapping_sync_logs_syncLogId_rows_stats || true
  finish
}
main "$@"
