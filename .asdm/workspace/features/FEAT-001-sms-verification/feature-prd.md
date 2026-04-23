# Feature PRD: 用户注册短信验证

**Feature ID**: FEAT-001-sms-verification
**Created Date**: 2026-04-23
**Status**: PLANNED
**Language**: zh

## 1. Overview

### 1.1 Feature Summary

本功能为用户注册流程增加短信验证码（SMS OTP）校验，用户在注册时需提供手机号并通过短信验证码确认手机号真实有效，替代当前仅靠邮箱字段的无验证注册模式。

- **做什么**：在注册表单中新增手机号输入和短信验证码校验，用户需先获取验证码、输入正确验证码后方可完成注册
- **为什么需要**：当前注册流程无任何身份验证手段，用户可使用任意邮箱注册，存在垃圾注册、恶意注册风险；短信验证是业界标准的用户身份确认方式
- **谁受益**：平台运营方（减少垃圾注册）、真实用户（提升账户安全性）、后续业务（手机号可用于登录、密码找回等）

### 1.2 Objectives

- 目标1：注册流程中新增手机号+短信验证码校验，确保注册用户手机号真实有效
- 目标2：提供验证码发送、倒计时防刷、验证码校验的完整交互闭环
- 目标3：为后端预留短信服务接口规范，当前阶段前端先完成交互与模拟验证
- 目标4：保持与现有 Element Plus UI 风格一致的用户体验

## 2. User Stories

### Story 1: 用户注册时验证手机号

**As a** 新注册用户
**I want to** 在注册时通过短信验证码确认我的手机号
**So that** 我的账户绑定真实手机号，提升账户安全性

**Acceptance Criteria**:
- 注册表单包含手机号输入框
- 点击"获取验证码"后，手机号收到6位数字验证码短信
- 输入正确验证码后才能提交注册
- 验证码输入错误时给出明确提示

### Story 2: 防止验证码滥用

**As a** 平台运营方
**I want to** 限制验证码发送频率
**So that** 防止恶意用户通过大量发送短信进行刷量攻击

**Acceptance Criteria**:
- 同一手机号60秒内不可重复发送验证码
- 发送后按钮进入倒计时状态，倒计时结束前不可再次点击
- 同一手机号每日发送次数上限为5次（后端校验，前端做辅助提示）

### Story 3: 验证码输入体验

**As a** 新注册用户
**I want to** 便捷地输入验证码
**So that** 注册流程顺畅高效

**Acceptance Criteria**:
- 验证码输入框限制为6位纯数字
- 验证码5分钟内有效，过期后提示重新获取
- 输入满6位后自动聚焦或可手动提交

## 3. Functional Requirements

### REQ-001: 手机号输入

- **ID**: REQ-001
- **Description**: 注册表单中新增手机号输入字段，支持中国大陆手机号格式（11位，1开头），替换现有邮箱字段为可选项，手机号为必填项
- **Priority**: High
- **Related Stories**: Story 1

### REQ-002: 发送短信验证码

- **ID**: REQ-002
- **Description**: 提供"获取验证码"按钮，点击后向后端请求发送6位数字验证码到指定手机号。发送成功后按钮进入60秒倒计时状态。需先校验手机号格式正确且不为空
- **Priority**: High
- **Related Stories**: Story 1, Story 2

### REQ-003: 验证码输入与校验

- **ID**: REQ-003
- **Description**: 提供6位验证码输入框，提交注册时将手机号和验证码一并提交后端校验。验证码正确方可注册成功，错误则提示"验证码错误或已过期"
- **Priority**: High
- **Related Stories**: Story 1, Story 3

### REQ-004: 倒计时与防刷机制

- **ID**: REQ-004
- **Description**: 验证码发送后，按钮显示60秒倒计时（如"重新发送(58s)"），倒计时期间按钮禁用。每日发送上限5次由后端控制，前端在收到相应错误码时提示用户
- **Priority**: High
- **Related Stories**: Story 2

### REQ-005: 表单校验规则更新

- **ID**: REQ-005
- **Description**: 更新注册表单校验规则：手机号必填且格式正确，验证码必填且为6位数字，邮箱改为选填，用户名和密码校验规则保持不变
- **Priority**: Medium
- **Related Stories**: Story 1

### REQ-006: User Store 适配

- **ID**: REQ-006
- **Description**: 更新 Pinia user store 的 register 方法，增加 phone 和 smsCode 参数。当前阶段使用模拟验证码逻辑（固定验证码如123456或随机生成后console输出），为后续对接后端 API 做好数据结构准备
- **Priority**: Medium
- **Related Stories**: Story 1

## 4. Non-Functional Requirements

### 4.1 Performance

- 验证码发送请求响应时间前端等待不超过3秒（含网络耗时）
- 倒计时精确到秒，无明显延迟
- 注册表单渲染与交互流畅，无卡顿

### 4.2 Security

- 验证码在传输和存储中不得明文暴露（后端要求）
- 前端不得缓存或记录已发送的验证码
- 同一IP短时间大量请求应触发后端限流（后端实现）
- 防止前端绕过验证码校验直接提交注册

### 4.3 Scalability

- 短信服务应设计为可插拔的 Provider 模式，便于后续切换短信服务商（后端设计）
- 验证码长度、有效期、发送间隔等参数应可配置

### 4.4 Reliability

- 短信发送失败时给予用户明确错误提示
- 网络异常时验证码按钮应恢复可用状态，允许用户重试
- 验证码过期后引导用户重新获取

## 5. Technical Requirements

### 5.1 Architecture Considerations

- 当前项目仅前端（Vue 3 + Element Plus + Pinia）已实现，后端尚未开发
- 本次功能在前端实现完整交互流程，短信验证使用模拟模式（mock）
- 后端接口规范需在 PRD 中定义，便于后续对接
- 注册表单需调整字段顺序：手机号 → 验证码 → 用户名 → 密码 → 确认密码 → 昵称 → 邮箱（选填）

### 5.2 Dependencies

- **内部依赖**：现有 `Register.vue`、`user.js` store、`users.json` mock 数据
- **外部依赖（后续）**：短信服务商 API（如阿里云短信、腾讯云短信）、后端验证码服务接口

### 5.3 Constraints

- 前端独立实现，不依赖后端服务
- 使用 Element Plus 现有组件，不引入额外 UI 库
- 保持与现有代码风格一致（Composition API + `<script setup>`）
- 验证码模拟逻辑仅用于开发阶段，需明确标注便于后续替换

### 5.4 后端接口规范（预留）

**发送验证码**:
- `POST /api/sms/send`
- Request: `{ "phone": "13800138000" }`
- Response: `{ "code": 200, "message": "发送成功" }`
- Error: `{ "code": 429, "message": "发送过于频繁" }` | `{ "code": 429, "message": "今日发送次数已达上限" }`

**注册**:
- `POST /api/auth/register`
- Request: `{ "phone": "13800138000", "smsCode": "123456", "username": "zhangsan", "password": "xxx", "name": "张三", "email": "optional" }`
- Response: `{ "code": 200, "data": { "token": "xxx", "userInfo": {...} } }`
- Error: `{ "code": 400, "message": "验证码错误或已过期" }`

## 6. Success Criteria

- 注册表单包含手机号和验证码输入，交互流程完整可用
- 点击"获取验证码"后按钮进入60秒倒计时，倒计时结束前不可再次点击
- 模拟验证码模式下，输入正确验证码（如123456）可注册成功，错误验证码给出提示
- 手机号格式校验生效，非中国大陆手机号格式被拒绝
- 邮箱字段变为选填
- 所有表单校验规则正确执行
- 现有注册流程不被破坏（向后兼容基本功能）

## 7. Task Breakdown Principles

### 7.1 Granularity

- 每个任务限定为人类开发者1-2小时的工作量（AI模型约5-10分钟）
- 任务聚焦单一职责，便于独立验证

### 7.2 Independence

- 最小化任务间依赖，支持并行执行
- 前端组件修改与 Store 修改可并行进行

### 7.3 Testability

- 每个任务有明确的验收标准
- 可通过浏览器手动验证或代码审查确认

### 7.4 Task Categories

- 分析与设计：接口规范定义、组件结构设计
- 代码实现：Vue 组件修改、Store 修改、mock 数据更新
- 测试：功能验证

### 7.5 Task Count Limitation

- 本功能预计6-8个任务，在10个任务限制内

## 8. Implementation Notes

- 验证码输入建议使用 Element Plus 的 `el-input` 配合 maxlength 限制，暂不使用第三方验证码输入组件
- 倒计时使用 `setInterval` 实现，组件卸载时需清除定时器
- 模拟验证码逻辑：固定使用 `123456` 作为有效验证码，并在控制台输出，便于开发调试
- 手机号正则：`/^1[3-9]\d{9}$/`
- 需在 Register.vue 中新增 `phone` 和 `smsCode` 两个表单字段及对应校验规则
- users.json mock 数据结构需增加 phone 字段
- 建议验证码按钮使用 `el-button` 放置在手机号输入框右侧或下方，采用行内布局（el-input + el-button 组合）

## 9. Risks and Mitigations

### Risk 1: 短信服务商成本

- **Description**: 短信发送产生费用，恶意刷量可能导致成本失控
- **Impact**: High
- **Mitigation**: 后端实现发送频率限制和每日上限；前端倒计时防刷；后续对接后端时增加图形验证码等人机验证手段

### Risk 2: 模拟模式与真实模式切换

- **Description**: 前期使用模拟验证码，后续对接后端时可能遗漏替换点
- **Impact**: Medium
- **Mitigation**: 在代码中使用明确的 mock 标记（如 `// TODO: [SMS-MOCK]`），模拟逻辑集中在 store 层便于替换

### Risk 3: 手机号隐私

- **Description**: 手机号为敏感个人信息，需合规处理
- **Impact**: Medium
- **Mitigation**: 前端不缓存手机号明文（除表单临时输入）；后续后端需对手机号加密存储；遵循个人信息保护法要求

### Risk 4: 国际手机号支持

- **Description**: 当前仅支持中国大陆手机号，未来可能需要支持国际号码
- **Impact**: Low
- **Mitigation**: 手机号校验逻辑封装为独立函数，便于后续扩展国际号码格式

## 10. Appendix

### 10.1 References

- Element Plus Form 组件文档：https://element-plus.org/zh-CN/component/form.html
- Element Plus Input 组件文档：https://element-plus.org/zh-CN/component/input.html
- 项目现有代码：`ai-fast-web-user/src/views/Register.vue`、`ai-fast-web-user/src/stores/user.js`

### 10.2 Glossary

- **SMS OTP**: Short Message Service One-Time Password，短信一次性验证码
- **防刷**: 防止恶意用户通过自动化手段频繁请求服务
- **Mock 模式**: 使用模拟数据替代真实后端接口的开发模式
