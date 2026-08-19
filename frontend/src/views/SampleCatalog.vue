<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import request from '../utils/request'
import { Search, Plus, Edit, Delete } from '@element-plus/icons-vue'
import { isRealModel } from '../utils/model'

const user = JSON.parse(localStorage.getItem('user') || '{}')
const canManage = computed(() => user.role === '管理员' || user.role === '样品管理员')

const catalog = ref([])
const loading = ref(true)
const searchText = ref('')

// 新增/编辑对话框
const dialogVisible = ref(false)
const editMode = ref(false)
const editingId = ref(null)
const saving = ref(false)
const dialogTitle = computed(() => editMode.value ? '编辑样品资料' : '新增样品资料')
const form = ref({
  sample_name: '', model: '', material_name: '',
  sample_code: '', process: '', material_suffix: '',
  source_sequence: '', category: '', unit: '',
  notes: '', enabled: true,
})

// 检测项目库（含标准）与选择状态
const experiments = ref([])
const selectedExperimentCodes = ref([])
const standardChoices = ref({})   // { experiment_code: 选中标准全文 }

function standardsFor(code) {
  const m = experiments.value.find(e => e.experiment_code === code)
  return m?.standards || []
}
function experimentName(code) {
  const m = experiments.value.find(e => e.experiment_code === code)
  return m?.experiment_name || code
}
function isMultiStandard(code) {
  return standardsFor(code).length > 1
}
const multiStandardCodes = computed(() => selectedExperimentCodes.value.filter(isMultiStandard))
// 检验项目 = 所选检测项目名称；检验依据 = 各检测项目选中标准（拼接）
const detectionMethodText = computed(() => selectedExperimentCodes.value.map(experimentName).filter(Boolean).join('、'))
const detectionBasisText = computed(() => selectedExperimentCodes.value.map(c => standardChoices.value[c]).filter(Boolean).join('；'))

function onExperimentsChange(codes) {
  const next = {}
  for (const code of codes) {
    const stds = standardsFor(code)
    const prev = standardChoices.value[code]
    next[code] = (prev && stds.includes(prev)) ? prev : (stds[0] || '')
  }
  standardChoices.value = next
}

async function loadExperiments() {
  try {
    const { data } = await request.get('/config/methods')
    experiments.value = data
  } catch { experiments.value = [] }
}

async function loadCatalog() {
  loading.value = true
  try {
    const res = await request.get('/catalog', { params: { search: searchText.value || undefined, limit: 200 } })
    catalog.value = res.data
  } finally {
    loading.value = false
  }
}

function resetForm() {
  form.value = {
    sample_name: '', model: '', material_name: '',
    sample_code: '', process: '', material_suffix: '',
    source_sequence: '', category: '', unit: '',
    notes: '', enabled: true,
  }
  selectedExperimentCodes.value = []
  standardChoices.value = {}
}

function showAddDialog() {
  editMode.value = false
  editingId.value = null
  resetForm()
  dialogVisible.value = true
}

function openEdit(row) {
  editMode.value = true
  editingId.value = row.id
  form.value = {
    sample_name: row.sample_name || '',
    model: row.model || '',
    material_name: row.material_name || '',
    sample_code: row.sample_code || '',
    process: row.process || '',
    material_suffix: '',
    source_sequence: '',
    category: row.category || '',
    unit: row.unit || '',
    notes: '',
    enabled: row.enabled !== false,
  }
  const codes = Array.isArray(row.experiment_codes) ? row.experiment_codes : []
  selectedExperimentCodes.value = codes
  // 忽略空白做匹配：Excel 导入的检测依据已去掉空格，与标准全文（含空格）需归一化后比对
  const basis = (row.detection_basis || '').replace(/\s+/g, '')
  const choices = {}
  for (const code of codes) {
    const stds = standardsFor(code)
    if (!stds.length) { choices[code] = ''; continue }
    const matched = stds.find(s => s && basis.includes(s.replace(/\s+/g, '')))
    choices[code] = matched || stds[0]
  }
  standardChoices.value = choices
  dialogVisible.value = true
}

async function handleSave() {
  const f = form.value
  if (!f.sample_name) { ElMessage.warning('请输入样品名称'); return }
  if (!f.model) { ElMessage.warning('请输入规格型号'); return }
  if (!isRealModel(f.model)) { ElMessage.warning('请输入真实规格型号（不能为「-」「无」等占位符）'); return }
  if (!f.material_name) { ElMessage.warning('请输入材料名称'); return }

  const payload = {
    sample_name: f.sample_name,
    model: f.model,
    material_name: f.material_name,
    detection_method: detectionMethodText.value || '',
    detection_basis: detectionBasisText.value || '',
    experiment_codes: selectedExperimentCodes.value,
    sample_code: f.sample_code || null,
    process: f.process || '',
    category: f.category || '',
    unit: f.unit || '',
    notes: f.notes || '',
  }

  saving.value = true
  try {
    if (editMode.value) {
      payload.enabled = f.enabled
      await request.put(`/catalog/${editingId.value}`, payload)
      ElMessage.success('样品资料已更新，并已回写历史记录')
    } else {
      payload.material_suffix = f.material_suffix || null
      payload.source_sequence = f.source_sequence || null
      await request.post('/catalog', payload)
      ElMessage.success('样品资料添加成功')
    }
    dialogVisible.value = false
    loadCatalog()
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '保存失败')
  } finally {
    saving.value = false
  }
}

async function handleDelete(item) {
  try {
    await ElMessageBox.confirm(
      `确定要删除样品资料「${item.sample_name}」吗？`,
      '确认删除',
      { type: 'warning', confirmButtonText: '删除', cancelButtonText: '取消' }
    )
    await request.delete(`/catalog/${item.id}`)
    ElMessage.success('样品资料已删除')
    loadCatalog()
  } catch (e) {
    if (e !== 'cancel') ElMessage.error(e.response?.data?.detail || '删除失败')
  }
}

onMounted(() => {
  loadCatalog()
  loadExperiments()
})
</script>

<template>
  <div class="page">
    <div class="page-header">
      <h1>样品资料库</h1>
      <div style="display:flex;gap:12px">
        <el-button v-if="canManage" type="primary" :icon="Plus" @click="showAddDialog">新增样品资料</el-button>
        <el-input
          v-model="searchText"
          placeholder="搜索样品名称/编号/材料..."
          style="width:300px"
          clearable
          @input="loadCatalog"
        >
          <template #prefix><el-icon><Search /></el-icon></template>
        </el-input>
      </div>
    </div>

    <el-card>
      <el-table :data="catalog" v-loading="loading" stripe empty-text="暂无数据" max-height="600">
        <el-table-column prop="sample_code" label="样品代码" width="120" />
        <el-table-column prop="sample_name" label="样品名称" min-width="200" />
        <el-table-column prop="model" label="规格型号" width="150" />
        <el-table-column prop="material_name" label="材料名称" width="150" />
        <el-table-column prop="detection_method" label="检验项目" min-width="120">
          <template #default="{ row }">{{ row.detection_method || '—' }}</template>
        </el-table-column>
        <el-table-column prop="detection_basis" label="检测依据" min-width="200">
          <template #default="{ row }">{{ row.detection_basis || '—' }}</template>
        </el-table-column>
        <el-table-column prop="process" label="工艺" width="120" />
        <el-table-column prop="category" label="类别" width="120">
          <template #default="{ row }">
            <el-tag size="small">{{ row.category }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="unit" label="单位" width="80" />
        <el-table-column prop="enabled" label="状态" width="80">
          <template #default="{ row }">
            <el-tag :type="row.enabled ? 'success' : 'danger'" size="small">{{ row.enabled ? '启用' : '停用' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column v-if="canManage" label="操作" width="140" fixed="right">
          <template #default="{ row }">
            <el-button text type="primary" :icon="Edit" @click.stop="openEdit(row)">编辑</el-button>
            <el-button text type="danger" :icon="Delete" @click.stop="handleDelete(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 新增/编辑对话框 -->
    <el-dialog v-model="dialogVisible" :title="dialogTitle" width="560px" :close-on-click-modal="false">
      <el-form :model="form" label-width="100px">
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="样品名称" required>
              <el-input v-model="form.sample_name" placeholder="如 TC4钛合金试样" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="样品代码">
              <el-input v-model="form.sample_code" placeholder="如 TC4-001" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="规格型号" required>
              <el-input v-model="form.model" placeholder="如 φ10×50mm" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="材料名称" required>
              <el-input v-model="form.material_name" placeholder="如 Ti-6Al-4V" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item label="检验项目">
          <el-select
            v-model="selectedExperimentCodes"
            multiple filterable collapse-tags
            placeholder="选择检测项目（可多选）"
            style="width:100%"
            @change="onExperimentsChange"
          >
            <el-option v-for="e in experiments" :key="e.experiment_code" :label="e.experiment_name" :value="e.experiment_code" />
          </el-select>
        </el-form-item>

        <el-form-item v-for="code in multiStandardCodes" :key="code" label="选择标准">
          <div style="width:100%">
            <div style="font-size:12px;color:#64748B;margin-bottom:4px">{{ experimentName(code) }}</div>
            <el-select v-model="standardChoices[code]" filterable style="width:100%">
              <el-option v-for="s in standardsFor(code)" :key="s" :label="s" :value="s" />
            </el-select>
          </div>
        </el-form-item>

        <el-form-item v-if="selectedExperimentCodes.length" label="检验依据">
          <div style="width:100%;padding:8px 12px;background:#F8FAFC;border:1px solid #E2E8F0;border-radius:4px;font-size:12px;color:#475569;line-height:1.6;white-space:pre-wrap">{{ detectionBasisText || '—' }}</div>
        </el-form-item>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="工艺">
              <el-input v-model="form.process" placeholder="如 退火态" />
            </el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="类别">
              <el-input v-model="form.category" placeholder="如 金属、陶瓷" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-row :gutter="16">
          <el-col :span="12">
            <el-form-item label="单位">
              <el-input v-model="form.unit" placeholder="如 件、kg" />
            </el-form-item>
          </el-col>
          <el-col v-if="!editMode" :span="12">
            <el-form-item label="后缀">
              <el-input v-model="form.material_suffix" placeholder="材料后缀" />
            </el-form-item>
          </el-col>
          <el-col v-else :span="12">
            <el-form-item label="状态">
              <el-switch v-model="form.enabled" active-text="启用" inactive-text="停用" />
            </el-form-item>
          </el-col>
        </el-row>
        <el-form-item v-if="!editMode" label="来源序号">
          <el-input v-model="form.source_sequence" placeholder="来源序号" />
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
.page { max-width: 1400px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; }
.page-header h1 { font-size: 22px; font-weight: 600; color: #0F172A; }
</style>
