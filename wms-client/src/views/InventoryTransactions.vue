<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>库存流水</span>
        <el-button @click="$router.push('/inventory')">返回库存查询</el-button>
      </div>
    </template>

    <div class="filter-bar">
      <el-select v-model="fType" placeholder="变动类型" clearable style="width:140px;margin-right:8px">
        <el-option label="入库" value="in" /><el-option label="出库" value="out" />
        <el-option label="移出" value="transfer_out" /><el-option label="移入" value="transfer_in" />
        <el-option label="盘盈" value="gain" /><el-option label="盘亏" value="loss" />
      </el-select>
      <el-date-picker v-model="fDateRange" type="daterange" range-separator="至" start-placeholder="开始日期" end-placeholder="结束日期" value-format="YYYY-MM-DD" style="margin-right:8px" />
      <el-button @click="loadData">查询</el-button>
    </div>

    <el-table :data="list" border stripe v-loading="loading" style="margin-top:12px">
      <el-table-column prop="product_code" label="SKU编码" width="120" />
      <el-table-column prop="product_name" label="物料名称" min-width="160" />
      <el-table-column label="变动类型" width="90">
        <template #default="{ row }">
          <el-tag :type="typeMap[row.type]">{{ typeLabel[row.type] }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="qty_change" label="变动量" width="90">
        <template #default="{ row }">
          <span :style="{ color: row.qty_change > 0 ? '#67C23A' : '#F56C6C' }">{{ row.qty_change > 0 ? '+' : '' }}{{ row.qty_change }}</span>
        </template>
      </el-table-column>
      <el-table-column prop="balance_qty" label="结存" width="90" />
      <el-table-column prop="batch_no" label="批次号" width="110" />
      <el-table-column prop="location_code" label="库位" width="120" />
      <el-table-column prop="reference_type" label="关联单据" width="100" />
      <el-table-column prop="reference_id" label="单据ID" width="80" />
      <el-table-column prop="remark" label="备注" width="120" />
      <el-table-column prop="created_at" label="时间" width="160" />
    </el-table>
    <div class="pagination"><el-pagination v-model:current-page="page" :page-size="pageSize" :total="total" layout="total, prev, pager, next" @current-change="loadData" /></div>
  </el-card>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import api from '../api'
const router = useRouter()
const list = ref<any[]>([]); const loading = ref(false)
const page = ref(1); const total = ref(0); const pageSize = ref(30)
const fType = ref(''); const fDateRange = ref<string[]>([])

const typeMap: Record<string, string> = { in:'success', out:'danger', transfer_out:'warning', transfer_in:'', gain:'success', loss:'danger' }
const typeLabel: Record<string, string> = { in:'入库', out:'出库', transfer_out:'移出', transfer_in:'移入', gain:'盘盈', loss:'盘亏' }

async function loadData() {
  loading.value = true
  try {
    const params: any = { page: page.value, pageSize: pageSize.value, type: fType.value }
    if (fDateRange.value && fDateRange.value.length === 2) {
      params.start_date = fDateRange.value[0]; params.end_date = fDateRange.value[1]
    }
    const { data } = await api.get('/inventory/transactions', { params })
    if (data.code === 0) { list.value = data.data.list; total.value = data.data.total }
  } finally { loading.value = false }
}
onMounted(() => loadData())
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.filter-bar { margin-bottom: 8px; }
.pagination { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
