<template>
  <div class="resources-page">
    <div class="page-container">
      <div class="page-hero">
        <h1>资源库</h1>
        <p>海量教程、模板和工具资源，助力你的 AI 应用开发</p>
      </div>

      <div class="resources-grid">
        <div
          v-for="(resource, index) in resourceList"
          :key="index"
          class="resource-card fade-in-up"
          :style="{ animationDelay: index * 0.08 + 's' }"
        >
          <div class="resource-icon" :style="{ background: resource.gradient }">
            <el-icon :size="28"><component :is="resource.icon" /></el-icon>
          </div>
          <div class="resource-info">
            <h3>{{ resource.title }}</h3>
            <p>{{ resource.description }}</p>
            <div class="resource-meta">
              <span class="count">{{ resource.count }} 项资源</span>
              <el-button text type="primary" size="small">
                进入查看
                <el-icon class="el-icon--right"><ArrowRight /></el-icon>
              </el-button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { Document, VideoCamera, SetUp, Collection, ChromeFilled, Reading, Cpu, ArrowRight } from '@element-plus/icons-vue'

const resourceList = [
  {
    title: '技术文档',
    description: '详细的 API 文档和开发指南，帮助你快速上手',
    icon: 'Document',
    count: 128,
    gradient: 'linear-gradient(135deg, #6366f1, #8b5cf6)'
  },
  {
    title: '视频教程',
    description: '从入门到进阶的视频教学，手把手带你实践',
    icon: 'VideoCamera',
    count: 86,
    gradient: 'linear-gradient(135deg, #ec4899, #f97316)'
  },
  {
    title: '开发工具',
    description: '精选开发工具和插件，提升开发效率',
    icon: 'SetUp',
    count: 52,
    gradient: 'linear-gradient(135deg, #06b6d4, #3b82f6)'
  },
  {
    title: '工作流模板',
    description: '即用型工作流模板，覆盖常见业务场景',
    icon: 'Collection',
    count: 210,
    gradient: 'linear-gradient(135deg, #10b981, #34d399)'
  },
  {
    title: '浏览器插件',
    description: '便捷的浏览器扩展，随时调用 AI 能力',
    icon: 'ChromeFilled',
    count: 35,
    gradient: 'linear-gradient(135deg, #f59e0b, #ef4444)'
  },
  {
    title: '学习路径',
    description: '系统化的学习路线规划，循序渐进掌握 AI 技能',
    icon: 'Reading',
    count: 24,
    gradient: 'linear-gradient(135deg, #8b5cf6, #ec4899)'
  },
  {
    title: 'SDK & API',
    description: '多语言 SDK 和 API 接口，快速集成到你的项目',
    icon: 'Cpu',
    count: 18,
    gradient: 'linear-gradient(135deg, #3b82f6, #06b6d4)'
  },
  {
    title: '社区分享',
    description: '来自社区的实战经验和最佳实践分享',
    icon: 'Reading',
    count: 340,
    gradient: 'linear-gradient(135deg, #f97316, #ec4899)'
  }
]
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

  h1 {
    font-size: 36px;
    font-weight: 700;
    color: var(--text-primary);
    margin-bottom: 12px;
  }

  p {
    font-size: 16px;
    color: var(--text-tertiary);
  }
}

.resources-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(380px, 1fr));
  gap: 24px;
}

.resource-card {
  display: flex;
  gap: 20px;
  padding: 24px;
  background: var(--bg-card);
  border: var(--card-border);
  border-radius: var(--radius-md);
  cursor: pointer;
  transition: all 0.3s ease;

  &:hover {
    transform: translateY(-3px);
    box-shadow: var(--shadow-md);
    border-color: var(--accent-primary);
  }

  .resource-icon {
    width: 60px;
    height: 60px;
    border-radius: var(--radius-md);
    display: flex;
    align-items: center;
    justify-content: center;
    color: #fff;
    flex-shrink: 0;
  }

  .resource-info {
    flex: 1;

    h3 {
      font-size: 17px;
      font-weight: 600;
      color: var(--text-primary);
      margin-bottom: 6px;
    }

    p {
      font-size: 13px;
      color: var(--text-tertiary);
      line-height: 1.5;
      margin-bottom: 12px;
    }

    .resource-meta {
      display: flex;
      justify-content: space-between;
      align-items: center;

      .count {
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

  .resources-grid {
    grid-template-columns: 1fr;
  }
}
</style>
