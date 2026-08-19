<script setup>
import { ref, reactive, onMounted, watch, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Warning, Search } from '@element-plus/icons-vue'
import request from '../utils/request'
import { chinaDate, chinaTime } from '../utils/time'

const router = useRouter()
const loading = ref(false)
const list = ref([])
const dialogVisible = ref(false)
const current = ref(null)
const actions = ref([])
const searchText = ref('')
const myTasks = ref([])
const faultTaskOptions = computed(() => myTasks.value.filter(t => ['检测中', '退回修改'].includes(t.status)))

async function loadMyTasks() {
  try {
    const { data } = await request.get('/tasks/my', { params: { limit: 200 } })
    myTasks.value = Array.isArray(data) ? data : []
  } catch { myTasks.value = [] }
}

const user = JSON.parse(localStorage.getItem('user') || '{}')

// ── 报告故障表单 ──
const reportForm = reactive({
  task_no: '', equipment_no: '', fault_type: '', fault_description: '',
  error_code: '', current_stage: '', collected_data: '', sample_condition: '',
  risk_types: [], immediate_actions: [],
})
const riskOptions = ['数据丢失风险', '样品损坏风险', '人员安全风险', '环境污染风险', '进度延误风险']
const actionOptions = ['终止试验动作', '保护故障现场', '样品保持原位并等待隔离']

// ── 隔离/评估/批准表单 ──
const actionDialogVisible = ref(false)
const actionType = ref('') // isolate | assess | approve
const actionSubmitting = ref(false)
const actionForm = reactive({
  isolation_location: '', storage_requirements: '', receiver_note: '',
  sample_validity: '', quality_conclusion: '', impact_scope: '', quality_note: '',
  recovery_route: '', performance_check_result: '', admin_note: '', backup_equipment_no: '',
})
const sampleValidityOptions = ['可稳定保存并整套重做', '样品不可逆失效', '需更换备用设备整套重做']
const recoveryRouteOptions = [
  '样品失效，等待客户重新送样',
  '原设备维修核查合格后整套重做',
  '改用备用合格设备整套重做',
]

const submitting = ref(false)

onMounted(() => { loadList(); loadMyTasks() })

async function loadList() {
  loading.value = true
  try {
    const { data } = await request.get('/incidents', { params: { search: searchText.value || undefined } })
    list.value = data
  } catch { ElMessage.warning('加载故障记录失败') } finally { loading.value = false }
}

async function openDetail(row) {
  try {
    const { data } = await request.get(`/incidents/${row.incident_no}`)
    current.value = data.incident
    actions.value = data.actions || []
    dialogVisible.value = true
  } catch { ElMessage.error('加载详情失败') }
}

// ── 报告故障 ──
const showReport = ref(false)
const reportError = ref('')
watch(showReport, (v) => { if (v) loadMyTasks() })
async function submitReport() {
  if (!reportForm.task_no || !reportForm.equipment_no || !reportForm.fault_description) {
    reportError.value = '请填写任务编号、设备编号和故障描述'
    return
  }
  reportError.value = ''
  submitting.value = true
  try {
    const res = await request.post('/incidents', {
      ...reportForm,
      risk_types: reportForm.risk_types,
      immediate_actions: reportForm.immediate_actions,
    })
    ElMessage.success(`故障已报告: ${res.data.incident_no}`)
    showReport.value = false
    resetReportForm()
    loadList()
  } catch (e) { ElMessage.error(e.response?.data?.detail || '报告失败') } finally { submitting.value = false }
}

function resetReportForm() {
  Object.assign(reportForm, { task_no: '', equipment_no: '', fault_type: '', fault_description: '', error_code: '', current_stage: '', collected_data: '', sample_condition: '', risk_types: [], immediate_actions: [] })
}

// ── 隔离/评估/批准操作（对话框） ──
function openAction(row, type) {
  actionType.value = type
  Object.assign(actionForm, {
    isolation_location: '', storage_requirements: '', receiver_note: '',
    sample_validity: '', quality_conclusion: '', impact_scope: '', quality_note: '',
    recovery_route: '', performance_check_result: '', admin_note: '', backup_equipment_no: '',
  })
  current.value = row
  actionDialogVisible.value = true
}

async function submitAction() {
  const f = actionForm
  const incNo = current.value.incident_no
  actionSubmitting.value = true
  try {
    if (actionType.value === 'isolate') {
      if (!f.isolation_location.trim() || !f.storage_requirements.trim()) {
        ElMessage.warning('隔离位置和保存要求均不能为空'); return
      }
      await request.put(`/incidents/${incNo}/isolate`, {
        isolation_location: f.isolation_location, storage_requirements: f.storage_requirements,
        receiver_note: f.receiver_note,
      })
    } else if (actionType.value === 'assess') {
      if (!f.sample_validity || !f.quality_conclusion.trim() || !f.impact_scope.trim()) {
        ElMessage.warning('请填写样品有效性、质量结论和影响范围'); return
      }
      await request.put(`/incidents/${incNo}/assess`, {
        sample_validity: f.sample_validity, quality_conclusion: f.quality_conclusion,
        impact_scope: f.impact_scope, quality_note: f.quality_note,
      })
    } else if (actionType.value === 'approve') {
      if (!f.recovery_route) { ElMessage.warning('请选择恢复路径'); return }
      if (!f.admin_note.trim()) { ElMessage.warning('请填写技术批准意见'); return }
      if (f.recovery_route === '改用备用合格设备整套重做' && !f.backup_equipment_no.trim()) {
        ElMessage.warning('请指定备用合格设备编号'); return
      }
      if (f.recovery_route !== '样品失效，等待客户重新送样' && !f.performance_check_result.includes('核查合格')) {
        ElMessage.warning('设备性能核查结果须包含「核查合格」'); return
      }
      await request.put(`/incidents/${incNo}/approve`, {
        recovery_route: f.recovery_route, performance_check_result: f.performance_check_result,
        admin_note: f.admin_note, backup_equipment_no: f.backup_equipment_no,
      })
    }
    ElMessage.success('操作成功')
    actionDialogVisible.value = false
    loadList()
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '操作失败')
  } finally {
    actionSubmitting.value = false
  }
}

// ── 继续重做：跳转至任务编辑 ──
function goRedo(row) {
  router.push({ name: 'ExperimentRun', params: { taskNo: row.task_no } })
}

function statusTag(s) {
  const map = {
    '待样品隔离': 'danger', '待质量评估': 'warning', '待管理员批准': '',
    '已关闭': 'success', '样品失效待重新送样': 'info',
  }
  return map[s] || 'info'
}
function formatDate(d) { return d ? chinaDate(new Date(d)) + ' ' + chinaTime(new Date(d)) : '—' }
</script>

<template>
  <div class="page-container">
    <div class="page-header">
      <h2><el-icon><Warning /></el-icon> 设备故障处置</h2>
      <el-button type="primary" @click="showReport = true">报告设备故障</el-button>
    </div>

    <!-- 搜索 -->
    <el-input v-model="searchText" placeholder="搜索故障编号或任务编号" clearable @clear="loadList" @keyup.enter="loadList" style="width:320px;margin-bottom:16px">
      <template #prefix><el-icon><Search /></el-icon></template>
    </el-input>

    <!-- 列表 -->
    <el-table :data="list" v-loading="loading" stripe @row-click="openDetail" style="cursor:pointer">
      <el-table-column prop="incident_no" label="故障编号" width="180" />
      <el-table-column prop="task_no" label="关联任务" width="150" />
      <el-table-column prop="equipment_no" label="设备编号" width="150" />
      <el-table-column prop="fault_type" label="故障类型" width="120" />
      <el-table-column prop="fault_description" label="故障描述" min-width="200" show-overflow-tooltip />
      <el-table-column prop="status" label="状态" width="130">
        <template #default="{ row }"><el-tag :type="statusTag(row.status)">{{ row.status }}</el-tag></template>
      </el-table-column>
      <el-table-column prop="created_at" label="报告时间" width="170">
        <template #default="{ row }">{{ formatDate(row.created_at) }}</template>
      </el-table-column>
      <el-table-column label="快捷操作" width="200" fixed="right">
        <template #default="{ row }">
          <el-button v-if="row.status==='待样品隔离' && (user.role==='样品管理员' || user.role==='管理员')" size="small" type="warning" @click.stop="openAction(row,'isolate')">隔离</el-button>
          <el-button v-if="row.status==='待质量评估' && (user.role==='质量负责人' || user.role==='管理员')" size="small" @click.stop="openAction(row,'assess')">评估</el-button>
          <el-button v-if="row.status==='待管理员批准' && user.role==='管理员'" size="small" type="success" @click.stop="openAction(row,'approve')">批准</el-button>
          <el-button v-if="row.status==='已关闭' && row.resumed_record_version" size="small" type="primary" @click.stop="goRedo(row)">继续重做</el-button>
        </template>
      </el-table-column>
    </el-table>

    <!-- 详情对话框 -->
    <el-dialog v-model="dialogVisible" title="故障详情" width="700px">
      <template v-if="current">
        <el-descriptions :column="2" border size="small">
          <el-descriptions-item label="故障编号">{{ current.incident_no }}</el-descriptions-item>
          <el-descriptions-item label="状态"><el-tag :type="statusTag(current.status)">{{ current.status }}</el-tag></el-descriptions-item>
          <el-descriptions-item label="关联任务">{{ current.task_no }}</el-descriptions-item>
          <el-descriptions-item label="设备编号">{{ current.equipment_no }}</el-descriptions-item>
          <el-descriptions-item label="故障类型">{{ current.fault_type }}</el-descriptions-item>
          <el-descriptions-item label="报告人">{{ current.reporter_name || current.reporter }}</el-descriptions-item>
          <el-descriptions-item v-if="current.recovery_route" label="恢复路径" :span="2">{{ current.recovery_route }}</el-descriptions-item>
          <el-descriptions-item v-if="current.backup_equipment_no" label="备用设备">{{ current.backup_equipment_no }}</el-descriptions-item>
          <el-descriptions-item v-if="current.resumed_record_version" label="重做版本">v{{ current.resumed_record_version }}</el-descriptions-item>
          <el-descriptions-item label="故障描述" :span="2">{{ current.fault_description }}</el-descriptions-item>
        </el-descriptions>
        <h4 style="margin-top:16px">操作历史</h4>
        <el-timeline v-if="actions.length">
          <el-timeline-item v-for="a in actions" :key="a.id" :timestamp="formatDate(a.created_at)" placement="top">
            <strong>{{ a.action }}</strong> — {{ a.actor }}<br/>
            <span v-if="a.comment">{{ a.comment }}</span>
          </el-timeline-item>
        </el-timeline>
        <el-empty v-else description="暂无操作记录" :image-size="60" />
      </template>
    </el-dialog>

    <!-- 报告故障对话框 -->
    <el-dialog v-model="showReport" title="报告设备故障" width="600px">
      <el-form :model="reportForm" label-width="100px">
        <el-form-item label="任务编号" required>
          <el-select v-model="reportForm.task_no" filterable placeholder="选择本人负责的实验任务（检测中/退回修改）" style="width:100%">
            <el-option v-for="t in faultTaskOptions" :key="t.task_no" :label="`${t.experiment || t.task_no}（${t.task_no}）`" :value="t.task_no" />
          </el-select>
        </el-form-item>
        <el-form-item label="设备编号" required><el-input v-model="reportForm.equipment_no" placeholder="故障设备编号" /></el-form-item>
        <el-form-item label="故障类型"><el-select v-model="reportForm.fault_type" placeholder="选择故障类型" clearable style="width:100%">
          <el-option label="机械故障" value="机械故障" /><el-option label="电气故障" value="电气故障" />
          <el-option label="软件故障" value="软件故障" /><el-option label="传感器故障" value="传感器故障" />
          <el-option label="校准偏差" value="校准偏差" /><el-option label="其他" value="其他" />
        </el-select></el-form-item>
        <el-form-item label="故障描述" required><el-input v-model="reportForm.fault_description" type="textarea" :rows="3" placeholder="详细描述故障现象" /></el-form-item>
        <el-form-item label="当前阶段"><el-input v-model="reportForm.current_stage" placeholder="实验进行到哪一步" /></el-form-item>
        <el-form-item label="风险类型"><el-checkbox-group v-model="reportForm.risk_types">
          <el-checkbox v-for="r in riskOptions" :key="r" :label="r">{{ r }}</el-checkbox>
        </el-checkbox-group></el-form-item>
        <el-form-item label="应急动作"><el-checkbox-group v-model="reportForm.immediate_actions">
          <el-checkbox v-for="a in actionOptions" :key="a" :label="a">{{ a }}</el-checkbox>
        </el-checkbox-group></el-form-item>
        <el-form-item label="样品状况"><el-input v-model="reportForm.sample_condition" placeholder="样品是否受影响" /></el-form-item>
      </el-form>
      <p v-if="reportError" style="color:#f56c6c">{{ reportError }}</p>
      <template #footer>
        <el-button @click="showReport = false">取消</el-button>
        <el-button type="primary" :loading="submitting" @click="submitReport">提交报告</el-button>
      </template>
    </el-dialog>

    <!-- 隔离/评估/批准对话框 -->
    <el-dialog
      v-model="actionDialogVisible"
      :title="actionType === 'isolate' ? '确认样品隔离' : actionType === 'assess' ? '质量评估' : '技术批准'"
      width="560px" :close-on-click-modal="false"
    >
      <el-form v-if="actionType === 'isolate'" label-width="100px">
        <el-form-item label="隔离位置" required><el-input v-model="actionForm.isolation_location" placeholder="样品隔离存放位置" /></el-form-item>
        <el-form-item label="保存要求" required><el-input v-model="actionForm.storage_requirements" placeholder="温湿度、避光等保存要求" /></el-form-item>
        <el-form-item label="接收备注"><el-input v-model="actionForm.receiver_note" type="textarea" :rows="2" /></el-form-item>
      </el-form>

      <el-form v-else-if="actionType === 'assess'" label-width="100px">
        <el-form-item label="样品有效性" required>
          <el-select v-model="actionForm.sample_validity" placeholder="选择样品有效性结论" style="width:100%">
            <el-option v-for="o in sampleValidityOptions" :key="o" :label="o" :value="o" />
          </el-select>
        </el-form-item>
        <el-form-item label="质量结论" required><el-input v-model="actionForm.quality_conclusion" type="textarea" :rows="2" placeholder="质量调查结论" /></el-form-item>
        <el-form-item label="影响范围" required><el-input v-model="actionForm.impact_scope" placeholder="受影响的数据、样品、任务范围" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="actionForm.quality_note" type="textarea" :rows="2" /></el-form-item>
      </el-form>

      <el-form v-else label-width="100px">
        <el-form-item label="恢复路径" required>
          <el-select v-model="actionForm.recovery_route" placeholder="选择恢复路径" style="width:100%">
            <el-option v-for="o in recoveryRouteOptions" :key="o" :label="o" :value="o" />
          </el-select>
        </el-form-item>
        <el-form-item v-if="actionForm.recovery_route === '改用备用合格设备整套重做'" label="备用设备" required>
          <el-input v-model="actionForm.backup_equipment_no" placeholder="备用合格设备管理编号" />
        </el-form-item>
        <el-form-item v-if="actionForm.recovery_route !== '样品失效，等待客户重新送样'" label="性能核查" required>
          <el-input v-model="actionForm.performance_check_result" placeholder="设备性能核查结果（须含「核查合格」）" />
        </el-form-item>
        <el-form-item label="批准意见" required><el-input v-model="actionForm.admin_note" type="textarea" :rows="2" placeholder="技术批准意见" /></el-form-item>
      </el-form>

      <template #footer>
        <el-button @click="actionDialogVisible = false">取消</el-button>
        <el-button type="primary" :loading="actionSubmitting" @click="submitAction">确认</el-button>
      </template>
    </el-dialog>
  </div>
</template>
