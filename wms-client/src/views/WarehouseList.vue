<template>
  <div>
    <el-card>
      <template #header>
        <div class="card-header">
          <span>仓库 & 库位管理</span>
          <el-button type="primary" @click="showWarehouseDialog = true" v-if="isManager">新增仓库</el-button>
        </div>
      </template>

      <el-tabs v-model="activeTab" type="border-card">
        <!-- 仓库列表 -->
        <el-tab-pane label="仓库列表" name="warehouses">
          <el-table :data="warehouses" border stripe>
            <el-table-column prop="code" label="仓库编码" width="120" />
            <el-table-column prop="name" label="仓库名称" />
            <el-table-column prop="address" label="地址" />
            <el-table-column label="操作" width="200">
              <template #default="{ row }">
                <el-button size="small" @click="loadAreas(row)">查看库区</el-button>
                <el-button size="small" type="primary" @click="editWarehouse(row)" v-if="isManager">编辑</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 库区管理 -->
        <el-tab-pane label="库区管理" name="areas" v-if="currentWarehouse">
          <div style="margin-bottom:12px">
            <span>当前仓库：<b>{{ currentWarehouse.name }}</b></span>
            <el-button size="small" type="primary" style="margin-left:12px" @click="showAreaDialog = true" v-if="isManager">新增库区</el-button>
          </div>
          <el-table :data="areas" border stripe>
            <el-table-column prop="name" label="库区名称" />
            <el-table-column prop="type" label="库区类型">
              <template #default="{ row }">{{ { storage:'存储区', picking:'拣货区', return:'退货区', staging:'待检区' }[row.type] }}</template>
            </el-table-column>
            <el-table-column label="操作" width="250">
              <template #default="{ row }">
                <el-button size="small" @click="loadLocations(row)">查看库位</el-button>
                <el-button size="small" type="primary" @click="editArea(row)" v-if="isManager">编辑</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 库位列表 -->
        <el-tab-pane label="库位详情" name="locations" v-if="currentArea">
          <div style="margin-bottom:12px">
            <span>当前库区：<b>{{ currentArea.name }}</b></span>
            <el-button size="small" type="primary" style="margin-left:12px" @click="showLocationDialog = true" v-if="isManager">新增库位</el-button>
          </div>
          <el-table :data="locations" border stripe>
            <el-table-column prop="code" label="库位编号" width="150" />
            <el-table-column prop="capacity" label="容量上限" width="120" />
            <el-table-column prop="status" label="状态" width="100">
              <template #default="{ row }">
                <el-tag :type="row.status===1?'success':'danger'">{{ row.status===1?'启用':'禁用' }}</el-tag>
              </template>
            </el-table-column>
            <el-table-column label="操作" width="150" v-if="isManager">
              <template #default="{ row }">
                <el-button size="small" @click="editLocation(row)">编辑</el-button>
              </template>
            </el-table-column>
          </el-table>
        </el-tab-pane>
      </el-tabs>
    </el-card>

    <!-- 仓库对话框 -->
    <el-dialog v-model="showWarehouseDialog" :title="editingWarehouse?'编辑仓库':'新增仓库'" width="500px">
      <el-form :model="warehouseForm" label-width="80px">
        <el-form-item label="仓库编码"><el-input v-model="warehouseForm.code" /></el-form-item>
        <el-form-item label="仓库名称"><el-input v-model="warehouseForm.name" /></el-form-item>
        <el-form-item label="地址"><el-input v-model="warehouseForm.address" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showWarehouseDialog = false">取消</el-button>
        <el-button type="primary" @click="saveWarehouse">保存</el-button>
      </template>
    </el-dialog>

    <!-- 库区对话框 -->
    <el-dialog v-model="showAreaDialog" :title="editingArea?'编辑库区':'新增库区'" width="500px">
      <el-form :model="areaForm" label-width="80px">
        <el-form-item label="库区名称"><el-input v-model="areaForm.name" /></el-form-item>
        <el-form-item label="库区类型">
          <el-select v-model="areaForm.type" style="width:100%">
            <el-option label="存储区" value="storage" /><el-option label="拣货区" value="picking" />
            <el-option label="退货区" value="return" /><el-option label="待检区" value="staging" />
          </el-select>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showAreaDialog = false">取消</el-button>
        <el-button type="primary" @click="saveArea">保存</el-button>
      </template>
    </el-dialog>

    <!-- 库位对话框 -->
    <el-dialog v-model="showLocationDialog" :title="editingLocation?'编辑库位':'新增库位'" width="500px">
      <el-form :model="locationForm" label-width="80px">
        <el-form-item label="库位编号"><el-input v-model="locationForm.code" /></el-form-item>
        <el-form-item label="容量上限"><el-input-number v-model="locationForm.capacity" :min="0" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="showLocationDialog = false">取消</el-button>
        <el-button type="primary" @click="saveLocation">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import api from '../api'
import { useAuthStore } from '../stores/auth'

const authStore = useAuthStore()
const isManager = authStore.isManager()

const activeTab = ref('warehouses')
const warehouses = ref<any[]>([])
const areas = ref<any[]>([])
const locations = ref<any[]>([])
const currentWarehouse = ref<any>(null)
const currentArea = ref<any>(null)

// Warehouse CRUD
const showWarehouseDialog = ref(false)
const editingWarehouse = ref<any>(null)
const warehouseForm = reactive({ code: '', name: '', address: '' })

async function loadWarehouses() {
  const { data } = await api.get('/warehouses')
  if (data.code === 0) warehouses.value = data.data
}

function editWarehouse(row: any) {
  editingWarehouse.value = row
  warehouseForm.code = row.code; warehouseForm.name = row.name; warehouseForm.address = row.address
  showWarehouseDialog.value = true
}

async function saveWarehouse() {
  if (editingWarehouse.value) {
    await api.put(`/warehouses/${editingWarehouse.value.id}`, warehouseForm)
  } else {
    await api.post('/warehouses', warehouseForm)
  }
  ElMessage.success('保存成功')
  showWarehouseDialog.value = false
  editingWarehouse.value = null
  warehouseForm.code = ''; warehouseForm.name = ''; warehouseForm.address = ''
  loadWarehouses()
}

// Area CRUD
const showAreaDialog = ref(false)
const editingArea = ref<any>(null)
const areaForm = reactive({ warehouse_id: 0, name: '', type: 'storage' })

async function loadAreas(row: any) {
  currentWarehouse.value = row
  activeTab.value = 'areas'
  const { data } = await api.get(`/warehouses/${row.id}/areas`)
  if (data.code === 0) areas.value = data.data
}

function editArea(row: any) {
  editingArea.value = row
  areaForm.name = row.name; areaForm.type = row.type
  showAreaDialog.value = true
}

async function saveArea() {
  if (editingArea.value) {
    await api.put(`/warehouses/areas/${editingArea.value.id}`, areaForm)
  } else {
    areaForm.warehouse_id = currentWarehouse.value.id
    await api.post('/warehouses/areas', areaForm)
  }
  ElMessage.success('保存成功')
  showAreaDialog.value = false
  editingArea.value = null
  areaForm.name = ''; areaForm.type = 'storage'
  loadAreas(currentWarehouse.value)
}

// Location CRUD
const showLocationDialog = ref(false)
const editingLocation = ref<any>(null)
const locationForm = reactive({ area_id: 0, code: '', capacity: 0 })

async function loadLocations(row: any) {
  currentArea.value = row
  activeTab.value = 'locations'
  const { data } = await api.get(`/warehouses/areas/${row.id}/locations`)
  if (data.code === 0) locations.value = data.data
}

function editLocation(row: any) {
  editingLocation.value = row
  locationForm.code = row.code; locationForm.capacity = row.capacity
  showLocationDialog.value = true
}

async function saveLocation() {
  if (editingLocation.value) {
    await api.put(`/warehouses/locations/${editingLocation.value.id}`, locationForm)
  } else {
    locationForm.area_id = currentArea.value.id
    await api.post('/warehouses/locations', locationForm)
  }
  ElMessage.success('保存成功')
  showLocationDialog.value = false
  editingLocation.value = null
  locationForm.code = ''; locationForm.capacity = 0
  loadLocations(currentArea.value)
}

onMounted(() => loadWarehouses())
</script>

<style scoped>
.card-header { display: flex; justify-content: space-between; align-items: center; }
</style>
