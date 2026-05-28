<template>
  <div class="home-page">
    <!-- Hero Section -->
    <section class="hero-section">
      <!-- Dynamic Background -->
      <div class="hero-bg">
        <div class="hero-orb hero-orb-1"></div>
        <div class="hero-orb hero-orb-2"></div>
        <div class="hero-orb hero-orb-3"></div>
      </div>

      <!-- Hero Content -->
      <div class="hero-content">
        <h1 class="hero-title">探索 AI Agent 的无限可能</h1>
        <p class="hero-desc">发现、学习、分享最前沿的 AI 智能体与工作流，开启智能化之旅</p>
        <div class="hero-actions">
          <button class="cta-btn" @click="$router.push('/agents')">
            开始探索
            <el-icon class="cta-icon"><ArrowRight /></el-icon>
          </button>
          <button class="cta-btn cta-btn--outline" @click="$router.push('/workflows')">
            浏览工作流
          </button>
        </div>
      </div>

      <!-- Scroll Indicator -->
      <div class="scroll-indicator" @click="scrollToContent">
        <el-icon :size="20"><ArrowDown /></el-icon>
      </div>
    </section>

    <!-- Hot Agents Section -->
    <section ref="agentsSectionRef" class="section agents-section">
      <div class="section-inner">
        <div class="section-header scroll-reveal">
          <div class="section-title-group">
            <div class="section-icon">
              <el-icon :size="24"><Monitor /></el-icon>
            </div>
            <div>
              <h2 class="section-title">热门智能体</h2>
              <p class="section-subtitle">最受欢迎的 AI 智能体，提升你的工作效率</p>
            </div>
          </div>
          <el-button text type="primary" @click="$router.push('/agents')">
            查看全部
            <el-icon class="el-icon--right"><ArrowRight /></el-icon>
          </el-button>
        </div>

        <div class="agents-grid">
          <AgentCard
            v-for="(agent, index) in agentStore.hotAgents"
            :key="agent.id"
            :agent="agent"
            :style="{ '--stagger-index': index }"
            class="scroll-reveal"
            @click="$router.push(`/agent/${agent.id}`)"
          />
        </div>
      </div>
    </section>

    <!-- Hot Workflows Section -->
    <section ref="workflowsSectionRef" class="section workflows-section">
      <div class="section-inner">
        <div class="section-header scroll-reveal">
          <div class="section-title-group">
            <div class="section-icon workflow-icon">
              <el-icon :size="24"><Connection /></el-icon>
            </div>
            <div>
              <h2 class="section-title">热点工作流</h2>
              <p class="section-subtitle">精选热门工作流教程，从入门到精通</p>
            </div>
          </div>
          <el-button text type="primary" @click="$router.push('/workflows')">
            查看全部
            <el-icon class="el-icon--right"><ArrowRight /></el-icon>
          </el-button>
        </div>

        <div class="workflows-grid">
          <WorkflowCard
            v-for="(workflow, index) in hotWorkflows"
            :key="workflow.id"
            :workflow="workflow"
            :style="{ '--stagger-index': index }"
            class="scroll-reveal"
            @click="$router.push(`/workflow/${workflow.id}`)"
          />
        </div>
      </div>
    </section>

    <!-- Stats Section -->
    <section ref="statsSectionRef" class="section stats-section">
      <div class="section-inner">
        <div class="stats-grid">
          <div
            v-for="(stat, index) in platformStats"
            :key="index"
            class="stat-card scroll-reveal"
            :style="{ '--stagger-index': index }"
          >
            <div class="stat-icon" :style="{ background: stat.gradient }">
              <el-icon :size="24"><component :is="stat.icon" /></el-icon>
            </div>
            <div class="stat-number">{{ stat.displayValue }}</div>
            <div class="stat-label">{{ stat.label }}</div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, reactive } from 'vue'
import { useWorkflowStore } from '@/stores/workflow'
import { useAgentStore } from '@/stores/agent'
import {
  Monitor, Connection, ArrowRight, ArrowDown, Star, User
} from '@element-plus/icons-vue'
import WorkflowCard from '@/components/WorkflowCard.vue'
import AgentCard from '@/components/AgentCard.vue'

const workflowStore = useWorkflowStore()
const agentStore = useAgentStore()

const agentsSectionRef = ref(null)
const workflowsSectionRef = ref(null)
const statsSectionRef = ref(null)

onMounted(() => {
  workflowStore.setCategory('全部')
  workflowStore.setSearchKeyword('')
  agentStore.setCategory('全部')
  agentStore.setSearchKeyword('')
  initCountUp()
})

const hotWorkflows = computed(() => {
  return [...workflowStore.workflows]
    .sort((a, b) => b.likes - a.likes)
    .slice(0, 6)
})

// ===== CountUp Logic =====
const platformStats = reactive([
  { icon: 'Monitor', targetValue: 1200, suffix: '+', displayValue: '0', label: '智能体', gradient: 'linear-gradient(135deg, #6366f1, #8b5cf6)' },
  { icon: 'Connection', targetValue: 3800, suffix: '+', displayValue: '0', label: '工作流', gradient: 'linear-gradient(135deg, #ec4899, #f97316)' },
  { icon: 'User', targetValue: 50000, suffix: '+', displayValue: '0', label: '活跃用户', gradient: 'linear-gradient(135deg, #06b6d4, #3b82f6)' },
  { icon: 'Star', targetValue: 98, suffix: '%', displayValue: '0', label: '好评率', gradient: 'linear-gradient(135deg, #10b981, #34d399)' }
])

function formatCountValue(value) {
  if (value >= 10000) {
    return (value / 10000).toFixed(0) + '万'
  }
  return value.toLocaleString()
}

function animateCountUp(stat) {
  const duration = 2000
  const startTime = performance.now()
  const target = stat.targetValue

  function update(currentTime) {
    const elapsed = currentTime - startTime
    const progress = Math.min(elapsed / duration, 1)
    // ease-out cubic
    const eased = 1 - Math.pow(1 - progress, 3)
    const current = Math.round(target * eased)
    stat.displayValue = formatCountValue(current) + stat.suffix

    if (progress < 1) {
      requestAnimationFrame(update)
    }
  }

  requestAnimationFrame(update)
}

function initCountUp() {
  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting) {
          platformStats.forEach((stat) => animateCountUp(stat))
          observer.unobserve(entry.target)
        }
      })
    },
    { threshold: 0.3 }
  )

  if (statsSectionRef.value) {
    observer.observe(statsSectionRef.value)
  }
}

// ===== Scroll to Content =====
function scrollToContent() {
  agentsSectionRef.value?.scrollIntoView({ behavior: 'smooth' })
}
</script>

<style lang="scss" scoped>
.home-page {
  background-color: var(--bg-secondary);
}

/* ===== Hero Section ===== */
.hero-section {
  position: relative;
  height: 80vh;
  min-height: 500px;
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
  background: linear-gradient(135deg, #0f0c29 0%, #1a1a3e 40%, #24243e 100%);

  html:not(.dark) & {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 50%, #f093fb 100%);
  }
}

/* Dynamic Background Orbs */
.hero-bg {
  position: absolute;
  inset: 0;
  pointer-events: none;
  overflow: hidden;
}

.hero-orb {
  position: absolute;
  border-radius: 50%;
  filter: blur(80px);
  opacity: 0.5;

  html:not(.dark) & {
    opacity: 0.4;
  }
}

.hero-orb-1 {
  width: 500px;
  height: 500px;
  background: radial-gradient(circle, #6366f1, #8b5cf6);
  top: -10%;
  left: -5%;
  animation: orb-float-1 20s ease-in-out infinite;
}

.hero-orb-2 {
  width: 350px;
  height: 350px;
  background: radial-gradient(circle, #ec4899, #f97316);
  bottom: -10%;
  right: 10%;
  animation: orb-float-2 16s ease-in-out infinite;
}

.hero-orb-3 {
  width: 250px;
  height: 250px;
  background: radial-gradient(circle, #06b6d4, #3b82f6);
  top: 40%;
  right: -5%;
  animation: orb-float-3 22s ease-in-out infinite;
}

@keyframes orb-float-1 {
  0%, 100% { transform: translate(0, 0) scale(1); }
  33% { transform: translate(60px, 40px) scale(1.1); }
  66% { transform: translate(-30px, 60px) scale(0.95); }
}

@keyframes orb-float-2 {
  0%, 100% { transform: translate(0, 0) scale(1); }
  33% { transform: translate(-50px, -30px) scale(1.05); }
  66% { transform: translate(40px, -50px) scale(0.9); }
}

@keyframes orb-float-3 {
  0%, 100% { transform: translate(0, 0) scale(1); }
  50% { transform: translate(-40px, 30px) scale(1.15); }
}

/* Hero Content */
.hero-content {
  position: relative;
  z-index: 2;
  text-align: center;
  padding: 0 32px;
  max-width: 700px;
}

.hero-title {
  font-size: 48px;
  font-weight: 800;
  color: #fff;
  line-height: 1.2;
  margin-bottom: 20px;
  letter-spacing: -0.02em;
}

.hero-desc {
  font-size: 18px;
  color: rgba(255, 255, 255, 0.8);
  line-height: 1.7;
  margin-bottom: 40px;
}

/* CTA Buttons */
.hero-actions {
  display: flex;
  gap: 16px;
  justify-content: center;
  flex-wrap: wrap;
}

.cta-btn {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 14px 32px;
  border-radius: 50px;
  font-size: 16px;
  font-weight: 600;
  cursor: pointer;
  transition: all var(--duration-normal) var(--ease-standard);
  border: none;
  outline: none;

  &--outline {
    background: rgba(255, 255, 255, 0.1);
    color: #fff;
    border: 1px solid rgba(255, 255, 255, 0.3);
    backdrop-filter: blur(8px);

    &:hover {
      background: rgba(255, 255, 255, 0.2);
      border-color: rgba(255, 255, 255, 0.5);
      transform: translateY(-2px);
    }
  }

  background: var(--accent-gradient, linear-gradient(135deg, #6366f1, #8b5cf6));
  color: #fff;
  box-shadow: 0 4px 20px rgba(99, 102, 241, 0.4);

  &:hover {
    transform: translateY(-2px);
    box-shadow: 0 8px 30px rgba(99, 102, 241, 0.6);
  }

  .cta-icon {
    transition: transform var(--duration-fast) var(--ease-standard);
  }

  &:hover .cta-icon {
    transform: translateX(4px);
  }
}

/* Scroll Indicator */
.scroll-indicator {
  position: absolute;
  bottom: 32px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 2;
  color: rgba(255, 255, 255, 0.6);
  cursor: pointer;
  animation: scroll-bounce 2s ease-in-out infinite;
  transition: color var(--duration-fast) var(--ease-standard);

  &:hover {
    color: rgba(255, 255, 255, 0.9);
  }
}

@keyframes scroll-bounce {
  0%, 20%, 50%, 80%, 100% { transform: translateX(-50%) translateY(0); }
  40% { transform: translateX(-50%) translateY(-10px); }
  60% { transform: translateX(-50%) translateY(-5px); }
}

/* ===== Section Common ===== */
.section {
  padding: 64px 0;

  .section-inner {
    max-width: 1400px;
    margin: 0 auto;
    padding: 0 32px;
  }
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px;
}

.section-title-group {
  display: flex;
  align-items: center;
  gap: 16px;

  .section-icon {
    width: 48px;
    height: 48px;
    border-radius: var(--radius-md);
    background: var(--accent-gradient);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;

    &.workflow-icon {
      background: linear-gradient(135deg, #ec4899, #f97316);
    }
  }

  .section-title {
    font-size: 24px;
    font-weight: 700;
    color: var(--text-primary);
  }

  .section-subtitle {
    font-size: 14px;
    color: var(--text-tertiary);
    margin-top: 4px;
  }
}

/* ===== Hot Agents ===== */
.agents-section {
  background: var(--bg-primary);
}

.agents-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 24px;
}

/* ===== Hot Workflows ===== */
.workflows-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 24px;
}

/* ===== Stats ===== */
.stats-section {
  background: var(--bg-primary);
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 24px;
}

.stat-card {
  text-align: center;
  padding: 32px 20px;
  background: var(--bg-card);
  border: var(--card-border);
  border-radius: var(--radius-md);
  transition: all var(--duration-normal) var(--ease-standard);

  &:hover {
    transform: translateY(calc(var(--card-hover-lift) / 2));
    box-shadow: var(--shadow-lg);

    .stat-icon {
      transform: scale(1.1);
    }
  }

  .stat-icon {
    width: 52px;
    height: 52px;
    border-radius: var(--radius-md);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
    margin: 0 auto 16px;
    transition: transform var(--duration-normal) var(--ease-spring);
  }

  .stat-number {
    font-size: 28px;
    font-weight: 700;
    color: var(--text-primary);
    margin-bottom: 4px;
    font-variant-numeric: tabular-nums;
  }

  .stat-label {
    font-size: 14px;
    color: var(--text-tertiary);
  }
}

/* ===== Responsive ===== */
@media (max-width: 992px) {
  .hero-title {
    font-size: 36px;
  }

  .hero-desc {
    font-size: 16px;
  }

  .agents-grid {
    grid-template-columns: 1fr;
  }

  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .hero-section {
    height: 60vh;
    min-height: 400px;
  }

  .hero-title {
    font-size: 28px;
  }

  .hero-desc {
    font-size: 15px;
    margin-bottom: 28px;
  }

  .cta-btn {
    padding: 12px 24px;
    font-size: 14px;
  }

  .section {
    padding: 40px 0;

    .section-inner {
      padding: 0 16px;
    }
  }

  .stats-grid {
    grid-template-columns: 1fr 1fr;
    gap: 12px;
  }

  .workflows-grid {
    grid-template-columns: 1fr;
  }
}

/* ===== Reduced Motion ===== */
@media (prefers-reduced-motion: reduce) {
  .hero-orb {
    animation: none;
  }

  .scroll-indicator {
    animation: none;
  }
}
</style>
