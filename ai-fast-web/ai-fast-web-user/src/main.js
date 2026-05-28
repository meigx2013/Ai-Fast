import { createApp, nextTick } from 'vue'
import { createPinia } from 'pinia'
import ElementPlus from 'element-plus'
import * as ElementPlusIconsVue from '@element-plus/icons-vue'
import 'element-plus/dist/index.css'
import 'element-plus/theme-chalk/dark/css-vars.css'
import zhCn from 'element-plus/dist/locale/zh-cn.mjs'

import App from './App.vue'
import router from './router'
import './assets/main.scss'

const app = createApp(App)

for (const [key, component] of Object.entries(ElementPlusIconsVue)) {
  app.component(key, component)
}

app.use(createPinia())
app.use(router)
app.use(ElementPlus, { locale: zhCn })

app.mount('#app')

// ===== Global IntersectionObserver for Scroll Reveal =====
const scrollObserver = new IntersectionObserver(
  (entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add('revealed')
        scrollObserver.unobserve(entry.target)
      }
    })
  },
  {
    threshold: 0.1,
    rootMargin: '0px 0px -40px 0px',
  }
)

function observeScrollReveals() {
  document
    .querySelectorAll('.scroll-reveal, .scroll-reveal-left, .scroll-reveal-scale')
    .forEach((el) => {
      if (!el.classList.contains('revealed')) {
        scrollObserver.observe(el)
      }
    })
}

// Observe on initial load
observeScrollReveals()

// Re-observe on route changes (Vue Router navigation)
router.afterEach(() => {
  nextTick(() => {
    observeScrollReveals()
  })
})

// Auto-detect new scroll-reveal elements added to DOM (e.g. after loading state changes)
const mutationObserver = new MutationObserver((mutations) => {
  let hasNewRevealElements = false
  for (const mutation of mutations) {
    for (const node of mutation.addedNodes) {
      if (node.nodeType === Node.ELEMENT_NODE) {
        if (node.classList && (
          node.classList.contains('scroll-reveal') ||
          node.classList.contains('scroll-reveal-left') ||
          node.classList.contains('scroll-reveal-scale')
        )) {
          hasNewRevealElements = true
        }
        if (node.querySelectorAll) {
          const reveals = node.querySelectorAll('.scroll-reveal, .scroll-reveal-left, .scroll-reveal-scale')
          if (reveals.length) hasNewRevealElements = true
        }
      }
    }
  }
  if (hasNewRevealElements) {
    observeScrollReveals()
  }
})

// Start observing (document.body already exists after app.mount)
mutationObserver.observe(document.body, { childList: true, subtree: true })
