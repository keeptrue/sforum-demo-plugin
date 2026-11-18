<script setup lang="ts">
import { computed, ref } from 'vue'
import type { AdminPageBridgeV1 } from '@sforum/admin-sdk'
import {
  SPluginAlert,
  SPluginButton,
  SPluginEmptyState,
  SPluginField,
  SPluginInput,
  SPluginPage,
  SPluginSection,
  SPluginTable,
  type SPluginTableColumn,
  type SPluginTableRow
} from '@sforum/plugin-ui'

const props = defineProps<{ bridge: AdminPageBridgeV1 }>()

// 中文优先：宿主 locale 以 zh 开头时用中文，其余走英文。
const isChinese = computed(() => props.bridge.locale.toLowerCase().startsWith('zh'))

const copy = computed(() => (isChinese.value
  ? {
      alertTitle: '本页由插件自构建，宿主提供管理端外壳',
      alertBody:
        'AdminDashboard.vue 是插件包内的 Vue SFC，构建后产出 dashboard.mjs 与 dashboard.css。管理端导航、路由、页面标题与权限校验仍由 SForum 宿主负责，插件只渲染页面主体。',
      menuTitle: '菜单注册',
      menuDescription:
        '侧栏菜单项来自 sforum.extension.json 的 admin.pages，而不是前端代码；下表展示的就是这份清单数据。',
      menuEmpty: '清单里没有声明任何管理页',
      columnPath: '路径',
      columnGroup: '分组',
      columnOrder: '排序',
      columnPermission: '权限',
      columnIcon: '图标',
      fieldLabel: '试一试：输入名字',
      fieldDescription: '点击按钮后由宿主弹出成功提示，页面本身不渲染 Toast。',
      inputPlaceholder: '例如：SForum 管理员',
      button: '弹出成功提示',
      toastTitle: '演示成功',
      toastWithName: (name: string) => `你好，${name}！这条提示由 bridge.toast 触发，菜单项仍然只来自 manifest。`,
      toastWithoutName: '这条提示由 bridge.toast 触发；填入名字可以让提示带上称呼。',
      buildTitle: '构建产物',
      buildDescription:
        '宿主只加载构建后的产物，不会编译插件里的 Vue 源码，也不把插件工作区当成 Nuxt Layer。',
      buildEmpty: '还没有构建产物，先运行 sforum extension build',
      columnArtifact: '产物',
      columnKind: '类型',
      columnNote: '说明',
      digestNote:
        '两个产物的 sha256 记录在 sforum.extension.json 的 packageFiles.digest 中；每次构建都会刷新摘要，摘要不符的包不会被加载。'
    }
  : {
      alertTitle: 'This page is built by the plugin; the host owns the admin shell',
      alertBody:
        'AdminDashboard.vue is a Vue SFC inside the package and compiles to dashboard.mjs plus dashboard.css. Navigation, routing, page heading, and permission checks stay with the SForum host; the plugin only renders the page body.',
      menuTitle: 'Menu registration',
      menuDescription:
        'Sidebar entries come from admin.pages in sforum.extension.json, not from frontend code; the table below shows that same manifest data.',
      menuEmpty: 'The manifest declares no admin pages',
      columnPath: 'Path',
      columnGroup: 'Group',
      columnOrder: 'Order',
      columnPermission: 'Permission',
      columnIcon: 'Icon',
      fieldLabel: 'Try it: enter a name',
      fieldDescription: 'The host raises the success toast; the page itself does not render one.',
      inputPlaceholder: 'For example: SForum admin',
      button: 'Show success toast',
      toastTitle: 'Demo completed',
      toastWithName: (name: string) =>
        `Hello ${name}! This toast came from bridge.toast; menu entries still come from the manifest only.`,
      toastWithoutName: 'This toast came from bridge.toast; add a name to personalise it.',
      buildTitle: 'Build artifacts',
      buildDescription:
        'The host loads the built artifacts only; it never compiles the Vue source and never treats this workspace as a Nuxt layer.',
      buildEmpty: 'No build artifacts yet; run sforum extension build first',
      columnArtifact: 'Artifact',
      columnKind: 'Kind',
      columnNote: 'Notes',
      digestNote:
        'Both artifact digests live in packageFiles.digest of sforum.extension.json. Every build refreshes them, and a package whose digest does not match is never loaded.'
    }))

const demoName = ref('')

const menuColumns = computed<SPluginTableColumn[]>(() => [
  { key: 'path', label: copy.value.columnPath, icon: 'i-lucide-route' },
  { key: 'group', label: copy.value.columnGroup, icon: 'i-lucide-folder-tree' },
  { key: 'order', label: copy.value.columnOrder, icon: 'i-lucide-list-ordered', align: 'end' },
  { key: 'permission', label: copy.value.columnPermission, icon: 'i-lucide-shield-check' },
  { key: 'icon', label: copy.value.columnIcon, icon: 'i-lucide-shapes' }
])

// 与 manifest 的 admin.pages 保持一致：改清单时同步这里，避免演示页撒谎。
const menuRows = computed<SPluginTableRow[]>(() => [
  {
    id: '/demo',
    path: '/demo',
    group: '示例',
    order: '10',
    permission: 'sforum.demo-plugin.manage',
    icon: 'i-lucide-sparkles'
  },
  {
    id: '/demo/settings',
    path: '/demo/settings',
    group: '示例',
    order: '20',
    permission: isChinese.value ? '（未声明）' : '(not declared)',
    icon: 'i-lucide-sliders-horizontal'
  }
])

const artifactColumns = computed<SPluginTableColumn[]>(() => [
  { key: 'name', label: copy.value.columnArtifact, icon: 'i-lucide-file-code' },
  { key: 'kind', label: copy.value.columnKind, icon: 'i-lucide-tag' },
  { key: 'note', label: copy.value.columnNote, icon: 'i-lucide-info' }
])

const artifactRows = computed<SPluginTableRow[]>(() => [
  {
    id: 'dashboard.mjs',
    name: 'dashboard.mjs',
    kind: 'ESM',
    note: isChinese.value
      ? '页面入口，宿主按 admin.pages[].component.entry 动态加载'
      : 'Page entry, loaded by the host from admin.pages[].component.entry'
  },
  {
    id: 'dashboard.css',
    name: 'dashboard.css',
    kind: 'CSS',
    note: isChinese.value ? '组件样式，与入口一起注入页面主体' : 'Component styles, injected with the entry'
  },
  {
    id: 'build-command',
    name: 'sforum extension build',
    kind: isChinese.value ? '命令' : 'Command',
    note: isChinese.value
      ? '安装依赖、Vite 构建、刷新摘要、校验清单、运行契约测试'
      : 'Install, Vite build, refresh digests, validate, run contract tests'
  }
])

function showToast() {
  const name = demoName.value.trim()
  props.bridge.toast({
    title: copy.value.toastTitle,
    description: name ? copy.value.toastWithName(name) : copy.value.toastWithoutName,
    kind: 'success'
  })
}
</script>

<template>
  <SPluginPage>
    <SPluginAlert tone="info" icon="i-lucide-shield-check" :title="copy.alertTitle">
      {{ copy.alertBody }}
    </SPluginAlert>

    <SPluginSection
      :title="copy.menuTitle"
      :description="copy.menuDescription"
      icon="i-lucide-list-tree"
    >
      <SPluginTable :columns="menuColumns" :rows="menuRows" row-key="id">
        <template #cell-group="{ value }">
          <span class="cell-nowrap">{{ value }}</span>
        </template>
        <template #cell-icon="{ value }">
          <span class="cell-nowrap">{{ value }}</span>
        </template>
        <template #empty>
          <SPluginEmptyState icon="i-lucide-folder-open" :title="copy.menuEmpty" />
        </template>
      </SPluginTable>

      <SPluginField
        :label="copy.fieldLabel"
        :description="copy.fieldDescription"
        for="demo-name"
      >
        <div class="demo-row">
          <div class="demo-row__control">
            <SPluginInput id="demo-name" v-model="demoName" :placeholder="copy.inputPlaceholder" />
          </div>
          <SPluginButton icon="i-lucide-send" @click="showToast">{{ copy.button }}</SPluginButton>
        </div>
      </SPluginField>
    </SPluginSection>

    <SPluginSection
      :title="copy.buildTitle"
      :description="copy.buildDescription"
      icon="i-lucide-package-check"
    >
      <SPluginTable :columns="artifactColumns" :rows="artifactRows" row-key="id">
        <template #empty>
          <SPluginEmptyState icon="i-lucide-package-x" :title="copy.buildEmpty" />
        </template>
      </SPluginTable>
      <p class="demo-note">{{ copy.digestNote }}</p>
    </SPluginSection>
  </SPluginPage>
</template>

<style scoped>
.demo-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
}

.demo-row__control {
  flex: 1 1 14rem;
  min-width: 0;
}

.demo-note {
  margin: 0;
  color: var(--splugin-muted, #64748b);
  font-size: 0.8125rem;
  line-height: 1.5;
}

/* 窄屏下表格按宿主 32rem 最小宽度横向滚动，短值不应再折成两行。 */
.cell-nowrap {
  white-space: nowrap;
}
</style>
