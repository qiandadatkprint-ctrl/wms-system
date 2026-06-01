<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>操作日志</span>
        <div>
          <el-select v-model="fAction" placeholder="操作类型" clearable style="width:150px;margin-right:8px">
            <el-option v-for="act in actions" :key="act" :label="actionLabel[act] || act" :value="act" />
          </el-select>
          <el-date-picker v-model="fDateRange" type="daterange" range-separator="至" start-placeholder="开始" end-placeholder="结束" value-format="YYYY-MM-DD" style="margin-right:8px" />
          <el-button @click="loadData">查询</el-button>
        </div>
      </div>
    </template>

    <el-table :data="list" border stripe v-loading="loading">
      <el-table-column prop="id" label="ID" width="70" />
      <el-table-column prop="username" label="操作人" width="120" />
      <el-table-column label="操作类型" width="140">
        <template #default="{ row }">
          <el-tag>{{ actionLabel[row.action] || row.action }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column prop="target_type" label="对象类型" width="120" />
      <el-table-column prop="target_id" label="对象ID" width="80" />
      <el-table-column prop="detail" label="详情" min-width="180">
        <template #default="{ row }">
          {{ row.detail?.length > 100 ? row.detail.substring(0, 100) + '...' : row.detail }}
        </template>
      </el-table-column>
      <el-table-column prop="created_at" label="时间" width="170" />
    </el-table>
    <div class="pagination"><el-pagination v-model:current-page="page" :page-size="pageSize" :total="total" layout="total, prev, pager, next" @current-change="loadData" /></div>
  </el-card>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import api from '../api'

const list = ref<any[]>([]); const loading = ref(false)
const page = ref(1); const total = ref(0); const pageSize = ref(30)
const fAction = ref(''); const fDateRange = ref<string[]>([]); const actions = ref<string[]>([])

const actionLabel: Record<string, string> = {
  login:'登录', create_inbound:'创建入库', confirm_inbound:'确认入库',
  create_outbound:'创建出库', confirm_outbound:'确认出库',
  create_transfer:'移库', create_stocktaking:'创建盘点',
}

async function loadData() {
  loading.value = true
  try {
    const params: any = { page: page.value, pageSize: pageSize.value, action: fAction.value }
    if (fDateRange.value && fDateRange.value.length === 2) {
      params.start_date = fDateRange.value[0]; params.end_date = fDateRange.value[1]
    }
    const { data } = await api.get('/logs', { params })
    if (data.code === 0) { list.value = data.data.list; total.value = data.data.total }
  } finally { loading.value = false }
}

async function loadActions() {
  const { data } = await api.get('/logs/actions')
  if (data.code === 0) actions.value = data.data
}

onMounted(() => { loadData(); loadActions() })
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.pagination { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
