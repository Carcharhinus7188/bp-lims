<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '../utils/request'

const router = useRouter()
const commissions = ref([])
const loading = ref(false)
const statusFilter = ref('')

const user = JSON.parse(localStorage.getItem('user') || '{}')
const canArchive = user.role === '管理员'

async function load() {
  loading.value = true
  try {
    const params = { limit: 200 }
    if (statusFilter.value) params.status = statusFilter.value
    const { data } = await request.get('/commissions', { params })
    commissions.value = data
  } finally {
    loading.value = false
  }
}

function statusTagType(status) {
  if (status === '已入库') return 'success'
  if (status === '已归档') return 'info'
  return 'warning'
}

async function archiveCommission(row) {
  try {
    await ElMessageBox.confirm(
      `确认归档委托 ${row.commission_no} 吗？归档后整单只读，仅限已完结委托。`,
      '归档确认',
      { type: 'warning', confirmButtonText: '确认归档', cancelButtonText: '取消' }
    )
  } catch { return }
  try {
    await request.post(`/commissions/${row.commission_no}/archive`, { note: '' })
    ElMessage.success(`委托 ${row.commission_no} 已归档`)
    await load()
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '归档失败')
  }
}

function goDetail(row) {
  router.push({ name: 'CommissionDetail', params: { id: row.commission_no } })
}

onMounted(load)
</script>

<template>
  <div class="page">
    <div class="page-header">
      <h1>委托与样品管理</h1>
      <div style="display:flex;gap:12px;align-items:center">
        <el-select v-model="statusFilter" placeholder="全部状态" clearable style="width:150px" @change="load">
          <el-option label="已入库" value="已入库" />
          <el-option label="已归档" value="已归档" />
        </el-select>
      </div>
    </div>

    <el-card>
      <el-table :data="commissions" v-loading="loading" stripe empty-text="暂无委托数据">
        <el-table-column prop="commission_no" label="委托编号" width="180" />
        <el-table-column prop="client_name" label="客户名称" width="200" show-overflow-tooltip />
        <el-table-column prop="production_org_name" label="生产单位" width="200" show-overflow-tooltip />
        <el-table-column prop="commission_date" label="委托日期" width="120" />
        <el-table-column prop="status" label="状态" width="110">
          <template #default="{ row }">
            <el-tag :type="statusTagType(row.status)" size="small">{{ row.status }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="created_at" label="创建时间" min-width="160" />
        <el-table-column label="操作" width="180" fixed="right">
          <template #default="{ row }">
            <el-button size="small" text type="primary" @click="goDetail(row)">详情</el-button>
            <el-button
              v-if="canArchive && row.status !== '已归档'"
              size="small" text type="warning" @click="archiveCommission(row)"
            >归档</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>
  </div>
</template>

<style scoped>
.page { max-width: 1200px; }
.page-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}
.page-header h1 { font-size: 22px; font-weight: 600; color: #0F172A; }
</style>
