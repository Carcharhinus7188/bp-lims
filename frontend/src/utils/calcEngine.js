// 计算字段公式引擎（白名单求值器，扁平规则列表）。
// 与后端 backend/app/core/calc_engine.py 语义一致；后端为提交权威值。
// 严禁 eval / new Function / exec；非法 op / 未声明引用 → 置空，不抛异常。

const NUMERIC_OPS = new Set(['avg', 'sum', 'min', 'max', 'add', 'subtract', 'multiply', 'divide', 'abs', 'round'])
const VERDICT_OPS = new Set(['le', 'ge', 'lt', 'gt', 'eq', 'ne', 'abs_le', 'abs_ge', 'all_eq'])
const SPECIAL_OPS = new Set(['color_overall', 'color_conclusion'])
const ALLOWED_OPS = new Set([...NUMERIC_OPS, ...VERDICT_OPS, ...SPECIAL_OPS, 'count', 'count_if'])

// 空值归一
function resolve(v) {
  if (v === null || v === undefined || v === '') return null
  return v
}

function toNum(v) {
  if (v === null || v === undefined || v === '') return null
  if (typeof v === 'boolean') return null
  const n = Number(v)
  return Number.isFinite(n) ? n : null
}

// 四舍五入、远离零，与后端 Decimal(str(value)).quantize(ROUND_HALF_UP) 逐值对齐。
// 不能用 Number.toFixed（其按二进制浮点舍入，会与后端十进制舍入不一致）。
function expandExponential(s) {
  if (!s.includes('e') && !s.includes('E')) return s
  const [mant, exp] = s.toLowerCase().split('e')
  const e = parseInt(exp, 10)
  const dot = mant.indexOf('.')
  const digits = mant.replace('.', '')
  const pointPos = dot === -1 ? mant.length : dot
  const newPos = pointPos + e
  if (newPos <= 0) return '0.' + '0'.repeat(-newPos) + digits
  if (newPos >= digits.length) return digits + '0'.repeat(newPos - digits.length)
  return digits.slice(0, newPos) + '.' + digits.slice(newPos)
}

function roundHalfAway(value, precision) {
  if (value == null || !Number.isFinite(value)) return value
  if (precision == null) return value
  if (value === 0) return 0
  const neg = value < 0
  const norm = expandExponential(String(Math.abs(value)))
  const dot = norm.indexOf('.')
  const intPart = dot === -1 ? norm : norm.slice(0, dot)
  const fracPart = dot === -1 ? '' : norm.slice(dot + 1)
  const fracPadded = fracPart.padEnd(precision, '0')
  const kept = intPart + fracPadded.slice(0, precision)
  const droppedFirst = fracPart.length > precision ? fracPart[precision] : '0'
  let int = BigInt(kept || '0')
  if (Number(droppedFirst) >= 5) int += 1n
  let digits = int.toString()
  const totalLen = intPart.length + precision
  if (digits.length < totalLen) digits = digits.padStart(totalLen, '0')
  const whole = digits.slice(0, -precision)
  const frac = precision > 0 ? digits.slice(-precision) : ''
  const out = precision > 0 ? Number(`${whole}.${frac}`) : Number(whole)
  return neg ? -out : out
}

function roundIfNeeded(value, precision) {
  if (value == null) return null
  if (precision == null) return value
  return roundHalfAway(value, precision)
}

// ── 数值算子 ──
function requireAll(nums) {
  if (!nums.length) return false
  return nums.every(n => n !== null)
}

function opAvg(nums) { return requireAll(nums) ? nums.reduce((a, b) => a + b, 0) / nums.length : null }
function opSum(nums) { return requireAll(nums) ? nums.reduce((a, b) => a + b, 0) : null }
function opMin(nums) { return requireAll(nums) ? Math.min(...nums) : null }
function opMax(nums) { return requireAll(nums) ? Math.max(...nums) : null }
function opAdd(nums, args) { return requireAll(nums) ? nums.reduce((a, b) => a + b, 0) + Number(args?.constant || 0) : null }
function opSubtract(nums) { return nums.length >= 2 && requireAll(nums.slice(0, 2)) ? nums[0] - nums[1] : null }
function opMultiply(nums, args) {
  if (!requireAll(nums)) return null
  let out = 1
  for (const n of nums) out *= n
  if (args?.constant != null && args.constant !== '') out *= Number(args.constant)
  return out
}
function opDivide(nums, args) {
  if (nums.length < 2 || !requireAll(nums)) return null
  let out = (args?.constant == null || args.constant === '') ? 1 : Number(args.constant)
  out *= nums[0]
  for (let i = 1; i < nums.length; i++) {
    if (nums[i] === 0) return null
    out /= nums[i]
  }
  return out
}
function opAbs(nums) { return nums[0] != null ? Math.abs(nums[0]) : null }

// ── 比较算子（输出判定字符串）──
function cmpRhs(inputs, args) {
  if (inputs.length >= 2 && resolve(inputs[1]) !== null) return inputs[1]
  return args?.constant
}
function compare(op, a, b) {
  const na = toNum(a), nb = toNum(b)
  if (na !== null && nb !== null) {
    if (op === 'le') return na <= nb
    if (op === 'ge') return na >= nb
    if (op === 'lt') return na < nb
    if (op === 'gt') return na > nb
    if (op === 'eq') return na === nb
    if (op === 'ne') return na !== nb
    if (op === 'abs_le') return Math.abs(na) <= nb
    if (op === 'abs_ge') return Math.abs(na) >= nb
  }
  const sa = resolve(a) === null ? '' : String(a)
  const sb = resolve(b) === null ? '' : String(b)
  if (op === 'eq') return sa === sb
  if (op === 'ne') return sa !== sb
  if (op === 'le') return sa <= sb
  if (op === 'ge') return sa >= sb
  if (op === 'lt') return sa < sb
  if (op === 'gt') return sa > sb
  return null
}
function verdict(res, args) {
  if (res == null) return ''
  return res ? String(args?.true_value ?? '符合') : String(args?.false_value ?? '不符合')
}
function opCompare(op, inputs, args) {
  if (!inputs.length || resolve(inputs[0]) === null) return ''
  const rhs = cmpRhs(inputs, args)
  if (resolve(rhs) === null) return ''
  return verdict(compare(op, inputs[0], rhs), args)
}
function opAllEq(inputs, args) {
  if (!inputs.length) return ''
  const resolved = inputs.map(resolve)
  if (resolved.some(v => v === null)) return ''
  const match = args?.match
  if (match !== undefined && match !== null) {
    return verdict(resolved.every(v => String(v) === String(match)), args)
  }
  return verdict(resolved.every(v => v === resolved[0]), args)
}

// ── 色稳定性三态判定（专属算子，前后端镜像实现，保证逐值一致）──
function colorCounts(inputs) {
  const resolved = inputs.map(resolve)
  const severe = resolved.filter(v => String(v) === '明显差异').length
  const unable = resolved.filter(v => String(v) === '无法判定').length
  return { severe, unable }
}
function opColorOverall(inputs) {
  const { severe, unable } = colorCounts(inputs)
  if (unable >= 2) return '无法判定'
  if (severe >= 2) return '明显差异'
  return '未见明显差异/轻微差异'
}
function opColorConclusion(inputs) {
  const { severe, unable } = colorCounts(inputs)
  if (severe >= 2) return '不符合'
  if (unable >= 2) return '需复核'
  return '符合'
}

// ── 计数算子 ──
function opCount(inputs) { return inputs.filter(v => resolve(v) !== null).length }
function opCountIf(inputs, args) {
  const match = String(args?.match ?? '')
  return inputs.filter(v => resolve(v) !== null && String(v) === match).length
}

// ── 单规则求值 ──
function evalRule(rule, row) {
  const op = rule?.op
  const args = rule?.args && typeof rule.args === 'object' ? rule.args : {}
  const inputs = (rule?.inputs || []).map(name => resolve(row[name]))
  const precision = args.precision

  if (!ALLOWED_OPS.has(op)) return null

  if (NUMERIC_OPS.has(op)) {
    const nums = inputs.map(toNum)
    let result
    switch (op) {
      case 'avg': result = opAvg(nums); break
      case 'sum': result = opSum(nums); break
      case 'min': result = opMin(nums); break
      case 'max': result = opMax(nums); break
      case 'add': result = opAdd(nums, args); break
      case 'subtract': result = opSubtract(nums); break
      case 'multiply': result = opMultiply(nums, args); break
      case 'divide': result = opDivide(nums, args); break
      case 'abs': result = opAbs(nums); break
      case 'round': result = nums[0] != null ? roundIfNeeded(nums[0], precision) : null; break
      default: result = null
    }
    return roundIfNeeded(result, precision)
  }

  if (VERDICT_OPS.has(op)) {
    if (op === 'all_eq') return opAllEq(inputs, args)
    return opCompare(op, inputs, args)
  }

  if (op === 'color_overall') return opColorOverall(inputs)
  if (op === 'color_conclusion') return opColorConclusion(inputs)

  if (op === 'count') return opCount(inputs)
  if (op === 'count_if') return opCountIf(inputs, args)
  return null
}

// rules: [{column_key, op, inputs, args}, ...]，须已按依赖顺序排列
export function evaluateRules(rules, rows) {
  return rows.map(raw => {
    const row = { ...raw }
    for (const rule of rules || []) {
      if (!rule || typeof rule !== 'object') continue
      const key = rule.column_key
      if (!key) continue
      row[key] = evalRule(rule, row)
    }
    return row
  })
}

export function evaluate(rules, row) {
  return evaluateRules(rules, [row])[0]
}

export { roundHalfAway, toNum, resolve }
