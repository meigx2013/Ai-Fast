# Instructions for awesome-pptx action

## Purpose

本指令指导 AI 模型根据用户提供的演示内容，自动生成**炫酷美观**的 HTML 演示页面。支持多种视觉风格、丰富的动画效果和高质量视觉元素。

## Language Setting

默认使用**中文（简体中文）**作为输出语言。

## Supported Styles

| 风格 ID | 名称 | 特点 | 适用场景 |
|---------|------|------|----------|
| `business` | 商务风格 | 深蓝主色、金色点缀、几何线条 | 企业汇报、商务演示 |
| `tech` | 科技风格 | 霓虹色、粒子背景、科技网格 | 技术分享、代码演示 |
| `chinese` | 中国风 | 水墨色、朱红点缀、云纹图案 | 文化展示、传统美学 |
| `fresh` | 清新风格 | 马卡龙色、柔和渐变、自然元素 | 教学课件、生活分享 |
| `minimal` | 简约风格 | 大量留白、单色、极简装饰 | 艺术展示、创意演示 |
| `gradient` | 渐变风格 | 彩虹渐变、动态色块、活力感 | 产品介绍、营销展示 |

## Input Types

### 1. 文件输入 (filePath)

**支持格式**：`.md`, `.txt` 或其他纯文本文件

**解析规则**：
- Markdown：`#` 和 `##` 作为页面标题，`---` 分隔页面
- 文本：空行分隔段落，第一行为标题

### 2. 对话输入 (content)

直接输入的演示内容，使用空行分隔页面。

### 3. 混合输入 (filePath + content)

优先使用 `content`，文件作为补充。

## Parameters

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `content` | string | 否 | 演示内容文本 |
| `filePath` | string | 否 | 内容文件路径 |
| `style` | string | 否 | 风格类型，默认自动检测 |
| `animation` | string | 否 | 动画类型：fade/slide/zoom/3d/auto |
| `theme` | string | 否 | 主题：dark/light，默认 dark |
| `background` | string | 否 | 背景图片 URL（可选） |

### Style 自动检测关键词

| 风格 | 触发关键词 |
|------|------------|
| business | 商务、会议、报告、年度、总结、汇报 |
| tech | 科技、技术、代码、编程、开发、数据、算法 |
| chinese | 中国风、传统、文化、古风、水墨、诗词 |
| fresh | 清新、自然、教学、分享、教程、学习 |
| minimal | 极简、简约、艺术、创意、设计 |
| gradient | 产品、发布、营销、活动、推广 |

## Steps to Generate

### Step 1: 接收并验证参数

```javascript
{
  content: string,      // 可选
  filePath: string,     // 可选
  style: string,        // 可选，默认 auto
  animation: string,    // 可选，默认 auto
  theme: string,        // 可选，默认 dark
  background: string     // 可选
}
```

至少提供 `content` 或 `filePath` 之一。

### Step 2: 获取并解析内容

读取文件或使用对话内容，解析为页面结构：

```javascript
{
  pages: [
    {
      title: string,
      content: string,
      type: 'title' | 'content' | 'list' | 'cards' | 'quote' | 'stats'
    }
  ],
  metadata: {
    totalPages: number,
    sourceType: 'file' | 'conversation' | 'mixed'
  }
}
```

### Step 3: 确定风格

1. 如果指定了 `style`，使用指定风格
2. 否则根据内容关键词自动检测
3. 默认使用 `gradient`（渐变风格）

### Step 4: 生成炫酷 HTML

**必须包含以下炫酷效果**：

#### A. Canvas 粒子/星空效果（必须）

```javascript
// 动态粒子系统
class ParticleSystem {
  constructor(canvas) {
    this.canvas = canvas;
    this.ctx = canvas.getContext('2d');
    this.particles = [];
    this.mouse = { x: null, y: null };
    this.init();
  }
  
  init() {
    // 创建粒子
    for (let i = 0; i < 100; i++) {
      this.particles.push({
        x: Math.random() * this.canvas.width,
        y: Math.random() * this.canvas.height,
        size: Math.random() * 3 + 1,
        speedX: Math.random() * 0.5 - 0.25,
        speedY: Math.random() * 0.5 - 0.25,
        opacity: Math.random() * 0.5 + 0.2,
        hue: Math.random() * 60 + 240 // 蓝紫色调
      });
    }
  }
  
  animate() {
    this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
    
    this.particles.forEach(p => {
      // 移动
      p.x += p.speedX;
      p.y += p.speedY;
      
      // 鼠标交互
      if (this.mouse.x && this.mouse.y) {
        const dx = p.x - this.mouse.x;
        const dy = p.y - this.mouse.y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < 150) {
          p.x += dx * 0.02;
          p.y += dy * 0.02;
        }
      }
      
      // 边界反弹
      if (p.x < 0 || p.x > this.canvas.width) p.speedX *= -1;
      if (p.y < 0 || p.y > this.canvas.height) p.speedY *= -1;
      
      // 绘制
      this.ctx.beginPath();
      this.ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
      this.ctx.fillStyle = `hsla(${p.hue}, 80%, 60%, ${p.opacity})`;
      this.ctx.fill();
      
      // 绘制光晕
      this.ctx.beginPath();
      this.ctx.arc(p.x, p.y, p.size * 3, 0, Math.PI * 2);
      this.ctx.fillStyle = `hsla(${p.hue}, 80%, 60%, ${p.opacity * 0.2})`;
      this.ctx.fill();
      
      // 连线效果
      this.particles.forEach(p2 => {
        const dx = p.x - p2.x;
        const dy = p.y - p2.y;
        const dist = Math.sqrt(dx * dx + dy * dy);
        if (dist < 100) {
          this.ctx.beginPath();
          this.ctx.moveTo(p.x, p.y);
          this.ctx.lineTo(p2.x, p2.y);
          this.ctx.strokeStyle = `hsla(${p.hue}, 80%, 60%, ${0.15 * (1 - dist / 100)})`;
          this.ctx.stroke();
        }
      });
    });
    
    requestAnimationFrame(() => this.animate());
  }
}
```

#### B. 打字机效果（标题必须）

```javascript
function typeWriter(element, text, speed = 50) {
  let i = 0;
  element.textContent = '';
  element.style.opacity = '1';
  
  function type() {
    if (i < text.length) {
      element.textContent += text.charAt(i);
      i++;
      setTimeout(type, speed);
    }
  }
  type();
}
```

#### C. Stagger 入场动画（元素必须顺序出现）

```javascript
function staggerAnimate(elements, baseDelay = 100) {
  elements.forEach((el, index) => {
    el.style.opacity = '0';
    el.style.transform = 'translateY(30px)';
    el.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
    
    setTimeout(() => {
      el.style.opacity = '1';
      el.style.transform = 'translateY(0)';
    }, baseDelay * index);
  });
}
```

#### D. 鼠标跟随光效（必须）

```javascript
const cursorGlow = document.querySelector('.cursor-glow');
document.addEventListener('mousemove', (e) => {
  cursorGlow.style.left = e.clientX + 'px';
  cursorGlow.style.top = e.clientY + 'px';
});
```

#### E. 卡片悬停 3D 倾斜效果（推荐）

```javascript
document.querySelectorAll('.card-3d').forEach(card => {
  card.addEventListener('mousemove', (e) => {
    const rect = card.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const y = e.clientY - rect.top;
    const centerX = rect.width / 2;
    const centerY = rect.height / 2;
    const rotateX = (y - centerY) / 10;
    const rotateY = (centerX - x) / 10;
    
    card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale(1.05)`;
  });
  
  card.addEventListener('mouseleave', () => {
    card.style.transform = 'perspective(1000px) rotateX(0) rotateY(0) scale(1)';
  });
});
```

#### F. 视差滚动效果（推荐）

```javascript
window.addEventListener('scroll', () => {
  const scrolled = window.pageYOffset;
  document.querySelectorAll('.parallax').forEach(el => {
    const speed = el.dataset.speed || 0.5;
    el.style.transform = `translateY(${scrolled * speed}px)`;
  });
});
```

#### G. 高质量背景图片（必须）

```html
<!-- 使用 Unsplash 随机高质量图片 -->
<div class="bg-image" style="background-image: url('https://images.unsplash.com/photo-{id}?w=1920&q=80');"></div>

<!-- 叠加渐变遮罩 -->
<div class="bg-overlay"></div>
```

风格对应的推荐背景图片主题：
- tech: 科技感、星系、网络、数据流
- business: 城市天际线、会议室、现代建筑
- chinese: 水墨山水、古典建筑、传统纹样
- fresh: 自然风景、植物、天空
- gradient: 抽象渐变、光效、色彩流动
- minimal: 纯色、简单几何

### Step 5: 保存文件

**输出路径**：`.asdm/workspace/awesome-pptx/output/`

**命名规则**：
- 文件输入：使用源文件名，如 `readme.html`
- 对话输入：`demo.html`，如已存在则 `demo-YYYYMMDD-HHMMSS.html`

## HTML Template Structure (炫酷版)

```html
<!DOCTYPE html>
<html lang="zh-CN" data-style="tech" data-animation="slide" data-theme="dark">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{标题}</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&family=Noto+Sans+SC:wght@300;400;500;700&display=swap" rel="stylesheet">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    
    /* ========== 核心动画 ========== */
    @keyframes gradientFlow { 0% { background-position: 0% 50%; } 50% { background-position: 100% 50%; } 100% { background-position: 0% 50%; } }
    @keyframes pulse { 0%, 100% { opacity: 0.4; transform: scale(1); } 50% { opacity: 0.8; transform: scale(1.1); } }
    @keyframes float { 0%, 100% { transform: translateY(0); } 50% { transform: translateY(-20px); } }
    @keyframes glow { 0%, 100% { box-shadow: 0 0 20px var(--accent), 0 0 40px var(--accent-glow); } 50% { box-shadow: 0 0 40px var(--accent), 0 0 80px var(--accent-glow); } }
    @keyframes textGlow { 0%, 100% { text-shadow: 0 0 20px var(--accent), 0 0 40px var(--accent-glow); } 50% { text-shadow: 0 0 40px var(--accent), 0 0 80px var(--accent-glow), 0 0 120px var(--accent-glow); } }
    @keyframes shimmer { 0% { background-position: -200% center; } 100% { background-position: 200% center; } }
    @keyframes scanline { 0% { transform: translateY(-100%); } 100% { transform: translateY(100vh); } }
    @keyframes rotate3d { 0% { transform: rotateY(0deg); } 100% { transform: rotateY(360deg); } }
    @keyframes borderLight { 0% { background-position: 0% 0%; } 100% { background-position: 200% 200%; } }
    
    /* ========== 变量定义 ========== */
    :root {
      --bg-primary: #050510;
      --accent: #00f5ff;
      --accent-secondary: #ff00ff;
      --accent-tertiary: #ffff00;
      --accent-glow: rgba(0, 245, 255, 0.5);
      --text-primary: #ffffff;
      --text-secondary: rgba(255, 255, 255, 0.7);
      --glass-bg: rgba(255, 255, 255, 0.05);
      --glass-border: rgba(255, 255, 255, 0.1);
      --font-display: 'Orbitron', 'Noto Sans SC', sans-serif;
      --font-body: 'Noto Sans SC', -apple-system, sans-serif;
    }
    
    /* ========== 背景层 ========== */
    .bg-container {
      position: fixed;
      top: 0; left: 0;
      width: 100%; height: 100%;
      z-index: 0;
      overflow: hidden;
    }
    
    .bg-image {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      background-size: cover;
      background-position: center;
      filter: brightness(0.3) saturate(1.2);
      transform: scale(1.1);
      transition: transform 10s ease;
    }
    
    .bg-gradient {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      background: linear-gradient(135deg, 
        var(--bg-primary) 0%, 
        rgba(20, 0, 40, 0.8) 50%, 
        var(--bg-primary) 100%);
      background-size: 400% 400%;
      animation: gradientFlow 15s ease infinite;
    }
    
    .bg-overlay {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      background: radial-gradient(ellipse at center, transparent 0%, var(--bg-primary) 70%);
    }
    
    #particle-canvas {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      z-index: 1;
    }
    
    .scanline {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 4px;
      background: linear-gradient(transparent, rgba(0, 245, 255, 0.1), transparent);
      animation: scanline 8s linear infinite;
      z-index: 2;
    }
    
    .noise {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      opacity: 0.03;
      background-image: url("data:image/svg+xml,%3Csvg viewBox='0 0 256 256' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noise'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='0.9' numOctaves='4' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noise)'/%3E%3C/svg%3E");
      z-index: 3;
    }
    
    /* ========== 鼠标跟随光效 ========== */
    .cursor-glow {
      position: fixed;
      width: 400px;
      height: 400px;
      border-radius: 50%;
      background: radial-gradient(circle, var(--accent-glow) 0%, transparent 70%);
      transform: translate(-50%, -50%);
      pointer-events: none;
      z-index: 9999;
      opacity: 0.3;
      transition: opacity 0.3s;
    }
    
    /* ========== 布局 ========== */
    .presentation {
      position: relative;
      width: 100vw;
      height: 100vh;
      overflow: hidden;
      font-family: var(--font-body);
      color: var(--text-primary);
    }
    
    .slide {
      position: absolute;
      top: 0; left: 0;
      width: 100%; height: 100%;
      display: none;
      flex-direction: column;
      justify-content: center;
      align-items: center;
      padding: 60px 80px;
      z-index: 10;
    }
    
    .slide.active {
      display: flex;
    }
    
    .slide-content {
      max-width: 1200px;
      width: 100%;
      text-align: center;
      z-index: 10;
    }
    
    /* ========== 标题样式 ========== */
    .slide-title {
      font-family: var(--font-display);
      font-size: clamp(2.5rem, 8vw, 5rem);
      font-weight: 900;
      color: var(--text-primary);
      margin-bottom: 1.5rem;
      line-height: 1.2;
      background: linear-gradient(135deg, var(--accent) 0%, var(--accent-secondary) 50%, var(--accent-tertiary) 100%);
      background-size: 200% auto;
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      animation: shimmer 3s linear infinite, textGlow 2s ease-in-out infinite;
      text-transform: uppercase;
      letter-spacing: 0.1em;
    }
    
    .slide-subtitle {
      font-size: clamp(1.2rem, 3vw, 2rem);
      color: var(--accent);
      margin-bottom: 2rem;
      font-weight: 300;
      letter-spacing: 0.3em;
      text-transform: uppercase;
      opacity: 0;
      animation: fadeInUp 1s ease forwards;
    }
    
    .slide-text {
      font-size: clamp(1rem, 2vw, 1.4rem);
      color: var(--text-secondary);
      line-height: 2;
      margin-bottom: 1.5rem;
      opacity: 0;
    }
    
    .divider {
      width: 200px;
      height: 2px;
      background: linear-gradient(90deg, transparent, var(--accent), var(--accent-secondary), transparent);
      margin: 2rem auto;
      position: relative;
      opacity: 0;
    }
    
    .divider::before {
      content: '';
      position: absolute;
      top: -3px;
      left: 50%;
      transform: translateX(-50%);
      width: 8px;
      height: 8px;
      background: var(--accent);
      border-radius: 50%;
      box-shadow: 0 0 20px var(--accent);
    }
    
    /* ========== 卡片网格 ========== */
    .card-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
      gap: 30px;
      margin-top: 3rem;
      width: 100%;
    }
    
    .card-3d {
      background: var(--glass-bg);
      border: 1px solid var(--glass-border);
      border-radius: 20px;
      padding: 2.5rem;
      backdrop-filter: blur(20px);
      transition: all 0.4s cubic-bezier(0.175, 0.885, 0.32, 1.275);
      transform-style: preserve-3d;
      position: relative;
      overflow: hidden;
      opacity: 0;
    }
    
    .card-3d::before {
      content: '';
      position: absolute;
      top: 0; left: -100%;
      width: 100%; height: 100%;
      background: linear-gradient(90deg, transparent, rgba(255,255,255,0.1), transparent);
      transition: left 0.5s;
    }
    
    .card-3d:hover::before {
      left: 100%;
    }
    
    .card-3d:hover {
      border-color: var(--accent);
      box-shadow: 0 20px 60px rgba(0, 245, 255, 0.2), 
                  inset 0 0 30px rgba(0, 245, 255, 0.05);
    }
    
    .card-icon {
      font-size: 4rem;
      margin-bottom: 1.5rem;
      display: block;
      filter: drop-shadow(0 0 20px var(--accent-glow));
    }
    
    .card-title {
      font-size: 1.5rem;
      font-weight: 700;
      color: var(--text-primary);
      margin-bottom: 1rem;
      font-family: var(--font-display);
    }
    
    .card-desc {
      font-size: 1rem;
      color: var(--text-secondary);
      line-height: 1.8;
    }
    
    /* ========== 列表样式 ========== */
    .slide-list {
      list-style: none;
      text-align: left;
      max-width: 800px;
      margin: 2rem auto;
    }
    
    .slide-list li {
      position: relative;
      padding: 1.2rem 0 1.2rem 3.5rem;
      font-size: 1.2rem;
      color: var(--text-secondary);
      border-bottom: 1px solid rgba(255,255,255,0.05);
      opacity: 0;
      transition: all 0.3s;
    }
    
    .slide-list li::before {
      content: '';
      position: absolute;
      left: 0;
      top: 50%;
      transform: translateY(-50%);
      width: 20px;
      height: 20px;
      background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
      border-radius: 4px;
      transform: translateY(-50%) rotate(45deg);
      box-shadow: 0 0 15px var(--accent-glow);
    }
    
    .slide-list li:hover {
      color: var(--text-primary);
      padding-left: 4rem;
    }
    
    /* ========== 统计数据 ========== */
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(4, 1fr);
      gap: 40px;
      margin-top: 3rem;
    }
    
    .stat-item {
      text-align: center;
      opacity: 0;
    }
    
    .stat-number {
      font-family: var(--font-display);
      font-size: clamp(2.5rem, 5vw, 4rem);
      font-weight: 900;
      background: linear-gradient(135deg, var(--accent), var(--accent-secondary));
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      display: block;
      margin-bottom: 0.5rem;
    }
    
    .stat-label {
      font-size: 1rem;
      color: var(--text-secondary);
      text-transform: uppercase;
      letter-spacing: 0.2em;
    }
    
    /* ========== 引用样式 ========== */
    .quote-block {
      position: relative;
      padding: 3rem;
      margin: 2rem 0;
      opacity: 0;
    }
    
    .quote-block::before {
      content: '"';
      position: absolute;
      top: -20px;
      left: 0;
      font-size: 8rem;
      color: var(--accent);
      opacity: 0.2;
      font-family: Georgia, serif;
      line-height: 1;
    }
    
    .quote-text {
      font-size: clamp(1.5rem, 3vw, 2.5rem);
      font-style: italic;
      color: var(--text-primary);
      line-height: 1.8;
      text-shadow: 0 0 30px var(--accent-glow);
    }
    
    /* ========== 导航 ========== */
    .page-indicator {
      position: fixed;
      top: 30px;
      right: 30px;
      font-family: var(--font-display);
      font-size: 1rem;
      color: var(--accent);
      background: var(--glass-bg);
      border: 1px solid var(--glass-border);
      padding: 12px 24px;
      border-radius: 30px;
      backdrop-filter: blur(10px);
      z-index: 100;
      letter-spacing: 0.2em;
    }
    
    .progress-bar {
      position: fixed;
      top: 0;
      left: 0;
      height: 3px;
      background: linear-gradient(90deg, var(--accent), var(--accent-secondary));
      z-index: 101;
      transition: width 0.3s;
    }
    
    .nav-dots {
      position: fixed;
      bottom: 40px;
      left: 50%;
      transform: translateX(-50%);
      display: flex;
      gap: 15px;
      z-index: 100;
    }
    
    .nav-dot {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      background: var(--glass-bg);
      border: 1px solid var(--glass-border);
      cursor: pointer;
      transition: all 0.3s;
    }
    
    .nav-dot.active {
      background: var(--accent);
      border-color: var(--accent);
      box-shadow: 0 0 20px var(--accent-glow);
      transform: scale(1.3);
    }
    
    .nav-dot:hover {
      background: var(--accent-secondary);
      border-color: var(--accent-secondary);
    }
    
    .controls {
      position: fixed;
      bottom: 30px;
      right: 30px;
      display: flex;
      gap: 15px;
      z-index: 100;
    }
    
    .ctrl-btn {
      width: 60px;
      height: 60px;
      border-radius: 50%;
      background: var(--glass-bg);
      border: 1px solid var(--glass-border);
      color: var(--accent);
      font-size: 24px;
      cursor: pointer;
      backdrop-filter: blur(10px);
      transition: all 0.3s;
      display: flex;
      align-items: center;
      justify-content: center;
    }
    
    .ctrl-btn:hover {
      background: var(--accent);
      color: var(--bg-primary);
      box-shadow: 0 0 30px var(--accent-glow);
      transform: scale(1.1);
    }
    
    /* ========== 动画定义 ========== */
    @keyframes fadeInUp {
      from {
        opacity: 0;
        transform: translateY(40px);
      }
      to {
        opacity: 1;
        transform: translateY(0);
      }
    }
    
    @keyframes fadeInLeft {
      from {
        opacity: 0;
        transform: translateX(-40px);
      }
      to {
        opacity: 1;
        transform: translateX(0);
      }
    }
    
    @keyframes fadeInRight {
      from {
        opacity: 0;
        transform: translateX(40px);
      }
      to {
        opacity: 1;
        transform: translateX(0);
      }
    }
    
    @keyframes scaleIn {
      from {
        opacity: 0;
        transform: scale(0.8);
      }
      to {
        opacity: 1;
        transform: scale(1);
      }
    }
    
    /* ========== 响应式 ========== */
    @media (max-width: 768px) {
      .slide { padding: 30px; }
      .stats-grid { grid-template-columns: repeat(2, 1fr); gap: 20px; }
      .card-grid { grid-template-columns: 1fr; gap: 20px; }
      .controls { display: none; }
      .cursor-glow { display: none; }
    }
  </style>
</head>
<body>
  <!-- 鼠标跟随光效 -->
  <div class="cursor-glow"></div>
  
  <div class="presentation">
    <!-- 背景层 -->
    <div class="bg-container">
      <div class="bg-gradient"></div>
      <div class="bg-image"></div>
      <div class="bg-overlay"></div>
      <canvas id="particle-canvas"></canvas>
      <div class="scanline"></div>
      <div class="noise"></div>
    </div>
    
    <!-- 进度条 -->
    <div class="progress-bar"></div>
    
    <!-- 页面内容占位 -->
    <!-- 由 AI 根据内容生成具体页面 -->
    
    <!-- 导航 -->
    <div class="page-indicator">1 / N</div>
    <nav class="nav-dots"></nav>
    <div class="controls">
      <button class="ctrl-btn" id="prevBtn">←</button>
      <button class="ctrl-btn" id="nextBtn">→</button>
    </div>
  </div>
  
  <script>
    // ========== 粒子系统 ==========
    class ParticleSystem {
      constructor() {
        this.canvas = document.getElementById('particle-canvas');
        this.ctx = this.canvas.getContext('2d');
        this.particles = [];
        this.mouse = { x: null, y: null };
        this.init();
        this.animate();
        this.bindEvents();
      }
      
      init() {
        this.resize();
        for (let i = 0; i < 120; i++) {
          this.particles.push(this.createParticle());
        }
      }
      
      createParticle() {
        return {
          x: Math.random() * this.canvas.width,
          y: Math.random() * this.canvas.height,
          size: Math.random() * 3 + 1,
          speedX: (Math.random() - 0.5) * 0.8,
          speedY: (Math.random() - 0.5) * 0.8,
          opacity: Math.random() * 0.6 + 0.2,
          hue: Math.random() * 60 + 220,
          pulse: Math.random() * Math.PI * 2
        };
      }
      
      resize() {
        this.canvas.width = window.innerWidth;
        this.canvas.height = window.innerHeight;
      }
      
      bindEvents() {
        window.addEventListener('resize', () => this.resize());
        document.addEventListener('mousemove', (e) => {
          this.mouse.x = e.clientX;
          this.mouse.y = e.clientY;
        });
        document.addEventListener('mouseleave', () => {
          this.mouse.x = null;
          this.mouse.y = null;
        });
      }
      
      animate() {
        this.ctx.clearRect(0, 0, this.canvas.width, this.canvas.height);
        
        this.particles.forEach((p, i) => {
          p.pulse += 0.02;
          
          p.x += p.speedX;
          p.y += p.speedY;
          
          // 鼠标交互
          if (this.mouse.x && this.mouse.y) {
            const dx = p.x - this.mouse.x;
            const dy = p.y - this.mouse.y;
            const dist = Math.sqrt(dx * dx + dy * dy);
            if (dist < 150) {
              const force = (150 - dist) / 150;
              p.x += dx * force * 0.03;
              p.y += dy * force * 0.03;
            }
          }
          
          // 边界处理
          if (p.x < 0) p.x = this.canvas.width;
          if (p.x > this.canvas.width) p.x = 0;
          if (p.y < 0) p.y = this.canvas.height;
          if (p.y > this.canvas.height) p.y = 0;
          
          // 绘制粒子
          const currentOpacity = p.opacity * (0.5 + Math.sin(p.pulse) * 0.3);
          
          // 光晕
          const gradient = this.ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, p.size * 4);
          gradient.addColorStop(0, `hsla(${p.hue}, 100%, 60%, ${currentOpacity})`);
          gradient.addColorStop(1, `hsla(${p.hue}, 100%, 60%, 0)`);
          this.ctx.beginPath();
          this.ctx.arc(p.x, p.y, p.size * 4, 0, Math.PI * 2);
          this.ctx.fillStyle = gradient;
          this.ctx.fill();
          
          // 核心
          this.ctx.beginPath();
          this.ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
          this.ctx.fillStyle = `hsla(${p.hue}, 100%, 80%, ${currentOpacity})`;
          this.ctx.fill();
          
          // 连线
          this.particles.slice(i + 1).forEach(p2 => {
            const dx = p.x - p2.x;
            const dy = p.y - p2.y;
            const dist = Math.sqrt(dx * dx + dy * dy);
            if (dist < 120) {
              this.ctx.beginPath();
              this.ctx.moveTo(p.x, p.y);
              this.ctx.lineTo(p2.x, p2.y);
              this.ctx.strokeStyle = `hsla(${p.hue}, 80%, 60%, ${0.15 * (1 - dist / 120)})`;
              this.ctx.lineWidth = 0.5;
              this.ctx.stroke();
            }
          });
        });
        
        requestAnimationFrame(() => this.animate());
      }
    }
    
    // ========== 打字机效果 ==========
    function typeWriter(element, text, speed = 50) {
      return new Promise(resolve => {
        let i = 0;
        element.textContent = '';
        element.style.opacity = '1';
        
        function type() {
          if (i < text.length) {
            element.textContent += text.charAt(i);
            i++;
            setTimeout(type, speed);
          } else {
            resolve();
          }
        }
        type();
      });
    }
    
    // ========== 演示控制器 ==========
    const presentation = {
      currentSlide: 1,
      totalSlides: 0,
      isAnimating: false,
      
      init() {
        this.totalSlides = document.querySelectorAll('.slide').length;
        this.createDots();
        this.bindEvents();
        this.updateSlide();
        this.animateSlideContent(1);
      },
      
      createDots() {
        const dotsNav = document.querySelector('.nav-dots');
        for (let i = 1; i <= this.totalSlides; i++) {
          const dot = document.createElement('span');
          dot.className = 'nav-dot' + (i === 1 ? ' active' : '');
          dot.dataset.slide = i;
          dot.addEventListener('click', () => this.goToSlide(i));
          dotsNav.appendChild(dot);
        }
      },
      
      bindEvents() {
        document.addEventListener('keydown', (e) => {
          if (this.isAnimating) return;
          switch(e.key) {
            case 'ArrowRight':
            case 'ArrowDown':
            case ' ':
              e.preventDefault();
              this.next();
              break;
            case 'ArrowLeft':
            case 'ArrowUp':
              e.preventDefault();
              this.prev();
              break;
            case 'Home':
              this.goToSlide(1);
              break;
            case 'End':
              this.goToSlide(this.totalSlides);
              break;
          }
        });
        
        document.getElementById('prevBtn').addEventListener('click', () => this.prev());
        document.getElementById('nextBtn').addEventListener('click', () => this.next());
        
        // 触摸滑动
        let touchStartX = 0;
        document.addEventListener('touchstart', (e) => {
          touchStartX = e.touches[0].clientX;
        });
        document.addEventListener('touchend', (e) => {
          const diff = touchStartX - e.changedTouches[0].clientX;
          if (Math.abs(diff) > 50) {
            diff > 0 ? this.next() : this.prev();
          }
        });
      },
      
      next() {
        if (this.currentSlide < this.totalSlides) {
          this.goToSlide(this.currentSlide + 1);
        }
      },
      
      prev() {
        if (this.currentSlide > 1) {
          this.goToSlide(this.currentSlide - 1);
        }
      },
      
      goToSlide(n) {
        if (this.isAnimating || n === this.currentSlide) return;
        this.isAnimating = true;
        
        const slides = document.querySelectorAll('.slide');
        const dots = document.querySelectorAll('.nav-dot');
        
        slides[this.currentSlide - 1].classList.remove('active');
        dots[this.currentSlide - 1].classList.remove('active');
        
        this.currentSlide = n;
        slides[this.currentSlide - 1].classList.add('active');
        dots[this.currentSlide - 1].classList.add('active');
        
        this.updateSlide();
        this.animateSlideContent(n);
        
        setTimeout(() => {
          this.isAnimating = false;
        }, 800);
      },
      
      updateSlide() {
        const indicator = document.querySelector('.page-indicator');
        const progressBar = document.querySelector('.progress-bar');
        indicator.textContent = `${this.currentSlide} / ${this.totalSlides}`;
        progressBar.style.width = `${(this.currentSlide / this.totalSlides) * 100}%`;
      },
      
      async animateSlideContent(slideNum) {
        const slide = document.querySelector(`.slide[data-slide="${slideNum}"]`);
        if (!slide) return;
        
        const elements = slide.querySelectorAll('.slide-title, .slide-subtitle, .slide-text, .divider, .slide-list li, .card-3d, .stat-item, .quote-block');
        
        // 重置
        elements.forEach(el => {
          el.style.opacity = '0';
          el.style.transform = 'translateY(30px)';
        });
        
        // 逐个动画
        for (let i = 0; i < elements.length; i++) {
          await new Promise(resolve => {
            setTimeout(() => {
              const el = elements[i];
              el.style.transition = 'all 0.6s cubic-bezier(0.175, 0.885, 0.32, 1.275)';
              el.style.opacity = '1';
              el.style.transform = 'translateY(0)';
              resolve();
            }, 150);
          });
        }
      }
    };
    
    // ========== 卡片 3D 效果 ==========
    document.querySelectorAll('.card-3d').forEach(card => {
      card.addEventListener('mousemove', (e) => {
        const rect = card.getBoundingClientRect();
        const x = e.clientX - rect.left;
        const y = e.clientY - rect.top;
        const centerX = rect.width / 2;
        const centerY = rect.height / 2;
        const rotateX = (y - centerY) / 15;
        const rotateY = (centerX - x) / 15;
        
        card.style.transform = `perspective(1000px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) scale(1.05)`;
        card.style.boxShadow = `${(centerX - x) / 5}px ${(centerY - y) / 5}px 30px rgba(0, 245, 255, 0.2)`;
      });
      
      card.addEventListener('mouseleave', () => {
        card.style.transform = 'perspective(1000px) rotateX(0) rotateY(0) scale(1)';
        card.style.boxShadow = 'none';
      });
    });
    
    // ========== 鼠标跟随光效 ==========
    const cursorGlow = document.querySelector('.cursor-glow');
    let mouseX = 0, mouseY = 0;
    let glowX = 0, glowY = 0;
    
    document.addEventListener('mousemove', (e) => {
      mouseX = e.clientX;
      mouseY = e.clientY;
    });
    
    function updateGlow() {
      glowX += (mouseX - glowX) * 0.1;
      glowY += (mouseY - glowY) * 0.1;
      cursorGlow.style.left = glowX + 'px';
      cursorGlow.style.top = glowY + 'px';
      requestAnimationFrame(updateGlow);
    }
    updateGlow();
    
    // ========== 初始化 ==========
    window.addEventListener('DOMContentLoaded', () => {
      new ParticleSystem();
      presentation.init();
    });
  </script>
</body>
</html>
```

## Style Injection Examples

### 科技风格 (tech) - 默认炫酷版
```css
--bg-primary: #050510;
--accent: #00f5ff;
--accent-secondary: #ff00ff;
--accent-glow: rgba(0, 245, 255, 0.5);
```

### 商务风格 (business)
```css
--bg-primary: #0a1628;
--accent: #d4af37;
--accent-secondary: #1e40af;
--accent-glow: rgba(212, 175, 55, 0.5);
```

### 中国风 (chinese)
```css
--bg-primary: #1a0a0a;
--accent: #c41e3a;
--accent-secondary: #d4af37;
--accent-glow: rgba(196, 30, 58, 0.5);
```

## Animation Types

| 类型 | 效果 | 适用场景 |
|------|------|----------|
| `fade` | 淡入淡出 | 优雅过渡 |
| `slide` | 左右滑动 | 标准演示 |
| `zoom` | 缩放入场 | 强调焦点 |
| `3d` | 3D 翻转 | 戏剧效果 |

## Output

生成文件保存至：`.asdm/workspace/awesome-pptx/output/{文件名}.html`

## Checklist

- [x] Canvas 粒子系统实现
- [x] 鼠标跟随光效
- [x] 卡片 3D 悬停效果
- [x] 元素顺序入场动画
- [x] 进度条指示器
- [x] 触摸滑动支持
- [x] 键盘导航支持
- [x] 响应式适配
- [x] 噪点纹理叠加
- [x] 扫描线效果
- [x] 背景图支持

## Copyright

Copyright (c) 2026 LeansoftX.com & iSoftStone. All rights reserved.
