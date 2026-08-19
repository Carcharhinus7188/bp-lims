<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '../utils/request'
import { chinaDate } from '../utils/time'
import { Search, Plus, Edit, Delete } from '@element-plus/icons-vue'

const user = JSON.parse(localStorage.getItem('user') || '{}')
const canManage = computed(() => user.role === '管理员' || user.role === '样品管理员')
const isAdmin = computed(() => user.role === '管理员')

const equipment = ref([])
const loading = ref(true)
const searchText = ref('')
const showDisabled = ref(false)

// 新增/编辑对话框
const dialogVisible = ref(false)
const editMode = ref(false)
const editingId = ref(null)
const saving = ref(false)
const dialogTitle = computed(() => editMode.value ? '编辑设备' : '新增设备')
const form = ref({
  management_no: '', equipment_name: '', model: '',
  measuring_range: '', manufacturer: '', serial_no: '',
  purchase_time: '', calibration_time: '', calibration_due: '',
  calibration_certificate: '', responsible: '', equipment_class: '',
  lifecycle_status: '正常', notes: '',
})

async function loadEquipment() {
  loading.value = true
  try {
    const { data } = await request.get('/equipment', {
      params: {
        search: searchText.value || undefined,
        include_disabled: showDisabled.value,
        limit: 200,
      },
    })
    equipment.value = data
  } finally {
    loading.value = false
  }
}

function resetForm() {
  form.value = {
    management_no: '', equipment_name: '', model: '',
    measuring_range: '', manufacturer: '', serial_no: '',
    purchase_time: '', calibration_time: '', calibration_due: '',
    calibration_certificate: '', responsible: '', equipment_class: '',
    lifecycle_status: '正常', notes: '',
  }
}

function showAddDialog() {
  editMode.value = false
  editingId.value = null
  resetForm()
  dialogVisible.value = true
}

function openEdit(row) {
  editMode.value = true
  editingId.value = row.management_no
  form.value = {
    management_no: row.management_no || '',
    equipment_name: row.equipment_name || '',
    model: row.model || '',
    measuring_range: row.measuring_range || '',
    manufacturer: row.manufacturer || '',
    serial_no: row.serial_no || '',
    purchase_time: (row.purchase_time || '').slice(0, 10),
    calibration_time: (row.calibration_time || '').slice(0, 10),
    calibration_due: (row.calibration_due || '').slice(0, 10),
    calibration_certificate: row.calibration_certificate || '',
    responsible: row.responsible || '',
    equipment_class: row.equipment_class || '',
    lifecycle_status: row.lifecycle_status || '正常',
    notes: row.notes || '',
  }
  dialogVisible.value = true
}

async function handleSave() {
  const f = form.value
  if (!f.management_no) { ElMessage.warning('请输入管理编号'); return }
  if (!f.equipment_name) { ElMessage.warning('请输入设备名称'); return }

  const payload = {
    equipment_name: f.equipment_name,
    model: f.model || '',
    measuring_range: f.measuring_range || '',
    manufacturer: f.manufacturer || '',
    serial_no: f.serial_no || '',
    purchase_time: f.purchase_time || '',
    calibration_time: f.calibration_time || '',
    calibration_due: f.calibration_due || '',
    calibration_certificate: f.calibration_certificate || '',
    responsible: f.responsible || '',
    equipment_class: f.equipment_class || '',
    lifecycle_status: f.lifecycle_status || '正常',
    notes: f.notes || '',
  }

  saving.value = true
  try {
    if (editMode.value) {
      await request.put(`/equipment/${editingId.value}`, payload)
      ElMessage.success('设备已更新，并已回写历史记录')
    } else {
      payload.management_no = f.management_no
      await request.post('/equipment', payload)
      ElMessage.success('设备添加成功')
    }
    dialogVisible.value = false
    loadEquipment()
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '保存失败')
  } finally {
    saving.value = false
  }
}

async function handleDelete(item) {
  try {
    await ElMessageBox.confirm(
      `确定要删除设备「${item.management_no} ${item.equipment_name}」吗？`,
      '确认删除',
      { type: 'warning', confirmButtonText: '删除', cancelButtonText: '取消' }
    )
    await request.delete(`/equipment/${item.management_no}`)
    ElMessage.success('设备已删除')
    loadEquipment()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error(e.response?.data?.detail || '删除失败')
  }
}

async function toggleEquipment(item) {
  const enabling = !item.enabled
  const verb = enabling ? '启用' : '停用'
  try {
    const { value } = await ElMessageBox.prompt(
      `${verb}设备「${item.management_no} ${item.equipment_name}」，请填写${verb}原因：`,
      `${verb}设备`,
      { confirmButtonText: verb, cancelButtonText: '取消', inputPlaceholder: `${verb}原因（可选）` }
    )
    await request.post(`/equipment/${item.management_no}/${enabling ? 'enable' : 'disable'}`, { note: value || '' })
    ElMessage.success(`设备已${verb}`)
    loadEquipment()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error(e.response?.data?.detail || `${verb}失败`)
  }
}

onMounted(loadEquipment)

function getLifecycleType(status) {
  const map = { '正常': 'success', '启用': 'success', '停用': 'warning', '维修': 'danger', '报废': 'info' }
  return map[status] || 'info'
}

// 校准有效期是否已过期（供列表高亮；未填视为未到期，避免误报存量数据）
function isCalibrationExpired(row) {
  const due = (row.calibration_due || '').trim()
  if (!due) return false
  const iso = due.slice(0, 10)
  if (!/^\d{4}-\d{2}-\d{2}$/.test(iso)) return false
  return iso < chinaDate()
}
</script>

<template>
  <div class="page">
    <div class="page-header">
      <h1>设备库</h1>
      <div style="display:flex;gap:12px;align-items:center">
        <el-button v-if="canManage" type="primary" :icon="Plus" @click="showAddDialog">新增设备</el-button>
        <el-checkbox v-if="isAdmin" v-model="showDisabled" @change="loadEquipment">显示停用设备</el-checkbox>
        <el-input
          v-model="searchText"
          placeholder="搜索设备名称/编号/型号..."
          style="width:300px"
          clearable
          @input="loadEquipment"
        >
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
      </div>
    </div>

    <el-card>
      <el-table :data="equipment" v-loading="loading" stripe empty-text="暂无数据" max-height="600">
        <el-table-column prop="management_no" label="管理编号" width="130" />
        <el-table-column prop="equipment_name" label="设备名称" min-width="180" />
        <el-table-column prop="model" label="型号" width="150" />
        <el-table-column prop="measuring_range" label="测量范围" width="150" />
        <el-table-column prop="manufacturer" label="制造商" width="150" />
        <el-table-column prop="serial_no" label="序列号" width="130" />
        <el-table-column prop="equipment_class" label="分类" width="100">
          <template #default="{ row }">
            <el-tag size="small">{{ row.equipment_class }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="calibration_time" label="校准日期" width="120" />
        <el-table-column label="校准有效期" width="140">
          <template #default="{ row }">
            <el-tag v-if="isCalibrationExpired(row)" type="danger" size="small">已过期 {{ row.calibration_due }}</el-tag>
            <span v-else-if="row.calibration_due" style="color:#64748B">{{ row.calibration_due }}</span>
            <span v-else style="color:#CBD5E1">—</span>
          </template>
        </el-table-column>
        <el-table-column prop="responsible" label="负责人" width="100" />
        <el-table-column prop="lifecycle_status" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="getLifecycleType(row.lifecycle_status)" size="small">{{ row.lifecycle_status }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column v-if="isAdmin" label="启用" width="70">
          <template #default="{ row }">
            <el-tag :type="row.enabled ? 'success' : 'danger'" size="small">{{ row.enabled ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column v-if="canManage" label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button text type="primary" :icon="Edit" @click.stop="openEdit(row)">编辑</el-button>
            <el-button v-if="isAdmin" text :type="row.enabled ? 'warning' : 'success'" @click.stop="toggleEquipment(row)">
              {{ row.enabled ? '停用' : '启用' }}
            </el-button>
            <el-button text type="danger" :icon="Delete" @click.stop="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑设备对话框 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="600px" :close-on-click-modal="false">
      <el-form :model="form" label-width="100px">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="管理编号" required>
              <el-input v-model="form.management_no" placeholder="如 EQ-2026-001" :disabled="editMode" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="设备名称" required>
              <el-input v-model="form.equipment_name" placeholder="如 万能试验机" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="型号">
              <el-input v-model="form.model" placeholder="如 Instron 5982" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="序列号">
              <el-input v-model="form.serial_no" placeholder="序列号" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="测量范围">
              <el-input v-model="form.measuring_range" placeholder="如 0-100kN" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="制造商">
              <el-input v-model="form.manufacturer" placeholder="如 Instron" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="分类">
              <el-input v-model="form.equipment_class" placeholder="如 力学、金相" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="状态">
              <el-select v-model="form.lifecycle_status" style="width:100%">
                <el-option label="正常" value="正常" />
                <el-option label="停用" value="停用" />
                <el-option label="维修" value="维修" />
              </el-select>
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="采购日期">
              <el-input v-model="form.purchase_time" type="date" style="width:100%" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="校准日期">
              <el-input v-model="form.calibration_time" type="date" style="width:100%" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="校准有效期">
              <el-input v-model="form.calibration_due" type="date" style="width:100%" placeholder="校准有效期至（用于检测门禁）" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="校准证书">
              <el-input v-model="form.calibration_certificate" placeholder="证书编号" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="负责人">
          <el-input v-model="form.responsible" placeholder="负责人用户名" />
        </el-form-item>
        <el-form-item label="备注">
          <el-input v-model="form.notes" type="textarea" :rows="2" placeholder="备注信息" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="dialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleSave" :loading="saving">{{ editMode ? '保存' : '添加' }}</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.page { max-width: 1600px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; }
.page-header h1 { font-size: 22px; font-weight: 600; color: #0F172A; }
</style>
