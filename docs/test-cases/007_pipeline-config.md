# 用例名称： 流水线配置
本用例适用于管理员进行流水线配置
## 操作步骤
1. 用户进入 ASDM管理后台 首页
2. 点击左下角 [平台级设置] 按钮
3. 右侧工作区打开 平台级设置 页面
4. 点击 [其他] Tab页签
5. 点击 [+ 添加流水线配置] 按钮, 打开 [新增流水线配置] 窗口
6. [新增流水线配置] 信息录入
   名称： "pipeline"
   流水线类型： 选择 [Jenkins]
   Jinkins凭证： "admin:11f054f0964f8cb86a627b296929b9df59"
   知识空间同步 Jenkinsfile : 选择 [context/asdm-context-space-sync.no-docker.Jenkinsfile]
   智能体空间执行 Jenkinsfile : 选择 [workspace/asdm-workspace-exec.no-docker.Jenkinsfile]
   知识空间分析 Jenkinsfile : 选择 [context/asdm-context-analyze.no-docker.Jenkinsfile]
   ASDM API PAT : 复制 [006_generate-pat.md]用例 创建的PAT令牌
7. 点击 [创建] 按钮
## 预期结果
1. 流水线配置创建成功
## 前置条件
1. 用户已完成系统登录
2. PAT令牌已创建