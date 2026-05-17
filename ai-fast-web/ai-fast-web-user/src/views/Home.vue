<template>
  <div class="home-page">
    <!-- Carousel Banner -->
    <section class="carousel-section">
      <el-carousel :interval="5000" :autoplay="true" height="420px" indicator-position="outside">
        <el-carousel-item v-for="(slide, index) in bannerSlides" :key="index">
          <div class="banner-slide" :style="{ background: slide.gradient }">
            <div class="banner-content">
              <div class="banner-text">
                <h1>{{ slide.title }}</h1>
                <p>{{ slide.description }}</p>
                <div class="banner-actions">
                  <el-button type="primary" size="large" round @click="$router.push(slide.link)">
                    {{ slide.btnText }}
                    <el-icon class="el-icon--right"><ArrowRight /></el-icon>
                  </el-button>
                  <el-button size="large" round class="btn-ghost" @click="$router.push('/workflows')">
                    浏览全部
                  </el-button>
                </div>
              </div>
              <div class="banner-visual">
                <div class="visual-card" v-for="(card, i) in slide.cards" :key="i" :style="{ animationDelay: i * 0.15 + 's' }">
                  <el-icon :size="28"><component :is="card.icon" /></el-icon>
                  <span>{{ card.label }}</span>
                </div>
              </div>
            </div>
          </div>
        </el-carousel-item>
      </el-carousel>
    </section>

    <!-- Hot Agents Section -->
    <section class="section agents-section">
      <div class="section-inner">
        <div class="section-header">
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
          <div
            v-for="(agent, index) in agentStore.hotAgents"
            :key="agent.id"
            class="agent-card fade-in-up"
            :style="{ animationDelay: index * 0.1 + 's' }"
          >
            <div class="agent-icon-wrap">
              <el-icon :size="32"><component :is="getAgentIcon(agent.category)" /></el-icon>
            </div>
            <div class="agent-info">
              <h3>{{ agent.name }}</h3>
              <p>{{ agent.description }}</p>
            </div>
            <div class="agent-stats">
              <span class="stat">
                <el-icon><User /></el-icon>
                {{ formatNumber(agent.users) }}
              </span>
              <span class="stat">
                <el-icon><Star /></el-icon>
                {{ agent.rating }}
              </span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Hot Workflows Section -->
    <section class="section workflows-section">
      <div class="section-inner">
        <div class="section-header">
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
            v-for="workflow in hotWorkflows"
            :key="workflow.id"
            :workflow="workflow"
            @click="$router.push(`/workflow/${workflow.id}`)"
          />
        </div>
      </div>
    </section>

    <!-- Stats Section -->
    <section class="section stats-section">
      <div class="section-inner">
        <div class="stats-grid">
          <div class="stat-card" v-for="(stat, index) in platformStats" :key="index">
            <div class="stat-icon" :style="{ background: stat.gradient }">
              <el-icon :size="24"><component :is="stat.icon" /></el-icon>
            </div>
            <div class="stat-number">{{ stat.value }}</div>
            <div class="stat-label">{{ stat.label }}</div>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import { useWorkflowStore } from '@/stores/workflow'
import { useAgentStore } from '@/stores/agent'
import {
  Monitor, Connection, ArrowRight, Star, User,
  Cpu, EditPen, DataAnalysis, Service, Picture, Document, TrendCharts, Microphone
} from '@element-plus/icons-vue'
import WorkflowCard from '@/components/WorkflowCard.vue'

const workflowStore = useWorkflowStore()
const agentStore = useAgentStore()

onMounted(() => {
  workflowStore.setCategory('全部')
  workflowStore.setSearchKeyword('')
  agentStore.setCategory('全部')
  agentStore.setSearchKeyword('')
})

const hotWorkflows = computed(() => {
  return [...workflowStore.workflows]
    .sort((a, b) => b.likes - a.likes)
    .slice(0, 6)
})

const bannerSlides = [
  {
    title: '探索 AI Agent 的无限可能',
    description: '发现、学习、分享最前沿的 AI 智能体，开启智能化之旅',
    btnText: '开始探索',
    link: '/agents',
    gradient: 'var(--carousel-gradient-1)',
    cards: [
      { icon: 'Cpu', label: '智能对话' },
      { icon: 'EditPen', label: '内容创作' },
      { icon: 'DataAnalysis', label: '数据分析' },
      { icon: 'Picture', label: '图像生成' }
    ]
  },
  {
    title: '工作流让复杂任务变简单',
    description: '可视化编排 AI 工作流，自动化处理复杂业务场景',
    btnText: '查看工作流',
    link: '/workflows',
    gradient: 'var(--carousel-gradient-2)',
    cards: [
      { icon: 'Connection', label: '流程编排' },
      { icon: 'Monitor', label: '自动化执行' },
      { icon: 'TrendCharts', label: '数据洞察' },
      { icon: 'Service', label: '智能服务' }
    ]
  },
  {
    title: '丰富的资源助力成长',
    description: '海量教程、模板和工具资源，加速你的 AI 应用开发',
    btnText: '进入资源库',
    link: '/resources',
    gradient: 'var(--carousel-gradient-3)',
    cards: [
      { icon: 'Document', label: '技术文档' },
      { icon: 'Microphone', label: '视频教程' },
      { icon: 'Cpu', label: '开发工具' },
      { icon: 'Star', label: '精选模板' }
    ]
  }
]

const platformStats = [
  { icon: 'Monitor', value: '1,200+', label: '智能体', gradient: 'linear-gradient(135deg, #6366f1, #8b5cf6)' },
  { icon: 'Connection', value: '3,800+', label: '工作流', gradient: 'linear-gradient(135deg, #ec4899, #f97316)' },
  { icon: 'User', value: '50,000+', label: '活跃用户', gradient: 'linear-gradient(135deg, #06b6d4, #3b82f6)' },
  { icon: 'Star', value: '98%', label: '好评率', gradient: 'linear-gradient(135deg, #10b981, #34d399)' }
]

function getAgentIcon(category) {
  const iconMap = {
    '写作': 'EditPen',
    '数据分析': 'DataAnalysis',
    '开发': 'Monitor',
    '客服': 'Service',
    '设计': 'Picture',
    '文档': 'Document',
    '营销': 'TrendCharts',
    '语音': 'Microphone'
  }
  return iconMap[category] || 'Cpu'
}

function formatNumber(num) {
  if (num >= 10000) {
    return (num / 10000).toFixed(1) + '万'
  }
  if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'k'
  }
  return num
}
</script>

<style lang="scss" scoped>
.home-page {
  background-color: var(--bg-secondary);
}

/* ===== Carousel ===== */
.carousel-section {
  max-width: 1400px;
  margin: 0 auto;
  padding: 24px 32px 0;

  :deep(.el-carousel__container) {
    border-radius: var(--radius-lg);
    overflow: hidden;
  }

  :deep(.el-carousel__indicators--outside) {
    margin-top: 12px;

    .el-carousel__indicator {
      .el-carousel__button {
        width: 24px;
        height: 4px;
        border-radius: 2px;
        background: var(--text-tertiary);
        opacity: 0.4;
      }

      &.is-active .el-carousel__button {
        width: 36px;
        background: var(--accent-primary);
        opacity: 1;
      }
    }
  }
}

.banner-slide {
  height: 100%;
  padding: 60px 64px;
  display: flex;
  align-items: center;
  position: relative;
  overflow: hidden;

  &::before {
    content: '';
    position: absolute;
    top: -50%;
    right: -20%;
    width: 600px;
    height: 600px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.06);
  }

  &::after {
    content: '';
    position: absolute;
    bottom: -30%;
    left: 30%;
    width: 300px;
    height: 300px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.04);
  }
}

.banner-content {
  display: flex;
  align-items: center;
  justify-content: space-between;
  width: 100%;
  position: relative;
  z-index: 1;
}

.banner-text {
  max-width: 520px;

  h1 {
    font-size: 40px;
    font-weight: 700;
    color: #fff;
    margin-bottom: 16px;
    line-height: 1.3;
  }

  p {
    font-size: 17px;
    color: rgba(255, 255, 255, 0.85);
    margin-bottom: 32px;
    line-height: 1.6;
  }

  .banner-actions {
    display: flex;
    gap: 16px;

    .el-button--primary {
      background: rgba(255, 255, 255, 0.2);
      border: 1px solid rgba(255, 255, 255, 0.3);
      backdrop-filter: blur(8px);

      &:hover {
        background: rgba(255, 255, 255, 0.3);
        border-color: rgba(255, 255, 255, 0.5);
      }
    }

    .btn-ghost {
      color: #fff;
      background: transparent;
      border: 1px solid rgba(255, 255, 255, 0.3);

      &:hover {
        background: rgba(255, 255, 255, 0.1);
        border-color: rgba(255, 255, 255, 0.5);
      }
    }
  }
}

.banner-visual {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;

  .visual-card {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 16px 20px;
    background: rgba(255, 255, 255, 0.12);
    backdrop-filter: blur(8px);
    border: 1px solid rgba(255, 255, 255, 0.15);
    border-radius: var(--radius-md);
    color: #fff;
    font-size: 14px;
    font-weight: 500;
    animation: fadeInUp 0.6s ease forwards;
    opacity: 0;
    transition: transform 0.3s;

    &:hover {
      transform: translateY(-2px);
      background: rgba(255, 255, 255, 0.18);
    }

    .el-icon {
      color: rgba(255, 255, 255, 0.9);
    }
  }
}

/* ===== Section Common ===== */
.section {
  padding: 48px 0;

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
  grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
  gap: 20px;
}

.agent-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px 24px;
  background: var(--bg-card);
  border: var(--card-border);
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: all 0.3s ease;

  &:hover {
    transform: translateY(-3px);
    box-shadow: var(--shadow-md);
    border-color: var(--accent-primary);

    .agent-icon-wrap {
      transform: scale(1.08);
    }
  }

  .agent-icon-wrap {
    width: 56px;
    height: 56px;
    border-radius: var(--radius-md);
    background: var(--accent-primary-bg);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--accent-primary);
    flex-shrink: 0;
    transition: transform 0.3s;
  }

  .agent-info {
    flex: 1;
    min-width: 0;

    h3 {
      font-size: 16px;
      font-weight: 600;
      color: var(--text-primary);
      margin-bottom: 4px;
    }

    p {
      font-size: 13px;
      color: var(--text-tertiary);
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
    }
  }

  .agent-stats {
    display: flex;
    flex-direction: column;
    gap: 4px;
    flex-shrink: 0;
    align-items: flex-end;

    .stat {
      display: flex;
      align-items: center;
      gap: 4px;
      font-size: 12px;
      color: var(--text-tertiary);

      .el-icon {
        font-size: 14px;
      }
    }
  }
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
  transition: all 0.3s;

  &:hover {
    transform: translateY(-4px);
    box-shadow: var(--shadow-md);

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
    transition: transform 0.3s;
  }

  .stat-number {
    font-size: 28px;
    font-weight: 700;
    color: var(--text-primary);
    margin-bottom: 4px;
  }

  .stat-label {
    font-size: 14px;
    color: var(--text-tertiary);
  }
}

/* ===== Responsive ===== */
@media (max-width: 992px) {
  .banner-slide {
    padding: 40px 32px;
  }

  .banner-text h1 {
    font-size: 28px;
  }

  .banner-visual {
    display: none;
  }

  .agents-grid {
    grid-template-columns: 1fr;
  }

  .stats-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}

@media (max-width: 768px) {
  .carousel-section {
    padding: 16px 16px 0;
  }

  .section .section-inner {
    padding: 0 16px;
  }

  .banner-slide {
    padding: 32px 20px;
  }

  .banner-text h1 {
    font-size: 24px;
  }

  .stats-grid {
    grid-template-columns: 1fr 1fr;
    gap: 12px;
  }

  .workflows-grid {
    grid-template-columns: 1fr;
  }
}
</style>
