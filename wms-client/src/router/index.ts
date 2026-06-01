import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/login', name: 'Login', component: () => import('../views/Login.vue') },
    {
      path: '/',
      component: () => import('../views/Layout.vue'),
      redirect: '/dashboard',
      children: [
        { path: 'dashboard', name: 'Dashboard', component: () => import('../views/Dashboard.vue') },
        { path: 'warehouses', name: 'WarehouseList', component: () => import('../views/WarehouseList.vue') },
        { path: 'products', name: 'ProductList', component: () => import('../views/ProductList.vue') },
        { path: 'suppliers', name: 'SupplierList', component: () => import('../views/SupplierList.vue') },
        { path: 'customers', name: 'CustomerList', component: () => import('../views/CustomerList.vue') },
        { path: 'inbound', name: 'InboundList', component: () => import('../views/InboundList.vue') },
        { path: 'inbound/:id', name: 'InboundDetail', component: () => import('../views/InboundDetail.vue') },
        { path: 'outbound', name: 'OutboundList', component: () => import('../views/OutboundList.vue') },
        { path: 'outbound/:id', name: 'OutboundDetail', component: () => import('../views/OutboundDetail.vue') },
        { path: 'inventory', name: 'InventoryList', component: () => import('../views/InventoryList.vue') },
        { path: 'inventory/transactions', name: 'InventoryTransactions', component: () => import('../views/InventoryTransactions.vue') },
        { path: 'transfers', name: 'TransferList', component: () => import('../views/TransferList.vue') },
        { path: 'stocktaking', name: 'StocktakingList', component: () => import('../views/StocktakingList.vue') },
        { path: 'alerts', name: 'AlertList', component: () => import('../views/AlertList.vue') },
        { path: 'logs', name: 'OperationLogs', component: () => import('../views/OperationLogs.vue') },
      ],
    },
  ],
})

router.beforeEach((to, _from, next) => {
  const token = localStorage.getItem('wms_token')
  if (to.path !== '/login' && !token) {
    next('/login')
  } else if (to.path === '/login' && token) {
    next('/dashboard')
  } else {
    next()
  }
})

export default router
