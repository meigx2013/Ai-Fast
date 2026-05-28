<template>
  <div class="workflow-detail" v-if="workflow">
    <!-- Task 5.1: 沉浸式封面区 + 视差滚动 -->
    <div class="immersive-cover" ref="coverRef">
      <div class="cover-parallax" :style="parallaxStyle">
        <img :src="workflow.cover" :alt="workflow.title" />
      </div>
      <div class="cover-gradient"></div>
      <button class="back-btn" @click="$router.back()">
        <el-icon><ArrowLeft /></el-icon>
      </button>
      <div class="cover-content">
        <h1 class="cover-title">{{ workflow.title }}</h1>
        <div class="cover-meta">
          <div class="author-info">
            <el-avatar :size="36" :src="workflow.author.avatar" />
            <div class="author-detail">
              <span class="author-name">{{ workflow.author.name }}</span>
              <span class="publish-date">发布于 {{ workflow.createdAt }}</span>
            </div>
          </div>
          <div class="workflow-stats">
            <span class="stat-item">
              <el-icon><View /></el-icon>
              {{ workflow.views }}
            </span>
            <span class="stat-item">
              <el-icon><Star /></el-icon>
              {{ workflow.likes }}
            </span>
            <span class="stat-item">
              <el-icon><CollectionTag /></el-icon>
              {{ workflow.favorites }}
            </span>
          </div>
        </div>
      </div>
    </div>

    <div class="detail-body">
      <div class="detail-container">
        <div class="detail-content">
          <div class="detail-main">
            <!-- 标签 -->
            <div class="workflow-tags">
              <el-tag
                v-for="tag in workflow.tags"
                :key="tag"
                size="large"
                effect="plain"
              >
                {{ tag }}
              </el-tag>
            </div>

            <!-- 简介 -->
            <div class="workflow-description scroll-reveal">
              <h3>简介</h3>
              <p>{{ workflow.description }}</p>
            </div>

            <!-- Task 5.2: 步骤卡片交互与进度标记 -->
            <div class="workflow-steps scroll-reveal">
              <div class="steps-header">
                <h3>学习步骤</h3>
                <div class="progress-bar-wrapper">
                  <div class="progress-bar">
                    <div
                      class="progress-fill"
                      :style="{ width: progressPercent + '%' }"
                    ></div>
                  </div>
                  <span class="progress-text">{{ completedSteps.length }}/{{ workflow.steps.length }} 已完成</span>
                </div>
              </div>

              <div class="steps-list">
                <div
                  v-for="(step, index) in workflow.steps"
                  :key="index"
                  class="step-card"
                  :class="{ 'is-completed': completedSteps.includes(index), 'is-expanded': expandedStep === index }"
                >
                  <div class="step-header" @click="toggleStep(index)">
                    <div class="step-left">
                      <button
                        class="step-check"
                        :class="{ checked: completedSteps.includes(index) }"
                        @click.stop="toggleStepComplete(index)"
                      >
                        <el-icon v-if="completedSteps.includes(index)"><Check /></el-icon>
                      </button>
                      <span class="step-number">步骤 {{ index + 1 }}</span>
                    </div>
                    <div class="step-right">
                      <h4 class="step-title">{{ step.title }}</h4>
                      <el-icon class="step-arrow" :class="{ rotated: expandedStep === index }">
                        <ArrowDown />
                      </el-icon>
                    </div>
                  </div>
                  <transition name="expand">
                    <div class="step-body" v-show="expandedStep === index">
                      <p>{{ step.content }}</p>
                    </div>
                  </transition>
                </div>
              </div>
            </div>
          </div>

          <!-- Task 5.3: Sidebar Sticky -->
          <div class="detail-sidebar">
            <div class="sidebar-inner">
              <div class="info-card">
                <h4>课程信息</h4>
                <div class="info-item">
                  <span class="label">难度等级</span>
                  <el-tag :type="difficultyType" effect="plain">{{ workflow.difficulty }}</el-tag>
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
              </div>

              <div class="action-card">
                <el-button
                  type="primary"
                  size="large"
                  class="gradient-btn"
                  @click="handleStartLearn"
                >
                  <el-icon><VideoPlay /></el-icon>
                  开始学习
                </el-button>
                <div class="action-row">
                  <el-button
                    size="large"
                    :class="{ 'is-active': isLiked }"
                    @click="toggleLike"
                    round
                  >
                    <el-icon><Star /></el-icon>
                    {{ isLiked ? '已点赞' : '点赞' }}
                  </el-button>
                  <el-button
                    size="large"
                    :class="{ 'is-active': isFavorited }"
                    @click="toggleFavorite"
                    round
                  >
                    <el-icon><CollectionTag /></el-icon>
                    {{ isFavorited ? '已收藏' : '收藏' }}
                  </el-button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Task 5.3: 浮动操作栏 -->
    <transition name="float-bar">
      <div class="floating-action-bar" v-show="showFloatingBar">
        <div class="floating-inner">
          <span class="floating-title">{{ workflow.title }}</span>
          <div class="floating-actions">
            <el-button
              type="primary"
              class="gradient-btn"
              @click="handleStartLearn"
            >
              <el-icon><VideoPlay /></el-icon>
              开始学习
            </el-button>
            <el-button
              :class="{ 'is-active': isLiked }"
              @click="toggleLike"
              round
            >
              <el-icon><Star /></el-icon>
            </el-button>
            <el-button
              :class="{ 'is-active': isFavorited }"
              @click="toggleFavorite"
              round
            >
              <el-icon><CollectionTag /></el-icon>
            </el-button>
          </div>
        </div>
      </div>
    </transition>
  </div>

  <div class="empty-state" v-else>
    <EmptyState
      type="error"
      title="工作流不存在"
      description="该工作流可能已被删除或链接无效"
      actionText="返回列表"
      actionLink="/workflows"
    />
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute } from 'vue-router'
import { useWorkflowStore } from '@/stores/workflow'
import { useUserStore } from '@/stores/user'
import { ArrowLeft, View, Star, CollectionTag, Check, ArrowDown, VideoPlay } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import EmptyState from '@/components/EmptyState.vue'

const route = useRoute()
const workflowStore = useWorkflowStore()
const userStore = useUserStore()

const workflow = ref(null)
const isLiked = ref(false)
const isFavorited = ref(false)

// Task 5.1: 视差滚动
const coverRef = ref(null)
const parallaxOffset = ref(0)

const parallaxStyle = computed(() => ({
  transform: `translateY(${parallaxOffset.value * 0.3}px) scale(1.1)`
}))

function handleScroll() {
  const scrollY = window.scrollY
  parallaxOffset.value = scrollY
  // Task 5.3: 浮动操作栏显示逻辑
  if (coverRef.value) {
    const coverBottom = coverRef.value.offsetTop + coverRef.value.offsetHeight
    showFloatingBar.value = scrollY > coverBottom - 68
  }
}

// Task 5.2: 步骤卡片交互
const expandedStep = ref(null)
const completedSteps = ref([])

const progressPercent = computed(() => {
  if (!workflow.value || !workflow.value.steps.length) return 0
  return Math.round((completedSteps.value.length / workflow.value.steps.length) * 100)
})

function toggleStep(index) {
  expandedStep.value = expandedStep.value === index ? null : index
}

function toggleStepComplete(index) {
  const pos = completedSteps.value.indexOf(index)
  if (pos > -1) {
    completedSteps.value.splice(pos, 1)
  } else {
    completedSteps.value.push(index)
  }
  saveProgress()
}

function saveProgress() {
  if (!workflow.value) return
  const key = `workflow-progress:${workflow.value.id}`
  localStorage.setItem(key, JSON.stringify(completedSteps.value))
}

function loadProgress() {
  if (!workflow.value) return
  const key = `workflow-progress:${workflow.value.id}`
  try {
    const data = localStorage.getItem(key)
    if (data) {
      completedSteps.value = JSON.parse(data)
    }
  } catch {
    completedSteps.value = []
  }
}

// Task 5.3: 浮动操作栏
const showFloatingBar = ref(false)

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

  if (workflow.value) {
    loadProgress()

    if (userStore.userInfo) {
      isLiked.value = userStore.userInfo.likes?.includes(workflow.value.id)
      isFavorited.value = userStore.userInfo.favorites?.includes(workflow.value.id)
    }
  }

  window.addEventListener('scroll', handleScroll, { passive: true })
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
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

function handleStartLearn() {
  if (!userStore.isLoggedIn) {
    ElMessage.warning('请先登录')
    return
  }
  ElMessage.success('开始学习！')
}
</script>

<style lang="scss" scoped>
.workflow-detail {
  background: var(--bg-secondary);
  min-height: calc(100vh - 68px);
}

/* ===== Task 5.1: 沉浸式封面区 ===== */
.immersive-cover {
  position: relative;
  width: 100%;
  height: 400px;
  overflow: hidden;

  .cover-parallax {
    position: absolute;
    inset: -40px 0;
    will-change: transform;

    img {
      width: 100%;
      height: calc(100% + 80px);
      object-fit: cover;
    }
  }

  .cover-gradient {
    position: absolute;
    inset: 0;
    background: linear-gradient(
      to bottom,
      rgba(0, 0, 0, 0.1) 0%,
      rgba(0, 0, 0, 0.2) 50%,
      var(--bg-secondary) 100%
    );
    z-index: 1;
  }

  .back-btn {
    position: absolute;
    top: 20px;
    left: 20px;
    z-index: 2;
    width: 40px;
    height: 40px;
    border-radius: 50%;
    background: rgba(0, 0, 0, 0.4);
    backdrop-filter: blur(8px);
    border: 1px solid rgba(255, 255, 255, 0.15);
    color: #fff;
    cursor: pointer;
    display: flex;
    align-items: center;
    justify-content: center;
    font-size: 18px;
    transition: all var(--duration-fast) var(--ease-standard);

    &:hover {
      background: rgba(0, 0, 0, 0.6);
      transform: scale(1.05);
    }
  }

  .cover-content {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    z-index: 2;
    padding: 0 32px 32px;
    max-width: 1400px;
    margin: 0 auto;
  }

  .cover-title {
    font-size: 32px;
    font-weight: 700;
    color: #fff;
    margin-bottom: 16px;
    text-shadow: 0 2px 8px rgba(0, 0, 0, 0.3);
  }

  .cover-meta {
    display: flex;
    justify-content: space-between;
    align-items: center;

    .author-info {
      display: flex;
      align-items: center;
      gap: 12px;

      .author-detail {
        display: flex;
        flex-direction: column;

        .author-name {
          font-weight: 500;
          color: #fff;
          font-size: 15px;
        }

        .publish-date {
          font-size: 13px;
          color: rgba(255, 255, 255, 0.7);
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
        color: rgba(255, 255, 255, 0.85);
        font-size: 14px;
      }
    }
  }
}

/* ===== Detail Body ===== */
.detail-body {
  position: relative;
  z-index: 1;
}

.detail-container {
  max-width: 1400px;
  margin: 0 auto;
  padding: 32px;
}

.detail-content {
  display: flex;
  gap: 28px;

  @media (max-width: 992px) {
    flex-direction: column;
  }
}

.detail-main {
  flex: 1;
  min-width: 0;

  .workflow-tags {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
    margin-bottom: 24px;
  }

  .workflow-description {
    margin-bottom: 40px;

    h3 {
      font-size: 18px;
      font-weight: 600;
      margin-bottom: 12px;
      color: var(--text-primary);
    }

    p {
      color: var(--text-secondary);
      line-height: 1.8;
      font-size: 15px;
    }
  }
}

/* ===== Task 5.2: 步骤卡片交互与进度标记 ===== */
.workflow-steps {
  .steps-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 24px;
    gap: 16px;

    h3 {
      font-size: 18px;
      font-weight: 600;
      color: var(--text-primary);
      white-space: nowrap;
    }

    .progress-bar-wrapper {
      display: flex;
      align-items: center;
      gap: 12px;
      flex: 1;
      max-width: 320px;
    }

    .progress-bar {
      flex: 1;
      height: 6px;
      background: var(--bg-tertiary);
      border-radius: 3px;
      overflow: hidden;
    }

    .progress-fill {
      height: 100%;
      background: var(--accent-gradient);
      border-radius: 3px;
      transition: width var(--duration-normal) var(--ease-decelerate);
    }

    .progress-text {
      font-size: 13px;
      color: var(--text-tertiary);
      white-space: nowrap;
    }
  }
}

.steps-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.step-card {
  background: var(--bg-card);
  border: var(--card-border);
  border-radius: var(--radius-md);
  overflow: hidden;
  transition: border-color var(--duration-fast) var(--ease-standard),
              box-shadow var(--duration-fast) var(--ease-standard);

  &.is-completed {
    border-color: var(--accent-primary);
    border-left: 3px solid var(--accent-primary);

    .step-title {
      color: var(--accent-primary);
    }
  }

  &.is-expanded {
    box-shadow: var(--shadow-md);
  }
}

.step-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  cursor: pointer;
  transition: background var(--duration-fast) var(--ease-standard);

  &:hover {
    background: var(--bg-card-hover);
  }
}

.step-left {
  display: flex;
  align-items: center;
  gap: 12px;
  flex-shrink: 0;
}

.step-check {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  border: 2px solid var(--border-color);
  background: transparent;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  color: transparent;
  transition: all var(--duration-fast) var(--ease-standard);
  font-size: 14px;
  padding: 0;

  &:hover {
    border-color: var(--accent-primary);
  }

  &.checked {
    background: var(--accent-primary);
    border-color: var(--accent-primary);
    color: #fff;
  }
}

.step-number {
  font-size: 12px;
  color: var(--text-tertiary);
  font-weight: 500;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}

.step-right {
  display: flex;
  align-items: center;
  gap: 8px;
  flex: 1;
  min-width: 0;
}

.step-title {
  font-size: 15px;
  font-weight: 500;
  color: var(--text-primary);
  flex: 1;
}

.step-arrow {
  color: var(--text-tertiary);
  transition: transform var(--duration-normal) var(--ease-standard);
  font-size: 14px;

  &.rotated {
    transform: rotate(180deg);
  }
}

.step-body {
  padding: 0 20px 20px 56px;

  p {
    color: var(--text-secondary);
    font-size: 14px;
    line-height: 1.7;
  }
}

/* Expand transition */
.expand-enter-active {
  transition: all var(--duration-normal) var(--ease-decelerate);
  overflow: hidden;
}

.expand-leave-active {
  transition: all var(--duration-fast) var(--ease-accelerate);
  overflow: hidden;
}

.expand-enter-from,
.expand-leave-to {
  opacity: 0;
  max-height: 0;
  padding-top: 0;
  padding-bottom: 0;
}

.expand-enter-to,
.expand-leave-from {
  opacity: 1;
  max-height: 200px;
}

/* ===== Task 5.3: Sidebar Sticky ===== */
.detail-sidebar {
  width: 320px;
  flex-shrink: 0;

  @media (max-width: 992px) {
    width: 100%;
  }
}

.sidebar-inner {
  position: sticky;
  top: 88px;

  @media (max-width: 992px) {
    position: static;
  }
}

.info-card {
  background: var(--bg-card);
  border: var(--card-border);
  border-radius: var(--radius-md);
  padding: 24px;
  margin-bottom: 16px;

  h4 {
    font-size: 16px;
    font-weight: 600;
    margin-bottom: 16px;
    color: var(--text-primary);
  }

  .info-item {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 12px 0;
    border-bottom: 1px solid var(--border-color);

    &:last-child {
      border-bottom: none;
    }

    .label {
      color: var(--text-tertiary);
      font-size: 14px;
    }

    .value {
      color: var(--text-primary);
      font-size: 14px;
    }
  }
}

.action-card {
  background: var(--bg-card);
  border: var(--card-border);
  border-radius: var(--radius-md);
  padding: 20px;
  display: flex;
  flex-direction: column;
  gap: 12px;

  .gradient-btn {
    width: 100%;
    background: var(--accent-gradient);
    border: none;
    color: #fff;
    font-weight: 600;
    font-size: 16px;
    height: 44px;
    transition: all var(--duration-fast) var(--ease-standard);

    &:hover {
      background: var(--accent-gradient-hover);
      box-shadow: var(--shadow-glow);
      transform: translateY(-1px);
    }
  }

  .action-row {
    display: flex;
    gap: 10px;

    .el-button {
      flex: 1;
    }
  }

  .is-active {
    background: var(--accent-primary-bg);
    border-color: var(--accent-primary);
    color: var(--accent-primary);
  }
}

/* ===== Task 5.3: 浮动操作栏 ===== */
.floating-action-bar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  z-index: var(--layer-sticky);
  background: var(--bg-card);
  border-top: 1px solid var(--border-color);
  box-shadow: 0 -4px 16px rgba(0, 0, 0, 0.08);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);

  .floating-inner {
    max-width: 1400px;
    margin: 0 auto;
    padding: 12px 32px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    gap: 16px;
  }

  .floating-title {
    font-size: 15px;
    font-weight: 600;
    color: var(--text-primary);
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    flex: 1;
    min-width: 0;
  }

  .floating-actions {
    display: flex;
    align-items: center;
    gap: 10px;
    flex-shrink: 0;

    .gradient-btn {
      background: var(--accent-gradient);
      border: none;
      color: #fff;
      font-weight: 600;

      &:hover {
        background: var(--accent-gradient-hover);
        box-shadow: var(--shadow-glow);
      }
    }

    .is-active {
      background: var(--accent-primary-bg);
      border-color: var(--accent-primary);
      color: var(--accent-primary);
    }
  }
}

/* Float bar transition */
.float-bar-enter-active {
  transition: all var(--duration-normal) var(--ease-decelerate);
}

.float-bar-leave-active {
  transition: all var(--duration-fast) var(--ease-accelerate);
}

.float-bar-enter-from,
.float-bar-leave-to {
  opacity: 0;
  transform: translateY(100%);
}

/* ===== Empty State ===== */
.empty-state {
  min-height: calc(100vh - 68px);
  display: flex;
  align-items: center;
  justify-content: center;
}

/* ===== Responsive ===== */
@media (max-width: 768px) {
  .immersive-cover {
    height: 250px;

    .cover-title {
      font-size: 22px;
    }

    .cover-meta {
      flex-direction: column;
      align-items: flex-start;
      gap: 12px;
    }
  }

  .detail-container {
    padding: 16px;
  }

  .step-header {
    padding: 12px 16px;
  }

  .step-body {
    padding: 0 16px 16px 48px;
  }

  .floating-action-bar .floating-inner {
    padding: 10px 16px;

    .floating-title {
      display: none;
    }
  }
}

/* ===== Reduced Motion ===== */
@media (prefers-reduced-motion: reduce) {
  .cover-parallax {
    transform: none !important;
  }

  .step-arrow {
    transition: none;
  }

  .floating-action-bar {
    transition: none;
  }
}
</style>
