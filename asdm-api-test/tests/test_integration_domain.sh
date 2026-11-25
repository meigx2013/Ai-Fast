#!/usr/bin/env bash
# ============================================================================
# 集成域 — 幂等自动化测试（由 gen/generate.js 从 api.json 生成，勿手工修改）
# 重新生成: node gen/generate.js
# 覆盖服务: adapter-ads, adapter-automation, adapter-codearts, adapter-gitlab, core, integration
# 接口总数: 209（读 103 直测 / 写 104 受控[含配对清理 32] / 永久跳过 2）
# 环境变量: ASDM_BASE_URL / ASDM_LOGIN_EMAIL / ASDM_LOGIN_PASSWORD / ASDM_TOKEN /
#           ASDM_PAT / ASDM_INTERNAL_TOKEN / ASDM_OPEN_ACCESS_TOKEN / ASDM_CITIC_SECRET /
#           ASDM_ALLOW_WRITES=1（执行写操作）/ ASDM_TEST_<参数名>（路径参数覆盖）
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ===== 被测接口用例 =====
# seq470 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integration_adapter_ads_pull_requests() {
  local label="POST /api/integration-adapter-ads/pull-requests — 所属控制器：REST controller for pull request operations in the ADS"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "workspaceId": 1,
 "sourceRefName": "example",
 "targetRefName": "example",
 "title": "example__RUN_ID__",
 "description": "example text",
 "isDraft": true,
 "reviewers": [
  "string"
 ]
}
JSONEOF
)"
  req none POST "/api/integration-adapter-ads/pull-requests" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq471 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=pat
integration_get_api_integration_adapter_ads_pull_requests() {
  local label="GET /api/integration-adapter-ads/pull-requests — 所属控制器：REST controller for pull request operations in the ADS"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/pull-requests" "" "repositoryId=string&organization=string&project=string&pat=string"
  expect_read_ok "$label" 200
}

# seq472 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integration_adapter_ads_pull_requests_pullReques() {
  local label="PATCH /api/integration-adapter-ads/pull-requests/:pullRequestId — 所属控制器：REST controller for pull request operations in the ADS"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "workspaceId": 1,
 "title": "example__RUN_ID__",
 "description": "example text",
 "status": "string",
 "completionOptions": {
  "key": "value"
 },
 "mergeOptions": {
  "key": "value"
 },
 "lastMergeSourceCommit": {
  "key": "value"
 }
}
JSONEOF
)"
  req none PATCH "/api/integration-adapter-ads/pull-requests/$(path_id pullRequestId)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq473 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=pat
integration_get_api_integration_adapter_ads_pull_requests_pullRequestI() {
  local label="GET /api/integration-adapter-ads/pull-requests/:pullRequestId — 所属控制器：REST controller for pull request operations in the ADS"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/pull-requests/$(path_id pullRequestId)" "" "repositoryId=string&organization=string&project=string&pat=string"
  expect_read_ok "$label" 200
}

# seq474 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=none（配对清理: POST /api/integration-adapter-ads/pull-requests/:pullRequestId/labels/:labelId）
integration_post_api_integration_adapter_ads_pull_requests_pullRequest() {
  local label="POST /api/integration-adapter-ads/pull-requests/:pullRequestId/comments — 所属控制器：REST controller for pull request operations in the ADS"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "regUrl": "https://example.com",
  "projectRepositoryId": 1,
  "workspaceId": 1,
  "content": "example text",
  "noteId": "string",
  "severity": "string",
  "assigneeId": "string",
  "reviewCategories": "string",
  "reviewModules": "string",
  "proposerId": "string",
  "resolved": true
}
JSONEOF
)"
  req none POST "/api/integration-adapter-ads/pull-requests/$(path_id pullRequestId)/comments" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integration-adapter-ads/pull-requests/:pullRequestId/labels/:labelId
  req pat DELETE "/api/integration-adapter-ads/pull-requests/${rid}/labels/$(path_id labelId)" "" "repositoryId=string&organization=string&project=string&pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/api/integration-adapter-ads/pull-requests/${rid}/labels/$(path_id labelId)" "" "repositoryId=string&organization=string&project=string&pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq475 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=pat
integration_get_api_integration_adapter_ads_pull_requests_pullRequestI_2() {
  local label="GET /api/integration-adapter-ads/pull-requests/:pullRequestId/diff — 所属控制器：REST controller for pull request operations in the ADS"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/pull-requests/$(path_id pullRequestId)/diff" "" "repositoryId=string&organization=string&project=string&pat=string"
  expect_read_ok "$label" 200
}

# seq476 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=none（配对清理: POST /api/integration-adapter-ads/pull-requests/:pullRequestId/labels/:labelId）
integration_post_api_integration_adapter_ads_pull_requests_pullRequest_2() {
  local label="POST /api/integration-adapter-ads/pull-requests/:pullRequestId/labels — 所属控制器：REST controller for pull request operations in the ADS"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "name": "example__RUN_ID__"
}
JSONEOF
)"
  req none POST "/api/integration-adapter-ads/pull-requests/$(path_id pullRequestId)/labels" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integration-adapter-ads/pull-requests/:pullRequestId/labels/:labelId
  req pat DELETE "/api/integration-adapter-ads/pull-requests/${rid}/labels/$(path_id labelId)" "" "repositoryId=string&organization=string&project=string&pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/api/integration-adapter-ads/pull-requests/${rid}/labels/$(path_id labelId)" "" "repositoryId=string&organization=string&project=string&pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq477 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=pat
integration_get_api_integration_adapter_ads_pull_requests_pullRequestI_3() {
  local label="GET /api/integration-adapter-ads/pull-requests/:pullRequestId/labels — 所属控制器：REST controller for pull request operations in the ADS"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/pull-requests/$(path_id pullRequestId)/labels" "" "repositoryId=string&organization=string&project=string&pat=string"
  expect_read_ok "$label" 200
}

# seq478 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=pat
integration_delete_api_integration_adapter_ads_pull_requests_pullReque() {
  local label="DELETE /api/integration-adapter-ads/pull-requests/:pullRequestId/labels/:labelId — 所属控制器：REST controller for pull request operations in the ADS"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integration-adapter-ads/pull-requests/${DUMMY_ID}/labels/${DUMMY_ID}" "" "repositoryId=string&organization=string&project=string&pat=string"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq479 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=pat（无配对删除接口，失败请人工核查数据残留）
integration_put_api_integration_adapter_ads_pull_requests_pullRequestI() {
  local label="PUT /api/integration-adapter-ads/pull-requests/:pullRequestId/reviewers/:reviewerId — 所属控制器：REST controller for pull request operations in the ADS"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  req pat PUT "/api/integration-adapter-ads/pull-requests/$(path_id pullRequestId)/reviewers/$(path_id reviewerId)" "" "repositoryId=string&organization=string&project=string&pat=string"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq480 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=pat
integration_delete_api_integration_adapter_ads_pull_requests_pullReque_2() {
  local label="DELETE /api/integration-adapter-ads/pull-requests/:pullRequestId/reviewers/:reviewerId — 所属控制器：REST controller for pull request operations in the ADS"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integration-adapter-ads/pull-requests/${DUMMY_ID}/reviewers/${DUMMY_ID}" "" "repositoryId=string&organization=string&project=string&pat=string"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq481 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=none（配对清理: POST /api/integration-adapter-ads/pull-requests/:pullRequestId/labels/:labelId）
integration_post_api_integration_adapter_ads_pull_requests_pullRequest_3() {
  local label="POST /api/integration-adapter-ads/pull-requests/:pullRequestId/submitPrReview — 所属控制器：REST controller for pull request operations in the ADS"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "regUrl": "https://example.com",
  "projectRepositoryId": 1,
  "workspaceId": 1,
  "reviewer": "string",
  "vote": 1,
  "isRequired": true
}
JSONEOF
)"
  req none POST "/api/integration-adapter-ads/pull-requests/$(path_id pullRequestId)/submitPrReview" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integration-adapter-ads/pull-requests/:pullRequestId/labels/:labelId
  req pat DELETE "/api/integration-adapter-ads/pull-requests/${rid}/labels/$(path_id labelId)" "" "repositoryId=string&organization=string&project=string&pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/api/integration-adapter-ads/pull-requests/${rid}/labels/$(path_id labelId)" "" "repositoryId=string&organization=string&project=string&pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq482 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integration_adapter_ads_pull_requests_pullReques_2() {
  local label="PATCH /api/integration-adapter-ads/pull-requests/:pullRequestId/threads/:threadId — 所属控制器：REST controller for pull request operations in the ADS"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "regUrl": "https://example.com",
  "projectRepositoryId": 1,
  "workspaceId": 1,
  "content": "example text",
  "noteId": "string",
  "severity": "string",
  "assigneeId": "string",
  "reviewCategories": "string",
  "reviewModules": "string",
  "proposerId": "string",
  "resolved": true
}
JSONEOF
)"
  req none PATCH "/api/integration-adapter-ads/pull-requests/$(path_id pullRequestId)/threads/$(path_id threadId)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq483 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=pat
integration_get_api_integration_adapter_ads_pull_requests_branch_diff() {
  local label="GET /api/integration-adapter-ads/pull-requests/branch-diff — 所属控制器：REST controller for pull request operations in the ADS"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/pull-requests/branch-diff" "" "repositoryId=string&organization=string&project=string&baseVersion=1.0.0&targetVersion=1.0.0&pat=string"
  expect_read_ok "$label" 200
}

# seq484 asdm-admin-services-adapter-ads (端口 8883)/AdapterPullRequest | auth=pat
integration_get_api_integration_adapter_ads_pull_requests_repositories() {
  local label="GET /api/integration-adapter-ads/pull-requests/repositories — 所属控制器：REST controller for pull request operations in the ADS"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/pull-requests/repositories" "" "organization=string&project=string&pat=string"
  expect_read_ok "$label" 200
}

# seq485 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=pat
integration_delete_api_integration_adapter_ads_test_management_cases_t() {
  local label="DELETE /api/integration-adapter-ads/test-management/cases/:testCaseId — 所属控制器：REST controller for test management operations in the"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integration-adapter-ads/test-management/cases/${DUMMY_ID}" "" "organization=string&project=string&pat=string"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq486 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=none（配对清理: POST /api/integration-adapter-ads/test-management/plans/:planId）
integration_post_api_integration_adapter_ads_test_management_plans() {
  local label="POST /api/integration-adapter-ads/test-management/plans — 所属控制器：REST controller for test management operations in the"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "name": "example__RUN_ID__",
 "description": "example text",
 "startDate": "2026-01-01",
 "endDate": "2026-01-01",
 "areaPath": "/tmp/example",
 "iteration": "string",
 "ownerId": 1
}
JSONEOF
)"
  req none POST "/api/integration-adapter-ads/test-management/plans" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integration-adapter-ads/test-management/plans/:planId
  req pat DELETE "/api/integration-adapter-ads/test-management/plans/${rid}" "" "organization=string&project=string&pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/api/integration-adapter-ads/test-management/plans/${rid}" "" "organization=string&project=string&pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq487 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=pat
integration_get_api_integration_adapter_ads_test_management_plans() {
  local label="GET /api/integration-adapter-ads/test-management/plans — 所属控制器：REST controller for test management operations in the"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/test-management/plans" "" "organization=string&project=string&pat=string"
  expect_read_ok "$label" 200
}

# seq488 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integration_adapter_ads_test_management_plans_pl() {
  local label="PATCH /api/integration-adapter-ads/test-management/plans/:planId — 所属控制器：REST controller for test management operations in the"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "name": "example__RUN_ID__",
 "description": "example text",
 "startDate": "2026-01-01",
 "endDate": "2026-01-01",
 "areaPath": "/tmp/example",
 "iteration": "string",
 "ownerId": 1,
 "state": "string"
}
JSONEOF
)"
  req none PATCH "/api/integration-adapter-ads/test-management/plans/$(path_id planId)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq489 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=pat
integration_get_api_integration_adapter_ads_test_management_plans_plan() {
  local label="GET /api/integration-adapter-ads/test-management/plans/:planId — 所属控制器：REST controller for test management operations in the"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/test-management/plans/$(path_id planId)" "" "organization=string&project=string&pat=string"
  expect_read_ok "$label" 200
}

# seq490 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=pat
integration_delete_api_integration_adapter_ads_test_management_plans_p() {
  local label="DELETE /api/integration-adapter-ads/test-management/plans/:planId — 所属控制器：REST controller for test management operations in the"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integration-adapter-ads/test-management/plans/${DUMMY_ID}" "" "organization=string&project=string&pat=string"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq491 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=none（配对清理: POST /api/integration-adapter-ads/test-management/plans/:planId/suites/:suiteId）
integration_post_api_integration_adapter_ads_test_management_plans_pla() {
  local label="POST /api/integration-adapter-ads/test-management/plans/:planId/suites — 所属控制器：REST controller for test management operations in the"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "name": "example__RUN_ID__",
 "description": "example text",
 "parentSuiteId": 1,
 "suiteType": "string",
 "queryString": "string",
 "testCaseIds": 1
}
JSONEOF
)"
  req none POST "/api/integration-adapter-ads/test-management/plans/$(path_id planId)/suites" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integration-adapter-ads/test-management/plans/:planId/suites/:suiteId
  req pat DELETE "/api/integration-adapter-ads/test-management/plans/${rid}/suites/$(path_id suiteId)" "" "organization=string&project=string&pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/api/integration-adapter-ads/test-management/plans/${rid}/suites/$(path_id suiteId)" "" "organization=string&project=string&pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq492 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=pat
integration_get_api_integration_adapter_ads_test_management_plans_plan_2() {
  local label="GET /api/integration-adapter-ads/test-management/plans/:planId/suites — 所属控制器：REST controller for test management operations in the"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/test-management/plans/$(path_id planId)/suites" "" "organization=string&project=string&pat=string"
  expect_read_ok "$label" 200
}

# seq493 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integration_adapter_ads_test_management_plans_pl_2() {
  local label="PATCH /api/integration-adapter-ads/test-management/plans/:planId/suites/:suiteId — 所属控制器：REST controller for test management operations in the"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "name": "example__RUN_ID__",
 "description": "example text",
 "queryString": "string"
}
JSONEOF
)"
  req none PATCH "/api/integration-adapter-ads/test-management/plans/$(path_id planId)/suites/$(path_id suiteId)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq494 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=pat
integration_get_api_integration_adapter_ads_test_management_plans_plan_3() {
  local label="GET /api/integration-adapter-ads/test-management/plans/:planId/suites/:suiteId — 所属控制器：REST controller for test management operations in the"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/test-management/plans/$(path_id planId)/suites/$(path_id suiteId)" "" "organization=string&project=string&pat=string"
  expect_read_ok "$label" 200
}

# seq495 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=pat
integration_delete_api_integration_adapter_ads_test_management_plans_p_2() {
  local label="DELETE /api/integration-adapter-ads/test-management/plans/:planId/suites/:suiteId — 所属控制器：REST controller for test management operations in the"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integration-adapter-ads/test-management/plans/${DUMMY_ID}/suites/${DUMMY_ID}" "" "organization=string&project=string&pat=string"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq496 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=none（配对清理: POST /api/integration-adapter-ads/test-management/plans/:planId/suites/:suiteId/cases）
integration_post_api_integration_adapter_ads_test_management_plans_pla_2() {
  local label="POST /api/integration-adapter-ads/test-management/plans/:planId/suites/:suiteId/cases — 所属控制器：REST controller for test management operations in the"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "regUrl": "https://example.com",
  "projectRepositoryId": 1,
  "testCaseIds": [
    1
  ],
  "configurationIds": [
    1
  ]
}
JSONEOF
)"
  req none POST "/api/integration-adapter-ads/test-management/plans/$(path_id planId)/suites/$(path_id suiteId)/cases" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integration-adapter-ads/test-management/plans/:planId/suites/:suiteId/cases
  req pat DELETE "/api/integration-adapter-ads/test-management/plans/${rid}/suites/$(path_id suiteId)/cases" "" "testCaseIds=string&organization=string&project=string&pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/api/integration-adapter-ads/test-management/plans/${rid}/suites/$(path_id suiteId)/cases" "" "testCaseIds=string&organization=string&project=string&pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq497 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integration_adapter_ads_test_management_plans_pl_3() {
  local label="PATCH /api/integration-adapter-ads/test-management/plans/:planId/suites/:suiteId/cases — 所属控制器：REST controller for test management operations in the"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "regUrl": "https://example.com",
  "projectRepositoryId": 1,
  "testCaseIds": [
    1
  ],
  "configurationIds": [
    1
  ]
}
JSONEOF
)"
  req none PATCH "/api/integration-adapter-ads/test-management/plans/$(path_id planId)/suites/$(path_id suiteId)/cases" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq498 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=pat
integration_get_api_integration_adapter_ads_test_management_plans_plan_4() {
  local label="GET /api/integration-adapter-ads/test-management/plans/:planId/suites/:suiteId/cases — 所属控制器：REST controller for test management operations in the"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/test-management/plans/$(path_id planId)/suites/$(path_id suiteId)/cases" "" "organization=string&project=string&pat=string"
  expect_read_ok "$label" 200
}

# seq499 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=pat
integration_delete_api_integration_adapter_ads_test_management_plans_p_3() {
  local label="DELETE /api/integration-adapter-ads/test-management/plans/:planId/suites/:suiteId/cases — 所属控制器：REST controller for test management operations in the"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integration-adapter-ads/test-management/plans/${DUMMY_ID}/suites/${DUMMY_ID}/cases" "" "testCaseIds=string&organization=string&project=string&pat=string"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq500 asdm-admin-services-adapter-ads (端口 8883)/AdapterTestManagement | auth=pat
integration_get_api_integration_adapter_ads_test_management_plans_plan_5() {
  local label="GET /api/integration-adapter-ads/test-management/plans/:planId/suites/:suiteId/cases/:testCaseId — 所属控制器：REST controller for test management operations in the"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/test-management/plans/$(path_id planId)/suites/$(path_id suiteId)/cases/$(path_id testCaseId)" "" "organization=string&project=string&pat=string"
  expect_read_ok "$label" 200
}

# seq501 asdm-admin-services-adapter-ads (端口 8883)/AdsAdapter | auth=none
integration_get_api_integration_adapter_ads_health() {
  local label="GET /api/integration-adapter-ads/health — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth none "$label" || return 0
  req none GET "/api/integration-adapter-ads/health" "" ""
  expect_read_ok "$label" 200
}

# seq502 asdm-admin-services-adapter-ads (端口 8883)/AdsAdapter | auth=none
integration_get_api_integration_adapter_ads_info() {
  local label="GET /api/integration-adapter-ads/info — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth none "$label" || return 0
  req none GET "/api/integration-adapter-ads/info" "" ""
  expect_read_ok "$label" 200
}

# seq503 asdm-admin-services-adapter-ads (端口 8883)/AdsAdapter | auth=pat
integration_get_api_integration_adapter_ads_projects() {
  local label="GET /api/integration-adapter-ads/projects — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/projects" "" "organization=string&pat=string"
  expect_read_ok "$label" 200
}

# seq504 asdm-admin-services-adapter-ads (端口 8883)/AdsAdapter | auth=none
integration_get_api_integration_adapter_ads_test_connection() {
  local label="GET /api/integration-adapter-ads/test-connection — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth none "$label" || return 0
  req none GET "/api/integration-adapter-ads/test-connection" "" ""
  expect_read_ok "$label" 200
}

# seq505 asdm-admin-services-adapter-ads (端口 8883)/AdsAdapter | auth=pat
integration_get_api_integration_adapter_ads_users() {
  local label="GET /api/integration-adapter-ads/users — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/users" "" "organization=string&searchText=string&searchFilter=General&pat=string"
  expect_read_ok "$label" 200
}

# seq506 asdm-admin-services-adapter-ads (端口 8883)/AdsAdapter | auth=none
integration_get_api_integration_adapter_ads_users_debug() {
  local label="GET /api/integration-adapter-ads/users/debug — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth none "$label" || return 0
  req none GET "/api/integration-adapter-ads/users/debug" "" "organization=string&searchText=string"
  expect_read_ok "$label" 200
}

# seq507 asdm-admin-services-adapter-ads (端口 8883)/AdsAdapter | auth=none
integration_get_api_integration_adapter_ads_workitems() {
  local label="GET /api/integration-adapter-ads/workitems — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth none "$label" || return 0
  req none GET "/api/integration-adapter-ads/workitems" "" ""
  expect_read_ok "$label" 200
}

# seq508 asdm-admin-services-adapter-ads (端口 8883)/AdsAdapter | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integration_adapter_ads_workitems() {
  local label="POST /api/integration-adapter-ads/workitems — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "project": "string",
 "baseUrl": "https://example.com",
 "organization": "string",
 "pat": "string",
 "state": "string",
 "title": "example__RUN_ID__",
 "description": "example text",
 "priority": "string",
 "tags": [
  "string"
 ],
 "multilineFieldsFormat": "string",
 "workItemType": "string"
}
JSONEOF
)"
  req none POST "/api/integration-adapter-ads/workitems" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq509 asdm-admin-services-adapter-ads (端口 8883)/AdsAdapter | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integration_adapter_ads_workitems_id() {
  local label="PATCH /api/integration-adapter-ads/workitems/:id — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "project": "string",
 "baseUrl": "https://example.com",
 "organization": "string",
 "pat": "string",
 "state": "string",
 "nativeState": "string",
 "title": "example__RUN_ID__",
 "description": "example text",
 "priority": "string",
 "assignee": "string",
 "tags": [
  "string"
 ],
 "comment": "example text",
 "workItemType": "string",
 "bypassRules": true,
 "validateOnly": true,
 "multilineFieldsFormat": "string",
 "addRelations": [
  {
   "rel": "string",
   "url": "https://example.com",
   "comment": "example text",
   "workItemId": "string",
   "linkType": "https://example.com"
  }
 ],
 "removeRelations": [
  1
 ],
 "updateRelations": {
  "key": "value"
 },
 "extensionFields": {
  "key": "value"
 }
}
JSONEOF
)"
  req none PATCH "/api/integration-adapter-ads/workitems/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq510 asdm-admin-services-adapter-ads (端口 8883)/AdsAdapter | auth=pat
integration_get_api_integration_adapter_ads_workitems_id() {
  local label="GET /api/integration-adapter-ads/workitems/:id — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/api/integration-adapter-ads/workitems/$(path_id id)" "" "project=string&organization=string&pat=string"
  expect_read_ok "$label" 200
}

# seq511 asdm-admin-services-adapter-ads (端口 8883)/AdsAdapter | auth=none
integration_get_api_integration_adapter_ads_workitemtypes() {
  local label="GET /api/integration-adapter-ads/workitemtypes — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth none "$label" || return 0
  req none GET "/api/integration-adapter-ads/workitemtypes" "" ""
  expect_read_ok "$label" 200
}

# seq512 asdm-admin-services-adapter-automation (端口 8890)/CodingHealth | auth=none
integration_get_api_integration_adapter_automation_coding_health() {
  local label="GET /_api/integration-adapter-automation/coding/health — 所属控制器：Dedicated health endpoint of the CODING adapter (FT-03"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-automation/coding/health" "" ""
  expect_read_ok "$label" 200
}

# seq513 asdm-admin-services-adapter-automation (端口 8890)/CodingPullRequest | auth=none
integration_get_api_integration_adapter_automation_coding_pull_request() {
  local label="GET /_api/integration-adapter-automation/coding/pull-requests/:pullRequestId — 所属控制器：Pull request endpoints of the CODING adapter (FT-030)."
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-automation/coding/pull-requests/$(path_id pullRequestId)" "" "params=%5Bobject%20Object%5D"
  expect_read_ok "$label" 200
}

# seq514 asdm-admin-services-adapter-automation (端口 8890)/CodingPullRequest | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integration_adapter_automation_coding_pull_reques() {
  local label="POST /_api/integration-adapter-automation/coding/pull-requests/:pullRequestId/comments — 所属控制器：Pull request endpoints of the CODING adapter (FT-030)."
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none POST "/_api/integration-adapter-automation/coding/pull-requests/$(path_id pullRequestId)/comments" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq515 asdm-admin-services-adapter-automation (端口 8890)/CodingPullRequest | auth=none
integration_get_api_integration_adapter_automation_coding_pull_request_2() {
  local label="GET /_api/integration-adapter-automation/coding/pull-requests/:pullRequestId/diff — 所属控制器：Pull request endpoints of the CODING adapter (FT-030)."
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-automation/coding/pull-requests/$(path_id pullRequestId)/diff" "" "params=%5Bobject%20Object%5D"
  expect_read_ok "$label" 200
}

# seq516 asdm-admin-services-adapter-automation (端口 8890)/CodingPullRequest | auth=none
integration_get_api_integration_adapter_automation_coding_pull_request_3() {
  local label="GET /_api/integration-adapter-automation/coding/pull-requests/repositories — 所属控制器：Pull request endpoints of the CODING adapter (FT-030)."
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-automation/coding/pull-requests/repositories" "" "params=%5Bobject%20Object%5D"
  expect_read_ok "$label" 200
}

# seq517 asdm-admin-services-adapter-automation (端口 8890)/CodingTestConnection | auth=none
integration_get_api_integration_adapter_automation_coding_test_connect() {
  local label="GET /_api/integration-adapter-automation/coding/test-connection — 所属控制器：Dedicated test-connection endpoint of the CODING adapt"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-automation/coding/test-connection" "" ""
  expect_read_ok "$label" 200
}

# seq518 asdm-admin-services-adapter-automation (端口 8890)/IntegratedPush | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_post_api_itol_integrated_push() {
  local label="POST /api/itol/integrated/push — 所属控制器：整合推送Controller <p> 对应设计文档 3.7.3.1。 使用 ResponseEntity&l"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "ssysId": "string",
  "jarNam": "string",
  "dsgnTaskNum": "string",
  "shdlTaskNum": "string",
  "crtUser": "string",
  "interfaceList": [
    {
      "intfNam": "string",
      "packNam": "string",
      "intfDsgnTyp": "string",
      "intfDesc": "string",
      "jarId": "string",
      "ssysIntlNum": "string",
      "dsgnTaskNum": "string",
      "shdlTaskNum": "string",
      "crtUser": "string"
    }
  ],
  "entityClassList": [
    {
      "enttNam": "string",
      "enttNamCn": "string",
      "enttDesc": "string",
      "packNam": "string",
      "moduId": "string",
      "crtUser": "string",
      "attrList": [
        {
          "attrNam": "string",
          "attrNamCn": "string",
          "attrTyp": "string",
          "attrDesc": "string",
          "dataTypCod": "string",
          "crtUser": "string"
        }
      ]
    }
  ],
  "methodList": [
    {
      "tranNam": "string",
      "tranDesc": "string",
      "packNam": "string",
      "intfObjtIntlNum": "string",
      "crtUser": "string",
      "paraList": [
        {
          "parmNam": "string",
          "parmNamCn": "string",
          "parmTyp": "string",
          "parmDesc": "string",
          "parmReqRspTyp": "string",
          "paraPackNam": "string",
          "ssysIntlNum": "string",
          "crtUser": "string"
        }
      ]
    }
  ]
}
JSONEOF
)"
  req none POST "/api/itol/integrated/push" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq519 asdm-admin-services-adapter-automation (端口 8890)/Itol | auth=none
integration_get_api_integration_adapter_automation_itol_health() {
  local label="GET /_api/integration-adapter-automation/itol/health — 完整路径：GET /_api/integration-adapter-automation/itol/health（服务"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-automation/itol/health" "" ""
  expect_read_ok "$label" 200
}

# seq520 asdm-admin-services-adapter-automation (端口 8890)/Itol | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integration_adapter_automation_itol_imports() {
  local label="POST /_api/integration-adapter-automation/itol/imports — 完整路径：POST /_api/integration-adapter-automation/itol/imports（"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none POST "/_api/integration-adapter-automation/itol/imports" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq521 asdm-admin-services-adapter-automation (端口 8890)/Itol | auth=none
integration_get_api_integration_adapter_automation_itol_imports_batchI() {
  local label="GET /_api/integration-adapter-automation/itol/imports/:batchId — 完整路径：GET /_api/integration-adapter-automation/itol/imports/:"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-automation/itol/imports/$(path_id batchId)" "" ""
  expect_read_ok "$label" 200
}

# seq522 asdm-admin-services-adapter-automation (端口 8890)/Itol | auth=none
integration_post_api_integration_adapter_automation_itol_imports_uploa() {
  log_skip "POST /_api/integration-adapter-automation/itol/imports/upload — 需要 multipart 文件上传，无法幂等自动执行（完整路径：POST /_api/integration-adapter-automation/itol/imports/）"
}

# seq523 asdm-admin-services-adapter-automation (端口 8890)/Itol | auth=none
integration_get_api_integration_adapter_automation_itol_info() {
  local label="GET /_api/integration-adapter-automation/itol/info — 完整路径：GET /_api/integration-adapter-automation/itol/info（服务：a"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-automation/itol/info" "" ""
  expect_read_ok "$label" 200
}

# seq524 asdm-admin-services-adapter-automation (端口 8890)/Itol | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integration_adapter_automation_itol_publish() {
  local label="POST /_api/integration-adapter-automation/itol/publish — 完整路径：POST /_api/integration-adapter-automation/itol/publish（"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none POST "/_api/integration-adapter-automation/itol/publish" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq525 asdm-admin-services-adapter-automation (端口 8890)/Itol | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integration_adapter_automation_itol_query() {
  local label="POST /_api/integration-adapter-automation/itol/query — 完整路径：POST /_api/integration-adapter-automation/itol/query（服务"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none POST "/_api/integration-adapter-automation/itol/query" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq526 asdm-admin-services-adapter-automation (端口 8890)/Itol | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integration_adapter_automation_itol_rollback() {
  local label="POST /_api/integration-adapter-automation/itol/rollback — 完整路径：POST /_api/integration-adapter-automation/itol/rollback"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none POST "/_api/integration-adapter-automation/itol/rollback" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq527 asdm-admin-services-adapter-automation (端口 8890)/Itol | auth=none
integration_get_api_integration_adapter_automation_itol_test_connectio() {
  local label="GET /_api/integration-adapter-automation/itol/test-connection — 完整路径：GET /_api/integration-adapter-automation/itol/test-conn"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-automation/itol/test-connection" "" ""
  expect_read_ok "$label" 200
}

# seq528 asdm-admin-services-adapter-automation (端口 8890)/ItolBusiness | auth=jwt（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integration_adapter_automation_itol_integrated_pu() {
  local label="POST /_api/integration-adapter-automation/itol/integrated-push/push — 完整路径：POST /_api/integration-adapter-automation/itol/integrat"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "ssysId": "string",
  "jarNam": "string",
  "dsgnTaskNum": "string",
  "shdlTaskNum": "string",
  "crtUser": "string",
  "interfaceList": [
    {
      "intfNam": "string",
      "packNam": "string",
      "intfDsgnTyp": "string",
      "intfDesc": "string",
      "jarId": "string",
      "ssysIntlNum": "string",
      "dsgnTaskNum": "string",
      "shdlTaskNum": "string",
      "crtUser": "string"
    }
  ],
  "entityClassList": [
    {
      "enttNam": "string",
      "enttNamCn": "string",
      "enttDesc": "string",
      "packNam": "string",
      "moduId": "string",
      "crtUser": "string",
      "attrList": [
        {
          "attrNam": "string",
          "attrNamCn": "string",
          "attrTyp": "string",
          "attrDesc": "string",
          "dataTypCod": "string",
          "crtUser": "string"
        }
      ]
    }
  ],
  "methodList": [
    {
      "tranNam": "string",
      "tranDesc": "string",
      "packNam": "string",
      "intfObjtIntlNum": "string",
      "crtUser": "string",
      "paraList": [
        {
          "parmNam": "string",
          "parmNamCn": "string",
          "parmTyp": "string",
          "parmDesc": "string",
          "parmReqRspTyp": "string",
          "paraPackNam": "string",
          "ssysIntlNum": "string",
          "crtUser": "string"
        }
      ]
    }
  ]
}
JSONEOF
)"
  req jwt POST "/_api/integration-adapter-automation/itol/integrated-push/push" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq529 asdm-admin-services-adapter-automation (端口 8890)/ItolBusiness | auth=jwt（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integration_adapter_automation_itol_model_createT() {
  local label="POST /_api/integration-adapter-automation/itol/model/createTable — 完整路径：POST /_api/integration-adapter-automation/itol/model/cr"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "modelId": 1,
  "ver": 1,
  "table": {}
}
JSONEOF
)"
  req jwt POST "/_api/integration-adapter-automation/itol/model/createTable" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq530 asdm-admin-services-adapter-automation (端口 8890)/ItolBusiness | auth=jwt（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integration_adapter_automation_itol_model_getBySy() {
  local label="POST /_api/integration-adapter-automation/itol/model/getBySystem — 完整路径：POST /_api/integration-adapter-automation/itol/model/ge"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "systemName": "example"
}
JSONEOF
)"
  req jwt POST "/_api/integration-adapter-automation/itol/model/getBySystem" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq531 asdm-admin-services-adapter-automation (端口 8890)/RagRelay | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integration_adapter_rag_relay() {
  local label="POST /_api/integration-adapter-rag/relay — 所属控制器：Thin RAG relay endpoint, mirroring the role of {@code"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none POST "/_api/integration-adapter-rag/relay" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq532 asdm-admin-services-adapter-automation (端口 8890)/Relay | auth=jwt（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integration_adapter_automation_relay() {
  local label="POST /_api/integration-adapter-automation/relay — 所属控制器：The only adapter endpoint used by the generic integrat"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "service": "string",
  "operation": "string",
  "payload": {}
}
JSONEOF
)"
  req jwt POST "/_api/integration-adapter-automation/relay" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq533 asdm-admin-services-adapter-automation (端口 8890)/TargetMessage | auth=jwt（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integration_adapter_automation_target_messages() {
  local label="POST /_api/integration-adapter-automation/target/messages — 完整路径：POST /_api/integration-adapter-automation/target/messag"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "message": "example text"
}
JSONEOF
)"
  req jwt POST "/_api/integration-adapter-automation/target/messages" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq534 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsAdapter | auth=none
integration_get_api_integration_adapter_codearts_health() {
  local label="GET /_api/integration-adapter-codearts/health — 完整路径：GET /_api/integration-adapter-codearts/health（服务：asdm-a"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-codearts/health" "" ""
  expect_read_ok "$label" 200
}

# seq535 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsAdapter | auth=none
integration_get_api_integration_adapter_codearts_info() {
  local label="GET /_api/integration-adapter-codearts/info — 完整路径：GET /_api/integration-adapter-codearts/info（服务：asdm-adm"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-codearts/info" "" ""
  expect_read_ok "$label" 200
}

# seq536 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsAdapter | auth=none
integration_get_api_integration_adapter_codearts_projects() {
  local label="GET /_api/integration-adapter-codearts/projects — 完整路径：GET /_api/integration-adapter-codearts/projects（服务：asdm"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-codearts/projects" "" "region=string&ak=string&sk=string&offset=0&limit=10"
  expect_read_ok "$label" 200
}

# seq537 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsAdapter | auth=none
integration_get_api_integration_adapter_codearts_test_connection() {
  local label="GET /_api/integration-adapter-codearts/test-connection — 完整路径：GET /_api/integration-adapter-codearts/test-connection（"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-codearts/test-connection" "" "region=string&ak=string&sk=string"
  expect_read_ok "$label" 200
}

# seq538 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none（配对清理: POST /_api/integration-adapter-codearts/workitems/:id）
integration_post_api_integration_adapter_codearts_pull_requests() {
  local label="POST /_api/integration-adapter-codearts/pull-requests — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "workspaceId": 1,
 "sourceRefName": "example",
 "targetRefName": "example",
 "title": "example__RUN_ID__",
 "description": "example text",
 "isDraft": true,
 "reviewers": [
  "string"
 ]
}
JSONEOF
)"
  req none POST "/_api/integration-adapter-codearts/pull-requests" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/integration-adapter-codearts/workitems/:id
  req pat DELETE "/_api/integration-adapter-codearts/workitems/${rid}" "" "projectId=string&pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/_api/integration-adapter-codearts/workitems/${rid}" "" "projectId=string&pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq539 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none
integration_get_api_integration_adapter_codearts_pull_requests() {
  local label="GET /_api/integration-adapter-codearts/pull-requests — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-codearts/pull-requests" "" "region=string&ak=string&sk=string&repositoryId=string&offset=0&limit=20"
  expect_read_ok "$label" 200
}

# seq540 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integration_adapter_codearts_pull_requests_id() {
  local label="PATCH /_api/integration-adapter-codearts/pull-requests/:id — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "workspaceId": 1,
 "title": "example__RUN_ID__",
 "description": "example text",
 "status": "string",
 "completionOptions": {
  "key": "value"
 },
 "mergeOptions": {
  "key": "value"
 },
 "lastMergeSourceCommit": {
  "key": "value"
 }
}
JSONEOF
)"
  req none PATCH "/_api/integration-adapter-codearts/pull-requests/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq541 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none
integration_get_api_integration_adapter_codearts_pull_requests_id() {
  local label="GET /_api/integration-adapter-codearts/pull-requests/:id — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-codearts/pull-requests/$(path_id id)" "" "region=string&ak=string&sk=string&repositoryId=string"
  expect_read_ok "$label" 200
}

# seq542 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_put_api_integration_adapter_codearts_pull_requests_id_clos() {
  local label="PUT /_api/integration-adapter-codearts/pull-requests/:id/close — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "region": "string",
  "ak": "string",
  "sk": "string",
  "repositoryId": "string"
}
JSONEOF
)"
  req none PUT "/_api/integration-adapter-codearts/pull-requests/$(path_id id)/close" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq543 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none（配对清理: POST /_api/integration-adapter-codearts/pull-requests/:id/comments/:commentId）
integration_post_api_integration_adapter_codearts_pull_requests_id_com() {
  local label="POST /_api/integration-adapter-codearts/pull-requests/:id/comments — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "regUrl": "https://example.com",
  "projectRepositoryId": 1,
  "workspaceId": 1,
  "content": "example text",
  "noteId": "string",
  "severity": "string",
  "assigneeId": "string",
  "reviewCategories": "string",
  "reviewModules": "string",
  "proposerId": "string",
  "resolved": true
}
JSONEOF
)"
  req none POST "/_api/integration-adapter-codearts/pull-requests/$(path_id id)/comments" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/integration-adapter-codearts/pull-requests/:id/comments/:commentId
  req none DELETE "/_api/integration-adapter-codearts/pull-requests/${rid}/comments/$(path_id commentId)" "" "region=string&ak=string&sk=string&repositoryId=string&noteId=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/_api/integration-adapter-codearts/pull-requests/${rid}/comments/$(path_id commentId)" "" "region=string&ak=string&sk=string&repositoryId=string&noteId=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq544 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none
integration_get_api_integration_adapter_codearts_pull_requests_id_comm() {
  local label="GET /_api/integration-adapter-codearts/pull-requests/:id/comments — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-codearts/pull-requests/$(path_id id)/comments" "" "region=string&ak=string&sk=string&repositoryId=string&skip=1&top=20"
  expect_read_ok "$label" 200
}

# seq545 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_put_api_integration_adapter_codearts_pull_requests_id_comm() {
  local label="PUT /_api/integration-adapter-codearts/pull-requests/:id/comments/:commentId — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "region": "string",
  "ak": "string",
  "sk": "string",
  "repositoryId": "string",
  "noteId": "string",
  "content": "example text",
  "severity": "string",
  "assigneeId": "string",
  "reviewCategories": "string",
  "reviewModules": "string",
  "proposerId": "string",
  "resolved": true
}
JSONEOF
)"
  req none PUT "/_api/integration-adapter-codearts/pull-requests/$(path_id id)/comments/$(path_id commentId)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq546 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none
integration_get_api_integration_adapter_codearts_pull_requests_id_comm_2() {
  local label="GET /_api/integration-adapter-codearts/pull-requests/:id/comments/:commentId — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-codearts/pull-requests/$(path_id id)/comments/$(path_id commentId)" "" "region=string&ak=string&sk=string&repositoryId=string"
  expect_read_ok "$label" 200
}

# seq547 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none
integration_delete_api_integration_adapter_codearts_pull_requests_id_c() {
  local label="DELETE /_api/integration-adapter-codearts/pull-requests/:id/comments/:commentId — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req none DELETE "/_api/integration-adapter-codearts/pull-requests/${DUMMY_ID}/comments/${DUMMY_ID}" "" "region=string&ak=string&sk=string&repositoryId=string&noteId=string"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq548 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none
integration_get_api_integration_adapter_codearts_pull_requests_id_diff() {
  local label="GET /_api/integration-adapter-codearts/pull-requests/:id/diff — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-codearts/pull-requests/$(path_id id)/diff" "" "region=string&ak=string&sk=string&repositoryId=string"
  expect_read_ok "$label" 200
}

# seq549 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_put_api_integration_adapter_codearts_pull_requests_id_merg() {
  local label="PUT /_api/integration-adapter-codearts/pull-requests/:id/merge — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "region": "string",
  "ak": "string",
  "sk": "string",
  "repositoryId": "string"
}
JSONEOF
)"
  req none PUT "/_api/integration-adapter-codearts/pull-requests/$(path_id id)/merge" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq550 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none（配对清理: POST /_api/integration-adapter-codearts/pull-requests/:id/comments/:commentId）
integration_post_api_integration_adapter_codearts_pull_requests_id_sub() {
  local label="POST /_api/integration-adapter-codearts/pull-requests/:id/submitPrReview — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "regUrl": "https://example.com",
  "projectRepositoryId": 1,
  "workspaceId": 1,
  "reviewer": "string",
  "vote": 1,
  "isRequired": true
}
JSONEOF
)"
  req none POST "/_api/integration-adapter-codearts/pull-requests/$(path_id id)/submitPrReview" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/integration-adapter-codearts/pull-requests/:id/comments/:commentId
  req none DELETE "/_api/integration-adapter-codearts/pull-requests/${rid}/comments/$(path_id commentId)" "" "region=string&ak=string&sk=string&repositoryId=string&noteId=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/_api/integration-adapter-codearts/pull-requests/${rid}/comments/$(path_id commentId)" "" "region=string&ak=string&sk=string&repositoryId=string&noteId=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq551 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsPullRequest | auth=none
integration_get_api_integration_adapter_codearts_pull_requests_reposit() {
  local label="GET /_api/integration-adapter-codearts/pull-requests/repositories — 所属控制器：CODE domain adapter controller exposing 6 HTTP endpoin"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-codearts/pull-requests/repositories" "" "region=string&ak=string&sk=string&projectId=string"
  expect_read_ok "$label" 200
}

# seq552 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsWorkItem | auth=none（配对清理: POST /_api/integration-adapter-codearts/workitems/:id）
integration_post_api_integration_adapter_codearts_workitems() {
  local label="POST /_api/integration-adapter-codearts/workitems — 所属控制器：WORK_ITEM domain adapter controller exposing 9 HTTP en"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "title": "example__RUN_ID__",
 "category": "string",
 "description": "example text",
 "descriptionFormat": "example text",
 "parentId": "string",
 "status": "string",
 "state": "string",
 "assignee": "string",
 "recipient": [
  {
   "key": "value"
  }
 ],
 "assignedCc": [
  {
   "key": "value"
  }
 ],
 "planEndDate": "2026-01-01",
 "workload": "string",
 "link": "https://example.com",
 "labels": [
  {
   "key": "value"
  }
 ],
 "customFields": [
  {
   "key": "value"
  }
 ],
 "children": [
  {
   "key": "value"
  }
 ],
 "ir2feature": "string",
 "priority": "string",
 "relatedNetworkSecurity": "string",
 "collaboratives": "string",
 "businessDomain": "string",
 "module": "string",
 "planStartDate": "2026-01-01",
 "projectId": "string",
 "pat": "string"
}
JSONEOF
)"
  req none POST "/_api/integration-adapter-codearts/workitems" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/integration-adapter-codearts/workitems/:id
  req pat DELETE "/_api/integration-adapter-codearts/workitems/${rid}" "" "projectId=string&pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/_api/integration-adapter-codearts/workitems/${rid}" "" "projectId=string&pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq553 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsWorkItem | auth=pat
integration_get_api_integration_adapter_codearts_workitems() {
  local label="GET /_api/integration-adapter-codearts/workitems — 所属控制器：WORK_ITEM domain adapter controller exposing 9 HTTP en"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-codearts/workitems" "" "page=1&size=20&pat=string"
  expect_read_ok "$label" 200
}

# seq554 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsWorkItem | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integration_adapter_codearts_workitems_id() {
  local label="PATCH /_api/integration-adapter-codearts/workitems/:id — 所属控制器：WORK_ITEM domain adapter controller exposing 9 HTTP en"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "title": "example__RUN_ID__",
 "category": "string",
 "description": "example text",
 "descriptionFormat": "example text",
 "parentId": "string",
 "status": "string",
 "state": "string",
 "assignee": "string",
 "recipient": [
  {
   "key": "value"
  }
 ],
 "assignedCc": [
  {
   "key": "value"
  }
 ],
 "planEndDate": "2026-01-01",
 "workload": "string",
 "link": "https://example.com",
 "labels": [
  {
   "key": "value"
  }
 ],
 "customFields": [
  {
   "key": "value"
  }
 ],
 "children": [
  {
   "key": "value"
  }
 ],
 "ir2feature": "string",
 "priority": "string",
 "relatedNetworkSecurity": "string",
 "collaboratives": "string",
 "businessDomain": "string",
 "module": "string",
 "planStartDate": "2026-01-01",
 "projectId": "string",
 "pat": "string"
}
JSONEOF
)"
  req none PATCH "/_api/integration-adapter-codearts/workitems/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq555 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsWorkItem | auth=pat
integration_delete_api_integration_adapter_codearts_workitems_id() {
  local label="DELETE /_api/integration-adapter-codearts/workitems/:id — 所属控制器：WORK_ITEM domain adapter controller exposing 9 HTTP en"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/_api/integration-adapter-codearts/workitems/${DUMMY_ID}" "" "projectId=string&pat=string"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq556 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsWorkItem | auth=pat
integration_get_api_integration_adapter_codearts_workitems_id() {
  local label="GET /_api/integration-adapter-codearts/workitems/:id — 所属控制器：WORK_ITEM domain adapter controller exposing 9 HTTP en"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-codearts/workitems/$(path_id id)" "" "type=string&pat=string"
  expect_read_ok "$label" 200
}

# seq557 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsWorkItem | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_put_api_integration_adapter_codearts_workitems_batch() {
  local label="PUT /_api/integration-adapter-codearts/workitems/batch — 所属控制器：WORK_ITEM domain adapter controller exposing 9 HTTP en"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none PUT "/_api/integration-adapter-codearts/workitems/batch" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq558 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsWorkItem | auth=none
integration_delete_api_integration_adapter_codearts_workitems_batch() {
  log_skip "DELETE /_api/integration-adapter-codearts/workitems/batch — 永久跳过：静态路径整体删除，无法限定删除范围"
}

# seq559 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsWorkItem | auth=none（配对清理: POST /_api/integration-adapter-codearts/workitems/batch）
integration_post_api_integration_adapter_codearts_workitems_batch() {
  local label="POST /_api/integration-adapter-codearts/workitems/batch — 所属控制器：WORK_ITEM domain adapter controller exposing 9 HTTP en"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none POST "/_api/integration-adapter-codearts/workitems/batch" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/integration-adapter-codearts/workitems/batch
  req none DELETE "/_api/integration-adapter-codearts/workitems/batch" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/_api/integration-adapter-codearts/workitems/batch" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq560 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsWorkItem | auth=pat
integration_get_api_integration_adapter_codearts_workitems_fields() {
  local label="GET /_api/integration-adapter-codearts/workitems/fields — 所属控制器：WORK_ITEM domain adapter controller exposing 9 HTTP en"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-codearts/workitems/fields" "" "projectId=string&pat=string"
  expect_read_ok "$label" 200
}

# seq561 asdm-admin-services-adapter-codearts (端口 8888)/CodeArtsWorkItem | auth=none
integration_get_api_integration_adapter_codearts_workitems_states() {
  local label="GET /_api/integration-adapter-codearts/workitems/states — 所属控制器：WORK_ITEM domain adapter controller exposing 9 HTTP en"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-codearts/workitems/states" "" ""
  expect_read_ok "$label" 200
}

# seq562 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_get_api_integration_adapter_gitlab_groups_groupId_projects() {
  local label="GET /_api/integration-adapter-gitlab/groups/:groupId/projects — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-gitlab/groups/$(path_id groupId)/projects" "" "pat=string"
  expect_read_ok "$label" 200
}

# seq563 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=none
integration_get_api_integration_adapter_gitlab_health() {
  local label="GET /_api/integration-adapter-gitlab/health — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-gitlab/health" "" ""
  expect_read_ok "$label" 200
}

# seq564 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=none
integration_get_api_integration_adapter_gitlab_info() {
  local label="GET /_api/integration-adapter-gitlab/info — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth none "$label" || return 0
  req none GET "/_api/integration-adapter-gitlab/info" "" ""
  expect_read_ok "$label" 200
}

# seq565 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_get_api_integration_adapter_gitlab_projects() {
  local label="GET /_api/integration-adapter-gitlab/projects — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-gitlab/projects" "" "pat=string"
  expect_read_ok "$label" 200
}

# seq566 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_get_api_integration_adapter_gitlab_projects_projectId() {
  local label="GET /_api/integration-adapter-gitlab/projects/:projectId — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-gitlab/projects/$(path_id projectId)" "" "pat=string"
  expect_read_ok "$label" 200
}

# seq567 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=none（配对清理: POST /_api/integration-adapter-gitlab/workitems/:iid）
integration_post_api_integration_adapter_gitlab_pullrequests() {
  local label="POST /_api/integration-adapter-gitlab/pullrequests — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "repositoryUrl": "https://example.com",
 "pat": "string",
 "sourceBranch": "string",
 "targetBranch": "string",
 "title": "example__RUN_ID__",
 "description": "example text",
 "reviewers": [
  "string"
 ],
 "assignee": "string",
 "extensionFields": {
  "key": "value"
 }
}
JSONEOF
)"
  req none POST "/_api/integration-adapter-gitlab/pullrequests" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/integration-adapter-gitlab/workitems/:iid
  req pat DELETE "/_api/integration-adapter-gitlab/workitems/${rid}" "" "pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/_api/integration-adapter-gitlab/workitems/${rid}" "" "pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq568 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_get_api_integration_adapter_gitlab_pullrequests() {
  local label="GET /_api/integration-adapter-gitlab/pullrequests — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-gitlab/pullrequests" "" "pat=string"
  expect_read_ok "$label" 200
}

# seq569 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_get_api_integration_adapter_gitlab_pullrequests_iid() {
  local label="GET /_api/integration-adapter-gitlab/pullrequests/:iid — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-gitlab/pullrequests/$(path_id iid)" "" "pat=string"
  expect_read_ok "$label" 200
}

# seq570 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integration_adapter_gitlab_pullrequests_iid() {
  local label="PATCH /_api/integration-adapter-gitlab/pullrequests/:iid — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req pat PATCH "/_api/integration-adapter-gitlab/pullrequests/$(path_id iid)" "$body" "pat=string"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq571 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat（配对清理: POST /_api/integration-adapter-gitlab/pullrequests/:iid/reviewers/:reviewerId）
integration_post_api_integration_adapter_gitlab_pullrequests_iid_appro() {
  local label="POST /_api/integration-adapter-gitlab/pullrequests/:iid/approve — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  req pat POST "/_api/integration-adapter-gitlab/pullrequests/$(path_id iid)/approve" "" "pat=string"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/integration-adapter-gitlab/pullrequests/:iid/reviewers/:reviewerId
  req pat DELETE "/_api/integration-adapter-gitlab/pullrequests/${rid}/reviewers/$(path_id reviewerId)" "" "pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/_api/integration-adapter-gitlab/pullrequests/${rid}/reviewers/$(path_id reviewerId)" "" "pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq572 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat（配对清理: POST /_api/integration-adapter-gitlab/pullrequests/:iid/reviewers/:reviewerId）
integration_post_api_integration_adapter_gitlab_pullrequests_iid_comme() {
  local label="POST /_api/integration-adapter-gitlab/pullrequests/:iid/comments — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req pat POST "/_api/integration-adapter-gitlab/pullrequests/$(path_id iid)/comments" "$body" "pat=string"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/integration-adapter-gitlab/pullrequests/:iid/reviewers/:reviewerId
  req pat DELETE "/_api/integration-adapter-gitlab/pullrequests/${rid}/reviewers/$(path_id reviewerId)" "" "pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/_api/integration-adapter-gitlab/pullrequests/${rid}/reviewers/$(path_id reviewerId)" "" "pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq573 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_get_api_integration_adapter_gitlab_pullrequests_iid_diff() {
  local label="GET /_api/integration-adapter-gitlab/pullrequests/:iid/diff — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-gitlab/pullrequests/$(path_id iid)/diff" "" "pat=string"
  expect_read_ok "$label" 200
}

# seq574 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat（无配对删除接口，失败请人工核查数据残留）
integration_put_api_integration_adapter_gitlab_pullrequests_iid_review() {
  local label="PUT /_api/integration-adapter-gitlab/pullrequests/:iid/reviewers/:reviewerId — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  req pat PUT "/_api/integration-adapter-gitlab/pullrequests/$(path_id iid)/reviewers/$(path_id reviewerId)" "" "pat=string"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq575 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_delete_api_integration_adapter_gitlab_pullrequests_iid_rev() {
  local label="DELETE /_api/integration-adapter-gitlab/pullrequests/:iid/reviewers/:reviewerId — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/_api/integration-adapter-gitlab/pullrequests/${DUMMY_ID}/reviewers/${DUMMY_ID}" "" "pat=string"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq576 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat（配对清理: POST /_api/integration-adapter-gitlab/pullrequests/:iid/reviewers/:reviewerId）
integration_post_api_integration_adapter_gitlab_pullrequests_iid_submi() {
  local label="POST /_api/integration-adapter-gitlab/pullrequests/:iid/submitPrReview — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req pat POST "/_api/integration-adapter-gitlab/pullrequests/$(path_id iid)/submitPrReview" "$body" "pat=string"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/integration-adapter-gitlab/pullrequests/:iid/reviewers/:reviewerId
  req pat DELETE "/_api/integration-adapter-gitlab/pullrequests/${rid}/reviewers/$(path_id reviewerId)" "" "pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/_api/integration-adapter-gitlab/pullrequests/${rid}/reviewers/$(path_id reviewerId)" "" "pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq577 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat（配对清理: POST /_api/integration-adapter-gitlab/pullrequests/:iid/reviewers/:reviewerId）
integration_post_api_integration_adapter_gitlab_pullrequests_iid_unapp() {
  local label="POST /_api/integration-adapter-gitlab/pullrequests/:iid/unapprove — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  req pat POST "/_api/integration-adapter-gitlab/pullrequests/$(path_id iid)/unapprove" "" "pat=string"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/integration-adapter-gitlab/pullrequests/:iid/reviewers/:reviewerId
  req pat DELETE "/_api/integration-adapter-gitlab/pullrequests/${rid}/reviewers/$(path_id reviewerId)" "" "pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/_api/integration-adapter-gitlab/pullrequests/${rid}/reviewers/$(path_id reviewerId)" "" "pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq578 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_get_api_integration_adapter_gitlab_pullrequests_branch_dif() {
  local label="GET /_api/integration-adapter-gitlab/pullrequests/branch-diff — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-gitlab/pullrequests/branch-diff" "" "pat=string&baseVersion=1.0.0&targetVersion=1.0.0"
  expect_read_ok "$label" 200
}

# seq579 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_get_api_integration_adapter_gitlab_pullrequests_repositori() {
  local label="GET /_api/integration-adapter-gitlab/pullrequests/repositories — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-gitlab/pullrequests/repositories" "" "pat=string"
  expect_read_ok "$label" 200
}

# seq580 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_get_api_integration_adapter_gitlab_test_connection() {
  local label="GET /_api/integration-adapter-gitlab/test-connection — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-gitlab/test-connection" "" "pat=string"
  expect_read_ok "$label" 200
}

# seq581 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=none（配对清理: POST /_api/integration-adapter-gitlab/workitems/:iid）
integration_post_api_integration_adapter_gitlab_workitems() {
  local label="POST /_api/integration-adapter-gitlab/workitems — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "repositoryUrl": "https://example.com",
 "pat": "string",
 "title": "example__RUN_ID__",
 "description": "example text",
 "state": "string",
 "type": "string",
 "priority": "string",
 "assignee": "string",
 "tags": [
  "string"
 ],
 "comment": "example text",
 "extensionFields": {
  "key": "value"
 },
 "addRelations": [
  {
   "key": "value"
  }
 ],
 "removeRelations": [
  1
 ],
 "updateRelations": {
  "key": "value"
 }
}
JSONEOF
)"
  req none POST "/_api/integration-adapter-gitlab/workitems" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/integration-adapter-gitlab/workitems/:iid
  req pat DELETE "/_api/integration-adapter-gitlab/workitems/${rid}" "" "pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/_api/integration-adapter-gitlab/workitems/${rid}" "" "pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq582 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_get_api_integration_adapter_gitlab_workitems() {
  local label="GET /_api/integration-adapter-gitlab/workitems — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-gitlab/workitems" "" "pat=string"
  expect_read_ok "$label" 200
}

# seq583 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integration_adapter_gitlab_workitems_iid() {
  local label="PATCH /_api/integration-adapter-gitlab/workitems/:iid — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "repositoryUrl": "https://example.com",
 "pat": "string",
 "title": "example__RUN_ID__",
 "description": "example text",
 "state": "string",
 "type": "string",
 "priority": "string",
 "assignee": "string",
 "tags": [
  "string"
 ],
 "comment": "example text",
 "extensionFields": {
  "key": "value"
 },
 "addRelations": [
  {
   "key": "value"
  }
 ],
 "removeRelations": [
  1
 ],
 "updateRelations": {
  "key": "value"
 }
}
JSONEOF
)"
  req none PATCH "/_api/integration-adapter-gitlab/workitems/$(path_id iid)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq584 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_get_api_integration_adapter_gitlab_workitems_iid() {
  local label="GET /_api/integration-adapter-gitlab/workitems/:iid — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-gitlab/workitems/$(path_id iid)" "" "pat=string"
  expect_read_ok "$label" 200
}

# seq585 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_delete_api_integration_adapter_gitlab_workitems_iid() {
  local label="DELETE /_api/integration-adapter-gitlab/workitems/:iid — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/_api/integration-adapter-gitlab/workitems/${DUMMY_ID}" "" "pat=string"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq586 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_get_api_integration_adapter_gitlab_workitems_iid_links() {
  local label="GET /_api/integration-adapter-gitlab/workitems/:iid/links — 所属控制器：REST controller exposing internal API endpoints for th"
  need_auth pat "$label" || return 0
  req pat GET "/_api/integration-adapter-gitlab/workitems/$(path_id iid)/links" "" "pat=string"
  expect_read_ok "$label" 200
}

# seq587 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat（配对清理: POST /_api/integration-adapter-gitlab/workitems/:iid/links/:linkId）
integration_post_api_integration_adapter_gitlab_workitems_iid_links() {
  local label="POST /_api/integration-adapter-gitlab/workitems/:iid/links — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req pat POST "/_api/integration-adapter-gitlab/workitems/$(path_id iid)/links" "$body" "pat=string"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /_api/integration-adapter-gitlab/workitems/:iid/links/:linkId
  req pat DELETE "/_api/integration-adapter-gitlab/workitems/${rid}/links/$(path_id linkId)" "" "pat=string"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/_api/integration-adapter-gitlab/workitems/${rid}/links/$(path_id linkId)" "" "pat=string"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq588 asdm-admin-services-adapter-gitlab (端口 8884)/GitLabAdapter | auth=pat
integration_delete_api_integration_adapter_gitlab_workitems_iid_links_() {
  local label="DELETE /_api/integration-adapter-gitlab/workitems/:iid/links/:linkId — 所属控制器：REST controller exposing internal API endpoints for th"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/_api/integration-adapter-gitlab/workitems/${DUMMY_ID}/links/${DUMMY_ID}" "" "pat=string"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq589 asdm-admin-services-adapter-gitlab (端口 8884)/Health | auth=none
integration_get_actuator_health() {
  local label="GET /actuator/health — 所属控制器：Simple health check endpoint at root level. The main a"
  need_auth none "$label" || return 0
  req none GET "/actuator/health" "" ""
  expect_read_ok "$label" 200
}

# seq590 asdm-admin-services-core (端口 8880)/对外 AI 使用统计 | auth=citic
integration_get_api_citic_aicoding_stats() {
  local label="GET /_api/citic/aicoding-stats — 摘要：AI 使用统计汇总查询 说明：返回每人 Token 消耗量、AI Coding 使用次数、AI 生成代码行数"
  need_auth citic "$label" || return 0
  req citic GET "/_api/citic/aicoding-stats" "" "date=2026-01-01&hasOrgInfo=false"
  expect_read_ok "$label" 200
}

# seq591 asdm-admin-services-core (端口 8880)/对外 AI 使用统计 | auth=citic
integration_get_api_citic_gen_lines() {
  local label="GET /_api/citic/gen-lines — 摘要：AI 生成代码量查询 说明：返回每人 AI 生成代码行数（行，整数四舍五入）。orgNo 不传时查全部部门。"
  need_auth citic "$label" || return 0
  req citic GET "/_api/citic/gen-lines" "" "date=2026-01-01"
  expect_read_ok "$label" 200
}

# seq592 asdm-admin-services-core (端口 8880)/对外 AI 使用统计 | auth=citic（无配对删除接口，失败请人工核查数据残留）
integration_post_api_citic_sync_history() {
  local label="POST /_api/citic/sync-history — 摘要：历史数据批量同步（异步） 说明：异步启动历史数据同步（默认 2026-07-15 至今）。立即返回 taskId，"
  writes_allowed "$label" || return 0
  need_auth citic "$label" || return 0
  req citic POST "/_api/citic/sync-history" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq593 asdm-admin-services-core (端口 8880)/对外 AI 使用统计 | auth=citic
integration_get_api_citic_sync_history_status() {
  local label="GET /_api/citic/sync-history/status — 摘要：查询历史同步任务进度 说明：根据 taskId 查询异步历史同步任务的当前进度、已处理天数与每日结果。"
  need_auth citic "$label" || return 0
  req citic GET "/_api/citic/sync-history/status" "" "taskId=string"
  expect_read_ok "$label" 200
}

# seq594 asdm-admin-services-core (端口 8880)/对外 AI 使用统计 | auth=citic（无配对删除接口，失败请人工核查数据残留）
integration_post_api_citic_sync() {
  local label="POST /_api/citic/sync — 摘要：手动触发单日 AI 使用统计同步 说明：手动触发 CodeBuddy 与 Lingma 单日数据同步。支持多次重复"
  writes_allowed "$label" || return 0
  need_auth citic "$label" || return 0
  req citic POST "/_api/citic/sync" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq595 asdm-admin-services-core (端口 8880)/对外 AI 使用统计 | auth=citic
integration_get_api_citic_token_usage() {
  local label="GET /_api/citic/token-usage — 摘要：Token 消耗量查询 说明：返回每人 Token 消耗量（万，保留 1 位小数四舍五入）。orgNo 不传时查全"
  need_auth citic "$label" || return 0
  req citic GET "/_api/citic/token-usage" "" "date=2026-01-01"
  expect_read_ok "$label" 200
}

# seq596 asdm-admin-services-core (端口 8880)/对外 AI 使用统计 | auth=citic
integration_get_api_citic_usage_count() {
  local label="GET /_api/citic/usage-count — 摘要：AI Coding 使用次数查询 说明：返回每人 AI Coding 使用次数（次，整数四舍五入）。orgNo 不"
  need_auth citic "$label" || return 0
  req citic GET "/_api/citic/usage-count" "" "date=2026-01-01"
  expect_read_ok "$label" 200
}

# seq597 asdm-admin-services-integration (端口 8882)/适配器注册管理 | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_post_api_adapter_register() {
  local label="POST /api/adapter/register — 摘要：注册适配器服务 说明：注册或更新适配器服务信息"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "adapterType": "string",
  "serviceName": "example",
  "baseUrl": "https://example.com",
  "healthEndpoint": "string",
  "domainCapabilitiesJson": "string",
  "adapterMetadataJson": "string"
}
JSONEOF
)"
  req none POST "/api/adapter/register" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq598 asdm-admin-services-integration (端口 8882)/AdsIntegration | auth=none
integration_get_api_integrations_ads_configs_id_projects() {
  local label="GET /api/integrations/ads/configs/:id/projects — 所属控制器：REST controller for ADS integration operations. <p>Exp"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/ads/configs/$(path_id id)/projects" "" ""
  expect_read_ok "$label" 200
}

# seq599 asdm-admin-services-integration (端口 8882)/AdsIntegration | auth=pat
integration_get_api_integrations_ads_projects() {
  local label="GET /api/integrations/ads/projects — 所属控制器：REST controller for ADS integration operations. <p>Exp"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/ads/projects" "" "baseUrl=https%3A%2F%2Fexample.com&organization=string&pat=string"
  expect_read_ok "$label" 200
}

# seq600 asdm-admin-services-integration (端口 8882)/AuditLog | auth=none
integration_get_api_integrations_audit_logs() {
  local label="GET /api/integrations/audit-logs — 所属控制器：REST controller for integration audit log operations."
  need_auth none "$label" || return 0
  req none GET "/api/integrations/audit-logs" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq601 asdm-admin-services-integration (端口 8882)/AuditLog | auth=none
integration_get_api_integrations_audit_logs_id() {
  local label="GET /api/integrations/audit-logs/:id — 所属控制器：REST controller for integration audit log operations."
  need_auth none "$label" || return 0
  req none GET "/api/integrations/audit-logs/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq602 asdm-admin-services-integration (端口 8882)/AuditLog | auth=none
integration_get_api_integrations_audit_logs_by_integration_integration() {
  local label="GET /api/integrations/audit-logs/by-integration/:integrationId — 所属控制器：REST controller for integration audit log operations."
  need_auth none "$label" || return 0
  req none GET "/api/integrations/audit-logs/by-integration/$(path_id integrationId)" "" "page=0&size=20"
  expect_read_ok "$label" 200
}

# seq603 asdm-admin-services-integration (端口 8882)/AutomationIntegration | auth=none（配对清理: POST /api/integrations/configs/:id:  d+）
integration_post_api_integrations_rag() {
  local label="POST /api/integrations/rag — 完整路径：POST /api/integrations/rag（服务：asdm-admin-services-integ"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none POST "/api/integrations/rag" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/configs/:id:  d+
  req none DELETE "/api/integrations/configs/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/api/integrations/configs/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq604 asdm-admin-services-integration (端口 8882)/AutomationMessage | auth=jwt（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integrations_automation_messages() {
  local label="POST /api/integrations/automation/messages — 完整路径：POST /api/integrations/automation/messages（服务：asdm-admi"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "message": "example text"
}
JSONEOF
)"
  req jwt POST "/api/integrations/automation/messages" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq605 asdm-admin-services-integration (端口 8882)/IntegratedPushIntegration | auth=jwt（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integrations_integrated_push_push() {
  local label="POST /api/integrations/integrated-push/push — 摘要：Execute integrated push 说明：Proxy integrated push requests"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/integrations/integrated-push/push" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq606 asdm-admin-services-integration (端口 8882)/Integration | auth=none
integration_get_api_integrations_adapters() {
  local label="GET /api/integrations/adapters — 摘要：获取所有适配器 说明：查询所有已注册的适配器服务"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/adapters" "" ""
  expect_read_ok "$label" 200
}

# seq607 asdm-admin-services-integration (端口 8882)/Integration | auth=none
integration_get_api_integrations_adapters_type_health() {
  local label="GET /api/integrations/adapters/:type/health — 所属控制器：REST controller for integration configuration manageme"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/adapters/$(path_id type)/health" "" ""
  expect_read_ok "$label" 200
}

# seq608 asdm-admin-services-integration (端口 8882)/Integration | auth=none（配对清理: POST /api/integrations/configs/:id:  d+）
integration_post_api_integrations_configs() {
  local label="POST /api/integrations/configs — 所属控制器：REST controller for integration configuration manageme"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "adapterType": "string",
 "projectId": 1,
 "config": {},
 "lastConnectedAt": "2026-01-01T10:00:00",
 "status": "string"
}
JSONEOF
)"
  req none POST "/api/integrations/configs" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/configs/:id:  d+
  req none DELETE "/api/integrations/configs/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/api/integrations/configs/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq609 asdm-admin-services-integration (端口 8882)/Integration | auth=none
integration_get_api_integrations_configs() {
  local label="GET /api/integrations/configs — 所属控制器：REST controller for integration configuration manageme"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/configs" "" "projectId=1"
  expect_read_ok "$label" 200
}

# seq610 asdm-admin-services-integration (端口 8882)/Integration | auth=none
integration_get_api_integrations_configs_id_d() {
  local label="GET /api/integrations/configs/:id:  d+ — 所属控制器：REST controller for integration configuration manageme"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/configs/$(path_id idd)" "" ""
  expect_read_ok "$label" 200
}

# seq611 asdm-admin-services-integration (端口 8882)/Integration | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_put_api_integrations_configs_id_d() {
  local label="PUT /api/integrations/configs/:id:  d+ — 所属控制器：REST controller for integration configuration manageme"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "name": "example__RUN_ID__",
 "adapterType": "string",
 "projectId": 1,
 "config": {},
 "lastConnectedAt": "2026-01-01T10:00:00",
 "status": "string"
}
JSONEOF
)"
  req none PUT "/api/integrations/configs/$(path_id idd)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq612 asdm-admin-services-integration (端口 8882)/Integration | auth=none
integration_delete_api_integrations_configs_id_d() {
  local label="DELETE /api/integrations/configs/:id:  d+ — 所属控制器：REST controller for integration configuration manageme"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req none DELETE "/api/integrations/configs/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq613 asdm-admin-services-integration (端口 8882)/Integration | auth=none
integration_get_api_integrations_configs_check_exists() {
  local label="GET /api/integrations/configs/check-exists — 所属控制器：REST controller for integration configuration manageme"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/configs/check-exists" "" "projectId=1&adapterType=string"
  expect_read_ok "$label" 200
}

# seq614 asdm-admin-services-integration (端口 8882)/Integration | auth=none
integration_get_api_integrations_configs_projects() {
  local label="GET /api/integrations/configs/projects — 所属控制器：REST controller for integration configuration manageme"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/configs/projects" "" "adapterType=string&configParams=%5Bobject%20Object%5D"
  expect_read_ok "$label" 200
}

# seq615 asdm-admin-services-integration (端口 8882)/Integration | auth=none（配对清理: POST /api/integrations/configs/:id:  d+）
integration_post_api_integrations_configs_test() {
  local label="POST /api/integrations/configs/test — 所属控制器：REST controller for integration configuration manageme"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "adapterType": "string",
  "baseUrl": "https://example.com",
  "organization": "string",
  "pat": "string",
  "config": {
    "key": "value"
  }
}
JSONEOF
)"
  req none POST "/api/integrations/configs/test" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/configs/:id:  d+
  req none DELETE "/api/integrations/configs/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/api/integrations/configs/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq616 asdm-admin-services-integration (端口 8882)/Integration | auth=none
integration_get_api_integrations_mappings() {
  local label="GET /api/integrations/mappings — 所属控制器：REST controller for integration configuration manageme"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/mappings" "" ""
  expect_read_ok "$label" 200
}

# seq617 asdm-admin-services-integration (端口 8882)/Integration | auth=none（配对清理: POST /api/integrations/mappings/:id:  d+）
integration_post_api_integrations_mappings() {
  local label="POST /api/integrations/mappings — 所属控制器：REST controller for integration configuration manageme"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "integrationConfigId": 1,
  "repositoryId": 1,
  "externalProjectId": "string",
  "externalProjectName": "example"
}
JSONEOF
)"
  req none POST "/api/integrations/mappings" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/mappings/:id:  d+
  req none DELETE "/api/integrations/mappings/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/api/integrations/mappings/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq618 asdm-admin-services-integration (端口 8882)/Integration | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_put_api_integrations_mappings_id_d() {
  local label="PUT /api/integrations/mappings/:id:  d+ — 所属控制器：REST controller for integration configuration manageme"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "integrationConfigId": 1,
  "repositoryId": 1,
  "externalProjectId": "string",
  "externalProjectName": "example"
}
JSONEOF
)"
  req none PUT "/api/integrations/mappings/$(path_id idd)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq619 asdm-admin-services-integration (端口 8882)/Integration | auth=none
integration_delete_api_integrations_mappings_id_d() {
  local label="DELETE /api/integrations/mappings/:id:  d+ — 所属控制器：REST controller for integration configuration manageme"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req none DELETE "/api/integrations/mappings/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq620 asdm-admin-services-integration (端口 8882)/Integration | auth=none
integration_get_api_integrations_mappings_by_config() {
  local label="GET /api/integrations/mappings/by-config — 所属控制器：REST controller for integration configuration manageme"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/mappings/by-config" "" "integrationConfigId=1"
  expect_read_ok "$label" 200
}

# seq621 asdm-admin-services-integration (端口 8882)/Integration | auth=none
integration_get_api_integrations_mappings_by_repository() {
  local label="GET /api/integrations/mappings/by-repository — 所属控制器：REST controller for integration configuration manageme"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/mappings/by-repository" "" "repositoryId=1"
  expect_read_ok "$label" 200
}

# seq622 asdm-admin-services-integration (端口 8882)/Integration | auth=none
integration_get_api_integrations_mappings_count() {
  local label="GET /api/integrations/mappings/count — 所属控制器：REST controller for integration configuration manageme"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/mappings/count" "" "integrationConfigId=1&repositoryId=1"
  expect_read_ok "$label" 200
}

# seq623 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat
integration_get_api_integrations_pull_requests() {
  local label="GET /api/integrations/pull-requests — 所属控制器：REST controller for pull request domain operations. <p"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/pull-requests" "" "asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq624 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat（配对清理: POST /api/integrations/configs/:id:  d+）
integration_post_api_integrations_pull_requests() {
  local label="POST /api/integrations/pull-requests — 所属控制器：REST controller for pull request domain operations. <p"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "workspaceId": 1,
 "sourceRefName": "example",
 "targetRefName": "example",
 "title": "example__RUN_ID__",
 "description": "example text",
 "isDraft": true,
 "reviewers": [
  "string"
 ]
}
JSONEOF
)"
  req pat POST "/api/integrations/pull-requests" "$body" "asdmPat=${PAT}"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/configs/:id:  d+
  req none DELETE "/api/integrations/configs/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/api/integrations/configs/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq625 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integrations_pull_requests_pullRequestId() {
  local label="PATCH /api/integrations/pull-requests/:pullRequestId — 所属控制器：REST controller for pull request domain operations. <p"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "workspaceId": 1,
 "title": "example__RUN_ID__",
 "description": "example text",
 "status": "string",
 "completionOptions": {
  "key": "value"
 },
 "mergeOptions": {
  "key": "value"
 },
 "lastMergeSourceCommit": {
  "key": "value"
 }
}
JSONEOF
)"
  req pat PATCH "/api/integrations/pull-requests/$(path_id pullRequestId)" "$body" "asdmPat=${PAT}"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq626 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat
integration_get_api_integrations_pull_requests_pullRequestId() {
  local label="GET /api/integrations/pull-requests/:pullRequestId — 所属控制器：REST controller for pull request domain operations. <p"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/pull-requests/$(path_id pullRequestId)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq627 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat（配对清理: POST /api/integrations/pull-requests/:pullRequestId/comments/:commentId）
integration_post_api_integrations_pull_requests_pullRequestId_comments() {
  local label="POST /api/integrations/pull-requests/:pullRequestId/comments — 所属控制器：REST controller for pull request domain operations. <p"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "regUrl": "https://example.com",
  "projectRepositoryId": 1,
  "workspaceId": 1,
  "content": "example text",
  "noteId": "string",
  "severity": "string",
  "assigneeId": "string",
  "reviewCategories": "string",
  "reviewModules": "string",
  "proposerId": "string",
  "resolved": true
}
JSONEOF
)"
  req pat POST "/api/integrations/pull-requests/$(path_id pullRequestId)/comments" "$body" "asdmPat=${PAT}"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/pull-requests/:pullRequestId/comments/:commentId
  req pat DELETE "/api/integrations/pull-requests/${rid}/comments/$(path_id commentId)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/api/integrations/pull-requests/${rid}/comments/$(path_id commentId)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq628 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat
integration_get_api_integrations_pull_requests_pullRequestId_comments() {
  local label="GET /api/integrations/pull-requests/:pullRequestId/comments — 所属控制器：REST controller for pull request domain operations. <p"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/pull-requests/$(path_id pullRequestId)/comments" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq629 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat（无配对删除接口，失败请人工核查数据残留）
integration_put_api_integrations_pull_requests_pullRequestId_comments_() {
  local label="PUT /api/integrations/pull-requests/:pullRequestId/comments/:commentId — 所属控制器：REST controller for pull request domain operations. <p"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "regUrl": "https://example.com",
  "projectRepositoryId": 1,
  "workspaceId": 1,
  "content": "example text",
  "noteId": "string",
  "severity": "string",
  "assigneeId": "string",
  "reviewCategories": "string",
  "reviewModules": "string",
  "proposerId": "string",
  "resolved": true
}
JSONEOF
)"
  req pat PUT "/api/integrations/pull-requests/$(path_id pullRequestId)/comments/$(path_id commentId)" "$body" "asdmPat=${PAT}"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq630 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat
integration_get_api_integrations_pull_requests_pullRequestId_comments_() {
  local label="GET /api/integrations/pull-requests/:pullRequestId/comments/:commentId — 所属控制器：REST controller for pull request domain operations. <p"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/pull-requests/$(path_id pullRequestId)/comments/$(path_id commentId)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq631 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat
integration_delete_api_integrations_pull_requests_pullRequestId_commen() {
  local label="DELETE /api/integrations/pull-requests/:pullRequestId/comments/:commentId — 所属控制器：REST controller for pull request domain operations. <p"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integrations/pull-requests/${DUMMY_ID}/comments/${DUMMY_ID}" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq632 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat
integration_get_api_integrations_pull_requests_pullRequestId_diff() {
  local label="GET /api/integrations/pull-requests/:pullRequestId/diff — 所属控制器：REST controller for pull request domain operations. <p"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/pull-requests/$(path_id pullRequestId)/diff" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq633 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat（配对清理: POST /api/integrations/pull-requests/:pullRequestId/labels/:labelId）
integration_post_api_integrations_pull_requests_pullRequestId_labels() {
  local label="POST /api/integrations/pull-requests/:pullRequestId/labels — 所属控制器：REST controller for pull request domain operations. <p"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "name": "example__RUN_ID__"
}
JSONEOF
)"
  req pat POST "/api/integrations/pull-requests/$(path_id pullRequestId)/labels" "$body" "asdmPat=${PAT}"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/pull-requests/:pullRequestId/labels/:labelId
  req pat DELETE "/api/integrations/pull-requests/${rid}/labels/$(path_id labelId)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/api/integrations/pull-requests/${rid}/labels/$(path_id labelId)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq634 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat
integration_get_api_integrations_pull_requests_pullRequestId_labels() {
  local label="GET /api/integrations/pull-requests/:pullRequestId/labels — 所属控制器：REST controller for pull request domain operations. <p"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/pull-requests/$(path_id pullRequestId)/labels" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq635 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat
integration_delete_api_integrations_pull_requests_pullRequestId_labels() {
  local label="DELETE /api/integrations/pull-requests/:pullRequestId/labels/:labelId — 所属控制器：REST controller for pull request domain operations. <p"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integrations/pull-requests/${DUMMY_ID}/labels/${DUMMY_ID}" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq636 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat（无配对删除接口，失败请人工核查数据残留）
integration_put_api_integrations_pull_requests_pullRequestId_reviewers() {
  local label="PUT /api/integrations/pull-requests/:pullRequestId/reviewers — 所属控制器：REST controller for pull request domain operations. <p"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  req pat PUT "/api/integrations/pull-requests/$(path_id pullRequestId)/reviewers" "" "reviewer=string&regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq637 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat
integration_delete_api_integrations_pull_requests_pullRequestId_review() {
  local label="DELETE /api/integrations/pull-requests/:pullRequestId/reviewers — 所属控制器：REST controller for pull request domain operations. <p"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integrations/pull-requests/${DUMMY_ID}/reviewers" "" "reviewer=string&regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq638 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat（配对清理: POST /api/integrations/pull-requests/:pullRequestId/comments/:commentId）
integration_post_api_integrations_pull_requests_pullRequestId_submitPr() {
  local label="POST /api/integrations/pull-requests/:pullRequestId/submitPrReview — 所属控制器：REST controller for pull request domain operations. <p"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "regUrl": "https://example.com",
  "projectRepositoryId": 1,
  "workspaceId": 1,
  "reviewer": "string",
  "vote": 1,
  "isRequired": true
}
JSONEOF
)"
  req pat POST "/api/integrations/pull-requests/$(path_id pullRequestId)/submitPrReview" "$body" "asdmPat=${PAT}"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/pull-requests/:pullRequestId/comments/:commentId
  req pat DELETE "/api/integrations/pull-requests/${rid}/comments/$(path_id commentId)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/api/integrations/pull-requests/${rid}/comments/$(path_id commentId)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq639 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integrations_pull_requests_pullRequestId_threads() {
  local label="PATCH /api/integrations/pull-requests/:pullRequestId/threads/:threadId — 所属控制器：REST controller for pull request domain operations. <p"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "regUrl": "https://example.com",
  "projectRepositoryId": 1,
  "workspaceId": 1,
  "content": "example text",
  "noteId": "string",
  "severity": "string",
  "assigneeId": "string",
  "reviewCategories": "string",
  "reviewModules": "string",
  "proposerId": "string",
  "resolved": true
}
JSONEOF
)"
  req pat PATCH "/api/integrations/pull-requests/$(path_id pullRequestId)/threads/$(path_id threadId)" "$body" "asdmPat=${PAT}"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq640 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat
integration_get_api_integrations_pull_requests_branch_diff() {
  local label="GET /api/integrations/pull-requests/branch-diff — 所属控制器：REST controller for pull request domain operations. <p"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/pull-requests/branch-diff" "" "regUrl=https%3A%2F%2Fexample.com&baseVersion=1.0.0&targetVersion=1.0.0&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq641 asdm-admin-services-integration (端口 8882)/IntegrationPullRequest | auth=pat
integration_get_api_integrations_pull_requests_repositories() {
  local label="GET /api/integrations/pull-requests/repositories — 所属控制器：REST controller for pull request domain operations. <p"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/pull-requests/repositories" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq642 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat
integration_delete_api_integrations_test_management_cases_testCaseId() {
  local label="DELETE /api/integrations/test-management/cases/:testCaseId — 所属控制器：REST controller for test management domain operations."
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integrations/test-management/cases/${DUMMY_ID}" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq643 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat（配对清理: POST /api/integrations/test-management/plans/:planId）
integration_post_api_integrations_test_management_plans() {
  local label="POST /api/integrations/test-management/plans — 所属控制器：REST controller for test management domain operations."
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "name": "example__RUN_ID__",
 "description": "example text",
 "startDate": "2026-01-01",
 "endDate": "2026-01-01",
 "areaPath": "/tmp/example",
 "iteration": "string",
 "ownerId": 1
}
JSONEOF
)"
  req pat POST "/api/integrations/test-management/plans" "$body" "asdmPat=${PAT}"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/test-management/plans/:planId
  req pat DELETE "/api/integrations/test-management/plans/${rid}" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/api/integrations/test-management/plans/${rid}" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq644 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat
integration_get_api_integrations_test_management_plans() {
  local label="GET /api/integrations/test-management/plans — 所属控制器：REST controller for test management domain operations."
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/test-management/plans" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq645 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integrations_test_management_plans_planId() {
  local label="PATCH /api/integrations/test-management/plans/:planId — 所属控制器：REST controller for test management domain operations."
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "name": "example__RUN_ID__",
 "description": "example text",
 "startDate": "2026-01-01",
 "endDate": "2026-01-01",
 "areaPath": "/tmp/example",
 "iteration": "string",
 "ownerId": 1,
 "state": "string"
}
JSONEOF
)"
  req pat PATCH "/api/integrations/test-management/plans/$(path_id planId)" "$body" "asdmPat=${PAT}"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq646 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat
integration_get_api_integrations_test_management_plans_planId() {
  local label="GET /api/integrations/test-management/plans/:planId — 所属控制器：REST controller for test management domain operations."
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/test-management/plans/$(path_id planId)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq647 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat
integration_delete_api_integrations_test_management_plans_planId() {
  local label="DELETE /api/integrations/test-management/plans/:planId — 所属控制器：REST controller for test management domain operations."
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integrations/test-management/plans/${DUMMY_ID}" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq648 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat（配对清理: POST /api/integrations/test-management/plans/:planId/suites/:suiteId）
integration_post_api_integrations_test_management_plans_planId_suites() {
  local label="POST /api/integrations/test-management/plans/:planId/suites — 所属控制器：REST controller for test management domain operations."
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "name": "example__RUN_ID__",
 "description": "example text",
 "parentSuiteId": 1,
 "suiteType": "string",
 "queryString": "string",
 "testCaseIds": 1
}
JSONEOF
)"
  req pat POST "/api/integrations/test-management/plans/$(path_id planId)/suites" "$body" "asdmPat=${PAT}"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/test-management/plans/:planId/suites/:suiteId
  req pat DELETE "/api/integrations/test-management/plans/${rid}/suites/$(path_id suiteId)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/api/integrations/test-management/plans/${rid}/suites/$(path_id suiteId)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq649 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat
integration_get_api_integrations_test_management_plans_planId_suites() {
  local label="GET /api/integrations/test-management/plans/:planId/suites — 所属控制器：REST controller for test management domain operations."
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/test-management/plans/$(path_id planId)/suites" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq650 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integrations_test_management_plans_planId_suites() {
  local label="PATCH /api/integrations/test-management/plans/:planId/suites/:suiteId — 所属控制器：REST controller for test management domain operations."
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "name": "example__RUN_ID__",
 "description": "example text",
 "queryString": "string"
}
JSONEOF
)"
  req pat PATCH "/api/integrations/test-management/plans/$(path_id planId)/suites/$(path_id suiteId)" "$body" "asdmPat=${PAT}"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq651 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat
integration_get_api_integrations_test_management_plans_planId_suites_s() {
  local label="GET /api/integrations/test-management/plans/:planId/suites/:suiteId — 所属控制器：REST controller for test management domain operations."
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/test-management/plans/$(path_id planId)/suites/$(path_id suiteId)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq652 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat
integration_delete_api_integrations_test_management_plans_planId_suite() {
  local label="DELETE /api/integrations/test-management/plans/:planId/suites/:suiteId — 所属控制器：REST controller for test management domain operations."
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integrations/test-management/plans/${DUMMY_ID}/suites/${DUMMY_ID}" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq653 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat（配对清理: POST /api/integrations/test-management/plans/:planId/suites/:suiteId/cases）
integration_post_api_integrations_test_management_plans_planId_suites_() {
  local label="POST /api/integrations/test-management/plans/:planId/suites/:suiteId/cases — 所属控制器：REST controller for test management domain operations."
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "regUrl": "https://example.com",
  "projectRepositoryId": 1,
  "testCaseIds": [
    1
  ],
  "configurationIds": [
    1
  ]
}
JSONEOF
)"
  req pat POST "/api/integrations/test-management/plans/$(path_id planId)/suites/$(path_id suiteId)/cases" "$body" "asdmPat=${PAT}"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/test-management/plans/:planId/suites/:suiteId/cases
  req pat DELETE "/api/integrations/test-management/plans/${rid}/suites/$(path_id suiteId)/cases" "" "regUrl=https%3A%2F%2Fexample.com&testCaseIds=string&asdmPat=${PAT}"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/api/integrations/test-management/plans/${rid}/suites/$(path_id suiteId)/cases" "" "regUrl=https%3A%2F%2Fexample.com&testCaseIds=string&asdmPat=${PAT}"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq654 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integrations_test_management_plans_planId_suites_2() {
  local label="PATCH /api/integrations/test-management/plans/:planId/suites/:suiteId/cases — 所属控制器：REST controller for test management domain operations."
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "regUrl": "https://example.com",
  "projectRepositoryId": 1,
  "testCaseIds": [
    1
  ],
  "configurationIds": [
    1
  ]
}
JSONEOF
)"
  req pat PATCH "/api/integrations/test-management/plans/$(path_id planId)/suites/$(path_id suiteId)/cases" "$body" "asdmPat=${PAT}"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq655 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat
integration_get_api_integrations_test_management_plans_planId_suites_s_2() {
  local label="GET /api/integrations/test-management/plans/:planId/suites/:suiteId/cases — 所属控制器：REST controller for test management domain operations."
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/test-management/plans/$(path_id planId)/suites/$(path_id suiteId)/cases" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq656 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat
integration_delete_api_integrations_test_management_plans_planId_suite_2() {
  local label="DELETE /api/integrations/test-management/plans/:planId/suites/:suiteId/cases — 所属控制器：REST controller for test management domain operations."
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integrations/test-management/plans/${DUMMY_ID}/suites/${DUMMY_ID}/cases" "" "regUrl=https%3A%2F%2Fexample.com&testCaseIds=string&asdmPat=${PAT}"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq657 asdm-admin-services-integration (端口 8882)/IntegrationTestManagement | auth=pat
integration_get_api_integrations_test_management_plans_planId_suites_s_3() {
  local label="GET /api/integrations/test-management/plans/:planId/suites/:suiteId/cases/:caseId — 所属控制器：REST controller for test management domain operations."
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/test-management/plans/$(path_id planId)/suites/$(path_id suiteId)/cases/$(path_id caseId)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq658 asdm-admin-services-integration (端口 8882)/Invoke | auth=jwt（配对清理: POST /api/integrations/configs/:id:  d+）
integration_post_api_integrations_invoke() {
  local label="POST /api/integrations/invoke — 摘要：Invoke a configured third-party operation 完整路径：POST /api/"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "service": "string",
  "operation": "string",
  "payload": {}
}
JSONEOF
)"
  req jwt POST "/api/integrations/invoke" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/configs/:id:  d+
  req none DELETE "/api/integrations/configs/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/api/integrations/configs/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq659 asdm-admin-services-integration (端口 8882)/ItolIntegration | auth=none
integration_get_api_integrations_data_dictionary_health() {
  local label="GET /api/integrations/data-dictionary/health — 摘要：Check Automation adapter health 完整路径：GET /api/integration"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/data-dictionary/health" "" ""
  expect_read_ok "$label" 200
}

# seq660 asdm-admin-services-integration (端口 8882)/ItolIntegration | auth=none
integration_get_api_integrations_data_dictionary_info() {
  local label="GET /api/integrations/data-dictionary/info — 摘要：Get Automation adapter info 完整路径：GET /api/integrations/da"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/data-dictionary/info" "" ""
  expect_read_ok "$label" 200
}

# seq661 asdm-admin-services-integration (端口 8882)/ItolIntegration | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integrations_data_dictionary_query() {
  local label="POST /api/integrations/data-dictionary/query — 摘要：Search Automation data dictionary fields 说明：Proxy search"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req none POST "/api/integrations/data-dictionary/query" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq662 asdm-admin-services-integration (端口 8882)/ItolModelIntegration | auth=jwt（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integrations_itol_model_createTable() {
  local label="POST /api/integrations/itol/model/createTable — 摘要：Create ITOL model table 完整路径：POST /api/integrations/itol/"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/integrations/itol/model/createTable" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq663 asdm-admin-services-integration (端口 8882)/ItolModelIntegration | auth=jwt（无配对删除接口，失败请人工核查数据残留）
integration_post_api_integrations_itol_model_getBySystem() {
  local label="POST /api/integrations/itol/model/getBySystem — 摘要：Get ITOL models by system 完整路径：POST /api/integrations/ito"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/integrations/itol/model/getBySystem" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq664 asdm-admin-services-integration (端口 8882)/PAT Mappings | auth=pat（配对清理: POST /api/integrations/pat-mappings/:id）
integration_post_api_integrations_pat_mappings() {
  local label="POST /api/integrations/pat-mappings — 摘要：Create PAT mapping 说明：Create a new PAT mapping between AS"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "userId": 1,
  "asdmPatId": 1,
  "adapterType": "string",
  "externalPat": "string",
  "status": "string"
}
JSONEOF
)"
  req pat POST "/api/integrations/pat-mappings" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/pat-mappings/:id
  req none DELETE "/api/integrations/pat-mappings/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req none DELETE "/api/integrations/pat-mappings/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq665 asdm-admin-services-integration (端口 8882)/PAT Mappings | auth=none
integration_get_api_integrations_pat_mappings_id() {
  local label="GET /api/integrations/pat-mappings/:id — 摘要：Get PAT mapping by ID 说明：Get a specific PAT mapping by it"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/pat-mappings/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq666 asdm-admin-services-integration (端口 8882)/PAT Mappings | auth=pat（无配对删除接口，失败请人工核查数据残留）
integration_put_api_integrations_pat_mappings_id() {
  local label="PUT /api/integrations/pat-mappings/:id — 摘要：Update PAT mapping 说明：Update an existing PAT mapping"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "userId": 1,
  "asdmPatId": 1,
  "adapterType": "string",
  "externalPat": "string",
  "status": "string"
}
JSONEOF
)"
  req pat PUT "/api/integrations/pat-mappings/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq667 asdm-admin-services-integration (端口 8882)/PAT Mappings | auth=none
integration_delete_api_integrations_pat_mappings_id() {
  local label="DELETE /api/integrations/pat-mappings/:id — 摘要：Delete PAT mapping 说明：Delete a PAT mapping by ID"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req none DELETE "/api/integrations/pat-mappings/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq668 asdm-admin-services-integration (端口 8882)/PAT Mappings | auth=none（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integrations_pat_mappings_id_status() {
  local label="PATCH /api/integrations/pat-mappings/:id/status — 摘要：Update PAT mapping status 说明：Update the status of a PAT m"
  writes_allowed "$label" || return 0
  need_auth none "$label" || return 0
  req none PATCH "/api/integrations/pat-mappings/$(path_id id)/status" "" "status=string"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq669 asdm-admin-services-integration (端口 8882)/PAT Mappings | auth=none
integration_get_api_integrations_pat_mappings_exists() {
  local label="GET /api/integrations/pat-mappings/exists — 摘要：Check if PAT mapping exists 说明：Check if an active PAT map"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/pat-mappings/exists" "" "userId=1&adapterType=string"
  expect_read_ok "$label" 200
}

# seq670 asdm-admin-services-integration (端口 8882)/PAT Mappings | auth=none
integration_get_api_integrations_pat_mappings_user_userId() {
  local label="GET /api/integrations/pat-mappings/user/:userId — 摘要：Get PAT mappings by user ID 说明：Get all PAT mappings for a"
  need_auth none "$label" || return 0
  req none GET "/api/integrations/pat-mappings/user/$(path_id userId)" "" ""
  expect_read_ok "$label" 200
}

# seq671 asdm-admin-services-integration (端口 8882)/WorkItem | auth=pat
integration_get_api_integrations_workitems() {
  local label="GET /api/integrations/workitems — 所属控制器：REST controller for work item domain operations. <p>Ex"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/workitems" "" "asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq672 asdm-admin-services-integration (端口 8882)/WorkItem | auth=pat（配对清理: POST /api/integrations/workitems/:id）
integration_post_api_integrations_workitems() {
  local label="POST /api/integrations/workitems — 所属控制器：REST controller for work item domain operations. <p>Ex"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "workItemType": "string",
 "title": "example__RUN_ID__",
 "description": "example text",
 "priority": "string",
 "state": "string",
 "category": "string",
 "tags": [
  "string"
 ],
 "multilineFieldsFormat": "string",
 "assignee": "string",
 "recipient": [
  {
   "key": "value"
  }
 ],
 "assignedCc": [
  {
   "key": "value"
  }
 ],
 "planStartDate": "2026-01-01",
 "planEndDate": "2026-01-01",
 "workload": "string",
 "link": "https://example.com",
 "labels": [
  {
   "key": "value"
  }
 ],
 "customFields": [
  {
   "key": "value"
  }
 ],
 "children": [
  {
   "key": "value"
  }
 ],
 "ir2feature": "string",
 "relatedNetworkSecurity": "string",
 "collaboratives": "string",
 "businessDomain": "string",
 "module": "string",
 "parentId": "string"
}
JSONEOF
)"
  req pat POST "/api/integrations/workitems" "$body" "asdmPat=${PAT}"
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/integrations/workitems/:id
  req pat DELETE "/api/integrations/workitems/${rid}" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req pat DELETE "/api/integrations/workitems/${rid}" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq673 asdm-admin-services-integration (端口 8882)/WorkItem | auth=pat（无配对删除接口，失败请人工核查数据残留）
integration_patch_api_integrations_workitems_id() {
  local label="PATCH /api/integrations/workitems/:id — 所属控制器：REST controller for work item domain operations. <p>Ex"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  local body; body="$(sed "s|__RUN_ID__|${RUN_ID}|g" <<'JSONEOF'
{
 "regUrl": "https://example.com",
 "projectRepositoryId": 1,
 "state": "string",
 "title": "example__RUN_ID__",
 "description": "example text",
 "priority": "string",
 "assignee": "string",
 "category": "string",
 "tags": [
  "string"
 ],
 "multilineFieldsFormat": "string",
 "comment": "example text",
 "extensionFields": {
  "key": "value"
 },
 "updateRelations": {
  "key": "value"
 },
 "addRelations": [
  {
   "rel": "string",
   "url": "https://example.com",
   "comment": "example text",
   "workItemId": "string",
   "linkType": "https://example.com"
  }
 ],
 "removeRelations": [
  1
 ],
 "recipient": [
  {
   "key": "value"
  }
 ],
 "assignedCc": [
  {
   "key": "value"
  }
 ],
 "planStartDate": "2026-01-01",
 "planEndDate": "2026-01-01",
 "workload": "string",
 "link": "https://example.com",
 "labels": [
  {
   "key": "value"
  }
 ],
 "customFields": [
  {
   "key": "value"
  }
 ],
 "children": [
  {
   "key": "value"
  }
 ],
 "ir2feature": "string",
 "relatedNetworkSecurity": "string",
 "collaboratives": "string",
 "businessDomain": "string",
 "module": "string",
 "parentId": "string"
}
JSONEOF
)"
  req pat PATCH "/api/integrations/workitems/$(path_id id)" "$body" "asdmPat=${PAT}"
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq674 asdm-admin-services-integration (端口 8882)/WorkItem | auth=pat
integration_get_api_integrations_workitems_id() {
  local label="GET /api/integrations/workitems/:id — 所属控制器：REST controller for work item domain operations. <p>Ex"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/workitems/$(path_id id)" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq675 asdm-admin-services-integration (端口 8882)/WorkItem | auth=pat
integration_delete_api_integrations_workitems_id() {
  local label="DELETE /api/integrations/workitems/:id — 所属控制器：REST controller for work item domain operations. <p>Ex"
  writes_allowed "$label" || return 0
  need_auth pat "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req pat DELETE "/api/integrations/workitems/${DUMMY_ID}" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_status "$label (幂等删除校验)" 200 404
}

# seq676 asdm-admin-services-integration (端口 8882)/WorkItem | auth=pat
integration_get_api_integrations_workitems_priorities() {
  local label="GET /api/integrations/workitems/priorities — 所属控制器：REST controller for work item domain operations. <p>Ex"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/workitems/priorities" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq677 asdm-admin-services-integration (端口 8882)/WorkItem | auth=pat
integration_get_api_integrations_workitems_states() {
  local label="GET /api/integrations/workitems/states — 所属控制器：REST controller for work item domain operations. <p>Ex"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/workitems/states" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# seq678 asdm-admin-services-integration (端口 8882)/WorkItem | auth=pat
integration_get_api_integrations_workitems_types() {
  local label="GET /api/integrations/workitems/types — 所属控制器：REST controller for work item domain operations. <p>Ex"
  need_auth pat "$label" || return 0
  req pat GET "/api/integrations/workitems/types" "" "regUrl=https%3A%2F%2Fexample.com&asdmPat=${PAT}"
  expect_read_ok "$label" 200
}

# ===== 入口 =====
main() {
  set +e   # 单用例失败不中断
  echo ""
  echo "========== 集成域 (209 apis) =========="
  login_if_needed || true
  integration_post_api_integration_adapter_ads_pull_requests || true
  integration_get_api_integration_adapter_ads_pull_requests || true
  integration_patch_api_integration_adapter_ads_pull_requests_pullReques || true
  integration_get_api_integration_adapter_ads_pull_requests_pullRequestI || true
  integration_post_api_integration_adapter_ads_pull_requests_pullRequest || true
  integration_get_api_integration_adapter_ads_pull_requests_pullRequestI_2 || true
  integration_post_api_integration_adapter_ads_pull_requests_pullRequest_2 || true
  integration_get_api_integration_adapter_ads_pull_requests_pullRequestI_3 || true
  integration_delete_api_integration_adapter_ads_pull_requests_pullReque || true
  integration_put_api_integration_adapter_ads_pull_requests_pullRequestI || true
  integration_delete_api_integration_adapter_ads_pull_requests_pullReque_2 || true
  integration_post_api_integration_adapter_ads_pull_requests_pullRequest_3 || true
  integration_patch_api_integration_adapter_ads_pull_requests_pullReques_2 || true
  integration_get_api_integration_adapter_ads_pull_requests_branch_diff || true
  integration_get_api_integration_adapter_ads_pull_requests_repositories || true
  integration_delete_api_integration_adapter_ads_test_management_cases_t || true
  integration_post_api_integration_adapter_ads_test_management_plans || true
  integration_get_api_integration_adapter_ads_test_management_plans || true
  integration_patch_api_integration_adapter_ads_test_management_plans_pl || true
  integration_get_api_integration_adapter_ads_test_management_plans_plan || true
  integration_delete_api_integration_adapter_ads_test_management_plans_p || true
  integration_post_api_integration_adapter_ads_test_management_plans_pla || true
  integration_get_api_integration_adapter_ads_test_management_plans_plan_2 || true
  integration_patch_api_integration_adapter_ads_test_management_plans_pl_2 || true
  integration_get_api_integration_adapter_ads_test_management_plans_plan_3 || true
  integration_delete_api_integration_adapter_ads_test_management_plans_p_2 || true
  integration_post_api_integration_adapter_ads_test_management_plans_pla_2 || true
  integration_patch_api_integration_adapter_ads_test_management_plans_pl_3 || true
  integration_get_api_integration_adapter_ads_test_management_plans_plan_4 || true
  integration_delete_api_integration_adapter_ads_test_management_plans_p_3 || true
  integration_get_api_integration_adapter_ads_test_management_plans_plan_5 || true
  integration_get_api_integration_adapter_ads_health || true
  integration_get_api_integration_adapter_ads_info || true
  integration_get_api_integration_adapter_ads_projects || true
  integration_get_api_integration_adapter_ads_test_connection || true
  integration_get_api_integration_adapter_ads_users || true
  integration_get_api_integration_adapter_ads_users_debug || true
  integration_get_api_integration_adapter_ads_workitems || true
  integration_post_api_integration_adapter_ads_workitems || true
  integration_patch_api_integration_adapter_ads_workitems_id || true
  integration_get_api_integration_adapter_ads_workitems_id || true
  integration_get_api_integration_adapter_ads_workitemtypes || true
  integration_get_api_integration_adapter_automation_coding_health || true
  integration_get_api_integration_adapter_automation_coding_pull_request || true
  integration_post_api_integration_adapter_automation_coding_pull_reques || true
  integration_get_api_integration_adapter_automation_coding_pull_request_2 || true
  integration_get_api_integration_adapter_automation_coding_pull_request_3 || true
  integration_get_api_integration_adapter_automation_coding_test_connect || true
  integration_post_api_itol_integrated_push || true
  integration_get_api_integration_adapter_automation_itol_health || true
  integration_post_api_integration_adapter_automation_itol_imports || true
  integration_get_api_integration_adapter_automation_itol_imports_batchI || true
  integration_post_api_integration_adapter_automation_itol_imports_uploa || true
  integration_get_api_integration_adapter_automation_itol_info || true
  integration_post_api_integration_adapter_automation_itol_publish || true
  integration_post_api_integration_adapter_automation_itol_query || true
  integration_post_api_integration_adapter_automation_itol_rollback || true
  integration_get_api_integration_adapter_automation_itol_test_connectio || true
  integration_post_api_integration_adapter_automation_itol_integrated_pu || true
  integration_post_api_integration_adapter_automation_itol_model_createT || true
  integration_post_api_integration_adapter_automation_itol_model_getBySy || true
  integration_post_api_integration_adapter_rag_relay || true
  integration_post_api_integration_adapter_automation_relay || true
  integration_post_api_integration_adapter_automation_target_messages || true
  integration_get_api_integration_adapter_codearts_health || true
  integration_get_api_integration_adapter_codearts_info || true
  integration_get_api_integration_adapter_codearts_projects || true
  integration_get_api_integration_adapter_codearts_test_connection || true
  integration_post_api_integration_adapter_codearts_pull_requests || true
  integration_get_api_integration_adapter_codearts_pull_requests || true
  integration_patch_api_integration_adapter_codearts_pull_requests_id || true
  integration_get_api_integration_adapter_codearts_pull_requests_id || true
  integration_put_api_integration_adapter_codearts_pull_requests_id_clos || true
  integration_post_api_integration_adapter_codearts_pull_requests_id_com || true
  integration_get_api_integration_adapter_codearts_pull_requests_id_comm || true
  integration_put_api_integration_adapter_codearts_pull_requests_id_comm || true
  integration_get_api_integration_adapter_codearts_pull_requests_id_comm_2 || true
  integration_delete_api_integration_adapter_codearts_pull_requests_id_c || true
  integration_get_api_integration_adapter_codearts_pull_requests_id_diff || true
  integration_put_api_integration_adapter_codearts_pull_requests_id_merg || true
  integration_post_api_integration_adapter_codearts_pull_requests_id_sub || true
  integration_get_api_integration_adapter_codearts_pull_requests_reposit || true
  integration_post_api_integration_adapter_codearts_workitems || true
  integration_get_api_integration_adapter_codearts_workitems || true
  integration_patch_api_integration_adapter_codearts_workitems_id || true
  integration_delete_api_integration_adapter_codearts_workitems_id || true
  integration_get_api_integration_adapter_codearts_workitems_id || true
  integration_put_api_integration_adapter_codearts_workitems_batch || true
  integration_delete_api_integration_adapter_codearts_workitems_batch || true
  integration_post_api_integration_adapter_codearts_workitems_batch || true
  integration_get_api_integration_adapter_codearts_workitems_fields || true
  integration_get_api_integration_adapter_codearts_workitems_states || true
  integration_get_api_integration_adapter_gitlab_groups_groupId_projects || true
  integration_get_api_integration_adapter_gitlab_health || true
  integration_get_api_integration_adapter_gitlab_info || true
  integration_get_api_integration_adapter_gitlab_projects || true
  integration_get_api_integration_adapter_gitlab_projects_projectId || true
  integration_post_api_integration_adapter_gitlab_pullrequests || true
  integration_get_api_integration_adapter_gitlab_pullrequests || true
  integration_get_api_integration_adapter_gitlab_pullrequests_iid || true
  integration_patch_api_integration_adapter_gitlab_pullrequests_iid || true
  integration_post_api_integration_adapter_gitlab_pullrequests_iid_appro || true
  integration_post_api_integration_adapter_gitlab_pullrequests_iid_comme || true
  integration_get_api_integration_adapter_gitlab_pullrequests_iid_diff || true
  integration_put_api_integration_adapter_gitlab_pullrequests_iid_review || true
  integration_delete_api_integration_adapter_gitlab_pullrequests_iid_rev || true
  integration_post_api_integration_adapter_gitlab_pullrequests_iid_submi || true
  integration_post_api_integration_adapter_gitlab_pullrequests_iid_unapp || true
  integration_get_api_integration_adapter_gitlab_pullrequests_branch_dif || true
  integration_get_api_integration_adapter_gitlab_pullrequests_repositori || true
  integration_get_api_integration_adapter_gitlab_test_connection || true
  integration_post_api_integration_adapter_gitlab_workitems || true
  integration_get_api_integration_adapter_gitlab_workitems || true
  integration_patch_api_integration_adapter_gitlab_workitems_iid || true
  integration_get_api_integration_adapter_gitlab_workitems_iid || true
  integration_delete_api_integration_adapter_gitlab_workitems_iid || true
  integration_get_api_integration_adapter_gitlab_workitems_iid_links || true
  integration_post_api_integration_adapter_gitlab_workitems_iid_links || true
  integration_delete_api_integration_adapter_gitlab_workitems_iid_links_ || true
  integration_get_actuator_health || true
  integration_get_api_citic_aicoding_stats || true
  integration_get_api_citic_gen_lines || true
  integration_post_api_citic_sync_history || true
  integration_get_api_citic_sync_history_status || true
  integration_post_api_citic_sync || true
  integration_get_api_citic_token_usage || true
  integration_get_api_citic_usage_count || true
  integration_post_api_adapter_register || true
  integration_get_api_integrations_ads_configs_id_projects || true
  integration_get_api_integrations_ads_projects || true
  integration_get_api_integrations_audit_logs || true
  integration_get_api_integrations_audit_logs_id || true
  integration_get_api_integrations_audit_logs_by_integration_integration || true
  integration_post_api_integrations_rag || true
  integration_post_api_integrations_automation_messages || true
  integration_post_api_integrations_integrated_push_push || true
  integration_get_api_integrations_adapters || true
  integration_get_api_integrations_adapters_type_health || true
  integration_post_api_integrations_configs || true
  integration_get_api_integrations_configs || true
  integration_get_api_integrations_configs_id_d || true
  integration_put_api_integrations_configs_id_d || true
  integration_delete_api_integrations_configs_id_d || true
  integration_get_api_integrations_configs_check_exists || true
  integration_get_api_integrations_configs_projects || true
  integration_post_api_integrations_configs_test || true
  integration_get_api_integrations_mappings || true
  integration_post_api_integrations_mappings || true
  integration_put_api_integrations_mappings_id_d || true
  integration_delete_api_integrations_mappings_id_d || true
  integration_get_api_integrations_mappings_by_config || true
  integration_get_api_integrations_mappings_by_repository || true
  integration_get_api_integrations_mappings_count || true
  integration_get_api_integrations_pull_requests || true
  integration_post_api_integrations_pull_requests || true
  integration_patch_api_integrations_pull_requests_pullRequestId || true
  integration_get_api_integrations_pull_requests_pullRequestId || true
  integration_post_api_integrations_pull_requests_pullRequestId_comments || true
  integration_get_api_integrations_pull_requests_pullRequestId_comments || true
  integration_put_api_integrations_pull_requests_pullRequestId_comments_ || true
  integration_get_api_integrations_pull_requests_pullRequestId_comments_ || true
  integration_delete_api_integrations_pull_requests_pullRequestId_commen || true
  integration_get_api_integrations_pull_requests_pullRequestId_diff || true
  integration_post_api_integrations_pull_requests_pullRequestId_labels || true
  integration_get_api_integrations_pull_requests_pullRequestId_labels || true
  integration_delete_api_integrations_pull_requests_pullRequestId_labels || true
  integration_put_api_integrations_pull_requests_pullRequestId_reviewers || true
  integration_delete_api_integrations_pull_requests_pullRequestId_review || true
  integration_post_api_integrations_pull_requests_pullRequestId_submitPr || true
  integration_patch_api_integrations_pull_requests_pullRequestId_threads || true
  integration_get_api_integrations_pull_requests_branch_diff || true
  integration_get_api_integrations_pull_requests_repositories || true
  integration_delete_api_integrations_test_management_cases_testCaseId || true
  integration_post_api_integrations_test_management_plans || true
  integration_get_api_integrations_test_management_plans || true
  integration_patch_api_integrations_test_management_plans_planId || true
  integration_get_api_integrations_test_management_plans_planId || true
  integration_delete_api_integrations_test_management_plans_planId || true
  integration_post_api_integrations_test_management_plans_planId_suites || true
  integration_get_api_integrations_test_management_plans_planId_suites || true
  integration_patch_api_integrations_test_management_plans_planId_suites || true
  integration_get_api_integrations_test_management_plans_planId_suites_s || true
  integration_delete_api_integrations_test_management_plans_planId_suite || true
  integration_post_api_integrations_test_management_plans_planId_suites_ || true
  integration_patch_api_integrations_test_management_plans_planId_suites_2 || true
  integration_get_api_integrations_test_management_plans_planId_suites_s_2 || true
  integration_delete_api_integrations_test_management_plans_planId_suite_2 || true
  integration_get_api_integrations_test_management_plans_planId_suites_s_3 || true
  integration_post_api_integrations_invoke || true
  integration_get_api_integrations_data_dictionary_health || true
  integration_get_api_integrations_data_dictionary_info || true
  integration_post_api_integrations_data_dictionary_query || true
  integration_post_api_integrations_itol_model_createTable || true
  integration_post_api_integrations_itol_model_getBySystem || true
  integration_post_api_integrations_pat_mappings || true
  integration_get_api_integrations_pat_mappings_id || true
  integration_put_api_integrations_pat_mappings_id || true
  integration_delete_api_integrations_pat_mappings_id || true
  integration_patch_api_integrations_pat_mappings_id_status || true
  integration_get_api_integrations_pat_mappings_exists || true
  integration_get_api_integrations_pat_mappings_user_userId || true
  integration_get_api_integrations_workitems || true
  integration_post_api_integrations_workitems || true
  integration_patch_api_integrations_workitems_id || true
  integration_get_api_integrations_workitems_id || true
  integration_delete_api_integrations_workitems_id || true
  integration_get_api_integrations_workitems_priorities || true
  integration_get_api_integrations_workitems_states || true
  integration_get_api_integrations_workitems_types || true
  finish
}
main "$@"
