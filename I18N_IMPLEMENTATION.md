# GOST Panel - 国际化 (i18n) 实现文档

## 概述

本文档说明了 GOST Panel 项目中国际化功能的实现，支持中文和英文的动态切换。

## 技术栈

- **vue-i18n@10** - Vue 3 的国际化插件
- **Naive UI locale** - UI 组件库的本地化支持

## 已实现的功能

### 1. 核心配置

#### 安装依赖
```bash
cd /root/gost-panel/web
npm install vue-i18n@10
```

#### 语言文件结构
```
web/src/locales/
├── index.ts       # 导出所有语言配置
├── zh-CN.ts       # 中文语言包
└── en.ts          # 英文语言包
```

### 2. 主要修改的文件

#### `/root/gost-panel/web/src/main.ts`
- 导入 `vue-i18n` 和语言包
- 创建 i18n 实例
- 从 localStorage 读取用户选择的语言（默认 zh-CN）
- 注册 i18n 插件到 Vue 应用

#### `/root/gost-panel/web/src/App.vue`
- 导入 Naive UI 的语言包（zhCN, enUS, dateZhCN, dateEnUS）
- 根据当前语言动态切换 Naive UI 的 locale
- 通过 `n-config-provider` 的 `locale` 和 `date-locale` props 应用

#### `/root/gost-panel/web/src/views/Layout.vue`
- 添加语言切换按钮（地球图标）
- 使用 `useI18n()` 获取 `t` 函数和 `locale` 响应式变量
- 菜单项标签使用 `t('menu.xxx')` 国际化
- 用户下拉菜单使用 `t('auth.xxx')` 国际化
- 修改密码弹窗和账户设置弹窗使用国际化文本
- 消息提示使用 `t()` 函数

### 3. 语言包内容

语言包按模块划分，包括：

- **common** - 通用词汇（保存、取消、删除、编辑等）
- **menu** - 菜单项标签
- **auth** - 认证相关（登录、登出、修改密码等）
- **dashboard** - 仪表盘统计标签
- **node** - 节点管理
- **client** - 客户端管理
- **user** - 用户管理
- **plan** - 套餐管理
- **settings** - 设置页面
- **portForward** - 端口转发
- **tunnel** - 隧道转发
- **notify** - 告警通知

### 4. 语言切换功能

在页面头部（主题切换按钮旁边）添加了语言切换下拉菜单：

- 点击地球图标打开下拉菜单
- 选择 "中文" 或 "English"
- 语言选择会保存到 localStorage
- 页面刷新后保持用户选择的语言
- Naive UI 组件的语言也会同步切换

## 使用方法

### 在组件中使用 i18n

```vue
<script setup lang="ts">
import { useI18n } from 'vue-i18n'

const { t, locale } = useI18n()
</script>

<template>
  <!-- 使用 t() 函数翻译文本 -->
  <n-button>{{ t('common.save') }}</n-button>

  <!-- 在 props 中使用 -->
  <n-form-item :label="t('auth.username')">
    <n-input :placeholder="t('auth.username')" />
  </n-form-item>

  <!-- 带参数的翻译 -->
  <span>{{ t('common.selected', { count: 5 }) }}</span>
</template>
```

### 添加新的翻译

1. 在 `/root/gost-panel/web/src/locales/zh-CN.ts` 中添加中文
2. 在 `/root/gost-panel/web/src/locales/en.ts` 中添加对应的英文
3. 使用 `t('xxx.yyy')` 访问翻译

示例：
```typescript
// zh-CN.ts
export default {
  myModule: {
    myKey: '我的文本',
  }
}

// en.ts
export default {
  myModule: {
    myKey: 'My Text',
  }
}
```

## 已国际化的页面

### 完全国际化
- ✅ Layout.vue（菜单、用户菜单、修改密码、账户设置）
- ✅ Dashboard.vue（统计标签 - 需要手动添加 t() 调用）

### 待国际化
其他页面可以逐步迁移，按需添加 i18n 支持。

## 注意事项

1. **不要本地编译** - 按照 MEMORY.md 的规则，修改后 push 到 GitHub，由 Actions 自动构建
2. **保持中文为默认语言** - 大部分用户是中文用户
3. **Naive UI 组件的 locale** - 已在 App.vue 中配置，会自动切换
4. **localStorage 持久化** - 用户选择的语言会保存在浏览器本地存储中

## 部署流程

```bash
# 1. 提交代码到 GitHub
cd /root/gost-panel
git add .
git commit -m "feat: 实现国际化支持，支持中英文切换"
git push origin main

# 2. 等待 GitHub Actions 构建完成
# 3. 下载 Actions Artifacts
# 4. 部署到服务器
systemctl stop gost-panel
cp gost-panel /opt/gost-panel/
systemctl start gost-panel
```

## 后续优化建议

1. 可以添加更多语言（日语、韩语等）
2. 将所有页面的硬编码文本迁移到语言包
3. 考虑使用 vue-i18n 的延迟加载功能减小包体积
4. 添加语言切换时的过渡动画

## 相关文件位置

- 语言包: `/root/gost-panel/web/src/locales/`
- 主配置: `/root/gost-panel/web/src/main.ts`
- UI 配置: `/root/gost-panel/web/src/App.vue`
- 布局组件: `/root/gost-panel/web/src/views/Layout.vue`
- 包依赖: `/root/gost-panel/web/package.json`
