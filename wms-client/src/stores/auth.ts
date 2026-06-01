import { defineStore } from 'pinia'
import { ref } from 'vue'

export const useAuthStore = defineStore('auth', () => {
  const token = ref(localStorage.getItem('wms_token') || '')
  const user = ref(JSON.parse(localStorage.getItem('wms_user') || 'null'))

  function setAuth(t: string, u: any) {
    token.value = t
    user.value = u
    localStorage.setItem('wms_token', t)
    localStorage.setItem('wms_user', JSON.stringify(u))
  }

  function logout() {
    token.value = ''
    user.value = null
    localStorage.removeItem('wms_token')
    localStorage.removeItem('wms_user')
  }

  const isAdmin = () => user.value?.role_type === 'admin'
  const isManager = () => user.value?.role_type === 'manager' || user.value?.role_type === 'admin'
  const isOperator = () => true

  return { token, user, setAuth, logout, isAdmin, isManager, isOperator }
})
