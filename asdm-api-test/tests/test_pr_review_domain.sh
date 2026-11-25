#!/usr/bin/env bash
# ============================================================================
# 代码评审域 — 幂等自动化测试（由 gen/generate.js 从 api.json 生成，勿手工修改）
# 重新生成: node gen/generate.js
# 覆盖服务: core
# 接口总数: 18（读 9 直测 / 写 9 受控[含配对清理 1] / 永久跳过 0）
# 环境变量: ASDM_BASE_URL / ASDM_LOGIN_EMAIL / ASDM_LOGIN_PASSWORD / ASDM_TOKEN /
#           ASDM_PAT / ASDM_INTERNAL_TOKEN / ASDM_OPEN_ACCESS_TOKEN / ASDM_CITIC_SECRET /
#           ASDM_ALLOW_WRITES=1（执行写操作）/ ASDM_TEST_<参数名>（路径参数覆盖）
# ============================================================================
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../common.sh"

# ===== 被测接口用例 =====
# seq679 asdm-admin-services-core (端口 8880)/PR Review Config | auth=jwt（配对清理: POST /api/code-review/configs/:id）
pr_review_post_api_code_review_configs() {
  local label="POST /api/code-review/configs — 摘要：新增评审配置（按仓库唯一） 完整路径：POST /api/code-review/configs（服务：asdm-"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "projectId": 1,
  "collectionId": 1,
  "projectRepositoryId": 1,
  "repositoryUrl": "https://example.com",
  "enabled": true,
  "triggerMode": "string",
  "reviewCommand": "string",
  "reviewLabel": "example",
  "removeLabelAfterTrigger": true,
  "skipDraft": true,
  "targetBranchPattern": "string",
  "maxDiffFiles": 10,
  "maxDiffLines": 10,
  "toolsetId": "string",
  "toolsetCommands": "string",
  "pipelineServerId": 1,
  "workspaceId": 1,
  "botPat": "string"
}
JSONEOF
)"
  req jwt POST "/api/code-review/configs" "$body" ""
  if ! expect_status "$label" 200; then return 1; fi
  expect_json_top "$label"
  local rid; rid="$(extract_id)"
  if [[ -z "$rid" ]]; then
    note "未能从响应提取资源 ID，跳过配对清理（请检查是否残留测试数据）：$(head -c 200 <<<"$BODY")"
    return 0
  fi
  # 清理：POST /api/code-review/configs/:id
  req jwt DELETE "/api/code-review/configs/${rid}" "" ""
  if ! expect_status "$label 清理删除" 200 404; then return 1; fi
  # 幂等：再次删除应成功或 404
  req jwt DELETE "/api/code-review/configs/${rid}" "" ""
  expect_status "$label 二次删除(幂等)" 200 404
}

# seq680 asdm-admin-services-core (端口 8880)/PR Review Config | auth=jwt
pr_review_get_api_code_review_configs() {
  local label="GET /api/code-review/configs — 摘要：按项目查询评审配置列表 完整路径：GET /api/code-review/configs（服务：asdm-adm"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/code-review/configs" "" "projectId=1"
  expect_read_ok "$label" 200
}

# seq681 asdm-admin-services-core (端口 8880)/PR Review Config | auth=jwt
pr_review_get_api_code_review_configs_id() {
  local label="GET /api/code-review/configs/:id — 摘要：查询单条评审配置 完整路径：GET /api/code-review/configs/:id（服务：asdm-ad"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/code-review/configs/$(path_id id)" "" ""
  expect_read_ok "$label" 200
}

# seq682 asdm-admin-services-core (端口 8880)/PR Review Config | auth=jwt（无配对删除接口，失败请人工核查数据残留）
pr_review_put_api_code_review_configs_id() {
  local label="PUT /api/code-review/configs/:id — 摘要：更新评审配置 完整路径：PUT /api/code-review/configs/:id（服务：asdm-admi"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "projectId": 1,
  "collectionId": 1,
  "projectRepositoryId": 1,
  "repositoryUrl": "https://example.com",
  "enabled": true,
  "triggerMode": "string",
  "reviewCommand": "string",
  "reviewLabel": "example",
  "removeLabelAfterTrigger": true,
  "skipDraft": true,
  "targetBranchPattern": "string",
  "maxDiffFiles": 10,
  "maxDiffLines": 10,
  "toolsetId": "string",
  "toolsetCommands": "string",
  "pipelineServerId": 1,
  "workspaceId": 1,
  "botPat": "string"
}
JSONEOF
)"
  req jwt PUT "/api/code-review/configs/$(path_id id)" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq683 asdm-admin-services-core (端口 8880)/PR Review Config | auth=jwt
pr_review_delete_api_code_review_configs_id() {
  local label="DELETE /api/code-review/configs/:id — 摘要：删除评审配置 完整路径：DELETE /api/code-review/configs/:id（服务：asdm-a"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  # 幂等语义校验：删除"大概率不存在"的资源（DUMMY_ID），期望 200（服务端幂等）或 404
  req jwt DELETE "/api/code-review/configs/${DUMMY_ID}" "" ""
  expect_status "$label (幂等删除校验)" 200 404
}

# seq684 asdm-admin-services-core (端口 8880)/PR Review Config | auth=jwt
pr_review_get_api_code_review_configs_preflight() {
  local label="GET /api/code-review/configs/preflight — 摘要：保存前置自检：集成域是否已建「仓库↔集成配置」映射（缺失会导致 DIFF 阶段 500） 完整路径：GET /ap"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/code-review/configs/preflight" "" "projectId=1&projectRepositoryId=1"
  expect_read_ok "$label" 200
}

# seq685 asdm-admin-services-core (端口 8880)/PR Review Owner Project | auth=jwt
pr_review_get_api_code_review_platform_integrations_owner_project() {
  local label="GET /api/code-review/platform-integrations/owner-project — 摘要：查询代码评审归属项目（含兼容回落状态） 完整路径：GET /api/code-review/platform-in"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/code-review/platform-integrations/owner-project" "" ""
  expect_read_ok "$label" 200
}

# seq686 asdm-admin-services-core (端口 8880)/PR Review Owner Project | auth=jwt（无配对删除接口，失败请人工核查数据残留）
pr_review_put_api_code_review_platform_integrations_owner_project() {
  local label="PUT /api/code-review/platform-integrations/owner-project — 摘要：保存代码评审归属项目 完整路径：PUT /api/code-review/platform-integration"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "projectId": 1
}
JSONEOF
)"
  req jwt PUT "/api/code-review/platform-integrations/owner-project" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq687 asdm-admin-services-core (端口 8880)/PR Review Platform Config | auth=jwt
pr_review_get_api_code_review_platform_config() {
  local label="GET /api/code-review/platform-config — 摘要：查询代码评审单实例配置摘要（订阅地址仅返回掩码） 完整路径：GET /api/code-review/platfo"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/code-review/platform-config" "" ""
  expect_read_ok "$label" 200
}

# seq688 asdm-admin-services-core (端口 8880)/PR Review Platform Config | auth=jwt（无配对删除接口，失败请人工核查数据残留）
pr_review_put_api_code_review_platform_config() {
  local label="PUT /api/code-review/platform-config — 摘要：保存代码评审单实例配置（单事务完成集成配置与评审配置物化） 完整路径：PUT /api/code-review/p"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "collectionId": 1,
  "projectId": 1,
  "workspaceId": 1,
  "pipelineServerId": 1,
  "platform": "string",
  "platformPat": "string",
  "asdmPat": "string",
  "reviewCommand": "string",
  "toolsetId": "string",
  "confirmPlatformSwitch": true
}
JSONEOF
)"
  req jwt PUT "/api/code-review/platform-config" "$body" ""
  expect_status_missing "$label" 200 404  # 404→资源不存在(默认ID)，记 SKIP
}

# seq689 asdm-admin-services-core (端口 8880)/PR Review Platform Config | auth=jwt
pr_review_get_api_code_review_platform_config_subscription_url() {
  local label="GET /api/code-review/platform-config/subscription-url — 摘要：获取完整订阅地址（含 ASDM PAT 明文） 完整路径：GET /api/code-review/platfor"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/code-review/platform-config/subscription-url" "" ""
  expect_read_ok "$label" 200
}

# seq690 asdm-admin-services-core (端口 8880)/PR Review Platform Config | auth=jwt（无配对删除接口，失败请人工核查数据残留）
pr_review_post_api_code_review_platform_config_test_connection() {
  local label="POST /api/code-review/platform-config/test-connection — 摘要：测试平台连接（失败不阻断保存） 完整路径：POST /api/code-review/platform-confi"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
{
  "platform": "string",
  "platformPat": "string"
}
JSONEOF
)"
  req jwt POST "/api/code-review/platform-config/test-connection" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq691 asdm-admin-services-core (端口 8880)/PR Review Task | auth=jwt
pr_review_get_api_code_review_tasks() {
  local label="GET /api/code-review/tasks — 摘要：分页查询评审任务 说明：支持按 pullRequestId / status 过滤；status 取值 PENDI"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/code-review/tasks" "" "projectId=1&page=0&size=20"
  expect_read_ok "$label" 200
}

# seq692 asdm-admin-services-core (端口 8880)/PR Review Task | auth=jwt
pr_review_get_api_code_review_tasks_guid() {
  local label="GET /api/code-review/tasks/:guid — 摘要：查询评审任务详情（含问题明细） 完整路径：GET /api/code-review/tasks/:guid（服务："
  need_auth jwt "$label" || return 0
  req jwt GET "/api/code-review/tasks/$(path_id guid)" "" ""
  expect_read_ok "$label" 200
}

# seq693 asdm-admin-services-core (端口 8880)/PR Review Task | auth=jwt（无配对删除接口，失败请人工核查数据残留）
pr_review_post_api_code_review_tasks_guid_retry() {
  local label="POST /api/code-review/tasks/:guid/retry — 摘要：失败任务重试（生成新任务，保留原任务） 说明：仅 FAILED 任务可重试；重试任务状态为 PENDING，实际重"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  req jwt POST "/api/code-review/tasks/$(path_id guid)/retry" "" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq694 asdm-admin-services-core (端口 8880)/PR Review Webhook | auth=jwt（无配对删除接口，失败请人工核查数据残留）
pr_review_post_api_webhook_pr_review() {
  local label="POST /api/webhook/pr-review — 摘要：接收 PR 事件（ADS / CODING） 说明：ADS：git.pullrequest.created / g"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/webhook/pr-review" "$body" "dryRun=false"
  expect_status "$label" 200
  expect_json_top "$label"
}

# seq695 asdm-admin-services-core (端口 8880)/PR Review Webhook | auth=jwt
pr_review_get_api_webhook_pr_review_selfcheck() {
  local label="GET /api/webhook/pr-review/selfcheck — 摘要：PR 评审只读自检（需 ASDM PAT） 说明：8 项只读检查 + 可选制品探测；关闭时返回 404"
  need_auth jwt "$label" || return 0
  req jwt GET "/api/webhook/pr-review/selfcheck" "" ""
  expect_read_ok "$label" 200
}

# seq696 asdm-admin-services-core (端口 8880)/Reporting Events (compat stub) | auth=jwt（无配对删除接口，失败请人工核查数据残留）
pr_review_post_api_reporting_events() {
  local label="POST /api/reporting/events — 摘要：Accept and discard legacy event batches 说明：No-op. Returns"
  writes_allowed "$label" || return 0
  need_auth jwt "$label" || return 0
  local body; body="$(cat <<'JSONEOF'
"string"
JSONEOF
)"
  req jwt POST "/api/reporting/events" "$body" ""
  expect_status "$label" 200
  expect_json_top "$label"
}

# ===== 入口 =====
main() {
  set +e   # 单用例失败不中断
  echo ""
  echo "========== 代码评审域 (18 apis) =========="
  login_if_needed || true
  pr_review_post_api_code_review_configs || true
  pr_review_get_api_code_review_configs || true
  pr_review_get_api_code_review_configs_id || true
  pr_review_put_api_code_review_configs_id || true
  pr_review_delete_api_code_review_configs_id || true
  pr_review_get_api_code_review_configs_preflight || true
  pr_review_get_api_code_review_platform_integrations_owner_project || true
  pr_review_put_api_code_review_platform_integrations_owner_project || true
  pr_review_get_api_code_review_platform_config || true
  pr_review_put_api_code_review_platform_config || true
  pr_review_get_api_code_review_platform_config_subscription_url || true
  pr_review_post_api_code_review_platform_config_test_connection || true
  pr_review_get_api_code_review_tasks || true
  pr_review_get_api_code_review_tasks_guid || true
  pr_review_post_api_code_review_tasks_guid_retry || true
  pr_review_post_api_webhook_pr_review || true
  pr_review_get_api_webhook_pr_review_selfcheck || true
  pr_review_post_api_reporting_events || true
  finish
}
main "$@"
