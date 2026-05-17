<template>
  <div class="workflows-page">
    <div class="page-container">
      <div class="page-hero">
        <h1>工作流中心</h1>
        <p>探索和学习精心编排的 AI 工作流，自动化处理复杂任务</p>
        <div class="search-box">
          <el-input
            v-model="searchKeyword"
            placeholder="搜索工作流..."
            :prefix-icon="Search"
            size="large"
            clearable
            @input="handleSearch"
          />
        </div>
      </div>

      <div class="category-bar">
        <div
          v-for="cat in workflowStore.categories"
          :key="cat.id"
          class="category-chip"
          :class="{ active: workflowStore.selectedCategory === cat.name }"
          @click="handleCategoryClick(cat.name)"
        >
          {{ cat.name }}
          <span class="count" v-if="cat.id !== 1">{{ cat.count }}</span>
        </div>
      </div>

      <div class="workflows-grid" v-if="workflowStore.filteredWorkflows.length">
        <WorkflowCard
          v-for="workflow in workflowStore.filteredWorkflows"
          :key="workflow.id"
          :workflow="workflow"
          @click="$router.push(`/workflow/${workflow.id}`)"
        />
      </div>

      <el-empty v-else description="暂无相关工作流" />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useWorkflowStore } from '@/stores/workflow'
import { Search } from '@element-plus/icons-vue'
import WorkflowCard from '@/components/WorkflowCard.vue'

const workflowStore = useWorkflowStore()
const searchKeyword = ref('')

onMounted(() => {
  workflowStore.setCategory('全部')
  workflowStore.setSearchKeyword('')
})

function handleSearch() {
  workflowStore.setSearchKeyword(searchKeyword.value)
}

function handleCategoryClick(name) {
  workflowStore.setCategory(name)
}
</script>

<style lang="scss" scoped>
.workflows-page {
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
  padding: 8px 18px;
  border-radius: var(--radius-xl);
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  color: var(--text-secondary);
  font-size: 14px;
  cursor: pointer;
  transition: all 0.3s;
  display: flex;
  align-items: center;
  gap: 4px;

  .count {
    font-size: 12px;
    color: var(--text-tertiary);
    background: var(--bg-tertiary);
    padding: 1px 8px;
    border-radius: 10px;
  }

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

.workflows-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 24px;
}

@media (max-width: 768px) {
  .page-container {
    padding: 16px;
  }

  .page-hero {
    padding: 32px 0 24px;

    h1 { font-size: 24px; }
  }

  .workflows-grid {
    grid-template-columns: 1fr;
  }
}
</style>
