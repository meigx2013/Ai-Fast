# ASDM Toolset - 炫彩演示生成器

toolset-id: awesome-pptx
toolset-name: 炫彩演示生成器
version: 1.0.0
updated-date: 2026-04-25
toolset-description: 支持多种风格的演示页面生成器，可生成商务、科技、中国风、清新等多种视觉风格的美观 HTML 演示页面，带有丰富的动画和装饰效果。

## Overview

炫彩演示生成器（awesome-pptx）是一款功能强大的 ASDM 工具集，能够根据用户提供的演示内容，自动生成美观的 HTML 演示页面。

**核心特性**：
- 🎨 **多风格支持**：商务、科技、中国风、清新、简约、渐变 6 种预设风格
- ✨ **丰富动画**：页面切换动画、内容入场动画、背景动态效果
- 🎯 **智能装饰**：每种风格配套专属几何装饰图案
- 📱 **响应式设计**：完美适配桌面和移动设备
- 🌙 **主题切换**：支持深色/浅色模式切换

## Supported Styles

| 风格 | 关键词 | 适用场景 |
|------|--------|----------|
| 商务 (business) | 商务、会议、报告、正式 | 企业汇报、商务演示 |
| 科技 (tech) | 科技、代码、数据、技术 | 技术分享、代码演示 |
| 中国风 (chinese) | 传统、文化、典雅、古风 | 文化展示、传统美学 |
| 清新 (fresh) | 清新、自然、轻松、活泼 | 教学课件、生活分享 |
| 简约 (minimal) | 极简、留白、干净 | 艺术展示、创意演示 |
| 渐变 (gradient) | 渐变、色彩、动感、活力 | 产品介绍、营销展示 |

## Features

### Common Features

- 支持文件输入（.md, .txt）
- 支持直接内容输入
- 支持混合输入
- 自动风格检测或手动指定
- 丰富的 CSS 动画效果
- SVG 几何装饰图案
- Canvas 粒子背景（可选）
- 键盘/触控导航
- 进度指示器
- 打印友好

### Animation Effects

- 页面切换：淡入淡化、滑入、缩放、3D 翻转
- 内容入场：渐显上升、逐字显示、弹性动画
- 背景效果：渐变流动、粒子漂浮、波浪动画
- 悬停反馈：缩放、发光、阴影变化

## Installation

```bash
# 创建工作目录
mkdir -p .asdm/workspace/awesome-pptx/output
```

## Usage

```bash
/awesome-pptx --style tech --content "演示内容"
/awesome-pptx --style chinese --file README.md
/awesome-pptx --file changelog.md --style business
```

## Structure

```
.asdm/toolsets/awesome-pptx/
├── manifest.json
├── README.md
├── INSTALL.md
├── actions/
│   └── awesome-pptx.md          # 主操作指令
└── spec/
    ├── styles-guide.md          # 风格指南
    └── templates/                # CSS 模板
        ├── business.css
        ├── tech.css
        ├── chinese.css
        ├── fresh.css
        ├── minimal.css
        └── gradient.css
```

## Output

生成文件保存至：`.asdm/workspace/awesome-pptx/output/`

## Copyright

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.
