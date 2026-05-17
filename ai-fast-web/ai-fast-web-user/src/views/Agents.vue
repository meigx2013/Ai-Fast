<template>
  <div class="agents-page">
    <div class="page-container">
      <div class="page-hero">
        <h1>智能体广场</h1>
        <p>发现并使用强大的 AI 智能体，让工作更高效</p>
        <div class="search-box">
          <el-input
            v-model="searchKeyword"
            placeholder="搜索智能体..."
            :prefix-icon="Search"
            size="large"
            clearable
            @input="handleSearch"
          />
        </div>
      </div>

      <div class="category-bar">
        <div
          v-for="cat in agentStore.categories"
          :key="cat.id"
          class="category-chip"
          :class="{ active: agentStore.selectedCategory === cat.name }"
          @click="handleCategoryClick(cat.name)"
        >
          <el-icon><component :is="cat.icon" /></el-icon>
          <span>{{ cat.name }}</span>
        </div>
      </div>

      <div class="agents-grid" v-if="agentStore.filteredAgents.length">
        <div
          v-for="(agent, index) in agentStore.filteredAgents"
          :key="agent.id"
          class="agent-card fade-in-up"
          :style="{ animationDelay: index * 0.05 + 's' }"
        >
          <div class="card-header">
            <div class="agent-icon">
              <el-icon :size="28"><component :is="getAgentIcon(agent.category)" /></el-icon>
            </div>
            <el-tag size="small" type="primary" effect="plain">{{ agent.category }}</el-tag>
          </div>
          <h3 class="agent-name">{{ agent.name }}</h3>
          <p class="agent-desc">{{ agent.description }}</p>
          <div class="agent-tags">
            <el-tag v-for="tag in agent.tags.slice(0, 3)" :key="tag" size="small" effect="plain">
              {{ tag }}
            </el-tag>
          </div>
          <div class="card-footer">
            <div class="author">
              <el-avatar :size="24" :src="agent.author.avatar" />
              <span>{{ agent.author.name }}</span>
            </div>
            <div class="stats">
              <span class="stat-item">
                <el-icon><User /></el-icon>
                {{ formatNumber(agent.users) }}
              </span>
              <span class="stat-item">
                <el-icon><Star /></el-icon>
                {{ agent.rating }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <el-empty v-else description="暂无相关智能体" />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAgentStore } from '@/stores/agent'
import { Search, Star, User, Cpu, EditPen, DataAnalysis, Monitor, Service, Picture, Document, TrendCharts, Microphone } from '@element-plus/icons-vue'

const agentStore = useAgentStore()
const searchKeyword = ref('')

onMounted(() => {
  agentStore.setCategory('全部')
  agentStore.setSearchKeyword('')
})

function handleSearch() {
  agentStore.setSearchKeyword(searchKeyword.value)
}

function handleCategoryClick(name) {
  agentStore.setCategory(name)
}

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
  if (num >= 10000) return (num / 10000).toFixed(1) + '万'
  if (num >= 1000) return (num / 1000).toFixed(1) + 'k'
  return num
}
</script>

<style lang="scss" scoped>
.agents-page {
  background: var(--bg-secondary);
  min-height: calc(100vh - 68px);
}

.page-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 32px;
}

.page-hero {
  text-align: center;
  padding: 48px 0 40px;

  h1 {
    font-size: 36px;
    font-weight: 700;
    color: var(--text-primary);
    margin-bottom: 12px;
  }

  p {
    font-size: 16px;
    color: var(--text-tertiary);
    margin-bottom: 28px;
  }

  .search-box {
    max-width: 480px;
    margin: 0 auto;

    :deep(.el-input__wrapper) {
      border-radius: var(--radius-xl);
      box-shadow: var(--shadow-md);
    }
  }
}

.category-bar {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
  margin-bottom: 32px;
  justify-content: center;
}

.category-chip {
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 8px 18px;
  border-radius: var(--radius-xl);
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  color: var(--text-secondary);
  font-size: 14px;
  cursor: pointer;
  transition: all 0.3s;

  &:hover {
    border-color: var(--accent-primary);
    color: var(--accent-primary);
  }

  &.active {
    background: var(--accent-primary-bg);
    border-color: var(--accent-primary);
    color: var(--accent-primary);
    font-weight: 500;
  }
}

.agents-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 24px;
}

.agent-card {
  background: var(--bg-card);
  border: var(--card-border);
  border-radius: var(--radius-md);
  padding: 24px;
  cursor: pointer;
  transition: all 0.3s ease;

  &:hover {
    transform: translateY(-4px);
    box-shadow: var(--shadow-lg);
    border-color: var(--accent-primary);
  }

  .card-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 16px;
  }

  .agent-icon {
    width: 52px;
    height: 52px;
    border-radius: var(--radius-md);
    background: var(--accent-primary-bg);
    display: flex;
    align-items: center;
    justify-content: center;
    color: var(--accent-primary);
  }

  .agent-name {
    font-size: 18px;
    font-weight: 600;
    color: var(--text-primary);
    margin-bottom: 8px;
  }

  .agent-desc {
    font-size: 13px;
    color: var(--text-tertiary);
    line-height: 1.6;
    height: 42px;
    overflow: hidden;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    margin-bottom: 12px;
  }

  .agent-tags {
    display: flex;
    gap: 6px;
    flex-wrap: wrap;
    margin-bottom: 16px;
  }

  .card-footer {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding-top: 16px;
    border-top: 1px solid var(--border-color);

    .author {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 13px;
      color: var(--text-secondary);
    }

    .stats {
      display: flex;
      gap: 12px;

      .stat-item {
        display: flex;
        align-items: center;
        gap: 4px;
        font-size: 12px;
        color: var(--text-tertiary);
      }
    }
  }
}

@media (max-width: 768px) {
  .page-container {
    padding: 16px;
  }

  .page-hero {
    padding: 32px 0 24px;

    h1 { font-size: 24px; }
  }

  .agents-grid {
    grid-template-columns: 1fr;
  }
}
</style>
