<template>
  <div>
    <el-button @click="$router.back()" style="margin-bottom:12px">
      <el-icon><ArrowLeft /></el-icon> 返回列表
    </el-button>

    <el-card v-if="order">
      <template #header>
        <div class="card-header">
          <span>出库单详情 — {{ order.order_no }}</span>
          <div>
            <el-tag :type="statusMap[order.status]" size="large">{{ statusLabel[order.status] }}</el-tag>
            <el-button type="danger" size="small" style="margin-left:12px" @click="cancelOrder" v-if="order.status!=='completed'&&order.status!=='cancelled'">取消</el-button>
          </div>
        </div>
      </template>

      <el-descriptions :column="4" border>
        <el-descriptions-item label="出库单号">{{ order.order_no }}</el-descriptions-item>
        <el-descriptions-item label="出库类型">{{ typeMap[order.type] }}</el-descriptions-item>
        <el-descriptions-item label="客户">{{ order.customer_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="仓库">{{ order.warehouse_name }}</el-descriptions-item>
        <el-descriptions-item label="操作员">{{ order.operator_name }}</el-descriptions-item>
        <el-descriptions-item label="备注">{{ order.remark || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ order.created_at }}</el-descriptions-item>
      </el-descriptions>

      <el-divider>出库明细</el-divider>

      <el-table :data="items" border stripe>
        <el-table-column prop="product_code" label="SKU编码" width="120" />
        <el-table-column prop="product_name" label="物料名称" min-width="160" />
        <el-table-column prop="ordered_qty" label="订单数量" width="100" />
        <el-table-column label="拣货库位" width="150">
          <template #default="{ row }">
            <span>{{ row.location_code || '待分配' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="批次号" width="130">
          <template #default="{ row }"><span>{{ row.batch_no || '-' }}</span></template>
        </el-table-column>
        <el-table-column label="实发数量" width="140" v-if="order.status === 'picking'">
          <template #default="{ row }">
            <el-input-number v-model="row.actual_qty" :min="1" :max="row.ordered_qty" size="small" />
          </template>
        </el-table-column>
      </el-table>

      <!-- FIFO按钮和确认 -->
      <div style="margin-top:16px;text-align:center">
        <el-button type="primary" @click="fifoAllocate" :loading="allocating" v-if="order.status === 'draft'">
          <el-icon><MagicStick /></el-icon> FIFO自动分配拣货方案
        </el-button>
        <el-button type="success" @click="confirmOutbound" :loading="confirming" v-if="order.status === 'picking'">
          确认出库（扣减库存）
        </el-button>
      </div>

      <!-- 分配结果展示 -->
      <div v-if="allocations.length > 0" style="margin-top:12px">
        <el-tag type="success">分配结果：</el-tag>
        <div v-for="a in allocations" :key="a.item_id" style="margin-top:4px">
          从库位批次"{{ a.batch_no }}"拣货 {{ a.pick_qty }} 件
        </div>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft, MagicStick } from '@element-plus/icons-vue'
import api from '../api'

const route = useRoute()
const router = useRouter()
const order = ref<any>(null)
const items = ref<any[]>([])
const allocations = ref<any[]>([])
const allocating = ref(false)
const confirming = ref(false)

const statusMap: Record<string, string> = { draft:'info', picking:'warning', completed:'success', cancelled:'danger' }
const statusLabel: Record<string, string> = { draft:'草稿', picking:'拣货中', completed:'已完成', cancelled:'已取消' }
const typeMap: Record<string, string> = { sale:'销售出库', picking:'领料出库', other:'其他出库' }

async function loadData() {
  const { data } = await api.get(`/outbound/${route.params.id}`)
  if (data.code === 0) { order.value = data.data.order; items.value = data.data.items }
  else { ElMessage.error(data.msg); router.back() }
}

async function fifoAllocate() {
  allocating.value = true
  try {
    const { data } = await api.post(`/outbound/${order.value.id}/fifo-allocate`)
    if (data.code === 0) {
      allocations.value = data.data.allocations || []
      ElMessage.success('FIFO分配成功，请确认出库')
      loadData()
    } else {
      ElMessage.error(data.msg)
    }
  } catch { ElMessage.error('分配失败') }
  finally { allocating.value = false }
}

async function confirmOutbound() {
  try { await ElMessageBox.confirm('确认出库将扣减库存，确定吗？', '确认出库', { type: 'warning' }) } catch { return }
  confirming.value = true
  try {
    const { data } = await api.post(`/outbound/${order.value.id}/confirm`)
    if (data.code === 0) {
      ElMessage.success('出库确认成功，库存已更新')
      loadData()
    } else { ElMessage.error(data.msg) }
  } catch { ElMessage.error('确认失败') }
  finally { confirming.value = false }
}

async function cancelOrder() {
  try { await ElMessageBox.confirm('确认取消？', '提示', { type: 'warning' }) } catch { return }
  await api.put(`/outbound/${order.value.id}/cancel`)
  ElMessage.success('已取消')
  loadData()
}

onMounted(() => loadData())
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
