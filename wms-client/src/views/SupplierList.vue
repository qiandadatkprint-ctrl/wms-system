<template>
  <el-card>
    <template #header>
      <div class="card-header">
        <span>供应商管理</span>
        <div>
          <el-input v-model="keyword" placeholder="搜索编码/名称" style="width:200px;margin-right:8px" clearable @clear="load" />
          <el-button @click="load">搜索</el-button>
          <el-button type="primary" @click="open()" v-if="isManager">新增供应商</el-button>
        </div>
      </div>
    </template>
    <el-table :data="list" border stripe v-loading="loading">
      <el-table-column prop="code" label="编码" width="120" />
      <el-table-column prop="name" label="名称" min-width="180" />
      <el-table-column prop="contact_name" label="联系人" width="120" />
      <el-table-column prop="phone" label="电话" width="140" />
      <el-table-column prop="address" label="地址" />
      <el-table-column label="状态" width="80">
        <template #default="{ row }"><el-tag :type="row.status===1?'success':'danger'">{{ row.status===1?'启用':'禁用' }}</el-tag></template>
      </el-table-column>
      <el-table-column label="操作" width="160" v-if="isManager">
        <template #default="{ row }">
          <el-button size="small" @click="open(row)">编辑</el-button>
          <el-button size="small" @click="toggle(row)">{{ row.status===1?'禁用':'启用' }}</el-button>
        </template>
      </el-table-column>
    </el-table>
    <div class="pagination"><el-pagination v-model:current-page="page" :page-size="pageSize" :total="total" layout="total, prev, pager, next" @current-change="load" /></div>
  </el-card>

  <el-dialog v-model="show" :title="editing?'编辑供应商':'新增供应商'" width="500px">
    <el-form :model="form" label-width="80px">
      <el-form-item label="编码"><el-input v-model="form.code" :disabled="editing" /></el-form-item>
      <el-form-item label="名称"><el-input v-model="form.name" /></el-form-item>
      <el-form-item label="联系人"><el-input v-model="form.contact_name" /></el-form-item>
      <el-form-item label="电话"><el-input v-model="form.phone" /></el-form-item>
      <el-form-item label="地址"><el-input v-model="form.address" /></el-form-item>
    </el-form>
    <template #footer><el-button @click="show=false">取消</el-button><el-button type="primary" @click="save">保存</el-button></template>
  </el-dialog>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import api from '../api'
import { useAuthStore } from '../stores/auth'
const isManager = useAuthStore().isManager()
const list = ref<any[]>([]); const loading = ref(false)
const page = ref(1); const total = ref(0); const pageSize = ref(20); const keyword = ref('')
const show = ref(false); const editing = ref(false)
const form = reactive({ code: '', name: '', contact_name: '', phone: '', address: '' })

async function load() {
  loading.value = true
  try {
    const { data } = await api.get('/suppliers', { params: { page: page.value, pageSize: pageSize.value, keyword: keyword.value } })
    if (data.code === 0) { list.value = data.data.list; total.value = data.data.total }
  } finally { loading.value = false }
}
function open(row?: any) {
  if (row) { editing.value = true; Object.assign(form, row) }
  else { editing.value = false; Object.assign(form, { code: '', name: '', contact_name: '', phone: '', address: '' }) }
  show.value = true
}
async function save() {
  if (editing.value) await api.put(`/suppliers/${(form as any).id}`, form)
  else await api.post('/suppliers', form)
  ElMessage.success('保存成功'); show.value = false; load()
}
async function toggle(row: any) {
  await api.put(`/suppliers/${row.id}/status`, { status: row.status === 1 ? 0 : 1 })
  ElMessage.success('操作成功'); load()
}
onMounted(() => load())
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
.pagination { margin-top: 16px; display: flex; justify-content: flex-end; }
</style>
