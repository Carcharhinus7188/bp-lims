import axios from 'axios'
import { ElMessage } from 'element-plus'
import { chinaDate, chinaTime } from './time'

const request = axios.create({
  baseURL: '/api/v1',
  timeout: 30000,
})

// 后端（asyncpg）返回带时区偏移的时间戳（如 2026-08-17 05:08:25+00:00 或 …T…+08:00），
// 统一转换为中国时区的朴素字符串 "YYYY-MM-DD HH:MM:SS"，保证表格直接展示即为北京时间。
const TZ_TS_RE = /^\d{4}-\d{2}-\d{2}[T ]\d{2}:\d{2}:\d{2}(\.\d+)?(Z|[+-]\d{2}:?\d{2})$/i

function toChinaLocal(str) {
  const d = new Date(str)
  if (isNaN(d)) return str
  return chinaDate(d) + ' ' + chinaTime(d)
}

function normalizeTimestamps(value) {
  if (typeof value === 'string') {
    return TZ_TS_RE.test(value) ? toChinaLocal(value) : value
  }
  if (Array.isArray(value)) {
    for (let i = 0; i < value.length; i++) value[i] = normalizeTimestamps(value[i])
  } else if (value && typeof value === 'object' && !(value instanceof Blob)) {
    for (const k of Object.keys(value)) value[k] = normalizeTimestamps(value[k])
  }
  return value
}

// 请求拦截器 — 自动附带 JWT
request.interceptors.request.use(config => {
  const token = localStorage.getItem('token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// 响应拦截器 — 统一时间口径 + 错误处理
request.interceptors.response.use(
  response => {
    if (response.data && typeof response.data === 'object') {
      response.data = normalizeTimestamps(response.data)
    }
    return response
  },
  error => {
    const status = error.response?.status
    const msg = error.response?.data?.detail || error.message
    if (status === 401) {
      localStorage.removeItem('token')
      localStorage.removeItem('user')
      if (window.location.pathname !== '/login') {
        window.location.href = '/login'
      }
    } else if (status === 403) {
      ElMessage.error('权限不足')
    } else if (status >= 500) {
      ElMessage.error('服务器错误: ' + msg)
    }
    return Promise.reject(error)
  }
)

export default request
