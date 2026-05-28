<template>
  <div class="agent-card" @click="$emit('click')">
    <div class="card-cover">
      <div class="icon-wrapper">
        <el-icon :size="36"><component :is="iconComponent" /></el-icon>
      </div>
      <el-tag class="category-tag" size="small" effect="dark" round>{{ agent.category }}</el-tag>
    </div>

    <div class="card-content">
      <h3 class="card-title">{{ agent.name }}</h3>
      <p class="card-desc">{{ agent.description }}</p>

      <div class="card-tags">
        <el-tag
          v-for="tag in agent.tags.slice(0, 3)"
          :key="tag"
          size="small"
          effect="plain"
        >
          {{ tag }}
        </el-tag>
      </div>

      <div class="card-footer">
        <div class="author-info">
          <el-avatar :size="24" :src="agent.author.avatar" />
          <span class="author-name">{{ agent.author.name }}</span>
        </div>

        <div class="card-stats">
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
</template>

<script setup>
import { computed } from 'vue'
import { Star, User, Cpu, EditPen, DataAnalysis, Monitor, Service, Picture, Document, TrendCharts, Microphone } from '@element-plus/icons-vue'

const props = defineProps({
  agent: {
    type: Object,
    required: true
  }
})

defineEmits(['click'])

const iconComponent = computed(() => {
  const iconMap = {
    '写作': EditPen,
    '数据分析': DataAnalysis,
    '开发': Monitor,
    '客服': Service,
    '设计': Picture,
    '文档': Document,
    '营销': TrendCharts,
    '语音': Microphone
  }
  return iconMap[props.agent.category] || Cpu
})

function formatNumber(num) {
  if (num >= 10000) return (num / 10000).toFixed(1) + '万'
  if (num >= 1000) return (num / 1000).toFixed(1) + 'k'
  return num
}
</script>

<style lang="scss" scoped>
.agent-card {
  cursor: pointer;
  background: var(--bg-card);
  border: var(--card-border);
  border-radius: var(--radius-lg);
  overflow: hidden;
  transition: transform var(--duration-slow) var(--ease-decelerate),
              box-shadow var(--duration-slow) var(--ease-decelerate),
              border-color var(--duration-fast) var(--ease-standard);

  &:hover {
    transform: translateY(calc(var(--card-hover-lift) * -1));
    box-shadow: var(--shadow-xl);
    border-color: var(--accent-primary-light);

    .card-cover .icon-wrapper {
      transform: scale(1.1);
    }
  }
}

.card-cover {
  position: relative;
  height: 140px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--accent-gradient);
  overflow: hidden;

  &::before {
    content: '';
    position: absolute;
    top: -30%;
    right: -20%;
    width: 200px;
    height: 200px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.08);
  }

  &::after {
    content: '';
    position: absolute;
    bottom: -20%;
    left: -10%;
    width: 120px;
    height: 120px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.05);
  }

  .icon-wrapper {
    position: relative;
    z-index: 1;
    width: 72px;
    height: 72px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.2);
    backdrop-filter: blur(8px);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
    transition: transform var(--duration-slow) var(--ease-spring);
  }

  .category-tag {
    position: absolute;
    top: 12px;
    right: 12px;
    background: rgba(255, 255, 255, 0.2);
    backdrop-filter: blur(4px);
    border: 1px solid rgba(255, 255, 255, 0.25);
    color: #fff;
    z-index: 1;
  }
}

.card-content {
  padding: 16px 20px 20px;
  background: var(--bg-card);

  .card-title {
    font-size: 16px;
    font-weight: 600;
    color: var(--text-primary);
    margin-bottom: 8px;
    overflow: hidden;
    text-overflow: ellipsis;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    line-height: 1.4;
  }

  .card-desc {
    font-size: 13px;
    color: var(--text-tertiary);
    line-height: 1.5;
    height: 40px;
    overflow: hidden;
    display: -webkit-box;
    -webkit-line-clamp: 2;
    -webkit-box-orient: vertical;
    margin-bottom: 12px;
  }
}

.card-tags {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  margin-bottom: 14px;
}

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 14px;
  border-top: 1px solid var(--border-light);

  .author-info {
    display: flex;
    align-items: center;
    gap: 8px;

    .author-name {
      font-size: 13px;
      color: var(--text-secondary);
    }
  }

  .card-stats {
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
</style>
