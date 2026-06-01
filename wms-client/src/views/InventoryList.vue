<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>库存查询</span>
        <div>
          <el-input v-model="keyword" placeholder="搜索物料编码/名称/条码" style="width:240px;margin-right:8px" clearable @clear="loadData" />
          <el-button @click="loadData">搜索</el-button>
          <el-button @click="$router.push('/inventory/transactions')">查看流水</el-button>
        </div>
      </div>
    </template>

    <el-table :data="list" border stripe v-loading="loading">
      <el-table-column prop="product_code" label="SKU编码" width="120" />
      <el-table-column prop="product_name" label="物料名称" min-width="160" />
      <el-table-column prop="category" label="分类" width="100" />
      <el-table-column prop="spec" label="规格" width="120" />
      <el-table-column prop="unit" label="单位" width="70" />
      <el-table-column prop="qty" label="库存数量" width="100" />
      <el-table-column prop="location_code" label="库位" width="120" />
      <el-table-column prop="batch_no" label="批次号" width="120" />
      <el-table-column prop="production_date" label="生产日期" width="120">
        <template #default="{ row }">{{ row.production_date || '-' }}</template>
      </el-table-column>
      <el-table-column prop="area_name" label="库区" width="140" />
      <el-table-column prop="warehouse_name" label="仓库" width="120" />
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
const page = ref(1); const total = ref(0); const pageSize = ref(30); const keyword = ref('')

async function loadData() {
  loading.value = true
  try {
    const { data } = await api.get('/inventory', { params: { page: page.value, pageSize: pageSize.value, keyword: keyword.value } })
    if (data.code === 0) { list.value = data.data.list; total.value = data.data.total }
  } finally { loading.value = false }
}
onMounted(() => loadData())
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.pagination { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
