import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  {
    path: '/login',
    name: 'AdminLogin',
    component: () => import('@/views/Login.vue'),
    meta: { title: '登录' }
  },
  {
    path: '/',
    component: () => import('@/views/Layout.vue'),
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/Dashboard.vue'),
        meta: { title: '数据统计', icon: 'DataAnalysis' }
      },
      {
        path: 'content',
        name: 'ContentManage',
        component: () => import('@/views/ContentManage.vue'),
        meta: { title: '内容管理', icon: 'Document' }
      },
      {
        path: 'content/edit/:id?',
        name: 'ContentEdit',
        component: () => import('@/views/ContentEdit.vue'),
        meta: { title: '内容编辑', icon: 'Edit', hidden: true }
      },
      {
        path: 'review',
        name: 'ContentReview',
        component: () => import('@/views/ContentReview.vue'),
        meta: { title: '内容审核', icon: 'Finished' }
      },
      {
        path: 'users',
        name: 'UserManage',
        component: () => import('@/views/UserManage.vue'),
        meta: { title: '用户管理', icon: 'User' }
      },
      {
        path: 'settings',
        name: 'SystemSettings',
        component: () => import('@/views/SystemSettings.vue'),
        meta: { title: '系统配置', icon: 'Setting' }
      }
    ]
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach((to, from, next) => {
  document.title = to.meta.title ? `${to.meta.title} - AI Fast 管理后台` : 'AI Fast 管理后台'

  const token = localStorage.getItem('admin_token')
  if (to.path !== '/login' && !token) {
    next('/login')
  } else if (to.path === '/login' && token) {
    next('/dashboard')
  } else {
    next()
  }
})

export default router
