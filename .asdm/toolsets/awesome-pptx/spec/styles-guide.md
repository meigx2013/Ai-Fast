# 风格指南 - Styles Guide

本指南定义了 awesome-pptx 工具集支持的 6 种预设风格，每种风格都有独特的配色方案、装饰元素和视觉效果。

---

## 1. 商务风格 (business)

### 适用场景
企业汇报、商务演示、会议展示、年度总结

### 视觉特点
- 深蓝主色调，传达专业与稳重
- 金色点缀，提升品质感
- 几何线条装饰，体现现代商务感
- 简洁有力的排版

### 配色方案
```css
:root {
  --bg-primary: #0a1628;
  --bg-secondary: #1a365d;
  --bg-gradient: linear-gradient(135deg, #0a1628 0%, #1a365d 50%, #0a1628 100%);
  
  --title-color: #f0f4f8;
  --text-color: #cbd5e1;
  
  --accent: #d4af37;           /* 金色 - 主强调色 */
  --accent-secondary: #1e40af; /* 深蓝 - 辅助色 */
  --accent-glow: rgba(212, 175, 55, 0.3);
  
  --dot-bg: rgba(255, 255, 255, 0.3);
  --dot-active: #d4af37;
  
  --btn-bg: rgba(255, 255, 255, 0.1);
  --btn-color: #f0f4f8;
  --btn-hover: #d4af37;
}

/* 深色主题 */
[data-theme="dark"] {
  --bg-primary: #050a15;
  --bg-gradient: linear-gradient(135deg, #050a15 0%, #0a1628 100%);
}
```

### 装饰元素
- **几何线条**：细金线装饰
- **圆形光晕**：半透明金色圆
- **网格背景**：淡金色点阵
- **角落装饰**：L 形线条

### CSS 片段
```css
/* 背景网格 */
.deco-grid {
  background-image: 
    radial-gradient(circle at 1px 1px, rgba(212, 175, 55, 0.15) 1px, transparent 0);
  background-size: 40px 40px;
}

/* 装饰圆 */
.deco-circle {
  border: 1px solid rgba(212, 175, 55, 0.3);
  box-shadow: 0 0 30px rgba(212, 175, 55, 0.1);
}
```

---

## 2. 科技风格 (tech)

### 适用场景
技术分享、代码演示、数据可视化、产品发布

### 视觉特点
- 深色背景，突显科技感
- 霓虹色彩点缀，发光效果
- 网格和电路纹理
- 粒子动画背景

### 配色方案
```css
:root {
  --bg-primary: #0d1117;
  --bg-secondary: #161b22;
  --bg-gradient: linear-gradient(180deg, #0d1117 0%, #161b22 50%, #0d1117 100%);
  
  --title-color: #58a6ff;
  --text-color: #8b949e;
  
  --accent: #00ff88;           /* 霓虹绿 */
  --accent-secondary: #ff6b6b;  /* 霓虹红 */
  --accent-tertiary: #a855f7;   /* 紫色 */
  --accent-glow: rgba(0, 255, 136, 0.4);
  
  --dot-bg: rgba(255, 255, 255, 0.2);
  --dot-active: #00ff88;
  
  --btn-bg: rgba(0, 255, 136, 0.1);
  --btn-color: #00ff88;
  --btn-hover: #00cc6a;
  --btn-shadow: 0 0 20px rgba(0, 255, 136, 0.3);
}

/* 发光文字效果 */
.glow-text {
  text-shadow: 0 0 10px var(--accent-glow), 0 0 20px var(--accent-glow);
}

/* 代码块高亮 */
.code-block {
  background: #1e1e1e;
  border-left: 3px solid #00ff88;
}
```

### 装饰元素
- **扫描线**：水平移动的光线
- **网格线**：科技感网格
- **电路纹理**：SVG 电路图案
- **粒子点**：漂浮的发光粒子

### CSS 动画
```css
/* 扫描线动画 */
@keyframes scanline {
  0% { transform: translateY(-100%); }
  100% { transform: translateY(100vh); }
}

.scanline {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 2px;
  background: linear-gradient(90deg, transparent, rgba(0, 255, 136, 0.5), transparent);
  animation: scanline 4s linear infinite;
}

/* 脉冲动画 */
@keyframes techPulse {
  0%, 100% { opacity: 0.3; }
  50% { opacity: 0.8; }
}
```

---

## 3. 中国风 (chinese)

### 适用场景
文化展示、传统美学、诗词演示、艺术欣赏

### 视觉特点
- 水墨淡雅的配色
- 云纹、水波等传统图案
- 书法质感的字体效果
- 留白与对称美学

### 配色方案
```css
:root {
  --bg-primary: #f5f0e8;
  --bg-secondary: #e8e0d5;
  --bg-gradient: linear-gradient(135deg, #f5f0e8 0%, #faf8f5 50%, #f5f0e8 100%);
  
  --title-color: #2c1810;
  --text-color: #4a3728;
  
  --accent: #c41e3a;           /* 朱红 - 中国传统色 */
  --accent-secondary: #1a5f4a;  /* 青绿 */
  --accent-tertiary: #d4a853;   /* 鎏金 */
  --accent-glow: rgba(196, 30, 58, 0.15);
  
  --dot-bg: rgba(44, 24, 16, 0.2);
  --dot-active: #c41e3a;
  
  --btn-bg: rgba(196, 30, 58, 0.1);
  --btn-color: #c41e3a;
  --btn-hover: #a01830;
}

/* 宣纸纹理 */
.paper-texture {
  background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 100 100' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.04' numOctaves='5' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)' opacity='0.03'/%3E%3C/svg%3E");
}

/* 深色主题 - 水墨风格 */
[data-theme="dark"] {
  --bg-primary: #1a1a1a;
  --bg-gradient: linear-gradient(135deg, #1a1a1a 0%, #2d2d2d 100%);
  --title-color: #e8e0d5;
  --text-color: #a09080;
}
```

### 装饰元素
- **云纹**：传统云纹图案
- **水墨晕染**：渐变模糊效果
- **印章**：红色印章装饰
- **竹节**：竖向装饰线条

### CSS 片段
```css
/* 云纹装饰 */
.cloud-pattern {
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 50'%3E%3Cpath fill='rgba(196,30,58,0.05)' d='M0,50 Q25,20 50,50 T100,50 L100,50 L0,50Z'/%3E%3C/svg%3E");
  background-size: 200px 50px;
}

/* 印章效果 */
.seal {
  width: 60px;
  height: 60px;
  border: 2px solid #c41e3a;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 24px;
  color: #c41e3a;
  transform: rotate(-5deg);
}

/* 竹节装饰 */
.bamboo {
  width: 2px;
  height: 100px;
  background: repeating-linear-gradient(
    to bottom,
    #1a5f4a 0px,
    #1a5f4a 20px,
    transparent 20px,
    transparent 25px
  );
}
```

---

## 4. 清新风格 (fresh)

### 适用场景
教学课件、生活分享、旅行记录、美食介绍

### 视觉特点
- 马卡龙色系，柔和甜美
- 大圆角设计，亲切可爱
- 柔和的渐变过渡
- 轻快的动画节奏

### 配色方案
```css
:root {
  --bg-primary: #f0f9ff;
  --bg-secondary: #e0f2fe;
  --bg-gradient: linear-gradient(135deg, #f0f9ff 0%, #e0f2fe 30%, #f0fdf4 70%, #faf5ff 100%);
  
  --title-color: #0c4a6e;
  --text-color: #475569;
  
  --accent: #22d3ee;           /* 天蓝 */
  --accent-secondary: #a78bfa; /* 紫色 */
  --accent-tertiary: #fb7185;   /* 粉色 */
  --accent-glow: rgba(34, 211, 238, 0.2);
  
  --dot-bg: rgba(12, 74, 110, 0.2);
  --dot-active: #22d3ee;
  
  --btn-bg: rgba(255, 255, 255, 0.9);
  --btn-color: #0c4a6e;
  --btn-hover: #22d3ee;
  --btn-shadow: 0 4px 15px rgba(34, 211, 238, 0.3);
  --btn-radius: 25px;
}

/* 柔和阴影 */
.soft-shadow {
  box-shadow: 0 10px 40px rgba(34, 211, 238, 0.15);
}

/* 圆角卡片 */
.card {
  background: rgba(255, 255, 255, 0.8);
  border-radius: 20px;
  padding: 30px;
  backdrop-filter: blur(10px);
}
```

### 装饰元素
- **气泡**：大小不一的半透明圆
- **星星**：闪烁的小星星
- **飘带**：曲线装饰
- **植物**：小叶子图标

### CSS 动画
```css
/* 漂浮动画 */
@keyframes gentleFloat {
  0%, 100% { transform: translateY(0) rotate(0deg); }
  25% { transform: translateY(-10px) rotate(2deg); }
  75% { transform: translateY(-5px) rotate(-2deg); }
}

/* 弹跳动画 */
@keyframes bounce {
  0%, 100% { transform: translateY(0); }
  50% { transform: translateY(-15px); }
}

/* 颜色流动 */
@keyframes colorFlow {
  0% { filter: hue-rotate(0deg); }
  100% { filter: hue-rotate(30deg); }
}
```

---

## 5. 简约风格 (minimal)

### 适用场景
艺术展示、创意演示、极简摄影、产品设计

### 视觉特点
- 大面积留白
- 单一强调色
- 精致的细线装饰
- 克制的动画

### 配色方案
```css
:root {
  --bg-primary: #ffffff;
  --bg-secondary: #fafafa;
  --bg-gradient: linear-gradient(180deg, #ffffff 0%, #fafafa 100%);
  
  --title-color: #000000;
  --text-color: #666666;
  
  --accent: #000000;           /* 纯黑 */
  --accent-secondary: #999999;
  --accent-glow: rgba(0, 0, 0, 0.05);
  
  --dot-bg: rgba(0, 0, 0, 0.1);
  --dot-active: #000000;
  
  --btn-bg: transparent;
  --btn-color: #000000;
  --btn-hover: #666666;
  --btn-radius: 0;
}

/* 细线装饰 */
.thin-line {
  height: 1px;
  background: #000000;
  width: 60px;
  margin: 20px auto;
}
```

### 装饰元素
- **细线**：1px 装饰线
- **点**：小圆点
- **留白**：大量空白空间
- **极简图标**：简单几何形状

---

## 6. 渐变风格 (gradient)

### 适用场景
产品介绍、营销展示、活动推广、品牌宣传

### 视觉特点
- 鲜艳的渐变色彩
- 大色块设计
- 动感流畅
- 充满活力

### 配色方案
```css
:root {
  --bg-primary: #667eea;
  --bg-secondary: #764ba2;
  --bg-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
  background-size: 200% 200%;
  animation: gradientShift 15s ease infinite;
  
  --title-color: #ffffff;
  --text-color: rgba(255, 255, 255, 0.9);
  
  --accent: #00d9ff;
  --accent-secondary: #ff6b9d;
  --accent-tertiary: #ffd93d;
  --accent-glow: rgba(0, 217, 255, 0.3);
  
  --dot-bg: rgba(255, 255, 255, 0.3);
  --dot-active: #ffffff;
  
  --btn-bg: rgba(255, 255, 255, 0.2);
  --btn-color: #ffffff;
  --btn-hover: rgba(255, 255, 255, 0.4);
  --btn-radius: 30px;
  --btn-shadow: 0 5px 20px rgba(0, 0, 0, 0.2);
}

/* 深色主题 */
[data-theme="dark"] {
  --bg-primary: #1a1a2e;
  --bg-secondary: #16213e;
  --bg-gradient: linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%);
}
```

### 装饰元素
- **渐变光斑**：模糊的彩色圆
- **流光线**：动态光效
- **波纹**：扩散的圆环
- **粒子**：彩屑效果

### CSS 动画
```css
/* 渐变流动 */
@keyframes gradientShift {
  0% { background-position: 0% 50%; }
  50% { background-position: 100% 50%; }
  100% { background-position: 0% 50%; }
}

/* 波纹扩散 */
@keyframes ripple {
  0% { transform: scale(0); opacity: 1; }
  100% { transform: scale(4); opacity: 0; }
}

/* 旋转渐变 */
@keyframes rotateGradient {
  0% { filter: hue-rotate(0deg); }
  100% { filter: hue-rotate(360deg); }
}
```

---

## 动画类型速查

| 动画类型 | 关键词 | 适用风格 |
|----------|--------|----------|
| `fade` | 淡入淡出、柔和 | 全部 |
| `slide` | 滑入、现代 | 商务、科技、渐变 |
| `zoom` | 缩放、聚焦 | 简约、清新 |
| `3d` | 翻转、立体 | 科技、渐变 |
| `auto` | 自动选择最佳 | 默认 |

---

## 风格选择建议

| 用户需求 | 推荐风格 |
|----------|----------|
| 公司会议汇报 | business |
| 技术分享演讲 | tech |
| 传统文化介绍 | chinese |
| 学校教学课件 | fresh |
| 艺术作品展示 | minimal |
| 产品发布会 | gradient |
| 不确定风格 | fresh (默认) |
