<template>
  <el-card class="workflow-card" shadow="hover" @click="$emit('click')">
    <div class="card-cover">
      <img :src="workflow.cover" :alt="workflow.title" />
      <div class="card-difficulty" :class="difficultyClass">
        {{ workflow.difficulty }}
      </div>
    </div>
    
    <div class="card-content">
      <h3 class="card-title">{{ workflow.title }}</h3>
      <p class="card-desc">{{ workflow.description }}</p>
      
      <div class="card-tags">
        <el-tag
          v-for="tag in workflow.tags.slice(0, 3)"
          :key="tag"
          size="small"
          type="info"
        >
          {{ tag }}
        </el-tag>
      </div>
      
      <div class="card-footer">
        <div class="author-info">
          <el-avatar :size="24" :src="workflow.author.avatar" />
          <span class="author-name">{{ workflow.author.name }}</span>
        </div>
        
        <div class="card-stats">
          <span class="stat-item">
            <el-icon><View /></el-icon>
            {{ formatNumber(workflow.views) }}
          </span>
          <span class="stat-item">
            <el-icon><Star /></el-icon>
            {{ formatNumber(workflow.likes) }}
          </span>
        </div>
      </div>
    </div>
  </el-card>
</template>

<script setup>
import { computed } from 'vue'
import { View, Star } from '@element-plus/icons-vue'

const props = defineProps({
  workflow: {
    type: Object,
    required: true
  }
})

defineEmits(['click'])

const difficultyClass = computed(() => {
  const map = {
    '初级': 'easy',
    '中级': 'medium',
    '高级': 'hard'
  }
  return map[props.workflow.difficulty] || 'medium'
})

function formatNumber(num) {
  if (num >= 1000) {
    return (num / 1000).toFixed(1) + 'k'
  }
  return num
}
</script>

<style lang="scss" scoped>
.workflow-card {
  cursor: pointer;
  transition: all 0.3s;
  border-radius: 12px;
  overflow: hidden;
  
  &:hover {
    transform: translateY(-4px);
    
    .card-cover img {
      transform: scale(1.05);
    }
  }
  
  :deep(.el-card__body) {
    padding: 0;
  }
}

.card-cover {
  position: relative;
  height: 180px;
  overflow: hidden;
  
  img {
    width: 100%;
    height: 100%;
    object-fit: cover;
    transition: transform 0.3s;
  }
  
  .card-difficulty {
    position: absolute;
    top: 12px;
    right: 12px;
    padding: 4px 12px;
    border-radius: 12px;
    font-size: 12px;
    font-weight: 500;
    
    &.easy {
      background: rgba(103, 194, 58, 0.9);
      color: #fff;
    }
    
    &.medium {
      background: rgba(230, 162, 60, 0.9);
      color: #fff;
    }
    
    &.hard {
      background: rgba(245, 108, 108, 0.9);
      color: #fff;
    }
  }
}

.card-content {
  padding: 16px;
  
  .card-title {
    font-size: 16px;
    font-weight: 600;
    color: #303133;
    margin-bottom: 8px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }
  
  .card-desc {
    font-size: 13px;
    color: #909399;
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
  margin-bottom: 12px;
}

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 12px;
  border-top: 1px solid #ebeef5;
  
  .author-info {
    display: flex;
    align-items: center;
    gap: 8px;
    
    .author-name {
      font-size: 13px;
      color: #606266;
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
      color: #909399;
    }
  }
}
</style>
