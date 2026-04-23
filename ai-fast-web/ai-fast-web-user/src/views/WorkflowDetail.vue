<template>
  <div class="workflow-detail" v-if="workflow">
    <div class="detail-header">
      <el-button text @click="$router.back()">
        <el-icon><ArrowLeft /></el-icon>
        返回
      </el-button>
    </div>
    
    <div class="detail-content">
      <div class="detail-main">
        <div class="workflow-cover">
          <img :src="workflow.cover" :alt="workflow.title" />
        </div>
        
        <h1 class="workflow-title">{{ workflow.title }}</h1>
        
        <div class="workflow-meta">
          <div class="author-info">
            <el-avatar :size="40" :src="workflow.author.avatar" />
            <div class="author-detail">
              <span class="author-name">{{ workflow.author.name }}</span>
              <span class="publish-date">发布于 {{ workflow.createdAt }}</span>
            </div>
          </div>
          
          <div class="workflow-stats">
            <span class="stat-item">
              <el-icon><View /></el-icon>
              {{ workflow.views }} 浏览
            </span>
            <span class="stat-item">
              <el-icon><Star /></el-icon>
              {{ workflow.likes }} 点赞
            </span>
            <span class="stat-item">
              <el-icon><CollectionTag /></el-icon>
              {{ workflow.favorites }} 收藏
            </span>
          </div>
        </div>
        
        <div class="workflow-tags">
          <el-tag
            v-for="tag in workflow.tags"
            :key="tag"
            size="large"
          >
            {{ tag }}
          </el-tag>
        </div>
        
        <el-divider />
        
        <div class="workflow-description">
          <h3>简介</h3>
          <p>{{ workflow.description }}</p>
        </div>
        
        <div class="workflow-steps">
          <h3>学习步骤</h3>
          <el-timeline>
            <el-timeline-item
              v-for="(step, index) in workflow.steps"
              :key="index"
              :timestamp="`步骤 ${index + 1}`"
              placement="top"
            >
              <el-card>
                <h4>{{ step.title }}</h4>
                <p>{{ step.content }}</p>
              </el-card>
            </el-timeline-item>
          </el-timeline>
        </div>
      </div>
      
      <div class="detail-sidebar">
        <el-card class="info-card">
          <h4>课程信息</h4>
          <div class="info-item">
            <span class="label">难度等级</span>
            <el-tag :type="difficultyType">{{ workflow.difficulty }}</el-tag>
          </div>
          <div class="info-item">
            <span class="label">预计时长</span>
            <span class="value">{{ workflow.duration }}</span>
          </div>
          <div class="info-item">
            <span class="label">分类</span>
            <span class="value">{{ workflow.category }}</span>
          </div>
          <div class="info-item">
            <span class="label">更新时间</span>
            <span class="value">{{ workflow.updatedAt }}</span>
          </div>
        </el-card>
        
        <el-card class="action-card">
          <el-button
            type="primary"
            size="large"
            :icon="isLiked ? 'StarFilled' : 'Star'"
            @click="toggleLike"
            :class="{ 'is-active': isLiked }"
          >
            {{ isLiked ? '已点赞' : '点赞' }}
          </el-button>
          <el-button
            size="large"
            :icon="isFavorited ? 'CollectionTag' : 'CollectionTag'"
            @click="toggleFavorite"
            :class="{ 'is-active': isFavorited }"
          >
            {{ isFavorited ? '已收藏' : '收藏' }}
          </el-button>
        </el-card>
      </div>
    </div>
  </div>
  
  <el-empty v-else description="工作流不存在" />
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useWorkflowStore } from '@/stores/workflow'
import { useUserStore } from '@/stores/user'
import { ArrowLeft, View, Star, CollectionTag } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'

const route = useRoute()
const workflowStore = useWorkflowStore()
const userStore = useUserStore()

const workflow = ref(null)
const isLiked = ref(false)
const isFavorited = ref(false)

const difficultyType = computed(() => {
  const map = {
    '初级': 'success',
    '中级': 'warning',
    '高级': 'danger'
  }
  return map[workflow.value?.difficulty] || 'info'
})

onMounted(() => {
  const id = route.params.id
  workflow.value = workflowStore.getWorkflowById(id)
  
  if (workflow.value && userStore.userInfo) {
    isLiked.value = userStore.userInfo.likes?.includes(workflow.value.id)
    isFavorited.value = userStore.userInfo.favorites?.includes(workflow.value.id)
  }
})

function toggleLike() {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    return
  }
  
  if (isLiked.value) {
    workflowStore.unlikeWorkflow(workflow.value.id)
    isLiked.value = false
    ElMessage.success('取消点赞')
  } else {
    workflowStore.likeWorkflow(workflow.value.id)
    isLiked.value = true
    ElMessage.success('点赞成功')
  }
}

function toggleFavorite() {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    return
  }
  
  if (isFavorited.value) {
    workflowStore.unfavoriteWorkflow(workflow.value.id)
    isFavorited.value = false
    ElMessage.success('取消收藏')
  } else {
    workflowStore.favoriteWorkflow(workflow.value.id)
    isFavorited.value = true
    ElMessage.success('收藏成功')
  }
}
</script>

<style lang="scss" scoped>
.workflow-detail {
  .detail-header {
    margin-bottom: 24px;
  }
  
  .detail-content {
    display: flex;
    gap: 24px;
    
    @media (max-width: 992px) {
      flex-direction: column;
    }
  }
  
  .detail-main {
    flex: 1;
    
    .workflow-cover {
      border-radius: 12px;
      overflow: hidden;
      margin-bottom: 24px;
      
      img {
        width: 100%;
        height: 400px;
        object-fit: cover;
      }
    }
    
    .workflow-title {
      font-size: 28px;
      font-weight: 600;
      color: #303133;
      margin-bottom: 16px;
    }
    
    .workflow-meta {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 16px;
      
      @media (max-width: 768px) {
        flex-direction: column;
        align-items: flex-start;
        gap: 12px;
      }
      
      .author-info {
        display: flex;
        align-items: center;
        gap: 12px;
        
        .author-detail {
          display: flex;
          flex-direction: column;
          
          .author-name {
            font-weight: 500;
            color: #303133;
          }
          
          .publish-date {
            font-size: 13px;
            color: #909399;
          }
        }
      }
      
      .workflow-stats {
        display: flex;
        gap: 20px;
        
        .stat-item {
          display: flex;
          align-items: center;
          gap: 6px;
          color: #909399;
          font-size: 14px;
        }
      }
    }
    
    .workflow-tags {
      display: flex;
      gap: 8px;
      flex-wrap: wrap;
    }
    
    .workflow-description {
      margin-bottom: 32px;
      
      h3 {
        font-size: 18px;
        font-weight: 600;
        margin-bottom: 12px;
        color: #303133;
      }
      
      p {
        color: #606266;
        line-height: 1.8;
      }
    }
    
    .workflow-steps {
      h3 {
        font-size: 18px;
        font-weight: 600;
        margin-bottom: 20px;
        color: #303133;
      }
      
      :deep(.el-timeline-item__timestamp) {
        font-weight: 500;
      }
      
      :deep(.el-card__body) {
        h4 {
          font-size: 15px;
          font-weight: 500;
          margin-bottom: 8px;
          color: #303133;
        }
        
        p {
          color: #606266;
          font-size: 14px;
        }
      }
    }
  }
  
  .detail-sidebar {
    width: 320px;
    flex-shrink: 0;
    
    @media (max-width: 992px) {
      width: 100%;
    }
    
    .info-card {
      margin-bottom: 16px;
      
      h4 {
        font-size: 16px;
        font-weight: 600;
        margin-bottom: 16px;
        color: #303133;
      }
      
      .info-item {
        display: flex;
        justify-content: space-between;
        align-items: center;
        padding: 12px 0;
        border-bottom: 1px solid #ebeef5;
        
        &:last-child {
          border-bottom: none;
        }
        
        .label {
          color: #909399;
          font-size: 14px;
        }
        
        .value {
          color: #303133;
          font-size: 14px;
        }
      }
    }
    
    .action-card {
      :deep(.el-card__body) {
        display: flex;
        flex-direction: column;
        gap: 12px;
      }
      
      .el-button {
        width: 100%;
        
        &.is-active {
          background: #ecf5ff;
          border-color: #409eff;
          color: #409eff;
        }
      }
    }
  }
}
</style>
