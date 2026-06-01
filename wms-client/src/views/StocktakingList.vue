<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>盘点管理</span>
        <div>
          <el-select v-model="fStatus" placeholder="状态筛选" clearable style="width:130px;margin-right:8px">
            <el-option label="已创建" value="created" /><el-option label="盘点中" value="counting" />
            <el-option label="复核中" value="reviewing" /><el-option label="已完成" value="completed" />
          </el-select>
          <el-button @click="loadTasks">查询</el-button>
          <el-button type="primary" @click="showCreate = true" v-if="isManager">创建盘点任务</el-button>
        </div>
      </div>
    </template>

    <el-table :data="tasks" border stripe v-loading="loading" @row-click="loadItems" highlight-current-row>
      <el-table-column prop="task_no" label="盘点单号" width="160" />
      <el-table-column prop="warehouse_name" label="仓库" width="120" />
      <el-table-column label="类型" width="90">
        <template #default="{ row }">{{ { full:'全盘', partial:'抽盘', dynamic:'动盘' }[row.type] }}</template>
      </el-table-column>
      <el-table-column label="状态" width="100">
        <template #default="{ row }">
          <el-tag :type="statusMap[row.status]">{{ { created:'已创建', counting:'盘点中', reviewing:'复核中', completed:'已完成' }[row.status] }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="operator_name" label="盘点员" width="100" />
      <el-table-column prop="created_at" label="创建时间" width="160" />
      <el-table-column label="操作" width="120" v-if="isManager">
        <template #default="{ row }">
          <el-button size="small" type="success" @click.stop="confirmTask(row)" v-if="row.status==='counting'||row.status==='reviewing'">确认调整</el-button>
        </template>
      </el-table-column>
    </el-table>
    <div class="pagination"><el-pagination v-model:current-page="page" :page-size="pageSize" :total="total" layout="total, prev, pager, next" @current-change="loadTasks" /></div>

    <!-- 盘点明细 -->
    <el-divider v-if="currentTask" />
    <div v-if="currentTask">
      <h3 style="margin-bottom:12px">盘点明细 — {{ currentTask.task_no }}</h3>
      <el-table :data="items" border stripe>
        <el-table-column prop="product_code" label="SKU编码" width="120" />
        <el-table-column prop="product_name" label="物料名称" min-width="160" />
        <el-table-column prop="location_code" label="库位" width="120" />
        <el-table-column prop="batch_no" label="批次号" width="110" />
        <el-table-column prop="system_qty" label="系统库存" width="100" />
        <el-table-column label="盘点数" width="140">
          <template #default="{ row }">
            <el-input-number v-model="row.actual_qty" :min="0" size="small" @change="saveCount(row)" v-if="currentTask.status!=='completed'" />
            <span v-else>{{ row.actual_qty ?? '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="复核数" width="140">
          <template #default="{ row }">
            <el-input-number v-model="row.review_qty" :min="0" size="small" @change="saveReview(row)" v-if="isManager && (currentTask.status==='counting'||currentTask.status==='reviewing')" />
            <span v-else>{{ row.review_qty ?? '-' }}</span>
          </template>
        </el-table-column>
        <el-table-column label="差异" width="80">
          <template #default="{ row }">
            <span :style="{ color: (row.review_qty??row.actual_qty??row.system_qty) - row.system_qty !== 0 ? '#F56C6C' : '#67C23A', fontWeight: 'bold' }">
              {{ ((row.review_qty??row.actual_qty??row.system_qty) - row.system_qty) || 0 }}
            </span>
          </template>
        </el-table-column>
        <el-table-column label="状态" width="90">
          <template #default="{ row }">
            <el-tag :type="itemStatusMap[row.status]">{{ itemStatusLabel[row.status] }}</el-tag>
          </template>
        </el-table-column>
      </el-table>
    </div>
  </el-card>

  <!-- 创建盘点任务 -->
  <el-dialog v-model="showCreate" title="创建盘点任务" width="600px">
    <el-form :model="createForm" label-width="80px">
      <el-form-item label="仓库"><el-select v-model="createForm.warehouse_id" style="width:100%"><el-option v-for="w in warehouses" :key="w.id" :label="w.name" :value="w.id" /></el-select></el-form-item>
      <el-form-item label="盘点类型"><el-select v-model="createForm.type" style="width:100%"><el-option label="全盘" value="full" /><el-option label="抽盘" value="partial" /><el-option label="动盘（7天内变动）" value="dynamic" /></el-select></el-form-item>
      <el-form-item label="指定物料" v-if="createForm.type==='partial'">
        <el-select v-model="createForm.product_ids" multiple filterable placeholder="不选则盘点全部" style="width:100%">
          <el-option v-for="p in products" :key="p.id" :label="`${p.code} ${p.name}`" :value="p.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="备注"><el-input v-model="createForm.remark" /></el-form-item>
    </el-form>
    <template #footer><el-button @click="showCreate=false">取消</el-button><el-button type="primary" @click="createTask" :loading="creating">创建</el-button></template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import api from '../api'
import { useAuthStore } from '../stores/auth'

const isManager = useAuthStore().isManager()
const tasks = ref<any[]>([]); const loading = ref(false)
const page = ref(1); const total = ref(0); const pageSize = ref(20); const fStatus = ref('')
const statusMap: Record<string, string> = { created:'info', counting:'warning', reviewing:'', completed:'success' }

const currentTask = ref<any>(null); const items = ref<any[]>([])
const itemStatusMap: Record<string, string> = { pending:'info', first_done:'warning', reviewed:'', adjusted:'success' }
const itemStatusLabel: Record<string, string> = { pending:'待盘点', first_done:'已盘点', reviewed:'已复核', adjusted:'已调整' }

const showCreate = ref(false); const creating = ref(false)
const warehouses = ref<any[]>([]); const products = ref<any[]>([])
const createForm = reactive({ warehouse_id: null as number|null, type: 'partial', product_ids: [] as number[], remark: '' })

async function loadTasks() {
  loading.value = true
  try {
    const { data } = await api.get('/stocktaking', { params: { page: page.value, pageSize: pageSize.value, status: fStatus.value } })
    if (data.code === 0) { tasks.value = data.data.list; total.value = data.data.total }
  } finally { loading.value = false }
}

async function loadItems(row: any) {
  currentTask.value = row
  const { data } = await api.get(`/stocktaking/${row.id}`)
  if (data.code === 0) { items.value = data.data.items }
}

async function saveCount(row: any) {
  if (row.actual_qty == null) return
  await api.put(`/stocktaking/${currentTask.value.id}/items/${row.id}/count`, { actual_qty: row.actual_qty })
}

async function saveReview(row: any) {
  if (row.review_qty == null) return
  await api.put(`/stocktaking/${currentTask.value.id}/items/${row.id}/review`, { review_qty: row.review_qty })
}

async function confirmTask(row: any) {
  try { await ElMessageBox.confirm('确认盘点结果将调整库存，确定吗？', '确认盘点', { type: 'warning' }) } catch { return }
  try {
    const { data } = await api.post(`/stocktaking/${row.id}/confirm`)
    if (data.code === 0) {
      ElMessage.success('盘点确认完成，库存已调整')
      loadTasks()
      if (currentTask.value?.id === row.id) currentTask.value = null
      items.value = []
    } else { ElMessage.error(data.msg) }
  } catch { ElMessage.error('确认失败') }
}

async function createTask() {
  creating.value = true
  try {
    const { data } = await api.post('/stocktaking', createForm)
    if (data.code === 0) {
      ElMessage.success(`盘点任务创建成功，共${data.data.items_count}条明细`)
      showCreate.value = false
      createForm.product_ids = []; createForm.remark = ''
      loadTasks()
    } else { ElMessage.error(data.msg) }
  } catch { ElMessage.error('创建失败') }
  finally { creating.value = false }
}

async function loadRefs() {
  const [wRes, pRes] = await Promise.all([api.get('/warehouses'), api.get('/products/all')])
  if (wRes.data.code === 0) warehouses.value = wRes.data.data
  if (pRes.data.code === 0) products.value = pRes.data.data
}

onMounted(() => { loadTasks(); loadRefs() })
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; flex-wrap: wrap; gap: 8px; }
.pagination { margin-top: 16px; display: flex; justify-content: flex-end; }
h3 { font-size: 16px; font-weight: 500; }
</style>
