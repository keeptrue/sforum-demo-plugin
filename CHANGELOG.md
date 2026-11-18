# Changelog

本文件记录 SForum Demo Plugin 的变更，格式参照 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，
版本号遵循 [语义化版本](https://semver.org/lang/zh-CN/)。

## [0.1.1] - 2026-11-18

### 变更

- 发布流水线支持条件平台矩阵：清单未声明 `backend` 的插件发一个通用 zip；声明了 `backend` 的插件
  自动按 `linux/amd64`、`linux/arm64`、`darwin/arm64`、`darwin/amd64` 四平台交叉编译、各自刷新摘要
  后打包，资产名带平台后缀。
- CI 与本地脚本同步支持条件构建：`scripts/prepare-package.sh` 与 ci 工作流在清单声明 `backend` 时
  先编译 `backend/plugin`，无后端时跳过；CI 仍只做单平台验证，四平台矩阵只在发布时展开。

## [0.1.0] - 2026-11-18

首个可安装版本：演示 SForum 插件的管理端菜单注册与自构建前端页面。

### 新增

- 管理端菜单注册：`admin.pages[]` 声明 `/demo`（`view: component`、`menu: true`、`group: "示例"`、
  `order: 10`、`permission: sforum.demo-plugin.manage`、`icon: i-lucide-sparkles`）与 `/demo/settings`
  （`view: settings`、`menu: true`、`group: "示例"`、`order: 20`、`icon: i-lucide-sliders-horizontal`，
  无 `permission`）；`admin.entry` 指向 `/demo`。
- 侧栏成组：两个页签的 `group` 同为 `示例`，在后台侧栏合成一个可展开的一级菜单「示例」，
  插在「扩展管理」之后、与内置分组同级；页签路由、图标与权限过滤全部由宿主渲染。
- 权限 `sforum.demo-plugin.manage`：`assignmentPolicy: host`，推荐映射给 `administrator` 角色，
  由宿主授权，安装与启用代码不自行授予。
- Vue 自构建页面：`frontend/admin/src/AdminDashboard.vue` + `@sforum/plugin-ui` 组件，
  经 Vite 构建为 `frontend/admin/dist/dashboard.mjs` 与 `dashboard.css`，
  以 Admin Micro-frontend API v1（`apiVersion = 1`、`mount(target, bridge)`）挂载到宿主页面 body。
- 品牌资产：`brand/icon.svg`、`brand/icon.png` 与 `brand/social-preview.png`，可通过
  `sforum extension brand check` 校验尺寸与字节上限。
- CI 工作流：推送与 PR 构建作者前端、刷新 `packageFiles` 摘要、校验清单并跑宿主契约检查。
- Release 工作流：推 `v*` 标签产出通用 zip 与 `SHA256SUMS`，并校验标签与清单版本一致。

### 说明

- 包内只有前端制品，无 `backend` 字段、无路由、无数据库租约。
- 生产宿主不编译 Vue，只加载 `packageFiles` 中登记的 `dist/*.mjs|*.css`；
  摘要与内容不一致时启用会被拒绝。

[0.1.0]: https://github.com/keeptrue/sforum-demo-plugin/releases/tag/v0.1.0
[0.1.1]: https://github.com/keeptrue/sforum-demo-plugin/releases/tag/v0.1.1
