<template>
  <div class="dashboard">
    <!-- 欢迎横幅 -->
    <div class="welcome-banner">
      <div>
        <h2>欢迎使用仓储管理系统</h2>
        <p>支持扫码枪 · 条码管理 · 先进先出(FIFO) · 实时库存预警</p>
      </div>
      <div class="welcome-tip">
        <el-icon :size="18"><InfoFilled /></el-icon>
        <span>点击右下角 <el-tag size="small" type="primary">?</el-tag> 查看操作教程</span>
      </div>
    </div>

    <!-- 统计卡片 -->
    <el-row :gutter="16" class="stat-row">
      <el-col :span="4" v-for="card in statCards" :key="card.label">
        <div class="stat-card" :style="{ borderTopColor: card.color }">
          <div class="stat-icon" :style="{ background: card.bg }"><el-icon :size="22" :color="card.color"><component :is="card.icon" /></el-icon></div>
          <div class="stat-body">
            <p class="stat-label">{{ card.label }}</p>
            <p class="stat-value" :style="{ color: card.color }">{{ card.value }}</p>
          </div>
        </div>
      </el-col>
    </el-row>

    <el-row :gutter="16" style="margin-top:16px">
      <!-- 快捷操作 -->
      <el-col :span="16">
        <el-card shadow="never">
          <template #header><div class="card-title"><el-icon><Grid /></el-icon> 快捷操作</div></template>
          <el-row :gutter="10">
            <el-col :span="6" v-for="act in quickActions" :key="act.label">
              <div class="quick-btn" @click="$router.push(act.path)">
                <el-icon :size="24" :color="act.color"><component :is="act.icon" /></el-icon>
                <span>{{ act.label }}</span>
                <small>{{ act.desc }}</small>
              </div>
            </el-col>
          </el-row>
        </el-card>
      </el-col>

      <!-- 新手引导 -->
      <el-col :span="8">
        <el-card shadow="never">
          <template #header><div class="card-title"><el-icon><Guide /></el-icon> 新手指引</div></template>
          <div class="guide-list">
            <div class="guide-item" v-for="(g, i) in guides" :key="i">
              <div class="guide-num">{{ i + 1 }}</div>
              <div class="guide-text">
                <strong>{{ g.title }}</strong>
                <p>{{ g.desc }}</p>
              </div>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { Box, Tickets, DataAnalysis, Warning, Plus, Minus, Refresh, List, Grid, Guide, InfoFilled } from '@element-plus/icons-vue'
import api from '../api'

const statCards = ref([
  { label: '物料SKU数', value: 0, color: '#409EFF', bg: '#ecf5ff', icon: Box },
  { label: '库位总数', value: 0, color: '#67C23A', bg: '#f0f9eb', icon: DataAnalysis },
  { label: '库存总量', value: 0, color: '#E6A23C', bg: '#fdf6ec', icon: Tickets },
  { label: '待处理入库', value: 0, color: '#409EFF', bg: '#ecf5ff', icon: Plus },
  { label: '待处理出库', value: 0, color: '#67C23A', bg: '#f0f9eb', icon: Minus },
  { label: '库存预警', value: 0, color: '#F56C6C', bg: '#fef0f0', icon: Warning },
])

const quickActions = [
  { label: '采购入库', desc: '收货上架', type: 'primary', color: '#409EFF', path: '/inbound', icon: Plus },
  { label: '销售出库', desc: '拣货发货', color: '#67C23A', path: '/outbound', icon: Minus },
  { label: '库存盘点', desc: '核对库存', color: '#E6A23C', path: '/stocktaking', icon: Refresh },
  { label: '库存查询', desc: '实时库存', color: '#909399', path: '/inventory', icon: List },
]

const guides = [
  { title: '创建物料档案', desc: '在"物料管理"中添加商品/SKU信息，设置安全库存预警线' },
  { title: '执行入库操作', desc: '创建采购入库单，到货后扫码确认收货并上架' },
  { title: '执行出库操作', desc: '创建销售出库单，系统FIFO自动分配拣货方案' },
  { title: '定期盘点核对', desc: '按周/月创建盘点任务，确保系统库存与实物一致' },
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
.welcome-banner {
  background: linear-gradient(135deg, #409EFF 0%, #337ecc 100%);
  color: #fff; padding: 18px 24px; border-radius: 8px; margin-bottom: 16px;
  display: flex; justify-content: space-between; align-items: center;
}
.welcome-banner h2 { font-size: 18px; margin: 0 0 4px; }
.welcome-banner p { font-size: 13px; opacity: 0.85; margin: 0; }
.welcome-tip { display: flex; align-items: center; gap: 6px; font-size: 12px; opacity: 0.9; }
.stat-row { margin-top: 0; }
.stat-card {
  background: #fff; border-radius: 8px; padding: 18px 14px;
  border-top: 3px solid; display: flex; align-items: center; gap: 12px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.06); cursor: pointer; transition: all 0.2s;
}
.stat-card:hover { transform: translateY(-2px); box-shadow: 0 4px 12px rgba(0,0,0,0.1); }
.stat-icon { width: 42px; height: 42px; border-radius: 10px; display: flex; align-items: center; justify-content: center; flex-shrink: 0; }
.stat-body { flex: 1; min-width: 0; }
.stat-label { font-size: 12px; color: #909399; margin: 0 0 4px; }
.stat-value { font-size: 24px; font-weight: 700; margin: 0; line-height: 1; }
.card-title { display: flex; align-items: center; gap: 6px; font-size: 15px; font-weight: 600; color: #303133; }
.quick-btn {
  display: flex; flex-direction: column; align-items: center; gap: 6px; padding: 16px 8px;
  border-radius: 8px; cursor: pointer; transition: all 0.2s; border: 1px solid #ebeef5;
}
.quick-btn:hover { background: #f5f7fa; border-color: #409EFF; }
.quick-btn span { font-size: 13px; font-weight: 500; color: #303133; }
.quick-btn small { font-size: 11px; color: #909399; }
.guide-list { display: flex; flex-direction: column; gap: 12px; }
.guide-item { display: flex; gap: 12px; align-items: flex-start; }
.guide-num { width: 22px; height: 22px; border-radius: 50%; background: #409EFF; color: #fff; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 600; flex-shrink: 0; margin-top: 1px; }
.guide-text strong { font-size: 13px; color: #303133; display: block; margin-bottom: 2px; }
.guide-text p { font-size: 12px; color: #909399; margin: 0; }
</style>
