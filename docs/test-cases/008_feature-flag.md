# 用例名称： 特性开关管理
本用例适用于管理员进行特性开关配置
## 操作步骤
1. 用户进入 ASDM管理后台 首页
2. 点击左下角 [平台级设置] 按钮
3. 右侧工作区打开 平台级设置 页面
4. 点击 [特性开关] Tab页签
6. 特性开关列表中搜索 "hide_admin_resource_management" 关键字
   点击 "hide_admin_resource_management" 这条记录，操作列中点击 [编辑] 按钮
   打开 [编辑特性开关] 窗口
   特性开关名称： "hide_admin_resource_management"
   状态： 选择 [全量开放]
   点击 [保存] 按钮
5. 重复步骤 6 操作
   特性开关名称： "minio_storage_enabled"
   状态： 选择 [全量开放]
   特性开关名称： "hide_mcp_management"
   状态： 选择 [全量开放]
## 预期结果
1. 特性开关项 "hide_admin_resource_management"、"minio_storage_enabled"、"hide_mcp_management" 状态 变为 全量开放
## 前置条件
1. 用户已完成系统登录
2. 特性开关项 "hide_admin_resource_management"、"minio_storage_enabled"、"hide_mcp_management" 存在