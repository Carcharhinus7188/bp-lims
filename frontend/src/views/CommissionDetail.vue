<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import request from '../utils/request'
import { materialWithSample } from '../utils/material'
import { formatChinaDateTime } from '../utils/time'

const route = useRoute()
const commission = ref(null)
const loading = ref(true)

const user = JSON.parse(localStorage.getItem('user') || '{}')
const canManageSample = ['样品管理员', '管理员'].includes(user.role)

// ── 留样/处置 ──
const sampleDialogVisible = ref(false)
const sampleAction = ref('retain') // retain | dispose
const sampleTarget = ref(null)
const retainForm = ref({ retention_period: '', retention_until: '' })
const disposeForm = ref({ disposal_type: '销毁', disposal_method: '', disposal_date: '', disposal_note: '' })
const sampleSubmitting = ref(false)

async function load() {
  loading.value = true
  try {
    const { data } = await request.get(`/commissions/${route.params.id}`)
    commission.value = data
  } finally {
    loading.value = false
  }
}

function openRetain(row) {
  sampleAction.value = 'retain'
  sampleTarget.value = row
  retainForm.value = { retention_period: row.retention_period || '', retention_until: row.retention_until || '' }
  sampleDialogVisible.value = true
}

function openDispose(row) {
  sampleAction.value = 'dispose'
  sampleTarget.value = row
  disposeForm.value = { disposal_type: '销毁', disposal_method: '', disposal_date: '', disposal_note: '' }
  sampleDialogVisible.value = true
}

async function submitSample() {
  sampleSubmitting.value = true
  try {
    const sno = sampleTarget.value.sample_no
    if (sampleAction.value === 'retain') {
      await request.post(`/samples/${sno}/retain`, retainForm.value)
      ElMessage.success(`样品 ${sno} 留样已登记`)
    } else {
      await request.post(`/samples/${sno}/dispose`, disposeForm.value)
      ElMessage.success(`样品 ${sno} 已${disposeForm.value.disposal_type}`)
    }
    sampleDialogVisible.value = false
    await load()
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '操作失败')
  } finally {
    sampleSubmitting.value = false
  }
}

onMounted(load)
</script>

<template>
  <div class="page" v-loading="loading">
    <div class="page-header">
      <h1>委托详情 — {{ commission?.commission_no }}</h1>
      <el-tag v-if="commission" :type="commission.status === '已入库' ? 'success' : 'info'">
        {{ commission.status }}
      </el-tag>
    </div>

    <template v-if="commission">
      <el-row :gutter="20">
        <el-col :span="12">
          <el-card header="基本信息" style="margin-bottom:16px">
            <el-descriptions :column="1" size="small">
              <el-descriptions-item label="委托编号">{{ commission.commission_no }}</el-descriptions-item>
              <el-descriptions-item label="客户名称">{{ commission.client_name }}</el-descriptions-item>
              <el-descriptions-item label="联系人">{{ commission.contact || '-' }}</el-descriptions-item>
              <el-descriptions-item label="电话">{{ commission.phone || '-' }}</el-descriptions-item>
              <el-descriptions-item label="客户地址">{{ commission.client_address || '-' }}</el-descriptions-item>
              <el-descriptions-item label="委托日期">{{ commission.commission_date || '-' }}</el-descriptions-item>
              <el-descriptions-item label="要求完成日期">{{ commission.due_date || '-' }}</el-descriptions-item>
            </el-descriptions>
          </el-card>
        </el-col>
        <el-col :span="12">
          <el-card header="生产信息" style="margin-bottom:16px">
            <el-descriptions :column="1" size="small">
              <el-descriptions-item label="生产单位">{{ commission.production_org_name }}</el-descriptions-item>
              <el-descriptions-item label="生产关系">{{ commission.production_relation }}</el-descriptions-item>
              <el-descriptions-item label="创建人">{{ commission.created_by || '-' }}</el-descriptions-item>
              <el-descriptions-item label="创建时间">{{ formatChinaDateTime(commission.created_at) }}</el-descriptions-item>
              <el-descriptions-item label="备注">{{ commission.notes || '-' }}</el-descriptions-item>
            </el-descriptions>
          </el-card>
        </el-col>
      </el-row>

      <!-- 样品组 -->
      <el-card style="margin-bottom:16px">
        <template #header>
          <div style="display:flex;justify-content:space-between;align-items:center">
            <span>样品组</span>
            <span style="font-size:13px;color:#64748B">样品总数：<strong style="color:#0F172A">{{ commission.total_sample_count || 0 }}</strong></span>
          </div>
        </template>
        <el-table :data="commission.sample_groups" empty-text="暂无样品组" size="small">
          <el-table-column prop="group_no" label="组号" width="180" />
          <el-table-column prop="sample_name" label="样品名称" />
          <el-table-column prop="model" label="型号" />
          <el-table-column label="材料">
            <template #default="{ row }">{{ materialWithSample(row.material_name, row.sample_name) }}</template>
          </el-table-column>
          <el-table-column prop="quantity" label="数量" width="80" />
          <el-table-column prop="experiment_codes" label="检测项目" width="150" />
          <el-table-column prop="status" label="状态" width="100">
            <template #default="{ row }">
              <el-tag size="small">{{ row.status }}</el-tag>
            </template>
          </el-table-column>
        </el-table>
      </el-card>

      <!-- 样品 -->
      <el-card header="样品">
        <el-table :data="commission.samples" empty-text="暂无样品" size="small">
          <el-table-column prop="sample_no" label="样品编号" width="190" />
          <el-table-column prop="group_no" label="组号" width="150" />
          <el-table-column prop="sample_name" label="样品名称" min-width="120" />
          <el-table-column prop="status" label="样品状态" width="110">
            <template #default="{ row }">
              <el-tag :type="['已销毁','已报废'].includes(row.status) ? 'danger' : 'info'" size="small">{{ row.status }}</el-tag>
            </template>
          </el-table-column>
          <el-table-column prop="retention_period" label="留样期限" width="110" />
          <el-table-column prop="retention_until" label="留样到期" width="110" />
          <el-table-column prop="disposal_method" label="处置方式" min-width="110" />
          <el-table-column v-if="canManageSample" label="留样/处置" width="150" fixed="right">
            <template #default="{ row }">
              <el-button size="small" @click="openRetain(row)">留样</el-button>
              <el-button size="small" type="danger" plain @click="openDispose(row)">处置</el-button>
            </template>
          </el-table-column>
        </el-table>
      </el-card>
    </template>

    <!-- 留样/处置对话框 -->
    <el-dialog
      v-model="sampleDialogVisible"
      :title="sampleAction === 'retain' ? '留样登记' : '样品处置'"
      width="480px" :close-on-click-modal="false"
    >
      <template v-if="sampleTarget">
        <el-descriptions :column="2" border size="small" style="margin-bottom:16px">
          <el-descriptions-item label="样品编号">{{ sampleTarget.sample_no }}</el-descriptions-item>
          <el-descriptions-item label="样品名称">{{ sampleTarget.sample_name || '—' }}</el-descriptions-item>
        </el-descriptions>

        <el-form v-if="sampleAction === 'retain'" label-width="100px">
          <el-form-item label="留样期限">
            <el-input v-model="retainForm.retention_period" placeholder="如：12个月 / 报告异议期满" />
          </el-form-item>
          <el-form-item label="到期日">
            <el-date-picker v-model="retainForm.retention_until" type="date" value-format="YYYY-MM-DD" placeholder="选择到期日" style="width:100%" />
          </el-form-item>
        </el-form>

        <el-form v-else label-width="100px">
          <el-form-item label="处置类型" required>
            <el-radio-group v-model="disposeForm.disposal_type">
              <el-radio value="销毁">销毁</el-radio>
              <el-radio value="报废">报废</el-radio>
            </el-radio-group>
          </el-form-item>
          <el-form-item label="处置方式">
            <el-input v-model="disposeForm.disposal_method" placeholder="具体处置方式" />
          </el-form-item>
          <el-form-item label="处置日期">
            <el-date-picker v-model="disposeForm.disposal_date" type="date" value-format="YYYY-MM-DD" placeholder="选择日期" style="width:100%" />
          </el-form-item>
          <el-form-item label="备注">
            <el-input v-model="disposeForm.disposal_note" type="textarea" :rows="2" />
          </el-form-item>
        </el-form>
      </template>
      <template #footer>
        <el-button @click="sampleDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="sampleSubmitting" @click="submitSample">确认</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.page { max-width: 1200px; }
.page-header {
  display: flex; align-items: center; gap: 16px;
  margin-bottom: 20px;
}
.page-header h1 { font-size: 22px; font-weight: 600; color: #0F172A; }
</style>
