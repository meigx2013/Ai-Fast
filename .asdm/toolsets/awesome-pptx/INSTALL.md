# awesome-pptx 安装指南

## 安装步骤

### 1. 创建工作目录

```bash
mkdir -p .asdm/workspace/awesome-pptx/output
```

### 2. 验证安装

工具集安装后，使用以下命令验证：

```bash
/awesome-pptx --help
```

### 3. 配置默认风格（可选）

在工作区根目录创建 `.asdm/config.json`：

```json
{
  "awesome-pptx": {
    "defaultStyle": "tech",
    "animationEnabled": true,
    "particleBackground": false
  }
}
```

## 依赖项

无外部依赖，所有功能通过纯 HTML/CSS/JavaScript 实现。

## 卸载

删除工具集目录即可：

```bash
rm -rf .asdm/toolsets/awesome-pptx
```
