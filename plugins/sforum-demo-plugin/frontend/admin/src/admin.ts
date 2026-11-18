import { ADMIN_MICRO_FRONTEND_API_VERSION } from '@sforum/admin-sdk'
import { definePluginPage } from '@sforum/plugin-ui'
import '@sforum/plugin-ui/style.css'
import AdminDashboard from './AdminDashboard.vue'

// definePluginPage 挂载组件并注入宿主图标解析器；不需要手写 createApp，
// 也不会因为忘记注入而让图标静默消失。
export const { apiVersion, mount } = definePluginPage(
  AdminDashboard,
  ADMIN_MICRO_FRONTEND_API_VERSION
)
