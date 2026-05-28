<template>
  <div class="card-skeleton-grid" :class="[`type-${type}`]">
    <div
      v-for="i in count"
      :key="i"
      class="skeleton-card"
    >
      <div class="skeleton-cover shimmer"></div>
      <div class="skeleton-content">
        <div class="skeleton-title shimmer"></div>
        <div class="skeleton-line shimmer" style="width: 85%"></div>
        <div class="skeleton-line shimmer" style="width: 60%"></div>
        <div class="skeleton-tags">
          <div class="skeleton-tag shimmer"></div>
          <div class="skeleton-tag shimmer" style="width: 56px"></div>
        </div>
        <div class="skeleton-footer">
          <div class="skeleton-avatar shimmer"></div>
          <div class="skeleton-name shimmer"></div>
          <div class="skeleton-stat shimmer"></div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
defineProps({
  count: {
    type: Number,
    default: 6
  },
  type: {
    type: String,
    default: 'card',
    validator: (v) => ['card', 'agent', 'list'].includes(v)
  }
})
</script>

<style lang="scss" scoped>
.card-skeleton-grid {
  display: grid;
  gap: 24px;

  &.type-card,
  &.type-agent {
    grid-template-columns: repeat(auto-fill, minmax(340px, 1fr));
  }

  &.type-list {
    grid-template-columns: 1fr;
  }
}

.skeleton-card {
  background: var(--bg-card);
  border: var(--card-border);
  border-radius: var(--radius-lg);
  overflow: hidden;
}

.skeleton-cover {
  height: 220px;

  .type-agent & {
    height: 140px;
  }

  .type-list & {
    height: 160px;
  }
}

.skeleton-content {
  padding: 16px 20px 20px;
}

.skeleton-title {
  height: 18px;
  width: 70%;
  border-radius: 4px;
  margin-bottom: 12px;
}

.skeleton-line {
  height: 12px;
  border-radius: 4px;
  margin-bottom: 8px;
}

.skeleton-tags {
  display: flex;
  gap: 8px;
  margin-top: 12px;
  margin-bottom: 14px;
}

.skeleton-tag {
  height: 22px;
  width: 64px;
  border-radius: var(--radius-sm);
}

.skeleton-footer {
  display: flex;
  align-items: center;
  gap: 8px;
  padding-top: 14px;
  border-top: 1px solid var(--border-light);
}

.skeleton-avatar {
  width: 24px;
  height: 24px;
  border-radius: 50%;
  flex-shrink: 0;
}

.skeleton-name {
  height: 12px;
  width: 60px;
  border-radius: 4px;
}

.skeleton-stat {
  height: 12px;
  width: 36px;
  border-radius: 4px;
  margin-left: auto;
}

.shimmer {
  background: linear-gradient(
    90deg,
    var(--bg-tertiary) 25%,
    var(--bg-card-hover) 50%,
    var(--bg-tertiary) 75%
  );
  background-size: 200% 100%;
  animation: shimmer 1.5s ease-in-out infinite;
}

@keyframes shimmer {
  0% {
    background-position: 200% 0;
  }
  100% {
    background-position: -200% 0;
  }
}

@media (prefers-reduced-motion: reduce) {
  .shimmer {
    animation: none;
    background: var(--bg-tertiary);
  }
}
</style>
