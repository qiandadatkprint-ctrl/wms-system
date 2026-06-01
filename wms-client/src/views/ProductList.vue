<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>物料管理</span>
        <div>
          <el-input v-model="searchKeyword" placeholder="搜索编码/名称/条码" style="width:220px;margin-right:8px" clearable @clear="loadData" />
          <el-button @click="loadData">搜索</el-button>
          <el-button type="primary" @click="openDialog()" v-if="isManager">新增物料</el-button>
        </div>
      </div>
    </template>

    <el-table :data="list" border stripe v-loading="loading">
      <el-table-column prop="code" label="SKU编码" width="130" />
      <el-table-column prop="name" label="品名" min-width="180" />
      <el-table-column prop="barcode" label="条码" width="140" />
      <el-table-column prop="category" label="分类" width="100" />
      <el-table-column prop="spec" label="规格" width="120" />
      <el-table-column prop="unit" label="单位" width="70" />
      <el-table-column prop="safety_stock" label="安全库存" width="90" />
      <el-table-column prop="retail_price" label="参考单价" width="90" />
      <el-table-column label="状态" width="80">
        <template #default="{ row }">
          <el-tag :type="row.status===1?'success':'danger'">{{ row.status===1?'启用':'禁用' }}</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" width="160" fixed="right" v-if="isManager">
        <template #default="{ row }">
          <el-button size="small" @click="openDialog(row)">编辑</el-button>
          <el-button size="small" :type="row.status===1?'danger':''" @click="toggleStatus(row)">
            {{ row.status===1?'禁用':'启用' }}
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <div class="pagination"><el-pagination v-model:current-page="page" :page-size="pageSize" :total="total" layout="total, prev, pager, next" @current-change="loadData" /></div>
  </el-card>

  <el-dialog v-model="dialogVisible" :title="editing?'编辑物料':'新增物料'" width="600px">
    <el-form :model="form" label-width="80px">
      <el-row :gutter="12">
        <el-col :span="12"><el-form-item label="SKU编码"><el-input v-model="form.code" :disabled="editing" /></el-form-item></el-col>
        <el-col :span="12"><el-form-item label="品名"><el-input v-model="form.name" /></el-form-item></el-col>
      </el-row>
      <el-row :gutter="12">
        <el-col :span="12"><el-form-item label="条码"><el-input v-model="form.barcode" placeholder="扫码枪或手动输入" /></el-form-item></el-col>
        <el-col :span="12"><el-form-item label="分类"><el-select v-model="form.category" placeholder="选择分类" style="width:100%" clearable><el-option v-for="c in categoryOptions" :key="c" :label="c" :value="c" /></el-select></el-form-item></el-col>
      </el-row>
      <el-row :gutter="12">
        <el-col :span="12"><el-form-item label="规格"><el-input v-model="form.spec" placeholder="例如：Φ50×3mm×6m" /></el-form-item></el-col>
        <el-col :span="12"><el-form-item label="单位"><el-select v-model="form.unit" placeholder="选择单位" style="width:100%"><el-option v-for="u in unitOptions" :key="u" :label="u" :value="u" /></el-select></el-form-item></el-col>
      </el-row>
      <el-row :gutter="12">
        <el-col :span="8"><el-form-item label="安全库存"><el-input-number v-model="form.safety_stock" :min="0" placeholder="低于此值预警" /></el-form-item></el-col>
        <el-col :span="8"><el-form-item label="最大库存"><el-input-number v-model="form.max_stock" :min="0" placeholder="高于此值预警" /></el-form-item></el-col>
        <el-col :span="8"><el-form-item label="参考单价(元)"><el-input-number v-model="form.retail_price" :min="0" :precision="2" /></el-form-item></el-col>
      </el-row>
    </el-form>
    <template #footer><el-button @click="dialogVisible=false">取消</el-button><el-button type="primary" @click="save">保存</el-button></template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import { ElMessage } from 'element-plus'
import api from '../api'
import { useAuthStore } from '../stores/auth'

const isManager = useAuthStore().isManager()
const list = ref<any[]>([])
const loading = ref(false)
const page = ref(1)
const total = ref(0)
const pageSize = ref(20)
const searchKeyword = ref('')
const categoryOptions = ['原材料', '半成品', '成品', '包装材料', '办公用品', '工具配件', '其他']
const unitOptions = ['个', '箱', '包', 'kg', '吨', '米', '升', '根', '台', '套', '卷', '双', '桶', '张', '支', '件', '盒']

const dialogVisible = ref(false)
const editing = ref(false)
const form = reactive({ code: '', name: '', barcode: '', category: '', spec: '', unit: '个', safety_stock: 0, max_stock: 0, retail_price: 0 })

async function loadData() {
  loading.value = true
  try {
    const { data } = await api.get('/products', { params: { page: page.value, pageSize: pageSize.value, keyword: searchKeyword.value } })
    if (data.code === 0) { list.value = data.data.list; total.value = data.data.total }
  } finally { loading.value = false }
}

function openDialog(row?: any) {
  if (row) {
    editing.value = true
    Object.assign(form, { id: row.id, code: row.code, name: row.name, barcode: row.barcode, category: row.category, spec: row.spec, unit: row.unit, safety_stock: row.safety_stock, max_stock: row.max_stock, retail_price: row.retail_price })
  } else {
    editing.value = false
    Object.assign(form, { id: 0, code: '', name: '', barcode: '', category: '', spec: '', unit: '个', safety_stock: 0, max_stock: 0, retail_price: 0 })
  }
  dialogVisible.value = true
}

async function save() {
  if (editing.value) {
    await api.put(`/products/${(form as any).id}`, form)
  } else {
    await api.post('/products', form)
  }
  ElMessage.success('保存成功')
  dialogVisible.value = false
  loadData()
}

async function toggleStatus(row: any) {
  const newStatus = row.status === 1 ? 0 : 1
  await api.put(`/products/${row.id}/status`, { status: newStatus })
  ElMessage.success(newStatus === 1 ? '已启用' : '已禁用')
  loadData()
}

import { onMounted } from 'vue'
onMounted(() => loadData())
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.pagination { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
