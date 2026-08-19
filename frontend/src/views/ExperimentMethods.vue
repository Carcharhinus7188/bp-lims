<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Plus, Edit, Delete, Check, Download, MagicStick } from '@element-plus/icons-vue'
import request from '../utils/request'

const user = JSON.parse(localStorage.getItem('user') || '{}')
const isAdmin = computed(() => user.role === '管理员')
const canManage = computed(() => user.role === '管理员' || user.role === '样品管理员')

const methods = ref([])
const loading = ref(true)

// 版本列表
const versionDialogVisible = ref(false)
const versions = ref([])
const versionLoading = ref(false)
const selectedExperiment = ref(null)

// 新增检测项目
const addMethodDialogVisible = ref(false)
const addMethodLoading = ref(false)
const addMethodForm = ref({
  experiment_code: '', experiment_name: '', method_code: '',
  standard: '', category: '', kind: 'generic',
})
const recordTemplateFile = ref(null)   // 原始记录模板 .docx
const sopFile = ref(null)              // SOP .docx

// 创建版本
const createDialogVisible = ref(false)
const createLoading = ref(false)
const createForm = ref({
  experiment_code: '', version: '', experiment_name: '',
  method_code: '', standard: '', category: '', kind: 'generic',
  effective_date: '', note: '',
})

// ============ 版本编辑器 ============
const editorVisible = ref(false)
const editorSaving = ref(false)
const editorLoading = ref(false)
const editorExperimentCode = ref('')
const editorVersion = ref('')
const editorActiveTab = ref('fields')

// 编辑器数据
const editFields = ref([])          // [{key, label, type, default, options, readonly, section_title, section_order}]
const editColumns = ref([])         // [{column_key, column_label, column_type, column_default}]
const editPhotos = ref([])          // [{code, label, required}]
const editPrechecks = ref([])       // [{label}]
const editEquipment = ref([])       // [{management_no, equipment_name, model, binding_role, required, note}]
const editMeta = ref({              // 元数据/提示（extra_json 相关）
  experiment_name: '',
  record_template_file: '',
  camera_hints: [],                 // [{code, hint}]
  report_decisive_photo_codes: [],  // [{code}]
  _extra: {},                       // 原始 extra_json（保存时合并，避免丢失 constants 等其它键）
})

// 设备库搜索
const equipSearch = ref('')
const equipOptions = ref([])        // Available equipment from registry for dropdown
const equipSearchLoading = ref(false)

const FIELD_TYPES = ['text', 'number', 'date', 'datetime', 'select', 'multiselect', 'checkbox', 'textarea']
const COLUMN_TYPES = ['number', 'calc', 'text', 'select:选项1|选项2']
const CALC_OPS = [
  { value: 'avg', label: '平均值 avg' },
  { value: 'sum', label: '求和 sum' },
  { value: 'min', label: '最小值 min' },
  { value: 'max', label: '最大值 max' },
  { value: 'add', label: '相加 add（可加常数）' },
  { value: 'subtract', label: '相减 subtract' },
  { value: 'multiply', label: '相乘 multiply' },
  { value: 'divide', label: '相除 divide' },
  { value: 'abs', label: '绝对值 abs' },
  { value: 'round', label: '四舍五入 round' },
  { value: 'le', label: '≤ 判定 le' },
  { value: 'ge', label: '≥ 判定 ge' },
  { value: 'lt', label: '< 判定 lt' },
  { value: 'gt', label: '> 判定 gt' },
  { value: 'eq', label: '= 判定 eq' },
  { value: 'ne', label: '≠ 判定 ne' },
  { value: 'abs_le', label: '|·|≤ 判定 abs_le' },
  { value: 'abs_ge', label: '|·|≥ 判定 abs_ge' },
  { value: 'all_eq', label: '全部等于 all_eq' },
  { value: 'count', label: '非空计数 count' },
  { value: 'count_if', label: '命中计数 count_if' },
  { value: 'color_overall', label: '色稳总评 color_overall' },
  { value: 'color_conclusion', label: '色稳结论 color_conclusion' },
]

// 自定义公式编辑器（calc 列）
const calcDialogVisible = ref(false)
const calcEditingRow = ref(null)
const calcForm = reactive({ op: 'avg', inputsText: '', precision: 3, constant: '', true_value: '符合', false_value: '不符合', match: '' })

onMounted(async () => {
  try {
    const { data } = await request.get('/config/methods')
    methods.value = data
  } finally {
    loading.value = false
  }
})

// ── 新增检测项目 ──
function showAddMethod() {
  addMethodForm.value = { experiment_code: '', experiment_name: '', method_code: '', standard: '', category: '', kind: 'generic' }
  recordTemplateFile.value = null
  sopFile.value = null
  addMethodDialogVisible.value = true
}

async function handleAddMethod() {
  const f = addMethodForm.value
  if (!f.experiment_code) { ElMessage.warning('请输入实验编码'); return }
  if (!f.experiment_name) { ElMessage.warning('请输入实验名称'); return }
  if (!f.method_code) { ElMessage.warning('请输入方法编号'); return }

  addMethodLoading.value = true
  try {
    // 若上传了 Word 模板/SOP → 走一键导入（自动生成配置版本 V1.0）
    if (recordTemplateFile.value || sopFile.value) {
      const fd = new FormData()
      fd.append('experiment_code', f.experiment_code)
      fd.append('experiment_name', f.experiment_name)
      fd.append('method_code', f.method_code)
      fd.append('standard', (f.standard || '').trim())
      fd.append('category', (f.category || '').trim())
      fd.append('kind', f.kind || 'generic')
      if (recordTemplateFile.value) fd.append('record_template', recordTemplateFile.value)
      if (sopFile.value) fd.append('sop_file', sopFile.value)

      const { data } = await request.post('/config/import-docx', fd, {
        headers: { 'Content-Type': 'multipart/form-data' },
      })
      ElMessage.success(`一键导入成功：检测项目 ${data.experiment_code}，已生成配置版本 ${data.version}（${data.fields_written} 字段）`)
      addMethodDialogVisible.value = false
      const res = await request.get('/config/methods')
      methods.value = res.data
    } else {
      await request.post('/methods', f)
      ElMessage.success('检测项目添加成功')
      addMethodDialogVisible.value = false
      const { data } = await request.get('/config/methods')
      methods.value = data
    }
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '添加失败')
  } finally { addMethodLoading.value = false }
}

// ── 删除检测项目 ──
async function handleDeleteMethod(method) {
  try {
    await ElMessageBox.confirm(`确定要删除「${method.experiment_code} ${method.experiment_name}」吗？`, '确认删除', { type: 'warning', confirmButtonText: '删除', cancelButtonText: '取消' })
    await request.delete(`/methods/${method.experiment_code}`)
    ElMessage.success('已删除')
    const { data } = await request.get('/config/methods')
    methods.value = data
  } catch (e) {
    if (e !== 'cancel') ElMessage.error(e.response?.data?.detail || '删除失败')
  }
}

// ── 编辑检测项目（方法编号/标准/类别）──
const editMethodDialogVisible = ref(false)
const editMethodLoading = ref(false)
const editMethodForm = ref({
  experiment_code: '', experiment_name: '', method_code: '', standard: '', category: '', kind: 'generic',
})

function openEditMethod(method) {
  editMethodForm.value = {
    experiment_code: method.experiment_code,
    experiment_name: method.experiment_name || '',
    method_code: method.method_code || '',
    standard: method.standard || '',
    category: method.category || '',
    kind: method.kind || 'generic',
  }
  editMethodDialogVisible.value = true
}

async function handleEditMethod() {
  const f = editMethodForm.value
  if (!f.experiment_name) { ElMessage.warning('请输入实验名称'); return }
  if (!f.method_code) { ElMessage.warning('请输入方法编号'); return }
  editMethodLoading.value = true
  try {
    await request.put(`/methods/${f.experiment_code}`, {
      experiment_name: f.experiment_name,
      method_code: f.method_code,
      standard: (f.standard || '').trim(),
      category: (f.category || '').trim(),
    })
    ElMessage.success('检测项目已更新，并已回写历史任务')
    editMethodDialogVisible.value = false
    const { data } = await request.get('/config/methods')
    methods.value = data
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '更新失败')
  } finally { editMethodLoading.value = false }
}

// ── 标准变体管理（一个检测项目多个标准，拆分独立使用）──
const standardsDialogVisible = ref(false)
const standardsLoading = ref(false)
const standards = ref([])
const standardsExperiment = ref(null)

const standardFormDialogVisible = ref(false)
const standardFormLoading = ref(false)
const standardFormIsEdit = ref(false)
const standardForm = ref({ id: null, standard: '' })

async function openStandards(method) {
  standardsExperiment.value = method
  standardsDialogVisible.value = true
  standardsLoading.value = true
  try {
    const { data } = await request.get(`/methods/${method.experiment_code}/standards`)
    standards.value = data
  } catch { standards.value = [] }
  finally { standardsLoading.value = false }
}

function showAddStandard() {
  standardForm.value = { id: null, standard: '' }
  standardFormIsEdit.value = false
  standardFormDialogVisible.value = true
}

function showEditStandard(row) {
  standardForm.value = {
    id: row.id, standard: row.standard || '',
  }
  standardFormIsEdit.value = true
  standardFormDialogVisible.value = true
}

async function saveStandard() {
  const f = standardForm.value
  if (!f.standard) { ElMessage.warning('请输入标准全文'); return }
  standardFormLoading.value = true
  const ec = standardsExperiment.value.experiment_code
  const payload = { standard: f.standard }
  try {
    if (standardFormIsEdit.value) {
      await request.put(`/methods/${ec}/standards/${f.id}`, payload)
      ElMessage.success('标准变体已更新')
    } else {
      await request.post(`/methods/${ec}/standards`, payload)
      ElMessage.success('标准变体已新增')
    }
    standardFormDialogVisible.value = false
    const { data } = await request.get(`/methods/${ec}/standards`)
    standards.value = data
    const res = await request.get('/config/methods')
    methods.value = res.data
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '保存失败')
  } finally { standardFormLoading.value = false }
}

async function handleDeleteStandard(row) {
  try {
    await ElMessageBox.confirm(`确定删除标准变体「${row.standard_code}」吗？`, '确认删除', { type: 'warning', confirmButtonText: '删除', cancelButtonText: '取消' })
    await request.delete(`/methods/${standardsExperiment.value.experiment_code}/standards/${row.id}`)
    ElMessage.success('已删除')
    const { data } = await request.get(`/methods/${standardsExperiment.value.experiment_code}/standards`)
    standards.value = data
    const res = await request.get('/config/methods')
    methods.value = res.data
  } catch (e) {
    if (e !== 'cancel') ElMessage.error(e.response?.data?.detail || '删除失败')
  }
}

// ── 版本列表 ──
async function openVersions(method) {
  selectedExperiment.value = method
  versionLoading.value = true
  versionDialogVisible.value = true
  try {
    const { data } = await request.get(`/config/${method.experiment_code}/versions`)
    versions.value = data
  } catch { versions.value = [] }
  finally { versionLoading.value = false }
}

// ── 新建版本 ──
function showCreateVersion() {
  createForm.value = {
    experiment_code: selectedExperiment.value.experiment_code,
    version: '', experiment_name: selectedExperiment.value.experiment_name,
    method_code: selectedExperiment.value.method_code || '',
    standard: selectedExperiment.value.standard || '',
    category: selectedExperiment.value.category || '',
    kind: selectedExperiment.value.kind || 'generic',
    effective_date: '', note: '',
  }
  createDialogVisible.value = true
}

async function handleCreateVersion() {
  const f = createForm.value
  if (!f.version) { ElMessage.warning('请输入版本号'); return }
  if (!f.experiment_name) { ElMessage.warning('请输入实验名称'); return }
  createLoading.value = true
  try {
    await request.post(`/config/${f.experiment_code}/versions`, f)
    ElMessage.success(`版本 ${f.version} 创建成功`)
    createDialogVisible.value = false
    openVersions(selectedExperiment.value)
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '创建失败')
  } finally { createLoading.value = false }
}

// ── 激活/归档/删除版本 ──
async function activateVersion(ec, v) {
  try {
    await ElMessageBox.confirm(`确定激活版本「${v}」？其他现行版本将被归档。`, '确认激活', { type: 'info', confirmButtonText: '激活', cancelButtonText: '取消' })
    await request.put(`/config/${ec}/versions/${v}/status`, { status: '现行' })
    ElMessage.success(`版本 ${v} 已激活`)
    openVersions(selectedExperiment.value)
    const { data } = await request.get('/config/methods')
    methods.value = data
  } catch { /* cancelled */ }
}
async function archiveVersion(ec, v) {
  try {
    await ElMessageBox.confirm(`确定归档版本「${v}」？`, '确认归档', { type: 'warning', confirmButtonText: '归档', cancelButtonText: '取消' })
    await request.put(`/config/${ec}/versions/${v}/status`, { status: '历史' })
    ElMessage.success(`版本 ${v} 已归档`)
    openVersions(selectedExperiment.value)
    const { data } = await request.get('/config/methods')
    methods.value = data
  } catch { /* cancelled */ }
}
async function deleteVersion(ec, v) {
  try {
    await ElMessageBox.confirm(`确定删除版本「${v}」？仅草稿可删。`, '确认删除', { type: 'warning', confirmButtonText: '删除', cancelButtonText: '取消' })
    await request.delete(`/config/${ec}/versions/${v}`)
    ElMessage.success(`版本 ${v} 已删除`)
    openVersions(selectedExperiment.value)
  } catch { /* cancelled */ }
}

// ============ 版本编辑器 ============

async function fetchEditorData() {
  const ec = editorExperimentCode.value
  const v = editorVersion.value
  editorLoading.value = true
  try {
    const { data } = await request.get(`/config/${ec}/versions/${v}`)
    editFields.value = (data.fields || []).map(f => ({ ...f, _dirty: false }))
    editColumns.value = (data.columns || []).map(c => ({ ...c, _dirty: false }))
    editPhotos.value = (data.photo_checkpoints || []).map(p => ({ code: p.code, label: p.label || p.checkpoint_label, required: p.required !== false, sampleLevel: !!p.is_sample_level, group: p.checkpoint_group || '', _dirty: false }))
    editPrechecks.value = (data.prechecks || []).map(p => ({ label: p.label || p.precheck_label || p.check_name, _dirty: false }))
    editEquipment.value = (data.equipment || []).map(e => ({
      management_no: e.management_no || '', equipment_name: e.equipment_name || '',
      model: e.model || '', binding_role: e.binding_role || 'primary',
      required: e.required || false, note: e.note || '', _dirty: false,
      // Registry info (read-only, matches ExperimentRun Step 2 display)
      measuring_range: e.measuring_range || '',
      manufacturer: e.manufacturer || '',
      serial_no: e.serial_no || '',
      calibration_time: e.calibration_time || '',
      equipment_class: e.equipment_class || '',
      responsible: e.responsible || '',
    }))
    editMeta.value = {
      experiment_name: data.experiment_name || '',
      record_template_file: data.record_template_file || '',
      camera_hints: Object.entries(data.camera_hints || {}).map(([code, hint]) => ({ code, hint })),
      report_decisive_photo_codes: (data.report_decisive_photo_codes || []).map(code => ({ code })),
      _extra: data.extra_json || {},
    }
  } catch (e) {
    // 加载失败时初始化为空
    editFields.value = []
    editColumns.value = []
    editPhotos.value = []
    editPrechecks.value = []
    editEquipment.value = []
    editMeta.value = { experiment_name: '', record_template_file: '', camera_hints: [], report_decisive_photo_codes: [], _extra: {} }
  } finally { editorLoading.value = false }
}

async function openEditor(versionRow) {
  editorExperimentCode.value = selectedExperiment.value.experiment_code
  editorVersion.value = versionRow.version
  editorActiveTab.value = 'fields'
  editorVisible.value = true
  await fetchEditorData()
}

// ── 从模板导入 ──
async function loadFromTemplate() {
  if (editFields.value.length || editColumns.value.length || editEquipment.value.length) {
    try {
      await ElMessageBox.confirm('当前编辑器已有数据，导入模板将覆盖。确认？', '覆盖确认', { type: 'warning' })
    } catch { return }
  }
  editorLoading.value = true
  try {
    // 用 GET config/{code} 获取硬编码回退（无现行版本时自动回退）
    const { data } = await request.get(`/config/${editorExperimentCode.value}`)
    editFields.value = (data.fields || []).map(f => ({ ...f, _dirty: true }))
    editColumns.value = (data.columns || []).map(c => ({ ...c, _dirty: true }))
    editPhotos.value = (data.photo_checkpoints || []).map(p => ({ code: p.code || p.checkpoint_code, label: p.label || p.checkpoint_label, required: p.required !== false, sampleLevel: !!p.is_sample_level, group: p.checkpoint_group || '', _dirty: true }))
    editPrechecks.value = (data.prechecks || []).map(p => ({ label: p.label || p.checkpoint_label, _dirty: true }))
    editEquipment.value = (data.equipment || []).map(e => ({
      management_no: e.management_no || '', equipment_name: e.equipment_name || '',
      model: e.model || '', binding_role: e.binding_role || 'primary',
      required: e.required || false, note: e.note || '', _dirty: true,
      measuring_range: e.measuring_range || '',
      manufacturer: e.manufacturer || '',
      serial_no: e.serial_no || '',
      calibration_time: e.calibration_time || '',
      equipment_class: e.equipment_class || '',
      responsible: e.responsible || '',
    }))
    editMeta.value = {
      experiment_name: data.experiment_name || '',
      record_template_file: data.record_template_file || '',
      camera_hints: Object.entries(data.camera_hints || {}).map(([code, hint]) => ({ code, hint })),
      report_decisive_photo_codes: (data.report_decisive_photo_codes || []).map(code => ({ code })),
      _extra: data.extra_json || {},
    }
    ElMessage.success(`已导入模板：${editFields.value.length} 字段, ${editColumns.value.length} 列, ${editPhotos.value.length} 拍照节点, ${editEquipment.value.length} 设备`)
  } catch (e) {
    ElMessage.error('导入失败')
  } finally { editorLoading.value = false }
}

// ── 字段操作 ──
function addField() {
  const maxOrder = editFields.value.reduce((m, f) => Math.max(m, f.section_order || 0), 0)
  editFields.value.push({
    key: '', label: '', type: 'text', default: '', options: [], readonly: false,
    section_title: '', section_order: maxOrder, _dirty: true,
  })
}
function removeField(idx) { editFields.value.splice(idx, 1) }

// ── 列操作 ──
function addColumn() {
  editColumns.value.push({
    column_key: '', column_label: '', column_type: 'number', column_default: '',
    calc_expression: null, calc_precision: 3, _dirty: true,
  })
}
function removeColumn(idx) { editColumns.value.splice(idx, 1) }

// ── 自定义公式编辑 ──
function openCalcDialog(row) {
  calcEditingRow.value = row
  const expr = row.calc_expression && typeof row.calc_expression === 'object' ? row.calc_expression : {}
  const args = expr.args && typeof expr.args === 'object' ? expr.args : {}
  calcForm.op = expr.op || 'avg'
  calcForm.inputsText = Array.isArray(expr.inputs) ? expr.inputs.join(', ') : (expr.inputs || '')
  calcForm.precision = args.precision != null ? args.precision : (row.calc_precision != null ? row.calc_precision : 3)
  calcForm.constant = args.constant != null ? args.constant : ''
  calcForm.true_value = args.true_value != null ? args.true_value : '符合'
  calcForm.false_value = args.false_value != null ? args.false_value : '不符合'
  calcForm.match = args.match != null ? args.match : ''
  calcDialogVisible.value = true
}
function saveCalcDialog() {
  const row = calcEditingRow.value
  if (!row) return
  const inputs = calcForm.inputsText.split(/[,，\s]+/).map(s => s.trim()).filter(Boolean)
  if (!inputs.length && !['count'].includes(calcForm.op)) {
    ElMessage.warning('请输入引用的列编码（逗号分隔）'); return
  }
  const args = {}
  if (calcForm.precision !== '' && calcForm.precision != null) args.precision = Number(calcForm.precision)
  if (calcForm.constant !== '' && calcForm.constant != null) args.constant = Number(calcForm.constant)
  if (calcForm.true_value !== '' && calcForm.true_value != null) args.true_value = String(calcForm.true_value)
  if (calcForm.false_value !== '' && calcForm.false_value != null) args.false_value = String(calcForm.false_value)
  if (calcForm.match !== '' && calcForm.match != null) args.match = String(calcForm.match)
  row.calc_expression = { op: calcForm.op, inputs, args }
  row.calc_precision = Number(calcForm.precision) || 3
  row._dirty = true
  calcDialogVisible.value = false
  ElMessage.success(`已配置公式：${calcForm.op}(${inputs.join(', ') || '—'})`)
}

// ── 拍照节点 ──
function addPhoto() {
  editPhotos.value.push({ code: '', label: '', required: true, sampleLevel: false, group: '', _dirty: true })
}
function removePhoto(idx) { editPhotos.value.splice(idx, 1) }

// ── 预检 ──
function addPrecheck() {
  editPrechecks.value.push({ label: '', _dirty: true })
}
function removePrecheck(idx) { editPrechecks.value.splice(idx, 1) }

// ── 设备绑定 ──
async function searchEquipment(query) {
  if (!query || query.length < 1) { equipOptions.value = []; return }
  equipSearchLoading.value = true
  try {
    const { data } = await request.get('/equipment', { params: { search: query, limit: 20 } })
    equipOptions.value = Array.isArray(data) ? data : []
  } catch { equipOptions.value = [] }
  finally { equipSearchLoading.value = false }
}
function addEquipment() {
  editEquipment.value.push({
    management_no: '', equipment_name: '', model: '',
    binding_role: 'primary', required: true, note: '', _dirty: true,
    measuring_range: '', manufacturer: '', serial_no: '',
    calibration_time: '', equipment_class: '', responsible: '',
  })
}
function selectEquipment(idx, equip) {
  // Fill equipment info from registry selection (syncs with ExperimentRun Step 2 display)
  const e = editEquipment.value[idx]
  e.management_no = equip.management_no || ''
  e.equipment_name = equip.equipment_name || ''
  e.model = equip.model || ''
  e.measuring_range = equip.measuring_range || ''
  e.manufacturer = equip.manufacturer || ''
  e.serial_no = equip.serial_no || ''
  e.calibration_time = equip.calibration_time || ''
  e.equipment_class = equip.equipment_class || ''
  e.responsible = equip.responsible || ''
  e._dirty = true
  equipOptions.value = []
}
function removeEquipment(idx) { editEquipment.value.splice(idx, 1) }

// ── 元数据/提示 ──
function addCameraHint() { editMeta.value.camera_hints.push({ code: '', hint: '' }) }
function removeCameraHint(idx) { editMeta.value.camera_hints.splice(idx, 1) }
function addDecisiveCode() { editMeta.value.report_decisive_photo_codes.push({ code: '' }) }
function removeDecisiveCode(idx) { editMeta.value.report_decisive_photo_codes.splice(idx, 1) }

// ── 保存编辑器 ──
async function saveEditor() {
  editorSaving.value = true
  try {
    // 构建提交数据 — 还原 DB 字段名
    const fieldsPayload = editFields.value.map(f => ({
      field_key: f.key, field_label: f.label, field_type: f.type,
      field_default: String(f.default ?? ''), field_options: Array.isArray(f.options) ? JSON.stringify(f.options) : String(f.options || ''),
      is_readonly: f.readonly || false, is_required: f.required || false,
      section_title: f.section_title || '', section_order: f.section_order || 0, sort_order: 0,
    }))
    const columnsPayload = editColumns.value.map(c => ({
      column_key: c.column_key, column_label: c.column_label, column_type: c.column_type,
      column_default: String(c.column_default ?? ''),
      calc_expression: c.calc_expression && typeof c.calc_expression === 'object' ? JSON.stringify(c.calc_expression) : (c.calc_expression || ''),
      calc_precision: c.calc_precision != null ? c.calc_precision : 3,
    }))
    const photosPayload = editPhotos.value.map(p => ({
      checkpoint_code: p.code, checkpoint_label: p.label, is_required: p.required !== false,
      is_sample_level: p.sampleLevel === true, checkpoint_group: p.group || null, sort_order: 0,
    }))
    const prechecksPayload = editPrechecks.value.map(p => ({
      precheck_label: p.label, precheck_code: '', is_required: true, sort_order: 0,
    }))
    const equipmentPayload = editEquipment.value.map((e, i) => ({
      management_no: e.management_no, binding_role: e.binding_role || 'primary',
      required: e.required || false, sort_order: i, note: e.note || '',
    }))

    // extra_json：合并原始 extra_json（保留 constants 等其它键），覆盖三个可编辑键
    const cameraHints = {}
    editMeta.value.camera_hints.forEach(({ code, hint }) => { if (code) cameraHints[code] = hint || '' })
    const decisiveCodes = editMeta.value.report_decisive_photo_codes.map(c => c.code).filter(Boolean)
    const extraJson = {
      ...(editMeta.value._extra || {}),
      camera_hints: cameraHints,
      report_decisive_photo_codes: decisiveCodes,
      record_template_file: editMeta.value.record_template_file || '',
    }

    // 标签→编码自动匹配的坐标映射（写入 template_field_mappings）
    const fieldMappingsPayload = []
    for (const f of editFields.value) {
      if (f._map && f.key) fieldMappingsPayload.push({ field_key: f.key, ...f._map })
    }
    for (const c of editColumns.value) {
      if (c._map && c.column_key) fieldMappingsPayload.push({ field_key: c.column_key, ...c._map })
    }

    await request.put(
      `/config/${editorExperimentCode.value}/versions/${editorVersion.value}`,
      {
        experiment_name: editMeta.value.experiment_name || null,
        fields: fieldsPayload, columns: columnsPayload, photo_checkpoints: photosPayload,
        prechecks: prechecksPayload, equipment: equipmentPayload, extra_json: extraJson,
        field_mappings: fieldMappingsPayload.length ? fieldMappingsPayload : null,
      },
    )
    ElMessage.success('配置已保存')
    editorVisible.value = false
    openVersions(selectedExperiment.value)
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '保存失败')
  } finally { editorSaving.value = false }
}

// ============ 模板自动匹配向导（任务三 P4） ============
const autoMapVisible = ref(false)
const autoMapLoading = ref(false)
const autoMapSaving = ref(false)
const autoMapResult = ref(null)   // { template_name, count, matched_count, unmatched_count, fields: [...] }

async function openAutoMap() {
  autoMapVisible.value = true
  autoMapLoading.value = true
  autoMapResult.value = null
  try {
    const { data } = await request.post(
      `/config/${editorExperimentCode.value}/versions/${editorVersion.value}/auto-map`,
      { apply: false },
    )
    autoMapResult.value = data
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '模板解析失败')
    autoMapVisible.value = false
  } finally { autoMapLoading.value = false }
}

async function applyAutoMap() {
  const fields = (autoMapResult.value?.fields || []).map(f => ({
    table: f.table, row: f.row, col: f.col,
    label: f.label, section: f.section,
    input_type: f.input_type, field_key: (f.field_key || '').trim(),
  }))
  autoMapSaving.value = true
  try {
    await request.post(
      `/config/${editorExperimentCode.value}/versions/${editorVersion.value}/auto-map`,
      { apply: true, fields },
    )
    ElMessage.success(`已写入 ${fields.length} 个字段与坐标映射`)
    autoMapVisible.value = false
    await fetchEditorData()
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '写入失败')
  } finally { autoMapSaving.value = false }
}

function getStatusTag(s) {
  const map = { '现行': 'success', '草稿': 'info', '历史': '' }
  return map[s] || 'info'
}

function optionsStr(opts) {
  if (Array.isArray(opts)) return opts.join(', ')
  if (typeof opts === 'string') {
    try { const p = JSON.parse(opts); if (Array.isArray(p)) return p.join(', ') } catch {}
    return opts
  }
  return ''
}
function parseOptionsInput(val) {
  return val.split(/[,;，；]/).map(s => s.trim()).filter(Boolean)
}

// ── 标签 → 编码 + 模板坐标 匹配 ──
async function matchLabelFor(row, kind) {
  const label = (kind === 'field' ? row.label : row.column_label || '').trim()
  if (!label) return
  try {
    const { data } = await request.post(`/config/${editorExperimentCode.value}/match-label`, { label })
    const keyField = kind === 'field' ? 'key' : 'column_key'
    if (data.matched) {
      if (data.field_key) row[keyField] = data.field_key
      row._map = { table: data.table, row: data.row, col: data.col, transform: data.input_type === 'checkbox' ? 'checkbox' : 'text' }
      row._mapText = `已匹配：${data.field_key || '（无词库编码）'} @ ${data.position}`
      row._dirty = true
      ElMessage.success(`已匹配「${data.label}」→ ${data.field_key || '（请手动填编码）'} @ ${data.position}`)
    } else {
      if (data.field_key) { row[keyField] = data.field_key; row._dirty = true }
      row._map = null
      row._mapText = ''
      ElMessage.warning(data.reason || '未在模板中匹配到该标签，请确认标签或手动填写编码')
    }
  } catch (e) {
    ElMessage.error(e.response?.data?.detail || '匹配失败')
  }
}

</script>

<template>
  <div class="page">
    <div class="page-header">
      <h1>检测项目与方法库</h1>
      <el-button v-if="canManage" type="primary" :icon="Plus" @click="showAddMethod">新增检测项目</el-button>
    </div>

    <el-card>
      <el-table :data="methods" v-loading="loading" stripe empty-text="暂无数据">
        <el-table-column prop="experiment_code" label="项目代码" width="120" />
        <el-table-column prop="experiment_name" label="检测项目" min-width="200" />
        <el-table-column prop="method_code" label="方法编号" width="140" />
        <el-table-column prop="standard" label="标准" min-width="200">
          <template #default="{ row }">
            <div style="white-space:pre-wrap">{{ row.standard }}</div>
            <el-tag v-if="row.standard_count > 0" size="small" type="info" style="margin-top:4px">+{{ row.standard_count }} 个标准变体</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="category" label="类别" width="120">
          <template #default="{ row }"><el-tag size="small">{{ row.category }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="kind" label="类型" width="100" />
        <el-table-column prop="current_version" label="现行版本" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.current_version" type="success" size="small">{{ row.current_version }}</el-tag>
            <span v-else style="color:#94A3B8">默认</span>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="340">
          <template #default="{ row }">
            <el-button v-if="canManage" text type="primary" :icon="Edit" @click="openEditMethod(row)">编辑</el-button>
            <el-button v-if="canManage" text type="primary" @click="openStandards(row)">标准管理</el-button>
            <el-button text type="primary" @click="openVersions(row)">版本管理</el-button>
            <el-button v-if="canManage" text type="danger" :icon="Delete" @click="handleDeleteMethod(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- ====== 版本列表对话框 ====== -->
    <el-dialog v-model="versionDialogVisible" :title="`${selectedExperiment?.experiment_code} — 配置版本`" width="800px">
      <div v-if="isAdmin" style="margin-bottom:12px">
        <el-button type="primary" :icon="Plus" @click="showCreateVersion">新建版本</el-button>
      </div>
      <el-table :data="versions" v-loading="versionLoading" stripe empty-text="暂无配置版本">
        <el-table-column prop="version" label="版本号" width="100" />
        <el-table-column prop="status" label="状态" width="80">
          <template #default="{ row }"><el-tag :type="getStatusTag(row.status)" size="small">{{ row.status }}</el-tag></template>
        </el-table-column>
        <el-table-column prop="effective_date" label="生效日期" width="120" />
        <el-table-column prop="created_at" label="创建时间" width="160" />
        <el-table-column prop="approved_by" label="批准人" width="100" />
        <el-table-column label="操作" min-width="250" v-if="isAdmin">
          <template #default="{ row }">
            <el-button text type="primary" :icon="Edit" @click="openEditor(row)">编辑</el-button>
            <el-button v-if="row.status !== '现行'" text type="success" :icon="Check" @click="activateVersion(selectedExperiment.experiment_code, row.version)">激活</el-button>
            <el-button v-if="row.status === '现行'" text type="warning" @click="archiveVersion(selectedExperiment.experiment_code, row.version)">归档</el-button>
            <el-button v-if="row.status === '草稿'" text type="danger" :icon="Delete" @click="deleteVersion(selectedExperiment.experiment_code, row.version)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-dialog>

    <!-- ====== 版本编辑器对话框 ====== -->
    <el-dialog v-model="editorVisible" :title="`编辑配置 — ${editorExperimentCode} / ${editorVersion}`" width="1100px" :close-on-click-modal="false" v-loading="editorLoading">
      <div style="margin-bottom:12px;display:flex;gap:8px">
        <el-button :icon="Download" @click="loadFromTemplate">从硬编码模板导入</el-button>
        <el-button type="primary" plain :icon="MagicStick" @click="openAutoMap">模板自动匹配</el-button>
        <span style="color:#94A3B8;font-size:12px;line-height:32px;margin-left:8px">自动解析模板生成字段与坐标映射（覆盖现有字段/映射）</span>
      </div>

      <el-tabs v-model="editorActiveTab">
        <!-- 表单字段 -->
        <el-tab-pane label="表单字段" name="fields">
          <div style="margin-bottom:8px">
            <el-button size="small" :icon="Plus" @click="addField">添加字段</el-button>
            <span style="color:#94A3B8;font-size:12px;margin-left:8px">{{ editFields.length }} 个字段</span>
          </div>
          <div style="max-height:400px;overflow-y:auto">
            <el-table :data="editFields" size="small" stripe>
              <el-table-column prop="section_title" label="分区标题" width="140">
                <template #default="{ row }"><el-input v-model="row.section_title" size="small" placeholder="如 环境与设备" /></template>
              </el-table-column>
              <el-table-column prop="section_order" label="分区序" width="70">
                <template #default="{ row }"><el-input-number v-model="row.section_order" size="small" :min="0" controls-position="right" style="width:60px" /></template>
              </el-table-column>
              <el-table-column prop="key" label="字段编码" width="130">
                <template #default="{ row }"><el-input v-model="row.key" size="small" placeholder="如 test_date" /></template>
              </el-table-column>
              <el-table-column prop="label" label="字段标签" min-width="160">
                <template #default="{ row }">
                  <el-input v-model="row.label" size="small" placeholder="如 检测日期" @blur="matchLabelFor(row, 'field')" />
                  <div v-if="row._mapText" style="font-size:11px;color:#16A34A;margin-top:2px">{{ row._mapText }}</div>
                </template>
              </el-table-column>
              <el-table-column prop="type" label="类型" width="110">
                <template #default="{ row }">
                  <el-select v-model="row.type" size="small" style="width:100px">
                    <el-option v-for="t in FIELD_TYPES" :key="t" :label="t" :value="t" />
                  </el-select>
                </template>
              </el-table-column>
              <el-table-column prop="default" label="默认值" width="100">
                <template #default="{ row }"><el-input v-model="row.default" size="small" placeholder="可选" /></template>
              </el-table-column>
              <el-table-column prop="options" label="选项" width="140">
                <template #default="{ row }">
                  <el-input :model-value="optionsStr(row.options)" size="small" placeholder="逗号分隔" @change="(v) => row.options = parseOptionsInput(v || '')" />
                </template>
              </el-table-column>
              <el-table-column prop="readonly" label="只读" width="55">
                <template #default="{ row }"><el-checkbox v-model="row.readonly" size="small" /></template>
              </el-table-column>
              <el-table-column label="" width="50">
                <template #default="{ $index }"><el-button text type="danger" size="small" :icon="Delete" @click="removeField($index)" /></template>
              </el-table-column>
            </el-table>
          </div>
        </el-tab-pane>

        <!-- 测量列 -->
        <el-tab-pane label="测量列" name="columns">
          <div style="margin-bottom:8px">
            <el-button size="small" :icon="Plus" @click="addColumn">添加列</el-button>
            <span style="color:#94A3B8;font-size:12px;margin-left:8px">{{ editColumns.length }} 列</span>
          </div>
          <el-table :data="editColumns" size="small" stripe>
            <el-table-column prop="column_key" label="列编码" width="140">
              <template #default="{ row }"><el-input v-model="row.column_key" size="small" placeholder="如 ra1" /></template>
            </el-table-column>
            <el-table-column prop="column_label" label="列标签" min-width="180">
              <template #default="{ row }">
                <el-input v-model="row.column_label" size="small" placeholder="如 Ra1/μm" @blur="matchLabelFor(row, 'column')" />
                <div v-if="row._mapText" style="font-size:11px;color:#16A34A;margin-top:2px">{{ row._mapText }}</div>
              </template>
            </el-table-column>
            <el-table-column prop="column_type" label="类型" width="170">
              <template #default="{ row }">
                <el-select v-model="row.column_type" size="small" style="width:160px" filterable allow-create>
                  <el-option v-for="t in COLUMN_TYPES" :key="t" :label="t" :value="t" />
                </el-select>
              </template>
            </el-table-column>
            <el-table-column prop="column_default" label="默认值" width="100">
              <template #default="{ row }"><el-input v-model="row.column_default" size="small" placeholder="可选" /></template>
            </el-table-column>
            <el-table-column prop="calc_expression" label="公式" width="110">
              <template #default="{ row }">
                <template v-if="row.column_type === 'calc'">
                  <el-button size="small" text type="primary" @click="openCalcDialog(row)">
                    {{ row.calc_expression && row.calc_expression.op ? row.calc_expression.op : '配置公式' }}
                  </el-button>
                </template>
                <span v-else style="color:#CBD5E1">—</span>
              </template>
            </el-table-column>
            <el-table-column label="" width="50">
              <template #default="{ $index }"><el-button text type="danger" size="small" :icon="Delete" @click="removeColumn($index)" /></template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 拍照节点 -->
        <el-tab-pane label="拍照节点" name="photos">
          <div style="margin-bottom:8px">
            <el-button size="small" :icon="Plus" @click="addPhoto">添加节点</el-button>
            <span style="color:#94A3B8;font-size:12px;margin-left:8px">{{ editPhotos.length }} 节点</span>
          </div>
          <el-table :data="editPhotos" size="small" stripe>
            <el-table-column prop="code" label="节点编码" width="160">
              <template #default="{ row }"><el-input v-model="row.code" size="small" placeholder="如 SAMPLE_BEFORE" /></template>
            </el-table-column>
            <el-table-column prop="label" label="节点标签" min-width="250">
              <template #default="{ row }"><el-input v-model="row.label" size="small" placeholder="如 实验前样品及标签" /></template>
            </el-table-column>
            <el-table-column prop="required" label="必填" width="60">
              <template #default="{ row }"><el-checkbox v-model="row.required" size="small" /></template>
            </el-table-column>
            <el-table-column label="级别" width="120">
              <template #default="{ row }">
                <el-select v-model="row.sampleLevel" size="small" style="width:110px">
                  <el-option label="任务级" :value="false" />
                  <el-option label="样品级" :value="true" />
                </el-select>
              </template>
            </el-table-column>
            <el-table-column label="" width="50">
              <template #default="{ $index }"><el-button text type="danger" size="small" :icon="Delete" @click="removePhoto($index)" /></template>
            </el-table-column>
          </el-table>
          <div style="color:#94A3B8;font-size:12px;margin-top:8px">
            级别说明：「任务级」整个实验过程仅拍摄一次；「样品级」按样品数量逐一拍摄（拍摄数量随样品数变化）。
          </div>
        </el-tab-pane>

        <!-- 预检查项 -->
        <el-tab-pane label="预检项" name="prechecks">
          <div style="margin-bottom:8px">
            <el-button size="small" :icon="Plus" @click="addPrecheck">添加预检</el-button>
            <span style="color:#94A3B8;font-size:12px;margin-left:8px">{{ editPrechecks.length }} 项</span>
          </div>
          <el-table :data="editPrechecks" size="small" stripe>
            <el-table-column prop="label" label="检查项标签" min-width="400">
              <template #default="{ row }"><el-input v-model="row.label" size="small" placeholder="如 设备校准证书在有效期内" /></template>
            </el-table-column>
            <el-table-column label="" width="50">
              <template #default="{ $index }"><el-button text type="danger" size="small" :icon="Delete" @click="removePrecheck($index)" /></template>
            </el-table-column>
          </el-table>
        </el-tab-pane>

        <!-- 设备绑定（与 ExperimentRun Step 2 设备确认已同步） -->
        <el-tab-pane label="设备绑定" name="equipment">
          <div style="margin-bottom:8px;display:flex;align-items:center;gap:8px">
            <el-button size="small" :icon="Plus" @click="addEquipment">添加设备</el-button>
            <span style="color:#94A3B8;font-size:12px">{{ editEquipment.length }} 台设备已绑定</span>
          </div>
          <el-table :data="editEquipment" size="small" stripe>
            <el-table-column label="管理编号" width="160">
              <template #default="{ row, $index }">
                <el-select
                  v-model="row.management_no"
                  size="small"
                  filterable
                  remote
                  :remote-method="searchEquipment"
                  :loading="equipSearchLoading"
                  placeholder="搜索设备"
                  style="width:150px"
                  @change="(val) => { const found = equipOptions.find(e => e.management_no === val); if (found) selectEquipment($index, found) }"
                >
                  <el-option v-for="eq in equipOptions" :key="eq.management_no" :label="`${eq.equipment_name} (${eq.management_no})`" :value="eq.management_no" />
                </el-select>
              </template>
            </el-table-column>
            <el-table-column prop="equipment_name" label="设备名称" width="140">
              <template #default="{ row }"><el-input v-model="row.equipment_name" size="small" placeholder="自动填充" /></template>
            </el-table-column>
            <el-table-column prop="model" label="型号" width="100">
              <template #default="{ row }"><el-input v-model="row.model" size="small" placeholder="自动填充" /></template>
            </el-table-column>
            <el-table-column prop="binding_role" label="角色" width="90">
              <template #default="{ row }">
                <el-select v-model="row.binding_role" size="small" style="width:80px">
                  <el-option label="主设备" value="primary" />
                  <el-option label="辅助" value="auxiliary" />
                </el-select>
              </template>
            </el-table-column>
            <el-table-column prop="required" label="必需" width="55">
              <template #default="{ row }"><el-checkbox v-model="row.required" size="small" /></template>
            </el-table-column>
            <el-table-column label="台账信息（在Step 2中只读显示）" min-width="180">
              <template #default="{ row }">
                <div style="font-size:11px;color:#94A3B8;line-height:1.5">
                  <span v-if="row.manufacturer || row.model">厂家/型号：{{ [row.manufacturer, row.model].filter(Boolean).join(' / ') }}</span>
                  <span v-if="row.measuring_range" style="display:block">测量范围：{{ row.measuring_range }}</span>
                  <span v-if="row.serial_no" style="display:block">编号：{{ row.serial_no }}</span>
                  <span v-if="row.calibration_time" style="display:block">校准：{{ row.calibration_time }}</span>
                  <span v-if="!row.manufacturer && !row.measuring_range && !row.serial_no && !row.calibration_time" style="color:#CBD5E1">从设备库选择后自动带入</span>
                </div>
              </template>
            </el-table-column>
            <el-table-column prop="note" label="配置备注" width="120">
              <template #default="{ row }"><el-input v-model="row.note" size="small" placeholder="可选" /></template>
            </el-table-column>
            <el-table-column label="" width="50">
              <template #default="{ $index }"><el-button text type="danger" size="small" :icon="Delete" @click="removeEquipment($index)" /></template>
            </el-table-column>
          </el-table>
          <div style="color:#94A3B8;font-size:12px;margin-top:8px">
            此处绑定的设备会自动带入实验执行的「②设备与实验前检查」步骤。管理编号和角色/必需字段存储在配置版本中，设备名称、型号、测量范围等台账信息从设备库实时拉取，与Step 2显示一致。
          </div>
        </el-tab-pane>

        <!-- 元数据/提示（extra_json 权威来源，硬编码仅兜底） -->
        <el-tab-pane label="元数据/提示" name="meta">
          <el-form label-width="140px" size="small">
            <el-form-item label="实验名称">
              <el-input v-model="editMeta.experiment_name" placeholder="如 表面粗糙度试验" style="max-width:360px" />
            </el-form-item>
            <el-form-item label="记录模板文件名">
              <el-input v-model="editMeta.record_template_file" placeholder="如 R001_表面粗糙度试验_CMA原始记录表.docx" style="max-width:480px" />
            </el-form-item>
          </el-form>

          <div style="margin:8px 0;font-weight:600">拍照提示词（camera_hints）</div>
          <div style="margin-bottom:8px">
            <el-button size="small" :icon="Plus" @click="addCameraHint">添加提示</el-button>
            <span style="color:#94A3B8;font-size:12px;margin-left:8px">{{ editMeta.camera_hints.length }} 条</span>
          </div>
          <div style="max-height:240px;overflow-y:auto">
            <el-table :data="editMeta.camera_hints" size="small" stripe>
              <el-table-column prop="code" label="节点编码" width="220">
                <template #default="{ row }"><el-input v-model="row.code" size="small" placeholder="如 ENV" /></template>
              </el-table-column>
              <el-table-column prop="hint" label="提示词" min-width="360">
                <template #default="{ row }"><el-input v-model="row.hint" size="small" placeholder="拍照提示" /></template>
              </el-table-column>
              <el-table-column label="" width="50">
                <template #default="{ $index }"><el-button text type="danger" size="small" :icon="Delete" @click="removeCameraHint($index)" /></template>
              </el-table-column>
            </el-table>
          </div>

          <div style="margin:8px 0;font-weight:600">决定性照片节点编码（report_decisive_photo_codes）</div>
          <div style="margin-bottom:8px">
            <el-button size="small" :icon="Plus" @click="addDecisiveCode">添加编码</el-button>
            <span style="color:#94A3B8;font-size:12px;margin-left:8px">{{ editMeta.report_decisive_photo_codes.length }} 个</span>
          </div>
          <div style="max-height:200px;overflow-y:auto">
            <el-table :data="editMeta.report_decisive_photo_codes" size="small" stripe>
              <el-table-column prop="code" label="节点编码" min-width="360">
                <template #default="{ row }"><el-input v-model="row.code" size="small" placeholder="如 ROUGH_POINT_1" /></template>
              </el-table-column>
              <el-table-column label="" width="50">
                <template #default="{ $index }"><el-button text type="danger" size="small" :icon="Delete" @click="removeDecisiveCode($index)" /></template>
              </el-table-column>
            </el-table>
          </div>

          <div style="color:#94A3B8;font-size:12px;margin-top:8px">
            这些值写入 extra_json，优先于代码中的硬编码兜底；留空则回退代码默认值。改后导出 Word 与实验执行页会立即反映。
          </div>
        </el-tab-pane>
      </el-tabs>

      <template #footer>
        <el-button @click="editorVisible = false">取消</el-button>
        <el-button type="primary" :loading="editorSaving" @click="saveEditor">💾 保存配置</el-button>
      </template>
    </el-dialog>

    <!-- ====== 自定义公式编辑对话框 ====== -->
    <el-dialog v-model="calcDialogVisible" title="配置计算列公式" width="560px" :close-on-click-modal="false">
      <el-form v-if="calcEditingRow" label-width="110px">
        <el-form-item label="计算列">
          <el-input :value="`${calcEditingRow.column_label || '未命名'}（${calcEditingRow.column_key || '未填编码'}）`" disabled />
        </el-form-item>
        <el-form-item label="算子" required>
          <el-select v-model="calcForm.op" filterable style="width:100%">
            <el-option v-for="op in CALC_OPS" :key="op.value" :label="op.label" :value="op.value" />
          </el-select>
        </el-form-item>
        <el-form-item label="引用列编码">
          <el-input v-model="calcForm.inputsText" placeholder="逗号分隔，如 ra1, ra2, ra3（本行内引用）" />
        </el-form-item>
        <el-form-item label="精度(小数位)">
          <el-input-number v-model="calcForm.precision" :min="0" :max="8" controls-position="right" style="width:100%" />
        </el-form-item>
        <el-form-item label="常数阈值">
          <el-input v-model="calcForm.constant" placeholder="比较/算术常量，如 15、0.5（可选）" />
        </el-form-item>
        <el-form-item label="判为(真)">
          <el-input v-model="calcForm.true_value" placeholder="如 符合 / 合格" />
        </el-form-item>
        <el-form-item label="判为(假)">
          <el-input v-model="calcForm.false_value" placeholder="如 不符合 / 不合格" />
        </el-form-item>
        <el-form-item label="命中值 match">
          <el-input v-model="calcForm.match" placeholder="all_eq / count_if 的命中值，如 无（可选）" />
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="calcDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveCalcDialog">确定</el-button>
      </template>
    </el-dialog>

    <!-- ====== 模板自动匹配向导对话框 ====== -->
    <el-dialog v-model="autoMapVisible" title="模板自动匹配向导" width="980px" :close-on-click-modal="false" v-loading="autoMapLoading">
      <div v-if="autoMapResult" style="margin-bottom:12px;display:flex;gap:16px;align-items:center;flex-wrap:wrap">
        <span style="color:#334155">模板：<b>{{ autoMapResult.template_name }}</b></span>
        <el-tag type="success" size="small">命中 {{ autoMapResult.matched_count }}</el-tag>
        <el-tag type="warning" size="small">未命中 {{ autoMapResult.unmatched_count }}</el-tag>
        <span style="color:#94A3B8;font-size:12px">黄色行为未命中项，请确认或修正字段编码后提交</span>
      </div>
      <el-table
        :data="autoMapResult?.fields || []"
        size="small" stripe
        :row-class-name="({ row }) => (row.matched ? '' : 'unmatched-row')"
        max-height="440"
      >
        <el-table-column prop="position" label="位置" width="110" />
        <el-table-column prop="label" label="模板标签" min-width="160" show-overflow-tooltip />
        <el-table-column prop="section" label="分区" min-width="140" show-overflow-tooltip />
        <el-table-column prop="input_type" label="类型" width="90">
          <template #default="{ row }">
            <el-tag :type="row.input_type === 'checkbox' ? 'info' : ''" size="small">{{ row.input_type === 'checkbox' ? '勾选' : '填空' }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="field_key" label="字段编码" width="190">
          <template #default="{ row }">
            <el-input v-model="row.field_key" size="small" placeholder="field_N" :class="{ 'unmatched-input': !row.matched }" />
          </template>
        </el-table-column>
        <el-table-column label="状态" width="80">
          <template #default="{ row }">
            <el-tag v-if="row.matched" type="success" size="small">命中</el-tag>
            <el-tag v-else type="warning" size="small">未命中</el-tag>
          </template>
        </el-table-column>
      </el-table>
      <template #footer>
        <el-button @click="autoMapVisible = false">取消</el-button>
        <el-button type="primary" :loading="autoMapSaving" @click="applyAutoMap">确认并写入</el-button>
      </template>
    </el-dialog>

    <!-- ====== 新建版本对话框 ====== -->
    <el-dialog v-model="createDialogVisible" title="新建配置版本" width="520px">
      <el-form :model="createForm" label-width="100px">
        <el-form-item label="实验编码"><el-input :model-value="createForm.experiment_code" disabled /></el-form-item>
        <el-form-item label="版本号" required><el-input v-model="createForm.version" placeholder="如 V2.0, A/1" /></el-form-item>
        <el-form-item label="实验名称" required><el-input v-model="createForm.experiment_name" /></el-form-item>
        <el-form-item label="方法编号" required><el-input v-model="createForm.method_code" /></el-form-item>
        <el-form-item label="标准"><el-input v-model="createForm.standard" /></el-form-item>
        <el-form-item label="类别"><el-input v-model="createForm.category" /></el-form-item>
        <el-form-item label="生效日期"><el-input v-model="createForm.effective_date" type="date" style="width:100%" /></el-form-item>
        <el-form-item label="备注"><el-input v-model="createForm.note" type="textarea" :rows="2" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="createDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleCreateVersion" :loading="createLoading">创建</el-button>
      </template>
    </el-dialog>

    <!-- ====== 新增检测项目对话框 ====== -->
    <el-dialog v-model="addMethodDialogVisible" title="新增检测项目" width="560px" :close-on-click-modal="false">
      <el-form :model="addMethodForm" label-width="100px">
        <el-form-item label="实验编码" required><el-input v-model="addMethodForm.experiment_code" placeholder="如 I010" /></el-form-item>
        <el-form-item label="实验名称" required><el-input v-model="addMethodForm.experiment_name" /></el-form-item>
        <el-form-item label="方法编号" required><el-input v-model="addMethodForm.method_code" /></el-form-item>
        <el-form-item label="标准"><el-input v-model="addMethodForm.standard" /></el-form-item>
        <el-form-item label="类别"><el-input v-model="addMethodForm.category" /></el-form-item>
        <el-form-item label="实验类型">
          <el-select v-model="addMethodForm.kind" style="width:100%">
            <el-option label="通用 (generic)" value="generic" />
            <el-option label="表面粗糙度 (rough)" value="rough" />
            <el-option label="金瓷结合裂纹 (mc_crack)" value="mc_crack" />
            <el-option label="X射线灰度 (xray)" value="xray" />
            <el-option label="翘曲变形 (warp)" value="warp" />
            <el-option label="热膨胀系数 (cte)" value="cte" />
            <el-option label="耐急冷急热 (shock)" value="shock" />
            <el-option label="弯曲性能 (bend)" value="bend" />
            <el-option label="维氏硬度 (hv)" value="hv" />
            <el-option label="厚度测量 (thickness)" value="thickness" />
            <el-option label="色稳定性 (color)" value="color" />
            <el-option label="固定义齿综合 (fixed_denture)" value="fixed_denture" />
            <el-option label="活动义齿综合 (removable_denture)" value="removable_denture" />
          </el-select>
        </el-form-item>

        <el-divider content-position="left">
          <span style="font-size:13px;color:#64748B">Word 一键导入（可选，上传后自动生成配置版本 V1.0）</span>
        </el-divider>
        <el-form-item label="记录模板">
          <el-upload
            :auto-upload="false"
            :limit="1"
            accept=".docx"
            :file-list="recordTemplateFile ? [{ name: recordTemplateFile.name }] : []"
            :on-change="(f) => recordTemplateFile = f.raw"
            :on-remove="() => recordTemplateFile = null"
            style="width:100%"
          >
            <el-button size="small">选择 .docx 原始记录模板</el-button>
            <div class="el-upload__tip" style="font-size:12px;color:#94A3B8">解析填空/勾选格并自动匹配字段编码</div>
          </el-upload>
        </el-form-item>
        <el-form-item label="SOP 文件">
          <el-upload
            :auto-upload="false"
            :limit="1"
            accept=".docx"
            :file-list="sopFile ? [{ name: sopFile.name }] : []"
            :on-change="(f) => sopFile = f.raw"
            :on-remove="() => sopFile = null"
            style="width:100%"
          >
            <el-button size="small">选择 .docx SOP 文件</el-button>
          </el-upload>
        </el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="addMethodDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleAddMethod" :loading="addMethodLoading">
          {{ recordTemplateFile || sopFile ? '一键导入' : '添加' }}
        </el-button>
      </template>
    </el-dialog>

    <!-- ====== 编辑检测项目对话框 ====== -->
    <el-dialog v-model="editMethodDialogVisible" title="编辑检测项目" width="500px" :close-on-click-modal="false">
      <el-form :model="editMethodForm" label-width="100px">
        <el-form-item label="实验编码"><el-input :model-value="editMethodForm.experiment_code" disabled /></el-form-item>
        <el-form-item label="实验名称" required><el-input v-model="editMethodForm.experiment_name" /></el-form-item>
        <el-form-item label="方法编号" required><el-input v-model="editMethodForm.method_code" /></el-form-item>
        <el-form-item label="标准"><el-input v-model="editMethodForm.standard" /></el-form-item>
        <el-form-item label="类别"><el-input v-model="editMethodForm.category" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="editMethodDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="handleEditMethod" :loading="editMethodLoading">保存</el-button>
      </template>
    </el-dialog>

    <!-- ====== 标准变体管理对话框 ====== -->
    <el-dialog v-model="standardsDialogVisible" :title="`${standardsExperiment?.experiment_code} — 标准变体`" width="860px" :close-on-click-modal="false">
      <div style="margin-bottom:12px;display:flex;justify-content:space-between;align-items:center">
        <span style="color:#64748B;font-size:13px">同一检测项目可拆分为多个标准，独立使用；配置版本与父实验共享，沿用父实验编码，仅标准全文不同。</span>
        <el-button v-if="canManage" type="primary" :icon="Plus" @click="showAddStandard">新增标准</el-button>
      </div>
      <el-table :data="standards" v-loading="standardsLoading" stripe empty-text="暂无标准变体，将使用父实验的标准">
        <el-table-column prop="standard" label="标准全文" min-width="380">
          <template #default="{ row }"><div style="white-space:pre-wrap">{{ row.standard }}</div></template>
        </el-table-column>
        <el-table-column label="操作" width="120" v-if="canManage">
          <template #default="{ row }">
            <el-button text type="primary" :icon="Edit" @click="showEditStandard(row)">编辑</el-button>
            <el-button text type="danger" :icon="Delete" @click="handleDeleteStandard(row)">删除</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-dialog>

    <!-- ====== 标准变体新增/编辑对话框 ====== -->
    <el-dialog v-model="standardFormDialogVisible" :title="standardFormIsEdit ? '编辑标准变体' : '新增标准变体'" width="560px" :close-on-click-modal="false">
      <el-form :model="standardForm" label-width="100px">
        <el-form-item label="标准全文" required><el-input v-model="standardForm.standard" type="textarea" :rows="4" placeholder="如 GB 17168-2013《牙科学 固定和活动修复用金属材料》" /></el-form-item>
      </el-form>
      <template #footer>
        <el-button @click="standardFormDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="saveStandard" :loading="standardFormLoading">保存</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<style scoped>
.page { max-width: 1300px; }
.page-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; }
.page-header h1 { font-size: 22px; font-weight: 600; color: #0F172A; }
</style>

<style>
/* 模板自动匹配向导：未命中行高亮（Element Plus 表格行由子组件渲染，需全局样式） */
.unmatched-row { background-color: #FFF7E6 !important; }
.unmatched-row td { background-color: #FFF7E6 !important; }
.unmatched-input .el-input__wrapper { background-color: #FFF1D6; box-shadow: 0 0 0 1px #F0C060 inset; }
</style>
