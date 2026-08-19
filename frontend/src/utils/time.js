// 中国标准时间 (Asia/Shanghai) 工具 — 统一前后端时间口径
// 后端 DB 已设为 Asia/Shanghai；前端不再用 toISOString()（UTC）取日期，
// 避免 UTC+8 时区在 00:00–07:59 拿到前一天。

const CHINA_TZ = 'Asia/Shanghai'

function pad(n) {
  return String(n).padStart(2, '0')
}

/** 返回中国时区日期 YYYY-MM-DD（默认取当前时刻）。 */
export function chinaDate(d = new Date()) {
  const parts = new Intl.DateTimeFormat('en-CA', {
    timeZone: CHINA_TZ,
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).formatToParts(d)
  const get = (t) => (parts.find((p) => p.type === t) || {}).value
  return `${get('year')}-${get('month')}-${get('day')}`
}

/** 返回中国时区时间 HH:MM:SS。 */
export function chinaTime(d = new Date()) {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: CHINA_TZ,
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  }).formatToParts(d)
  const get = (t) => (parts.find((p) => p.type === t) || {}).value
  return `${get('hour')}:${get('minute')}:${get('second')}`
}

/** 返回中国时区完整时间戳 YYYY-MM-DDTHH:MM:SS（无时区后缀，等价于北京时间）。 */
export function chinaDateTime(d = new Date()) {
  return `${chinaDate(d)}T${chinaTime(d)}`
}

/** 返回中国时区 ISO 字符串（带 +08:00，供后端解析为北京时间）。 */
export function chinaNowISO(d = new Date()) {
  return `${chinaDateTime(d)}+08:00`
}

/**
 * 后端时间（UTC 或 naive 字符串）→ 中国时区 "YYYY-MM-DD HH:MM:SS"。
 * 用于表格/详情中直接展示后端 created_at/…_at 等时间戳，统一中国时间口径。
 */
export function formatChinaDateTime(d) {
  if (!d) return '—'
  const dt = new Date(d)
  if (isNaN(dt)) return String(d)
  return `${chinaDate(dt)} ${chinaTime(dt)}`
}

/** 后端时间 → 中国时区日期 "YYYY-MM-DD"。 */
export function formatChinaDate(d) {
  if (!d) return '—'
  const dt = new Date(d)
  if (isNaN(dt)) return String(d)
  return chinaDate(dt)
}
