<template>
  <div class="resources-page">
    <div class="page-container">
      <div class="page-hero">
        <div class="hero-decoration">
          <div class="deco-circle deco-1"></div>
          <div class="deco-circle deco-2"></div>
          <div class="deco-circle deco-3"></div>
        </div>
        <h1>资源库</h1>
        <p>海量教程、模板和工具资源，助力你的 AI 应用开发</p>
        <div class="search-box">
          <el-input
            v-model="searchKeyword"
            placeholder="搜索资源..."
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
            v-for="cat in categories"
            :key="cat"
            class="category-chip"
            :class="{ active: selectedCategory === cat }"
            @click="selectedCategory = cat"
          >
            {{ cat }}
          </div>
        </transition-group>
      </div>

      <CardSkeleton v-if="isLoading" type="card" :count="4" />

      <transition-group
        v-else-if="filteredResources.length"
        name="card-list"
        tag="div"
        class="resources-grid"
      >
        <div
          v-for="(resource, index) in filteredResources"
          :key="resource.title"
          class="resource-card scroll-reveal"
          :style="{ '--stagger-index': index }"
        >
          <div class="card-cover" :style="{ background: resource.gradient }">
            <el-icon :size="40"><component :is="resource.iconComponent" /></el-icon>
          </div>
          <div class="card-content">
            <h3 class="card-title">{{ resource.title }}</h3>
            <p class="card-desc">{{ resource.description }}</p>
            <div class="card-footer">
              <span class="resource-count">{{ resource.count }} 项资源</span>
              <el-button text type="primary" size="small" class="view-btn">
                进入查看
                <el-icon class="el-icon--right"><ArrowRight /></el-icon>
              </el-button>
            </div>
          </div>
        </div>
      </transition-group>

      <EmptyState
        v-else
        type="no-result"
        title="未找到相关资源"
        description="尝试调整搜索关键词或筛选条件"
        actionText="清除筛选"
        @action="clearFilters"
      />
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Document, VideoCamera, SetUp, Collection, ChromeFilled, Reading, Cpu, ArrowRight, Search } from '@element-plus/icons-vue'
import EmptyState from '@/components/EmptyState.vue'
import CardSkeleton from '@/components/CardSkeleton.vue'

const searchKeyword = ref('')
const selectedCategory = ref('全部')
const isLoading = ref(true)

const resourceList = [
  {
    title: '技术文档',
    description: '详细的 API 文档和开发指南，帮助你快速上手',
    icon: 'Document',
    iconComponent: Document,
    count: 128,
    gradient: 'linear-gradient(135deg, #6366f1, #8b5cf6)',
    category: '文档'
  },
  {
    title: '视频教程',
    description: '从入门到进阶的视频教学，手把手带你实践',
    icon: 'VideoCamera',
    iconComponent: VideoCamera,
    count: 86,
    gradient: 'linear-gradient(135deg, #ec4899, #f97316)',
    category: '教程'
  },
  {
    title: '开发工具',
    description: '精选开发工具和插件，提升开发效率',
    icon: 'SetUp',
    iconComponent: SetUp,
    count: 52,
    gradient: 'linear-gradient(135deg, #06b6d4, #3b82f6)',
    category: '工具'
  },
  {
    title: '工作流模板',
    description: '即用型工作流模板，覆盖常见业务场景',
    icon: 'Collection',
    iconComponent: Collection,
    count: 210,
    gradient: 'linear-gradient(135deg, #10b981, #34d399)',
    category: '模板'
  },
  {
    title: '浏览器插件',
    description: '便捷的浏览器扩展，随时调用 AI 能力',
    icon: 'ChromeFilled',
    iconComponent: ChromeFilled,
    count: 35,
    gradient: 'linear-gradient(135deg, #f59e0b, #ef4444)',
    category: '工具'
  },
  {
    title: '学习路径',
    description: '系统化的学习路线规划，循序渐进掌握 AI 技能',
    icon: 'Reading',
    iconComponent: Reading,
    count: 24,
    gradient: 'linear-gradient(135deg, #8b5cf6, #ec4899)',
    category: '教程'
  },
  {
    title: 'SDK & API',
    description: '多语言 SDK 和 API 接口，快速集成到你的项目',
    icon: 'Cpu',
    iconComponent: Cpu,
    count: 18,
    gradient: 'linear-gradient(135deg, #3b82f6, #06b6d4)',
    category: '文档'
  },
  {
    title: '社区分享',
    description: '来自社区的实战经验和最佳实践分享',
    icon: 'Reading',
    iconComponent: Reading,
    count: 340,
    gradient: 'linear-gradient(135deg, #f97316, #ec4899)',
    category: '教程'
  }
]

const categories = computed(() => {
  const cats = ['全部', ...new Set(resourceList.map(r => r.category))]
  return cats
})

const filteredResources = computed(() => {
  let result = resourceList

  if (selectedCategory.value !== '全部') {
    result = result.filter(r => r.category === selectedCategory.value)
  }

  if (searchKeyword.value) {
    const keyword = searchKeyword.value.toLowerCase()
    result = result.filter(r =>
      r.title.toLowerCase().includes(keyword) ||
      r.description.toLowerCase().includes(keyword)
    )
  }

  return result
})

onMounted(() => {
  selectedCategory.value = '全部'
  searchKeyword.value = ''
  // Simulate loading for skeleton display
  setTimeout(() => {
    isLoading.value = false
  }, 600)
})

function handleSearch() {
  // searchKeyword is reactive, filteredResources auto-updates
}

function clearFilters() {
  searchKeyword.value = ''
  selectedCategory.value = '全部'
}
</script>

<style lang="scss" scoped>
.resources-page {
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
    width: 260px;
    height: 260px;
    top: -80px;
    right: -60px;
    background: var(--accent-gradient);
    animation: float 8s ease-in-out infinite;
  }

  .deco-2 {
    width: 180px;
    height: 180px;
    bottom: -60px;
    left: -30px;
    background: var(--accent-secondary);
    animation: float 6s ease-in-out infinite reverse;
  }

  .deco-3 {
    width: 100px;
    height: 100px;
    top: 30%;
    left: 20%;
    background: var(--accent-primary);
    opacity: 0.05;
    animation: float 7s ease-in-out infinite 0.8s;
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

.resources-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  gap: 24px;
}

.resource-card {
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

    .card-cover {
      opacity: 0.9;

      .el-icon {
        transform: scale(1.15);
      }
    }
  }
}

.card-cover {
  height: 120px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  position: relative;
  overflow: hidden;

  &::before {
    content: '';
    position: absolute;
    top: -30%;
    right: -20%;
    width: 140px;
    height: 140px;
    border-radius: 50%;
    background: rgba(255, 255, 255, 0.08);
  }

  .el-icon {
    position: relative;
    z-index: 1;
    transition: transform var(--duration-slow) var(--ease-spring);
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
    margin-bottom: 0;
  }
}

.card-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-top: 14px;
  border-top: 1px solid var(--border-light);

  .resource-count {
    font-size: 12px;
    color: var(--text-tertiary);
  }

  .view-btn {
    padding: 0;
  }
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

    .deco-1 { width: 160px; height: 160px; }
    .deco-2 { width: 100px; height: 100px; }
  }

  .resources-grid {
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
