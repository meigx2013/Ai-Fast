<template>
  <div class="home-page">
    <section class="hero-section">
      <div class="hero-content">
        <h1>探索 AI Agent 与工作流的无限可能</h1>
        <p>发现、学习、分享最前沿的 AI 工作流实践案例</p>
      </div>
    </section>
    
    <section class="category-section">
      <div class="category-list">
        <el-tag
          v-for="category in workflowStore.categories"
          :key="category.id"
          :type="workflowStore.selectedCategory === category.name ? '' : 'info'"
          :effect="workflowStore.selectedCategory === category.name ? 'dark' : 'plain'"
          size="large"
          class="category-tag"
          @click="handleCategoryClick(category.name)"
        >
          {{ category.name }} ({{ category.count }})
        </el-tag>
      </div>
    </section>
    
    <section class="workflow-section">
      <h2 class="section-title">
        <el-icon><Collection /></el-icon>
        工作流列表
      </h2>
      
      <div class="workflow-grid" v-if="workflowStore.filteredWorkflows.length">
        <WorkflowCard
          v-for="workflow in workflowStore.filteredWorkflows"
          :key="workflow.id"
          :workflow="workflow"
          @click="goToDetail(workflow.id)"
        />
      </div>
      
      <el-empty v-else description="暂无相关工作流" />
    </section>
  </div>
</template>

<script setup>
import { onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useWorkflowStore } from '@/stores/workflow'
import { Collection } from '@element-plus/icons-vue'
import WorkflowCard from '@/components/WorkflowCard.vue'

const router = useRouter()
const workflowStore = useWorkflowStore()

onMounted(() => {
  workflowStore.setCategory('全部')
  workflowStore.setSearchKeyword('')
})

function handleCategoryClick(category) {
  workflowStore.setCategory(category)
}

function goToDetail(id) {
  router.push(`/workflow/${id}`)
}
</script>

<style lang="scss" scoped>
.home-page {
  .hero-section {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    border-radius: 16px;
    padding: 60px 40px;
    margin-bottom: 32px;
    text-align: center;
    color: #fff;
    
    .hero-content {
      h1 {
        font-size: 36px;
        font-weight: 600;
        margin-bottom: 16px;
      }
      
      p {
        font-size: 18px;
        opacity: 0.9;
      }
    }
  }
  
  .category-section {
    margin-bottom: 32px;
    
    .category-list {
      display: flex;
      flex-wrap: wrap;
      gap: 12px;
    }
    
    .category-tag {
      cursor: pointer;
      transition: all 0.3s;
      
      &:hover {
        transform: translateY(-2px);
      }
    }
  }
  
  .workflow-section {
    .section-title {
      display: flex;
      align-items: center;
      gap: 8px;
      font-size: 20px;
      font-weight: 600;
      color: #303133;
      margin-bottom: 24px;
    }
    
    .workflow-grid {
      display: grid;
      grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
      gap: 24px;
    }
  }
}
</style>
