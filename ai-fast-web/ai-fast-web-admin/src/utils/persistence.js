/**
 * localStorage 持久化工具
 * 提供 Store 数据的读写和同步机制
 */

export const STORAGE_KEYS = {
  WORKFLOWS: 'admin_workflows',
  CATEGORIES: 'admin_categories',
  USERS: 'admin_users',
  SYSTEM_CONFIG: 'admin_system_config',
  THEME_MODE: 'admin_theme_mode',
  SIDEBAR_COLLAPSED: 'admin_sidebar_collapsed'
}

/**
 * 从 localStorage 读取数据
 * @param {string} key - 存储 key
 * @param {*} defaultValue - 默认值
 * @returns {*} 解析后的数据或默认值
 */
export function loadData(key, defaultValue = null) {
  try {
    const data = localStorage.getItem(key)
    if (data === null) return defaultValue
    return JSON.parse(data)
  } catch (e) {
    console.warn(`[persistence] 读取 ${key} 失败:`, e)
    return defaultValue
  }
}

/**
 * 将数据保存到 localStorage
 * @param {string} key - 存储 key
 * @param {*} value - 要保存的数据
 */
export function saveData(key, value) {
  try {
    localStorage.setItem(key, JSON.stringify(value))
  } catch (e) {
    console.warn(`[persistence] 保存 ${key} 失败:`, e)
  }
}

/**
 * 从 localStorage 删除数据
 * @param {string} key - 存储 key
 */
export function removeData(key) {
  try {
    localStorage.removeItem(key)
  } catch (e) {
    console.warn(`[persistence] 删除 ${key} 失败:`, e)
  }
}
