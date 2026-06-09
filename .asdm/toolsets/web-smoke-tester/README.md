# ASDM Toolset - Web Smoke Tester

toolset-id: web-smoke-tester
toolset-name: Web Smoke Tester
version: 1.0.0
updated-date: 2026-06-09
toolset-description: 模拟测试人员进行 WEB 系统冒烟测试的 ASDM 工具集，支持自然语言描述测试步骤、场景化执行和结果表格输出。

## Overview

Web Smoke Tester (toolset-id: web-smoke-tester) 是一款面向 WEB 系统冒烟测试的 ASDM 工具集。它模拟测试人员的手工冒烟测试行为，通过斜杠命令携带业务场景的详细操作步骤，自动执行测试并生成结构化的测试结果表格。

## 核心理念

- **自然语言驱动**：用户在斜杠命令后以自然语言描述测试步骤，无需编写脚本
- **场景化执行**：每次执行对应一个完整的业务场景（如"用户登录→浏览商品→加入购物车→下单"）
- **结果表格化**：每个场景生成一条测试记录，以表格形式汇总所有场景的测试结果
- **冒烟测试级别**：聚焦核心链路的 P0/P1 级验证，不替代完整功能测试

## Features

- 提供斜杠命令 `/smoke-test-run`，携带业务场景操作步骤执行冒烟测试
- 提供斜杠命令 `/smoke-test-list`，列出所有已执行的测试场景记录
- 提供斜杠命令 `/smoke-test-report`，生成冒烟测试汇总报告
- 提供斜杠命令 `/smoke-test-clear`，清空测试记录
- 支持自然语言描述测试步骤，AI 自动解析为可执行操作序列
- 每个场景生成一条结构化测试记录（场景名、步骤数、通过/失败、耗时、截图/日志）
- 所有场景测试结果以 Markdown 表格形式输出
- 测试记录持久化存储，支持跨会话查询和报告生成

## Toolset Installation Process

`INSTALL.md` will setup the toolset with the following steps:

- Detect the current `Agentic Engine` provider, e.g. Claude Code, GitHub Copilot, Tencent CodeBuddy etc.
- Create shortcuts commands for `Web Smoke Tester` in provider's entry point

## Toolset Structure

```
.asdm/toolsets/web-smoke-tester/
├── actions/
│   ├── smoke-test-run.md         ## 执行单个冒烟测试场景（核心命令）
│   ├── smoke-test-list.md        ## 列出所有测试场景记录
│   ├── smoke-test-report.md      ## 生成冒烟测试汇总报告
│   └── smoke-test-clear.md       ## 清空测试记录
├── spec/
│   ├── smoke-test-shared-spec.md       ## 共享规范：数据模型、存储、输出格式
│   ├── smoke-test-pipeline-spec.md     ## 测试 Pipeline 规范：步骤解析、执行、断言
│   └── smoke-test-report-spec.md       ## 测试报告规范：表格格式、汇总统计
└── INSTALL.md
```
