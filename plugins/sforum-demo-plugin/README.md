# SForum 示例插件

SForum 示例插件：演示「管理端菜单注册 + 自构建前端页面」，纯前端实现，不含任何后端代码。

- 扩展 ID：`sforum.demo-plugin`
- 类型：`plugin`
- 清单契约：`sforum.manifest@3`
- 仓库：https://github.com/keeptrue/sforum-demo-plugin

## 注册的管理页

两个页面都声明在 `sforum.extension.json` 的 `admin.pages` 里，`menu: true` 且 `group: "示例"`，
因此会收进侧栏同一个「示例」分组；`admin.entry` 指向 `/demo`，也就是扩展管理入口的落地页。

| 路径 | 名称 | 视图 | 权限 | 排序 |
| --- | --- | --- | --- | --- |
| `/demo` | 示例面板 | `component`（插件自构建页面） | `sforum.demo-plugin.manage` | 10 |
| `/demo/settings` | 示例设置 | `settings`（宿主渲染的设置文档） | 未声明，沿用宿主设置页策略 | 20 |

侧栏菜单项完全由清单决定，前端代码不参与注册；`/demo` 的页面主体由插件自己的构建产物渲染，
`/demo/settings` 则由宿主按 `settings` 字段渲染成表单，插件不需要为它写任何界面代码。

## 自构建前端页面

`frontend/admin/src/AdminDashboard.vue` 使用 `@sforum/plugin-ui` 组件，`admin.ts` 通过
`definePluginPage` 导出宿主约定的 `apiVersion` 与 `mount`，Vite 把它编译成页面主体产物：

- `frontend/admin/dist/dashboard.mjs` — 页面入口
- `frontend/admin/dist/dashboard.css` — 组件样式

宿主的管理端外壳（侧栏、顶栏、页标题、路由守卫、权限校验）始终由 SForum 负责；插件只渲染
页面主体，拿不到也不需要这些能力。生产环境只加载 `dist` 下的产物，不会编译 Vue 源码，也不会
把本工作区当成 Nuxt Layer。

页面内的文案按 `bridge.locale` 切换：以 `zh` 开头用中文，其余用英文。

## 构建与校验

```bash
sforum extension build .
```

作者侧构建命令会依次完成：安装 `frontend/admin` 依赖（有锁文件时用 `--frozen-lockfile`）、
运行 Vite 构建、刷新 `packageFiles` 里的精确摘要、校验清单、运行宿主契约测试。依赖已经装好时
可以用 `--skip-install` 跳过安装步骤：

```bash
sforum extension build --skip-install .
```

单独跑其中两步：

```bash
sforum extension validate .
sforum extension test .
```

`packageFiles` 中两个产物的 `digest` 由构建自动刷新，不要手写；摘要与文件不一致的包不会被加载。
`frontend/admin/bun.lock` 需要随包提交，保证依赖可复现。

## 无后端

本包不声明 `backend`，也没有 Go 代码、路由、迁移、任务或事件：安装后即可在管理端看到两个菜单页，
不需要构建或启动任何插件进程。
