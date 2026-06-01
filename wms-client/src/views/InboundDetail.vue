<template>
  <div>
    <el-button @click="$router.back()" style="margin-bottom:12px">
      <el-icon><ArrowLeft /></el-icon> 返回列表
    </el-button>

    <el-card v-if="order">
      <template #header>
        <div class="card-header">
          <span>入库单详情 — {{ order.order_no }}</span>
          <div>
            <el-tag :type="statusMap[order.status]" size="large">{{ statusLabel[order.status] }}</el-tag>
            <el-button type="danger" size="small" style="margin-left:12px" @click="cancelOrder" v-if="order.status!=='completed'&&order.status!=='cancelled'">取消订单</el-button>
          </div>
        </div>
      </template>

      <el-descriptions :column="4" border>
        <el-descriptions-item label="入库单号">{{ order.order_no }}</el-descriptions-item>
        <el-descriptions-item label="入库类型">{{ typeMap[order.type] }}</el-descriptions-item>
        <el-descriptions-item label="供应商">{{ order.supplier_name || '-' }}</el-descriptions-item>
        <el-descriptions-item label="仓库">{{ order.warehouse_name }}</el-descriptions-item>
        <el-descriptions-item label="操作员">{{ order.operator_name }}</el-descriptions-item>
        <el-descriptions-item label="备注">{{ order.remark || '-' }}</el-descriptions-item>
        <el-descriptions-item label="创建时间">{{ order.created_at }}</el-descriptions-item>
      </el-descriptions>

      <el-divider>入库明细</el-divider>

      <el-table :data="items" border stripe>
        <el-table-column prop="product_code" label="SKU编码" width="120" />
        <el-table-column prop="product_name" label="物料名称" />
        <el-table-column prop="product_unit" label="单位" width="70">
          <template #default="{ row }">{{ row.unit || '个' }}</template>
        </el-table-column>
        <el-table-column prop="expected_qty" label="预期数量" width="100" />
        <el-table-column label="实收数量" width="140">
          <template #default="{ row }">
            <el-input-number v-model="row.actual_qty" :min="0" size="small" v-if="editable" />
            <span v-else>{{ row.actual_qty || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="上架库位" width="160">
          <template #default="{ row }">
            <el-select v-model="row.location_id" size="small" filterable v-if="editable">
              <el-option v-for="l in locations" :key="l.id" :label="l.code" :value="l.id" />
            </el-select>
            <span v-else>{{ row.location_code || '未分配' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="批次号" width="130">
          <template #default="{ row }">
            <el-input v-model="row.batch_no" size="small" v-if="editable" />
            <span v-else>{{ row.batch_no || '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="生产日期" width="140">
          <template #default="{ row }">
            <el-date-picker v-model="row.production_date" type="date" size="small" value-format="YYYY-MM-DD" v-if="editable" />
            <span v-else>{{ row.production_date || '-' }}</span>
          </template>
        </el-table-column>
      </el-table>

      <div style="margin-top:16px;text-align:center" v-if="editable">
        <el-button @click="saveItems">保存明细</el-button>
        <el-button type="success" @click="confirmInbound" :loading="confirming">确认入库（更新库存）</el-button>
      </div>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { ArrowLeft } from '@element-plus/icons-vue'
import api from '../api'

const route = useRoute()
const router = useRouter()
const order = ref<any>(null)
const items = ref<any[]>([])
const locations = ref<any[]>([])
const confirming = ref(false)

const statusMap: Record<string, string> = { draft:'info', receiving:'warning', completed:'success', cancelled:'danger' }
const statusLabel: Record<string, string> = { draft:'草稿', receiving:'收货中', completed:'已完成', cancelled:'已取消' }
const typeMap: Record<string, string> = { purchase:'采购入库', return:'退货入库', other:'其他入库' }

const editable = computed(() => order.value && (order.value.status === 'draft' || order.value.status === 'receiving'))

async function loadData() {
  const { data } = await api.get(`/inbound/${route.params.id}`)
  if (data.code === 0) {
    order.value = data.data.order
    items.value = data.data.items
  } else { ElMessage.error(data.msg); router.back() }
}
async function loadLocations() {
  const { data } = await api.get('/warehouses/all-locations')
  if (data.code === 0) locations.value = data.data
}

async function saveItems() {
  for (const item of items.value) {
    await api.put(`/inbound/${order.value.id}/items/${item.id}`, {
      actual_qty: item.actual_qty,
      location_id: item.location_id,
      batch_no: item.batch_no || '',
      production_date: item.production_date || null,
      expiry_date: null,
    })
  }
  ElMessage.success('明细已保存')
  loadData()
}

async function confirmInbound() {
  try { await ElMessageBox.confirm('确认入库将更新库存，确定吗？', '确认入库', { type: 'warning' }) } catch { return }
  confirming.value = true
  try {
    const { data } = await api.post(`/inbound/${order.value.id}/confirm`)
    if (data.code === 0) {
      ElMessage.success('入库确认成功，库存已更新')
      loadData()
    } else { ElMessage.error(data.msg) }
  } catch { ElMessage.error('确认失败') }
  finally { confirming.value = false }
}

async function cancelOrder() {
  try { await ElMessageBox.confirm('确认取消该入库单？', '提示', { type: 'warning' }) } catch { return }
  await api.put(`/inbound/${order.value.id}/cancel`)
  ElMessage.success('已取消')
  loadData()
}

onMounted(() => { loadData(); loadLocations() })
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
