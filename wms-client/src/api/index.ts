import axios from 'axios'
import router from '../router'

const api = axios.create({
  baseURL: location.hostname === 'localhost' ? '/api' : 'https://wms-backend-uanj.onrender.com/api',
  timeout: 15000,
})

// 请求拦截器：自动附加 Token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('wms_token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

// 响应拦截器：统一错误处理
api.interceptors.response.use(
  (res) => res,
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('wms_token')
      localStorage.removeItem('wms_user')
      router.push('/login')
    }
    return Promise.reject(error)
  }
)

export default api
