<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>出库管理</span>
        <el-button type="primary" @click="showCreate = true">新增出库单</el-button>
      </div>
    </template>

    <div class="filter-bar">
      <el-select v-model="fType" placeholder="出库类型" clearable style="width:130px;margin-right:8px">
        <el-option label="销售出库" value="sale" /><el-option label="领料出库" value="picking" /><el-option label="其他出库" value="other" />
      </el-select>
      <el-select v-model="fStatus" placeholder="状态" clearable style="width:130px;margin-right:8px">
        <el-option label="草稿" value="draft" /><el-option label="拣货中" value="picking" /><el-option label="已完成" value="completed" /><el-option label="已取消" value="cancelled" />
      </el-select>
      <el-input v-model="fKeyword" placeholder="搜索单号" style="width:200px;margin-right:8px" clearable />
      <el-button @click="loadData">搜索</el-button>
    </div>

    <el-table :data="list" border stripe v-loading="loading" style="margin-top:12px">
      <el-table-column prop="order_no" label="出库单号" width="170" />
      <el-table-column label="类型" width="90">
        <template #default="{ row }">{{ { sale:'销售出库', picking:'领料出库', other:'其他出库' }[row.type] }}</template>
      </el-table-column>
      <el-table-column prop="customer_name" label="客户" width="140" />
      <el-table-column prop="warehouse_name" label="仓库" width="120" />
      <el-table-column label="状态" width="90">
        <template #default="{ row }">
          <el-tag :type="statusMap[row.status]">{{ { draft:'草稿', picking:'拣货中', completed:'已完成', cancelled:'已取消' }[row.status] }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="operator_name" label="操作员" width="100" />
      <el-table-column prop="created_at" label="创建时间" width="160" />
      <el-table-column label="操作" width="180" fixed="right">
        <template #default="{ row }">
          <el-button size="small" type="primary" @click="$router.push(`/outbound/${row.id}`)">详情</el-button>
          <el-button size="small" type="danger" @click="cancelOrder(row)" v-if="row.status!=='completed' && row.status!=='cancelled' && isManager">取消</el-button>
        </template>
      </el-table-column>
    </el-table>
    <div class="pagination"><el-pagination v-model:current-page="page" :page-size="pageSize" :total="total" layout="total, prev, pager, next" @current-change="loadData" /></div>
  </el-card>

  <!-- 创建出库单 -->
  <el-dialog v-model="showCreate" title="新增出库单" width="700px" :close-on-click-modal="false">
    <el-form :model="createForm" label-width="80px">
      <el-row :gutter="12">
        <el-col :span="8"><el-form-item label="出库类型"><el-select v-model="createForm.type" style="width:100%"><el-option label="销售出库" value="sale" /><el-option label="领料出库" value="picking" /><el-option label="其他出库" value="other" /></el-select></el-form-item></el-col>
        <el-col :span="8"><el-form-item label="客户"><el-select v-model="createForm.customer_id" style="width:100%" filterable clearable><el-option v-for="c in customers" :key="c.id" :label="c.name" :value="c.id" /></el-select></el-form-item></el-col>
        <el-col :span="8"><el-form-item label="仓库"><el-select v-model="createForm.warehouse_id" style="width:100%"><el-option v-for="w in warehouses" :key="w.id" :label="w.name" :value="w.id" /></el-select></el-form-item></el-col>
      </el-row>
      <el-form-item label="备注"><el-input v-model="createForm.remark" /></el-form-item>

      <el-divider>出库明细</el-divider>
      <div v-for="(item, idx) in createForm.items" :key="idx" class="item-row">
        <el-select v-model="item.product_id" placeholder="选择物料" filterable style="width:240px">
          <el-option v-for="p in products" :key="p.id" :label="`${p.code} ${p.name}`" :value="p.id" />
        </el-select>
        <el-input-number v-model="item.ordered_qty" :min="1" placeholder="数量" style="width:130px;margin-left:8px" />
        <el-button type="danger" circle :icon="Delete" size="small" style="margin-left:8px" @click="createForm.items.splice(idx,1)" :disabled="createForm.items.length<=1" />
      </div>
      <el-button type="primary" link @click="createForm.items.push({ product_id: null, ordered_qty: 1 })">+ 添加明细</el-button>
    </el-form>
    <template #footer><el-button @click="showCreate = false">取消</el-button><el-button type="primary" @click="createOrder" :loading="creating">创建出库单</el-button></template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Delete } from '@element-plus/icons-vue'
import api from '../api'
import { useAuthStore } from '../stores/auth'
import { useRouter } from 'vue-router'
const $router = useRouter()
const isManager = useAuthStore().isManager()
const list = ref<any[]>([]); const loading = ref(false)
const page = ref(1); const total = ref(0); const pageSize = ref(20)
const fType = ref(''); const fStatus = ref(''); const fKeyword = ref('')
const statusMap: Record<string, string> = { draft:'info', picking:'warning', completed:'success', cancelled:'danger' }

const showCreate = ref(false); const creating = ref(false)
const customers = ref<any[]>([]); const warehouses = ref<any[]>([]); const products = ref<any[]>([])
const createForm = reactive({ type: 'sale', customer_id: null as number|null, warehouse_id: null as number|null, remark: '' as string, items: [{ product_id: null, ordered_qty: 1 }] as any[] })

async function loadData() {
  loading.value = true
  try {
    const { data } = await api.get('/outbound', { params: { page: page.value, pageSize: pageSize.value, type: fType.value, status: fStatus.value, keyword: fKeyword.value } })
    if (data.code === 0) { list.value = data.data.list; total.value = data.data.total }
  } finally { loading.value = false }
}
async function loadRefs() {
  const [cRes, wRes, pRes] = await Promise.all([api.get('/customers/all'), api.get('/warehouses'), api.get('/products/all')])
  if (cRes.data.code === 0) customers.value = cRes.data.data
  if (wRes.data.code === 0) warehouses.value = wRes.data.data
  if (pRes.data.code === 0) products.value = pRes.data.data
}
async function createOrder() {
  creating.value = true
  try {
    const { data } = await api.post('/outbound', createForm)
    if (data.code === 0) {
      ElMessage.success('出库单创建成功')
      showCreate.value = false
      createForm.items = [{ product_id: null, ordered_qty: 1 }]
      loadData()
      if (data.data?.id) $router.push(`/outbound/${data.data.id}`)
    } else { ElMessage.error(data.msg) }
  } catch { ElMessage.error('创建失败') }
  finally { creating.value = false }
}
async function cancelOrder(row: any) {
  try { await ElMessageBox.confirm('确认取消？', '提示', { type: 'warning' }) } catch { return }
  await api.put(`/outbound/${row.id}/cancel`)
  ElMessage.success('已取消'); loadData()
}
onMounted(() => { loadData(); loadRefs() })
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.filter-bar { margin-bottom: 8px; }
.pagination { margin-top: 16px; display: flex; justify-content: flex-end; }
.item-row { display: flex; align-items: center; margin-bottom: 8px; }
</style>
