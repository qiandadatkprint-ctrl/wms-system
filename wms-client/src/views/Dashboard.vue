<template>
  <div class="dashboard">
    <el-row :gutter="16">
      <el-col :span="6" v-for="card in statCards" :key="card.label">
        <el-card :body-style="{ padding: '20px' }" class="stat-card">
          <div class="stat-row">
            <div class="stat-info">
              <p class="stat-label">{{ card.label }}</p>
              <p class="stat-value" :style="{ color: card.color }">{{ card.value }}</p>
            </div>
            <el-icon :size="36" :color="card.color"><component :is="card.icon" /></el-icon>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <el-card style="margin-top:16px">
      <template #header>快捷操作</template>
      <el-row :gutter="12">
        <el-col :span="4" v-for="act in quickActions" :key="act.label">
          <el-button :type="act.type" style="width:100%" @click="$router.push(act.path)">
            <el-icon><component :is="act.icon" /></el-icon> {{ act.label }}
          </el-button>
        </el-col>
      </el-row>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Box, Tickets, DataAnalysis, Warning, Plus, Minus, Refresh, List } from '@element-plus/icons-vue'
import api from '../api'

const statCards = ref([
  { label: '物料SKU数', value: 0, color: '#409EFF', icon: Box },
  { label: '库位总数', value: 0, color: '#67C23A', icon: DataAnalysis },
  { label: '库存总量', value: 0, color: '#E6A23C', icon: Tickets },
  { label: '待处理入库', value: 0, color: '#409EFF', icon: Plus },
  { label: '待处理出库', value: 0, color: '#67C23A', icon: Minus },
  { label: '库存预警', value: 0, color: '#F56C6C', icon: Warning },
])

const quickActions = [
  { label: '新增入库', type: 'primary', path: '/inbound', icon: Plus },
  { label: '新增出库', type: 'success', path: '/outbound', icon: Minus },
  { label: '库存盘点', type: 'warning', path: '/stocktaking', icon: Refresh },
  { label: '查看库存', type: 'info', path: '/inventory', icon: List },
  { label: '操作日志', type: '', path: '/logs', icon: Tickets },
]

onMounted(async () => {
  try {
    const { data } = await api.get('/dashboard/stats')
    if (data.code === 0) {
      const s = data.data
      statCards.value[0].value = s.productCount
      statCards.value[1].value = s.locationCount
      statCards.value[2].value = s.totalQty
      statCards.value[3].value = s.pendingInbound
      statCards.value[4].value = s.pendingOutbound
      statCards.value[5].value = s.alertCount
    }
  } catch { /* ignore */ }
})
</script>

<style scoped>
.stat-card { cursor: pointer; }
.stat-row { display: flex; justify-content: space-between; align-items: center; }
.stat-label { font-size: 13px; color: #909399; margin-bottom: 6px; }
.stat-value { font-size: 28px; font-weight: bold; }
</style>
