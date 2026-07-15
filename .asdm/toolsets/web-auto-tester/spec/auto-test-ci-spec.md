# Web Auto Tester CI/CD 配置规范

**Document Version**: 1.0
**Last Updated**: 2026-07-14
**Toolset ID**: web-auto-tester

## Overview

本文档定义 Web Auto Tester CI/CD 配置生成的完整规范，包括 Jenkins Declarative Pipeline、GitHub Actions、GitLab CI、Azure Pipelines 四种平台的配置模板、关键配置要点、配置文件命名与存储。所有 CI/CD 配置生成功能由 AI Agent 按本规范生成，无实际编译代码。

---

## 1. Jenkins 配置模板

### 1.1 Declarative Pipeline 完整流程

Jenkinsfile 采用 Declarative Pipeline 格式，包含 5 个 Stage：

```
┌─────────────────────────────────────────────────────────────────────┐
│  Jenkinsfile (Declarative Pipeline)                                 │
├─────────────────────────────────────────────────────────────────────┤
│  Stage 1: 安装环境                                                  │
│    → Node.js 安装 → npm 依赖安装 → Playwright 浏览器安装            │
│  Stage 2: 启动服务                                                  │
│    → 启动目标 Web 服务（可选，如本地开发服务器）                     │
│  Stage 3: 执行测试                                                  │
│    → 执行 auto-test-run → YAML DSL 用例逐个执行                     │
│  Stage 4: 生成报告                                                  │
│    → auto-test-report → HTML 报告生成 → Allure 报告生成（可选）     │
│  Stage 5: 通知                                                      │
│    → 邮件/Webhook 通知 → 测试结果摘要推送                           │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.2 Jenkinsfile 模板

```groovy
pipeline {
    agent any

    environment {
        NODE_VERSION = '${nodeVersion}'
        CASES_DIR = '${casesDir}'
        WORKSPACE_DIR = '.asdm/workspace/auto-test'
        REPORT_DIR = '.asdm/workspace/auto-test/reports'
        RESULTS_DIR = '.asdm/workspace/auto-test/results'
        SCREENSHOTS_DIR = '.asdm/workspace/auto-test/screenshots'
    }

    stages {
        stage('安装环境') {
            steps {
                echo '=== Stage 1: 安装环境 ==='
                // Node.js 安装
                sh 'node --version || (curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | sudo -E bash - && sudo apt-get install -y nodejs)'
                sh 'node --version'
                sh 'npm --version'

                // npm 依赖安装
                sh 'npm ci || npm install'

                // Playwright 浏览器安装
                sh 'npx playwright install --with-deps chromium'
                sh 'npx playwright install-deps chromium'
            }
        }

        stage('启动服务') {
            steps {
                echo '=== Stage 2: 启动服务 ==='
                // 可选：启动目标 Web 服务
                // 示例：启动本地开发服务器
                sh '''
                    if [ -f "package.json" ]; then
                        npm run dev &
                        sleep 10
                    fi
                '''
            }
        }

        stage('执行测试') {
            steps {
                echo '=== Stage 3: 执行测试 ==='
                // 确保工作区目录存在
                sh '''
                    mkdir -p ${WORKSPACE_DIR}/cases
                    mkdir -p ${WORKSPACE_DIR}/results
                    mkdir -p ${WORKSPACE_DIR}/reports
                    mkdir -p ${WORKSPACE_DIR}/screenshots
                    mkdir -p ${WORKSPACE_DIR}/ci
                '''

                // 执行 YAML DSL 测试用例
                sh '''
                    for case_file in ${CASES_DIR}/*.yaml; do
                        echo "执行用例: $case_file"
                        // 这里应调用 AI Agent 执行 /auto-test-run
                        // 或通过 Node.js 脚本桥接执行引擎
                        // 实际 CI 环境中需要预构建执行脚本
                    done
                '''
            }

            post {
                always {
                    // 收集执行结果
                    archiveArtifacts artifacts: '${RESULTS_DIR}/*.json', allowEmptyArchive: true
                    archiveArtifacts artifacts: '${SCREENSHOTS_DIR}/*.png', allowEmptyArchive: true
                }
                failure {
                    echo '测试执行阶段失败'
                }
            }
        }

        stage('生成报告') {
            steps {
                echo '=== Stage 4: 生成报告 ==='
                // 生成 HTML 报告
                sh '''
                    // 调用 AI Agent 执行 /auto-test-report
                    // 或通过 Node.js 脚本桥接报告引擎
                    echo "HTML 报告生成完成"
                '''

                // 可选：生成 Allure 报告
                sh '''
                    if command -v allure &> /dev/null; then
                        allure generate ${REPORT_DIR}/allure-results -o ${REPORT_DIR}/allure-report --clean
                    else
                        echo "Allure CLI 未安装，跳过 Allure 报告生成"
                    fi
                '''
            }

            post {
                always {
                    // 收集 HTML 报告
                    archiveArtifacts artifacts: '${REPORT_DIR}/*.html', allowEmptyArchive: true
                    // 收集 Allure 报告（如有）
                    archiveArtifacts artifacts: '${REPORT_DIR}/allure-report/**', allowEmptyArchive: true
                }
            }
        }

        stage('通知') {
            steps {
                echo '=== Stage 5: 通知 ==='
                // 邮件通知
                emailext(
                    subject: 'Web Auto Tester 测试报告 - ${BUILD_STATUS}',
                    body: '''
                        构建编号: ${BUILD_NUMBER}
                        构建状态: ${BUILD_STATUS}
                        通过率: 请查看 HTML 报告
                        报告路径: ${REPORT_DIR}/report-latest.html
                    ''',
                    to: '${notifyEmail}'
                )
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        failure {
            echo 'Pipeline 执行失败'
        }
        success {
            echo 'Pipeline 执行成功'
        }
    }
}
```

### 1.3 Jenkins 关键配置要点

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| NODE_VERSION | Node.js 版本 | 18 |
| CASES_DIR | 用例目录路径 | .asdm/workspace/auto-test/cases |
| Playwright 安装 | `npx playwright install --with-deps chromium` | chromium |
| 报告归档 | `archiveArtifacts` 收集 HTML/JSON/PNG | 允许空归档 |
| Allure 插件 | Jenkins Allure Plugin 可选安装 | — |
| 通知方式 | emailext 邮件通知 | 构建状态邮件 |
| 清理策略 | `cleanWs()` 构建后清理工作区 | always |

---

## 2. GitHub Actions 配置模板

### 2.1 Workflow 完整流程

GitHub Actions Workflow 包含 6 个 Step：

```
┌─────────────────────────────────────────────────────────────────────┐
│  GitHub Actions Workflow                                            │
├─────────────────────────────────────────────────────────────────────┤
│  Step 1: checkout                                                  │
│    → 拉取代码仓库                                                   │
│  Step 2: setup-node                                                │
│    → 安装 Node.js → npm 依赖安装                                   │
│  Step 3: playwright-install                                        │
│    → Playwright 浏览器安装                                          │
│  Step 4: test                                                      │
│    → 执行 auto-test-run → YAML DSL 用例逐个执行                     │
│  Step 5: report-artifact                                           │
│    → auto-test-report → HTML 报告上传 artifact                     │
│  Step 6: notify                                                    │
│    → 测试结果摘要 → 可选 Slack/Webhook 通知                        │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 GitHub Actions Workflow YAML 模板

```yaml
name: Web Auto Tester CI

on:
  push:
    branches: [ main, develop ]
    paths:
      - 'src/**'
      - '.asdm/workspace/auto-test/cases/**'
  pull_request:
    branches: [ main, develop ]
  workflow_dispatch:
    inputs:
      case_filter:
        description: '用例筛选条件（tag/framework/status）'
        required: false
        default: ''
      browser:
        description: '浏览器类型'
        required: false
        default: 'chromium'

jobs:
  auto-test:
    runs-on: ubuntu-latest

    env:
      CASES_DIR: .asdm/workspace/auto-test/cases
      RESULTS_DIR: .asdm/workspace/auto-test/results
      REPORTS_DIR: .asdm/workspace/auto-test/reports
      SCREENSHOTS_DIR: .asdm/workspace/auto-test/screenshots

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '${nodeVersion}'
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Install Playwright browsers
        run: npx playwright install --with-deps chromium

      - name: Ensure workspace directories
        run: |
          mkdir -p $CASES_DIR
          mkdir -p $RESULTS_DIR
          mkdir -p $REPORTS_DIR
          mkdir -p $SCREENSHOTS_DIR
          mkdir -p .asdm/workspace/auto-test/ci

      - name: Run auto tests
        run: |
          echo "=== 执行 Web Auto Tester 测试 ==="
          # 执行 YAML DSL 测试用例
          # 这里应调用 AI Agent 执行 /auto-test-run
          # 或通过 Node.js 脚本桥接执行引擎
          # CI 环境中需要预构建执行脚本
          for case_file in $CASES_DIR/*.yaml; do
            if [ -f "$case_file" ]; then
              echo "执行用例: $case_file"
            fi
          done

      - name: Generate test report
        if: always()
        run: |
          echo "=== 生成测试报告 ==="
          # 调用 AI Agent 执行 /auto-test-report
          # 或通过 Node.js 脚本桥接报告引擎

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: auto-test-results
          path: |
            ${{ env.RESULTS_DIR }}/*.json
            ${{ env.SCREENSHOTS_DIR }}/*.png
          retention-days: 30

      - name: Upload test report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: auto-test-report
          path: ${{ env.REPORTS_DIR }}/*.html
          retention-days: 90

      - name: Upload Allure report
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: allure-report
          path: ${{ env.REPORTS_DIR }}/allure-report/**
          retention-days: 90

      - name: Test summary notification
        if: always()
        run: |
          echo "=== 测试结果摘要 ==="
          # 解析结果 JSON 输出摘要
          total=0
          passed=0
          failed=0
          for result_file in $RESULTS_DIR/*.json; do
            if [ -f "$result_file" ]; then
              total=$((total + 1))
              # 解析 JSON 状态
            fi
          done
          echo "总用例: $total | 通过: $passed | 失败: $failed"

      - name: Slack notification
        if: failure() && github.event_name == 'push'
        uses: slackapi/slack-github-action@v1.25.0
        with:
          payload: |
            {
              "text": "Web Auto Tester 测试失败",
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": ":x: *测试失败*\\n构建: ${{ github.run_number }}\\n分支: ${{ github.ref_name }}"
                  }
                }
              ]
            }
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

### 2.3 GitHub Actions 关键配置要点

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| node-version | Node.js 版本 | 18 |
| runs-on | 运行环境 | ubuntu-latest |
| Playwright 安装 | `npx playwright install --with-deps chromium` | chromium |
| 触发条件 | push/PR/workflow_dispatch | main, develop 分支 |
| Artifact 保留 | 结果 30 天 / 报告 90 天 | — |
| 通知方式 | Slack Webhook（可选） | secrets.SLACK_WEBHOOK_URL |
| 缓存 | npm 缓存加速依赖安装 | npm |
| 条件执行 | `if: always()` 确保报告始终生成 | — |

---

## 3. GitLab CI 模板参考

### 3.1 GitLab CI Pipeline 流程

```yaml
# .gitlab-ci.yml
stages:
  - install
  - test
  - report
  - notify

variables:
  NODE_VERSION: "${nodeVersion}"
  CASES_DIR: ".asdm/workspace/auto-test/cases"
  RESULTS_DIR: ".asdm/workspace/auto-test/results"
  REPORTS_DIR: ".asdm/workspace/auto-test/reports"
  SCREENSHOTS_DIR: ".asdm/workspace/auto-test/screenshots"

install_env:
  stage: install
  image: node:${NODE_VERSION}
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
  script:
    - npm ci
    - npx playwright install --with-deps chromium
    - mkdir -p $CASES_DIR $RESULTS_DIR $REPORTS_DIR $SCREENSHOTS_DIR

run_tests:
  stage: test
  image: node:${NODE_VERSION}
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
  script:
    - echo "=== 执行 Web Auto Tester 测试 ==="
    # 执行 YAML DSL 测试用例
    # 调用 AI Agent 或 Node.js 框接执行引擎
  artifacts:
    when: always
    paths:
      - $RESULTS_DIR/*.json
      - $SCREENSHOTS_DIR/*.png
    expire_in: 30 days

generate_report:
  stage: report
  image: node:${NODE_VERSION}
  cache:
    key: ${CI_COMMIT_REF_SLUG}
    paths:
      - node_modules/
  script:
    - echo "=== 生成测试报告 ==="
    # 调用 AI Agent 或 Node.js 框接报告引擎
    - if command -v allure; then allure generate $REPORTS_DIR/allure-results -o $REPORTS_DIR/allure-report --clean; fi
  artifacts:
    when: always
    paths:
      - $REPORTS_DIR/*.html
      - $REPORTS_DIR/allure-report/**
    expire_in: 90 days

notify:
  stage: notify
  script:
    - echo "=== 测试结果通知 ==="
    # 发送邮件或 Webhook 通知
  when: always
  only:
    - main
    - develop
```

### 3.2 GitLab CI 关键配置要点

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| Docker 镜像 | node:${NODE_VERSION} | node:18 |
| 缓存策略 | 按分支缓存 node_modules | CI_COMMIT_REF_SLUG |
| Artifact 保留 | 结果 30 天 / 报告 90 天 | — |
| 触发分支 | main, develop | — |
| Playwright 安装 | `npx playwright install --with-deps chromium` | chromium |

---

## 4. Azure Pipelines 模板参考

### 4.1 Azure Pipelines Pipeline 流程

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop
  paths:
    include:
      - src/*
      - .asdm/workspace/auto-test/cases/*

pr:
  branches:
    include:
      - main
      - develop

variables:
  nodeVersion: '${nodeVersion}'
  casesDir: '.asdm/workspace/auto-test/cases'
  resultsDir: '.asdm/workspace/auto-test/results'
  reportsDir: '.asdm/workspace/auto-test/reports'
  screenshotsDir: '.asdm/workspace/auto-test/screenshots'

stages:
  - stage: Install
    jobs:
      - job: InstallEnv
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - task: NodeTool@0
            inputs:
              versionSpec: '$(nodeVersion)'
            displayName: 'Install Node.js'

          - script: npm ci
            displayName: 'Install npm dependencies'

          - script: npx playwright install --with-deps chromium
            displayName: 'Install Playwright browsers'

          - script: |
              mkdir -p $(casesDir)
              mkdir -p $(resultsDir)
              mkdir -p $(reportsDir)
              mkdir -p $(screenshotsDir)
            displayName: 'Create workspace directories'

  - stage: Test
    dependsOn: Install
    jobs:
      - job: RunTests
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - script: |
              echo "=== 执行 Web Auto Tester 测试 ==="
              # 执行 YAML DSL 测试用例
            displayName: 'Run auto tests'

          - task: PublishBuildArtifacts@1
            condition: always()
            inputs:
              pathToPublish: '$(resultsDir)'
              artifactName: 'auto-test-results'
            displayName: 'Publish test results'

          - task: PublishBuildArtifacts@1
            condition: always()
            inputs:
              pathToPublish: '$(screenshotsDir)'
              artifactName: 'auto-test-screenshots'
            displayName: 'Publish screenshots'

  - stage: Report
    dependsOn: Test
    condition: always()
    jobs:
      - job: GenerateReport
        pool:
          vmImage: 'ubuntu-latest'
        steps:
          - script: |
              echo "=== 生成测试报告 ==="
              # 调用 AI Agent 或 Node.js 框接报告引擎
            displayName: 'Generate HTML report'

          - task: PublishBuildArtifacts@1
            condition: always()
            inputs:
              pathToPublish: '$(reportsDir)'
              artifactName: 'auto-test-report'
            displayName: 'Publish HTML report'
```

### 4.2 Azure Pipelines 关键配置要点

| 配置项 | 说明 | 默认值 |
|--------|------|--------|
| vmImage | 运行环境 | ubuntu-latest |
| Node.js | NodeTool@0 任务 | 18 |
| Playwright 安装 | `npx playwright install --with-deps chromium` | chromium |
| Artifact 发布 | PublishBuildArtifacts@1 | — |
| 触发条件 | push/PR | main, develop |
| 条件执行 | `condition: always()` | — |

---

## 5. 通用配置要点

### 5.1 Playwright 安装配置

所有 CI 平台的 Playwright 安装通用配置：

```bash
# 安装 Playwright 浏览器及系统依赖
npx playwright install --with-deps chromium

# 仅安装浏览器（系统依赖已预装）
npx playwright install chromium

# 安装多个浏览器
npx playwright install chromium firefox webkit
```

**关键注意事项**：

| 注意项 | 说明 |
|--------|------|
| `--with-deps` | 首次安装必须使用，自动安装系统级依赖（如 libglib, libnss 等） |
| chromium 优先 | CI 环境推荐仅安装 chromium，减少安装耗时和资源消耗 |
| Docker 环境 | 使用官方 Playwright Docker 镜像可跳过安装步骤 |
| 缓存策略 | Playwright 浏览器二进制可缓存到 CI 缓存目录加速后续构建 |

### 5.2 报告归档配置

| 平台 | 归档命令 | 保留期限建议 |
|------|----------|-------------|
| Jenkins | `archiveArtifacts artifacts: 'path/**'` | 30 天（结果）/ 90 天（报告） |
| GitHub Actions | `actions/upload-artifact@v4` | 30 天（结果）/ 90 天（报告） |
| GitLab CI | `artifacts: paths: [...] expire_in: 30d` | 30 天（结果）/ 90 天（报告） |
| Azure Pipelines | `PublishBuildArtifacts@1` | 默认保留 |

### 5.3 失败通知配置

| 平台 | 通知方式 | 配置说明 |
|------|----------|----------|
| Jenkins | emailext 邮件插件 | 需配置 Jenkins 邮件服务器 |
| GitHub Actions | Slack Webhook / GitHub Checks | 需配置 secrets.SLACK_WEBHOOK_URL |
| GitLab CI | 集成邮件通知 | GitLab 内置邮件通知 |
| Azure Pipelines | 集成通知 / Webhook | Azure DevOps 内置通知 |

### 5.4 环境变量通用配置

所有 CI 平台通用环境变量：

| 变量名 | 说明 | 默认值 |
|--------|------|--------|
| CASES_DIR | 用例目录 | .asdm/workspace/auto-test/cases |
| RESULTS_DIR | 结果目录 | .asdm/workspace/auto-test/results |
| REPORTS_DIR | 报告目录 | .asdm/workspace/auto-test/reports |
| SCREENSHOTS_DIR | 截图目录 | .asdm/workspace/auto-test/screenshots |
| NODE_VERSION | Node.js 版本 | 18 |
| BROWSER | 浏览器类型 | chromium |

---

## 6. 配置文件命名与存储

### 6.1 配置文件命名

| 平台 | 配置文件名 | 存储位置 |
|------|-----------|---------|
| Jenkins | Jenkinsfile | `.asdm/workspace/auto-test/ci/Jenkinsfile` |
| GitHub Actions | auto-test.yml | `.asdm/workspace/auto-test/ci/.github/workflows/auto-test.yml` |
| GitLab CI | .gitlab-ci.yml | `.asdm/workspace/auto-test/ci/.gitlab-ci.yml` |
| Azure Pipelines | azure-pipelines.yml | `.asdm/workspace/auto-test/ci/azure-pipelines.yml` |

### 6.2 部署说明

生成的 CI 配置文件存储在 `ci/` 工作区目录后，用户需手动将配置文件移动到项目对应位置：

| 平台 | 目标位置 | 说明 |
|------|----------|------|
| Jenkins | 项目根目录 `Jenkinsfile` | Jenkins 自动识别根目录 Jenkinsfile |
| GitHub Actions | `.github/workflows/auto-test.yml` | GitHub Actions 固定目录结构 |
| GitLab CI | 项目根目录 `.gitlab-ci.yml` | GitLab CI 自动识别根目录配置 |
| Azure Pipelines | 项目根目录 `azure-pipelines.yml` | Azure DevOps 配置文件 |

### 6.3 配置参数占位符

模板中使用 `${...}` 格式的占位符，AI Agent 生成配置时根据用户参数替换：

| 占位符 | 参数来源 | 说明 |
|--------|----------|------|
| `${nodeVersion}` | 参数 `nodeVersion` | Node.js 版本 |
| `${casesDir}` | 参数 `casesDir` | 用例目录路径 |
| `${notifyEmail}` | 参数 `notifyEmail` | 通知邮箱 |
| `${notifyWebhook}` | 参数 `notifyWebhook` | 通知 Webhook URL |

---

## 7. AutoTestCIConfig 数据模型

| 字段 | 类型 | 说明 |
|------|------|------|
| id | string | CI 配置 ID：`ci-config-{YYYYMMDD}-{NNN}` |
| platform | string | CI 平台：jenkins / github-actions / gitlab-ci / azure-pipelines |
| nodeVersion | string | Node.js 版本 |
| casesDir | string | 用例目录路径 |
| browser | string | 浏览器类型 |
| notifyEmail | string | 通知邮箱（可选） |
| notifyWebhook | string | 通知 Webhook URL（可选） |
| generatedAt | string | 生成时间（ISO 8601） |
| configContent | string | 生成的配置文件内容 |
| outputPath | string | 配置文件输出路径 |
| targetPath | string | 配置文件部署目标路径 |
