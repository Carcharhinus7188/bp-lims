// 规格型号（model）规范化工具，与后端 app/core/model_utils.py 保持一致。
// 历史数据里存在「-」「无」等占位符，这些并非真实规格型号，视为未填写。
// 注：「标准」暂不作为占位符，允许作为规格型号值使用。
const PLACEHOLDERS = new Set([
  '', '-', '—', '－', '_', '无', '暂无', '不适用',
  'na', 'n/a', 'none', 'null', 'nil',
])

export function normalizeModel(value) {
  if (value === null || value === undefined) return ''
  const s = String(value).trim()
  return PLACEHOLDERS.has(s.toLowerCase()) ? '' : s
}

export function isRealModel(value) {
  return Boolean(normalizeModel(value))
}
