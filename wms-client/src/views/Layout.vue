<template>
  <el-container class="layout">
    <el-aside :width="isCollapse ? '64px' : '220px'" class="aside">
      <div class="logo">
        <span v-if="!isCollapse">📦 WMS</span>
        <span v-else>📦</span>
      </div>
      <el-menu
        :default-active="route.path"
        :collapse="isCollapse"
        :collapse-transition="false"
        router
        background-color="#304156"
        text-color="#bfcbd9"
        active-text-color="#409EFF"
      >
        <el-menu-item index="/dashboard">
          <el-icon><Odometer /></el-icon><span>工作台</span>
        </el-menu-item>

        <el-sub-menu index="base">
          <template #title><el-icon><Setting /></el-icon><span>基础资料</span></template>
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
          <template #title><el-icon><List /></el-icon><span>库存</span></template>
          <el-menu-item index="/inventory">库存查询</el-menu-item>
          <el-menu-item index="/inventory/transactions">库存流水</el-menu-item>
          <el-menu-item index="/alerts">库存预警</el-menu-item>
        </el-sub-menu>

        <el-menu-item index="/logs">
          <el-icon><Document /></el-icon><span>操作日志</span>
        </el-menu-item>
      </el-menu>
    </el-aside>

    <el-container>
      <el-header class="header">
        <div class="header-left">
          <el-icon class="collapse-btn" @click="isCollapse = !isCollapse" :size="20">
            <Fold v-if="!isCollapse" /><Expand v-else />
          </el-icon>
          <span class="page-title">{{ pageTitle }}</span>
        </div>
        <div class="header-right">
          <span class="user-info">{{ authStore.user?.real_name }}（{{ roleLabel }}）</span>
          <el-button text @click="handleLogout">退出登录</el-button>
        </div>
      </el-header>

      <el-main class="main">
        <router-view />
      </el-main>
    </el-container>
  </el-container>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const isCollapse = ref(false)

const roleMap: Record<string, string> = { admin: '管理员', manager: '主管', operator: '操作员' }
const roleLabel = computed(() => roleMap[authStore.user?.role_type] || '未知')

const titleMap: Record<string, string> = {
  '/dashboard': '工作台', '/warehouses': '仓库库位管理', '/products': '物料管理',
  '/suppliers': '供应商管理', '/customers': '客户管理', '/inbound': '入库管理',
  '/outbound': '出库管理', '/transfers': '移库管理', '/stocktaking': '盘点管理',
  '/inventory': '库存查询', '/alerts': '库存预警', '/logs': '操作日志',
}
const pageTitle = computed(() => {
  const p = route.path
  if (p.startsWith('/inbound/')) return '入库单详情'
  if (p.startsWith('/outbound/')) return '出库单详情'
  if (p.startsWith('/inventory/transactions')) return '库存流水'
  return titleMap[p] || '仓储管理系统'
})

function handleLogout() {
  authStore.logout()
  router.push('/login')
}
</script>

<style scoped>
.layout { height: 100vh; }
.aside { background-color: #304156; overflow-y: auto; }
.logo { height: 60px; display: flex; align-items: center; justify-content: center; color: #fff; font-size: 18px; font-weight: bold; border-bottom: 1px solid rgba(255,255,255,0.1); }
.header { background: #fff; display: flex; align-items: center; justify-content: space-between; border-bottom: 1px solid #e6e6e6; padding: 0 20px; }
.header-left { display: flex; align-items: center; gap: 12px; }
.collapse-btn { cursor: pointer; }
.page-title { font-size: 16px; font-weight: 500; }
.header-right { display: flex; align-items: center; gap: 12px; }
.user-info { font-size: 14px; color: #606266; }
.main { background: #f0f2f5; padding: 20px; overflow-y: auto; }
</style>
