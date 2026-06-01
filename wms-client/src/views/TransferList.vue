<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>移库管理</span>
        <el-button type="primary" @click="showCreate = true">新增移库</el-button>
      </div>
    </template>

    <el-table :data="list" border stripe v-loading="loading">
      <el-table-column prop="transfer_no" label="移库单号" width="170" />
      <el-table-column prop="product_code" label="物料编码" width="120" />
      <el-table-column prop="product_name" label="物料名称" min-width="160" />
      <el-table-column prop="qty" label="数量" width="80" />
      <el-table-column prop="batch_no" label="批次号" width="120" />
      <el-table-column prop="from_location_code" label="源库位" width="120" />
      <el-table-column prop="to_location_code" label="目标库位" width="120" />
      <el-table-column prop="operator_name" label="操作员" width="100" />
      <el-table-column prop="status" label="状态" width="90">
        <template #default="{ row }"><el-tag :type="row.status==='completed'?'success':'info'">{{ row.status==='completed'?'已完成':'草稿' }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="created_at" label="时间" width="160" />
    </el-table>
    <div class="pagination"><el-pagination v-model:current-page="page" :page-size="pageSize" :total="total" layout="total, prev, pager, next" @current-change="loadData" /></div>
  </el-card>

  <!-- 新增移库 -->
  <el-dialog v-model="showCreate" title="新增移库" width="600px">
    <el-form :model="form" label-width="80px">
      <el-form-item label="物料">
        <el-select v-model="selectedProductId" placeholder="选择物料" filterable style="width:100%" @change="onProductChange">
          <el-option v-for="p in products" :key="p.id" :label="`${p.code} ${p.name}`" :value="p.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="源库位">
        <el-select v-model="form.from_location_id" placeholder="选择源库位" style="width:100%">
          <el-option v-for="l in sourceLocations" :key="l.id" :label="`${l.code} (库存:${l.qty})`" :value="l.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="目标库位">
        <el-select v-model="form.to_location_id" placeholder="选择目标库位" filterable style="width:100%">
          <el-option v-for="l in allLocations" :key="l.id" :label="`${l.code} - ${l.area_name}`" :value="l.id" />
        </el-select>
      </el-form-item>
      <el-form-item label="数量"><el-input-number v-model="form.qty" :min="1" style="width:100%" /></el-form-item>
      <el-form-item label="批次号"><el-input v-model="form.batch_no" /></el-form-item>
      <el-form-item label="备注"><el-input v-model="form.remark" /></el-form-item>
    </el-form>
    <template #footer><el-button @click="showCreate=false">取消</el-button><el-button type="primary" @click="createTransfer" :loading="creating">确认移库</el-button></template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import api from '../api'

const list = ref<any[]>([]); const loading = ref(false)
const page = ref(1); const total = ref(0); const pageSize = ref(20)

const showCreate = ref(false); const creating = ref(false)
const products = ref<any[]>([]); const allLocations = ref<any[]>([]); const sourceLocations = ref<any[]>([])
const selectedProductId = ref<number|null>(null)

const form = reactive({ product_id: null as number|null, from_location_id: null as number|null, to_location_id: null as number|null, qty: 1, batch_no: '', remark: '' })

async function loadData() {
  loading.value = true
  try {
    const { data } = await api.get('/transfers', { params: { page: page.value, pageSize: pageSize.value } })
    if (data.code === 0) { list.value = data.data.list; total.value = data.data.total }
  } finally { loading.value = false }
}

async function loadRefs() {
  const [pRes, lRes] = await Promise.all([api.get('/products/all'), api.get('/warehouses/all-locations')])
  if (pRes.data.code === 0) products.value = pRes.data.data
  if (lRes.data.code === 0) allLocations.value = lRes.data.data
}

// 选择物料后，加载该物料有库存的库位
async function onProductChange(val: number) {
  form.product_id = val
  form.from_location_id = null
  sourceLocations.value = []
  if (!val) return
  try {
    const { data } = await api.get('/inventory', { params: { pageSize: 100 } })
    if (data.code === 0) {
      sourceLocations.value = data.data.list.filter((r: any) => r.product_id === val)
    }
  } catch { /* ignore */ }
}

async function createTransfer() {
  creating.value = true
  try {
    const { data } = await api.post('/transfers', form)
    if (data.code === 0) {
      ElMessage.success('移库成功')
      showCreate.value = false
      form.product_id = null; form.from_location_id = null; form.to_location_id = null
      form.qty = 1; form.batch_no = ''; form.remark = ''
      loadData()
    } else { ElMessage.error(data.msg) }
  } catch { ElMessage.error('移库失败') }
  finally { creating.value = false }
}

onMounted(() => { loadData(); loadRefs() })
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.pagination { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
