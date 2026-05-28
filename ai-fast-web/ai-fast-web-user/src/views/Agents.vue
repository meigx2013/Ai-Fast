<template>
  <div class="agents-page">
    <div class="page-container">
      <div class="page-hero">
        <div class="hero-decoration">
          <div class="deco-circle deco-1"></div>
          <div class="deco-circle deco-2"></div>
          <div class="deco-circle deco-3"></div>
        </div>
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
        <transition-group name="chip" tag="div" class="category-bar-inner">
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
        </transition-group>
      </div>

      <CardSkeleton v-if="isLoading" type="agent" :count="6" />

      <transition-group
        v-else-if="agentStore.filteredAgents.length"
        name="card-list"
        tag="div"
        class="agents-grid"
      >
        <AgentCard
          v-for="(agent, index) in agentStore.filteredAgents"
          :key="agent.id"
          :agent="agent"
          :style="{ '--stagger-index': index }"
          class="scroll-reveal"
          @click="$router.push(`/agent/${agent.id}`)"
        />
      </transition-group>

      <EmptyState
        v-else
        type="no-result"
        title="未找到相关智能体"
        description="尝试调整搜索关键词或筛选条件"
        actionText="清除筛选"
        @action="clearFilters"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useAgentStore } from '@/stores/agent'
import { Search } from '@element-plus/icons-vue'
import AgentCard from '@/components/AgentCard.vue'
import EmptyState from '@/components/EmptyState.vue'
import CardSkeleton from '@/components/CardSkeleton.vue'

const agentStore = useAgentStore()
const searchKeyword = ref('')
const isLoading = ref(true)

onMounted(() => {
  agentStore.setCategory('全部')
  agentStore.setSearchKeyword('')
  // Simulate loading for skeleton display
  setTimeout(() => {
    isLoading.value = false
  }, 600)
})

function handleSearch() {
  agentStore.setSearchKeyword(searchKeyword.value)
}

function handleCategoryClick(name) {
  agentStore.setCategory(name)
}

function clearFilters() {
  searchKeyword.value = ''
  agentStore.setSearchKeyword('')
  agentStore.setCategory('全部')
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
  position: relative;
  overflow: hidden;

  .hero-decoration {
    position: absolute;
    inset: 0;
    pointer-events: none;
    z-index: 0;
  }

  .deco-circle {
    position: absolute;
    border-radius: 50%;
    opacity: 0.08;
    filter: blur(2px);
  }

  .deco-1 {
    width: 300px;
    height: 300px;
    top: -120px;
    right: -80px;
    background: var(--accent-gradient);
    animation: float 6s ease-in-out infinite;
  }

  .deco-2 {
    width: 200px;
    height: 200px;
    bottom: -60px;
    left: -40px;
    background: var(--accent-secondary);
    animation: float 8s ease-in-out infinite reverse;
  }

  .deco-3 {
    width: 120px;
    height: 120px;
    top: 20%;
    left: 15%;
    background: var(--accent-primary);
    opacity: 0.05;
    animation: float 7s ease-in-out infinite 1s;
  }

  h1 {
    font-size: 36px;
    font-weight: 700;
    color: var(--text-primary);
    margin-bottom: 12px;
    position: relative;
    z-index: 1;
  }

  p {
    font-size: 16px;
    color: var(--text-tertiary);
    margin-bottom: 28px;
    position: relative;
    z-index: 1;
  }

  .search-box {
    max-width: 480px;
    margin: 0 auto;
    position: relative;
    z-index: 1;

    :deep(.el-input__wrapper) {
      border-radius: var(--radius-xl);
      box-shadow: var(--shadow-md);
    }
  }
}

.category-bar {
  margin-bottom: 32px;
  display: flex;
  justify-content: center;
}

.category-bar-inner {
  display: flex;
  gap: 10px;
  flex-wrap: wrap;
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
  transition: all var(--duration-normal) var(--ease-standard);

  &:hover {
    border-color: var(--accent-primary);
    color: var(--accent-primary);
    transform: translateY(-1px);
  }

  &.active {
    background: var(--accent-primary-bg);
    border-color: var(--accent-primary);
    color: var(--accent-primary);
    font-weight: 500;
    box-shadow: var(--shadow-sm);
  }
}

/* Category chip transition */
.chip-enter-active {
  transition: all var(--duration-normal) var(--ease-decelerate);
}

.chip-leave-active {
  transition: all var(--duration-fast) var(--ease-accelerate);
}

.chip-enter-from {
  opacity: 0;
  transform: scale(0.9);
}

.chip-leave-to {
  opacity: 0;
  transform: scale(0.9);
}

.agents-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 24px;
}

/* Card list transition */
.card-list-enter-active {
  transition: all var(--duration-slow) var(--ease-decelerate);
  transition-delay: calc(var(--stagger-index, 0) * 80ms);
}

.card-list-leave-active {
  transition: all var(--duration-fast) var(--ease-accelerate);
}

.card-list-enter-from {
  opacity: 0;
  transform: translateY(20px) scale(0.96);
}

.card-list-leave-to {
  opacity: 0;
  transform: scale(0.96);
}

.card-list-move {
  transition: transform var(--duration-normal) var(--ease-standard);
}

@media (max-width: 768px) {
  .page-container {
    padding: 16px;
  }

  .page-hero {
    padding: 32px 0 24px;

    h1 { font-size: 24px; }

    .deco-1 { width: 180px; height: 180px; }
    .deco-2 { width: 120px; height: 120px; }
  }

  .agents-grid {
    grid-template-columns: 1fr;
  }
}

@keyframes float {
  0%, 100% {
    transform: translateY(0px);
  }
  50% {
    transform: translateY(-12px);
  }
}
</style>
