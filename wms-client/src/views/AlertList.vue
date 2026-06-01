<template>
  <el-card>
    <template #header><span>库存预警</span></template>

    <el-table :data="list" border stripe v-loading="loading" :empty-text="'暂无预警'">
      <el-table-column prop="product_code" label="SKU编码" width="120" />
      <el-table-column prop="product_name" label="物料名称" min-width="180" />
      <el-table-column prop="unit" label="单位" width="70" />
      <el-table-column prop="total_qty" label="当前库存" width="100" />
      <el-table-column prop="safety_stock" label="安全库存" width="100" />
      <el-table-column prop="max_stock" label="最大库存" width="100" />
      <el-table-column label="预警类型" width="110">
        <template #default="{ row }">
          <el-tag :type="row.alert_type==='库存过低'?'danger':'warning'">{{ row.alert_type }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="差距" width="80">
        <template #default="{ row }">
          <span :style="{ color: row.alert_type==='库存过低'?'#F56C6C':'#E6A23C', fontWeight:'bold' }">
            {{ row.alert_type==='库存过低' ? `缺${row.gap}` : `超${row.gap}` }}
          </span>
        </template>
      </el-table-column>
      <el-table-column label="建议" min-width="180">
        <template #default="{ row }">
          {{ row.alert_type==='库存过低' ? '建议尽快采购入库' : '建议暂停采购或促销出库' }}
        </template>
      </el-table-column>
    </el-table>
  </el-card>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import api from '../api'

const list = ref<any[]>([]); const loading = ref(false)

async function loadData() {
  loading.value = true
  try {
    const { data } = await api.get('/inventory/alerts')
    if (data.code === 0) list.value = data.data
  } finally { loading.value = false }
}

onMounted(() => loadData())
</script>
