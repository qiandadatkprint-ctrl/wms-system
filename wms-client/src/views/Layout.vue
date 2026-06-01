<template>
  <el-container class="layout">
    <!-- 侧边栏 -->
    <el-aside :width="isCollapse ? '64px' : '220px'" class="aside">
      <div class="logo">
        <el-icon :size="22" color="#fff"><Box /></el-icon>
        <span v-if="!isCollapse" class="logo-text">仓储管理系统</span>
      </div>
      <el-menu
        :default-active="route.path"
        :collapse="isCollapse"
        :collapse-transition="false"
        router
        background-color="#1d1e2c"
        text-color="#a0a8c0"
        active-text-color="#fff"
      >
        <el-menu-item index="/dashboard">
          <el-icon><Odometer /></el-icon><span>工作台</span>
        </el-menu-item>
        <el-sub-menu index="base">
          <template #title><el-icon><FolderOpened /></el-icon><span>基础资料</span></template>
          <el-menu-item index="/warehouses">仓库库位</el-menu-item>
          <el-menu-item index="/products">物料管理</el-menu-item>
          <el-menu-item index="/suppliers">供应商</el-menu-item>
          <el-menu-item index="/customers">客户</el-menu-item>
        </el-sub-menu>
        <el-sub-menu index="biz">
          <template #title><el-icon><TakeawayBox /></el-icon><span>仓储作业</span></template>
          <el-menu-item index="/inbound">入库管理</el-menu-item>
          <el-menu-item index="/outbound">出库管理</el-menu-item>
          <el-menu-item index="/transfers">移库管理</el-menu-item>
          <el-menu-item index="/stocktaking">盘点管理</el-menu-item>
        </el-sub-menu>
        <el-sub-menu index="inv">
          <template #title><el-icon><List /></el-icon><span>库存管理</span></template>
          <el-menu-item index="/inventory">库存查询</el-menu-item>
          <el-menu-item index="/inventory/transactions">库存流水</el-menu-item>
          <el-menu-item index="/alerts">库存预警</el-menu-item>
        </el-sub-menu>
        <el-menu-item index="/logs">
          <el-icon><Document /></el-icon><span>操作日志</span>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <!-- 右侧主体 -->
    <el-container>
      <el-header class="header">
        <div class="header-left">
          <el-icon class="collapse-btn" @click="isCollapse = !isCollapse" :size="20">
            <Fold v-if="!isCollapse" /><Expand v-else />
          </el-icon>
          <el-breadcrumb separator="/">
            <el-breadcrumb-item :to="{ path: '/dashboard' }">首页</el-breadcrumb-item>
            <el-breadcrumb-item v-if="breadcrumbParent">{{ breadcrumbParent }}</el-breadcrumb-item>
            <el-breadcrumb-item>{{ pageTitle }}</el-breadcrumb-item>
          </el-breadcrumb>
        </div>
        <div class="header-right">
          <el-tag size="small" :type="roleType" effect="dark">{{ roleLabel }}</el-tag>
          <span class="user-info">{{ authStore.user?.real_name }}</span>
          <el-button type="danger" text size="small" @click="handleLogout">退出</el-button>
        </div>
      </el-header>

      <el-main class="main">
        <router-view />
      </el-main>

      <!-- Footer -->
      <el-footer class="footer" height="32px">
        <span>仓储管理系统 WMS v1.0</span>
        <span>|</span>
        <span>支持扫码枪 · 条码管理 · FIFO · 库存预警</span>
      </el-footer>
    </el-container>

    <!-- 教程面板 -->
    <TutorialPanel />
  </el-container>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { Box } from '@element-plus/icons-vue'
import TutorialPanel from '../components/TutorialPanel.vue'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const isCollapse = ref(false)

const roleMap: Record<string, string> = { admin: '管理员', manager: '主管', operator: '操作员' }
const roleType = computed(() => {
  const t: Record<string, string> = { admin: 'danger', manager: 'warning', operator: '' }
  return t[authStore.user?.role_type] || ''
})
const roleLabel = computed(() => roleMap[authStore.user?.role_type] || '')

const titleMap: Record<string, string> = {
  '/dashboard': '工作台', '/warehouses': '仓库库位管理', '/products': '物料管理',
  '/suppliers': '供应商管理', '/customers': '客户管理', '/inbound': '入库管理',
  '/outbound': '出库管理', '/transfers': '移库管理', '/stocktaking': '盘点管理',
  '/inventory': '库存查询', '/alerts': '库存预警', '/logs': '操作日志',
}
const parentMap: Record<string, string> = {
  '/warehouses': '基础资料', '/products': '基础资料', '/suppliers': '基础资料', '/customers': '基础资料',
  '/inbound': '仓储作业', '/outbound': '仓储作业', '/transfers': '仓储作业', '/stocktaking': '仓储作业',
  '/inventory': '库存管理', '/alerts': '库存管理',
}

const pageTitle = computed(() => {
  const p = route.path
  if (p.startsWith('/inbound/')) return '入库单详情'
  if (p.startsWith('/outbound/')) return '出库单详情'
  if (p.startsWith('/inventory/transactions')) return '库存流水'
  return titleMap[p] || ''
})
const breadcrumbParent = computed(() => {
  const p = route.path
  if (p.startsWith('/inventory/transactions')) return '库存管理'
  return parentMap[p] || ''
})

function handleLogout() { authStore.logout(); router.push('/login') }
</script>

<style scoped>
.layout { height: 100vh; }
.aside { background-color: #1d1e2c; overflow-y: auto; transition: width 0.3s; }
.logo { height: 60px; display: flex; align-items: center; justify-content: center; gap: 8px; border-bottom: 1px solid rgba(255,255,255,0.08); }
.logo-text { color: #fff; font-size: 15px; font-weight: 600; white-space: nowrap; }
.header { background: #fff; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #ebeef5; padding: 0 20px; height: 56px; box-shadow: 0 1px 4px rgba(0,0,0,0.04); }
.header-left { display: flex; align-items: center; gap: 14px; }
.collapse-btn { cursor: pointer; color: #606266; }
.header-right { display: flex; align-items: center; gap: 10px; }
.user-info { font-size: 13px; color: #303133; }
.main { background: #f5f6fa; padding: 16px 20px; overflow-y: auto; min-height: 0; }
.footer { display: flex; align-items: center; justify-content: center; gap: 8px; font-size: 12px; color: #909399; border-top: 1px solid #ebeef5; background: #fff; }
</style>

<style>
.el-menu-item.is-active { background-color: #409EFF !important; }
.el-sub-menu .el-menu { background-color: #161722 !important; }
.el-sub-menu .el-menu-item:hover { background-color: #2a2b3d !important; }
</style>
