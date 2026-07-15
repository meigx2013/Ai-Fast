# ASDM Action: Auto Test CI

## Metadata

```json
{
  "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456794",
  "name": "auto-test-ci",
  "displayName": "生成 CI/CD 配置",
  "description": "根据目标平台生成 Jenkins/GitHub Actions/GitLab CI/Azure Pipelines CI/CD 配置文件，包含安装环境、执行测试、生成报告、失败通知完整流程，保存到 ci/ 目录",
  "toolset": {
    "guid": "a1b2c3d4-e5f6-4789-abcd-ef0123456789",
    "id": "web-auto-tester",
    "name": "Web Auto Tester Toolset",
    "version": "0.0.1"
  },
  "scenario": "auto-test-ci-config"
}
```

## Purpose

本 action 是 Web Auto Tester 的 CI/CD 配置生成命令。用户指定目标 CI 平台，AI 根据规范模板生成可直接使用的 CI/CD 配置文件（包含安装环境、执行测试、生成报告、失败通知完整流程），保存到 `.asdm/workspace/auto-test/ci/` 目录，并提供部署说明。

## Language Setting

默认使用**中文（简体中文）**作为输出语言。所有生成的配置注释、文档和说明均使用中文。

## Context Injection

在生成 CI/CD 配置前，AI Agent **必须**读取并理解以下规范文件：

### Required Context Files

1. **CI/CD 配置规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-ci-spec.md`
   - Purpose: 了解四种 CI 平台的配置模板、关键配置要点、占位符替换规则、配置文件命名与存储

2. **执行引擎规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-execution-spec.md`
   - Purpose: 了解执行流程和结果数据模型，确保 CI 配置正确引用执行步骤

3. **YAML DSL 规范** (Required)
   - Path: `.asdm/toolsets/web-auto-tester/spec/auto-test-dsl-spec.md`
   - Purpose: 了解用例数据模型和文件结构，确保 CI 配置正确引用用例路径

## Steps

### Step 1: 根据平台参数选择配置模板

1. 解析用户输入参数 `platform`：
   - `platform=jenkins` → 选择 Jenkins Declarative Pipeline 模板
   - `platform=github-actions` → 选择 GitHub Actions Workflow 模板
   - `platform=gitlab-ci` → 选择 GitLab CI Pipeline 模板
   - `platform=azure-pipelines` → 选择 Azure Pipelines Pipeline 模板
   - 未指定 → 默认选择 `github-actions` 模板
2. 从 `auto-test-ci-spec.md` 中读取对应平台的完整配置模板
3. 如用户指定 `platform=all` → 生成所有四个平台的配置文件

### Step 2: 填充项目信息

根据用户参数替换模板中的占位符：

1. **必填参数替换**：
   - `${nodeVersion}` → 用户参数 `nodeVersion`，默认 `18`
   - `${casesDir}` → 用户参数 `casesDir`，默认 `.asdm/workspace/auto-test/cases`

2. **可选参数替换**：
   - `${notifyEmail}` → 用户参数 `notifyEmail`，默认删除通知相关代码（如 Jenkins emailext）
   - `${notifyWebhook}` → 用户参数 `notifyWebhook`，默认删除 Webhook 通知代码

3. **环境路径确认**：
   - 确认 `.asdm/workspace/auto-test/` 目录结构存在
   - 确认 cases/ 目录下有 YAML 用例文件
   - 如目录不存在 → 在配置文件中添加 `mkdir -p` 创建命令

4. **浏览器选择**：
   - `${browser}` → 用户参数 `browser`，默认 `chromium`
   - 在 Playwright 安装命令中使用：`npx playwright install --with-deps ${browser}`

### Step 3: 生成 CI/CD 配置文件

根据平台生成可直接使用的配置文件：

#### 3.1 Jenkins 配置生成

生成 `Jenkinsfile`（Declarative Pipeline 格式），包含：
- **5 个 Stage**：安装环境 → 启动服务 → 执行测试 → 生成报告 → 通知
- **环境变量**：NODE_VERSION, CASES_DIR, WORKSPACE_DIR, REPORT_DIR, RESULTS_DIR, SCREENSHOTS_DIR
- **Playwright 安装**：`npx playwright install --with-deps ${browser}`
- **Artifact 收集**：results JSON + screenshots PNG + reports HTML
- **Allure 报告**：可选 allure generate 步骤
- **通知配置**：如有 notifyEmail 则添加 emailext 步骤

#### 3.2 GitHub Actions 配置生成

生成 `.github/workflows/auto-test.yml`，包含：
- **触发条件**：push (main/develop) + pull_request + workflow_dispatch
- **6 个 Step**：checkout → setup-node → playwright-install → test → report-artifact → notify
- **Node.js 版本**：使用 actions/setup-node@v4
- **Playwright 安装**：`npx playwright install --with-deps ${browser}`
- **Artifact 上传**：actions/upload-artifact@v4（结果 30 天 / 报告 90 天）
- **Slack 通知**：如有 notifyWebhook 则添加 slack-github-action 步骤
- **条件执行**：`if: always()` 确保报告和 artifact 始终上传

#### 3.3 GitLab CI 配置生成

生成 `.gitlab-ci.yml`，包含：
- **4 个 Stage**：install → test → report → notify
- **Docker 镜像**：node:${nodeVersion}
- **缓存策略**：按分支缓存 node_modules
- **Artifact 保留**：结果 30 天 / 报告 90 天

#### 3.4 Azure Pipelines 配置生成

生成 `azure-pipelines.yml`，包含：
- **3 个 Stage**：Install → Test → Report
- **VM 镜像**：ubuntu-latest
- **Node.js 任务**：NodeTool@0
- **Artifact 发布**：PublishBuildArtifacts@1

### Step 4: 其他平台提供模板参考文档

对于非首选平台，提供模板参考文档说明：

1. 在生成的配置文件头部添加注释说明：
   ```
   # Web Auto Tester CI/CD 配置文件
   # 平台: {platform}
   # 生成时间: {generatedAt}
   # Node.js 版本: {nodeVersion}
   # 浏览器: {browser}
   #
   # 使用说明：
   # 1. 将此文件移动到项目 {targetPath} 位置
   # 2. 根据项目实际情况调整触发条件和环境变量
   # 3. 确保 CI 环境已安装 Node.js 和 Playwright 浏览器
   # 4. 配置通知邮箱或 Webhook（可选）
   ```

2. 提供 4 个平台的模板对比说明：
   - Jenkins → 项目根目录 Jenkinsfile
   - GitHub Actions → .github/workflows/ 目录
   - GitLab CI → 项目根目录 .gitlab-ci.yml
   - Azure Pipelines → 项目根目录 azure-pipelines.yml

3. 如用户指定 `platform=all` → 在输出中附加所有平台的简要对比表

### Step 5: 保存配置文件到 ci/ 目录

1. 确定配置文件名和路径：
   - Jenkins → `.asdm/workspace/auto-test/ci/Jenkinsfile`
   - GitHub Actions → `.asdm/workspace/auto-test/ci/.github/workflows/auto-test.yml`
   - GitLab CI → `.asdm/workspace/auto-test/ci/.gitlab-ci.yml`
   - Azure Pipelines → `.asdm/workspace/auto-test/ci/azure-pipelines.yml`

2. 确保目标目录存在（`mkdir -p`）

3. 保存配置文件到指定路径

4. 输出配置文件摘要和部署说明

## Execution Guidelines

### 模板选择策略

| 参数值 | 生成的配置 | 说明 |
|--------|-----------|------|
| jenkins | Jenkinsfile | Jenkins Declarative Pipeline |
| github-actions | auto-test.yml | GitHub Actions Workflow |
| gitlab-ci | .gitlab-ci.yml | GitLab CI Pipeline |
| azure-pipelines | azure-pipelines.yml | Azure Pipelines |
| all | 以上四个文件 | 所有平台配置 |
| 未指定 | auto-test.yml | 默认 GitHub Actions |

### 占位符替换规则

- `${nodeVersion}` → 用户参数，默认 18
- `${casesDir}` → 用户参数，默认 .asdm/workspace/auto-test/cases
- `${browser}` → 用户参数，默认 chromium
- `${notifyEmail}` → 用户参数，无则删除通知代码块
- `${notifyWebhook}` → 用户参数，无则删除 Slack 通知步骤

### 配置文件可执行性

- 生成的配置文件必须**语法正确**，可直接用于对应 CI 平台
- YAML 格式配置文件需通过 YAML 语法校验
- Jenkinsfile 需通过 Groovy 语法校验
- 所有路径引用使用相对路径，适配不同项目根目录

### 部署说明规范

每个生成的配置文件附带部署说明：
1. 配置文件的目标存放位置
2. 需要修改的配置项（触发分支、通知邮箱等）
3. 前置依赖（Node.js 版本、Playwright 浏览器）
4. 可选配置（Allure 插件、Slack Webhook）

## Usage

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|:----:|------|
| platform | string | ❌ | CI 平台：jenkins / github-actions / gitlab-ci / azure-pipelines / all，默认 github-actions |
| nodeVersion | string | ❌ | Node.js 版本，默认 18 |
| casesDir | string | ❌ | 用例目录路径，默认 .asdm/workspace/auto-test/cases |
| browser | string | ❌ | 浏览器类型，默认 chromium |
| notifyEmail | string | ❌ | 通知邮箱（仅 Jenkins 适用） |
| notifyWebhook | string | ❌ | 通知 Webhook URL（Slack/GitLab/Azure 适用） |

### 命令示例

```
/auto-test-ci
/auto-test-ci platform=github-actions
/auto-test-ci platform=jenkins nodeVersion=20
/auto-test-ci platform=github-actions nodeVersion=18 browser=chromium notifyWebhook=https://hooks.slack.com/services/xxx
/auto-test-ci platform=jenkins notifyEmail=dev-team@example.com
/auto-test-ci platform=all nodeVersion=18
/auto-test-ci platform=gitlab-ci
/auto-test-ci platform=azure-pipelines
```

## Output

### 配置生成摘要

```markdown
### 🚀 CI/CD 配置已生成

> 平台: {platform} | Node.js: {nodeVersion} | 浏览器: {browser}

**配置文件**：
- 路径：`.asdm/workspace/auto-test/ci/{configFileName}`
- 部署目标：`{targetPath}`

**部署步骤**：
1. 将配置文件复制到项目 `{targetPath}` 位置
2. 根据项目实际分支调整触发条件
3. 如需通知功能，配置邮箱/Webhook 参数
4. 确保 CI 运行环境已安装 Node.js {nodeVersion} 和 Playwright 浏览器

**配置要点**：
- ✅ Playwright 浏览器自动安装（`npx playwright install --with-deps {browser}`）
- ✅ 测试结果和截图自动归档
- ✅ HTML 报告自动生成并上传
- ✅ 失败时通知机制（如已配置）
```

### 结构化输出

```json
{
  "phase": "auto-test-ci",
  "status": "success",
  "platform": "github-actions",
  "node_version": "18",
  "browser": "chromium",
  "config_files": [
    {
      "platform": "github-actions",
      "file_name": "auto-test.yml",
      "output_path": ".asdm/workspace/auto-test/ci/.github/workflows/auto-test.yml",
      "target_path": ".github/workflows/auto-test.yml",
      "size_bytes": 3500
    }
  ],
  "notify_configured": false,
  "generated_at": "ISO 8601 datetime"
}
```

### 多平台输出（platform=all）

```markdown
### 🚀 CI/CD 配置已生成（所有平台）

> 已生成 4 个平台的 CI/CD 配置文件

| 平台 | 配置文件 | 部署目标 |
|------|---------|---------|
| Jenkins | ci/Jenkinsfile | 项目根目录 Jenkinsfile |
| GitHub Actions | ci/.github/workflows/auto-test.yml | .github/workflows/auto-test.yml |
| GitLab CI | ci/.gitlab-ci.yml | 项目根目录 .gitlab-ci.yml |
| Azure Pipelines | ci/azure-pipelines.yml | 项目根目录 azure-pipelines.yml |
```

## Configuration

Refer to:
- [auto-test-ci-spec.md](../spec/auto-test-ci-spec.md) — Jenkins/GitHub Actions/GitLab CI/Azure Pipelines 配置模板、关键配置要点、占位符替换规则
- [auto-test-execution-spec.md](../spec/auto-test-execution-spec.md) — 执行引擎 7 阶段流程、AutoTestResult 数据模型
- [auto-test-dsl-spec.md](../spec/auto-test-dsl-spec.md) — AutoTestCase 数据模型、用例文件结构
