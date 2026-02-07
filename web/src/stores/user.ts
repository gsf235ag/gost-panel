import { defineStore } from 'pinia'
import { ref } from 'vue'
import { login as apiLogin } from '../api'
import type { User } from '../types'

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('token') || '')

  // 从 localStorage 恢复用户信息
  const storedUser = localStorage.getItem('user')
  const user = ref<User | null>(storedUser ? JSON.parse(storedUser) : null)

  const login = async (username: string, password: string) => {
    const res = await apiLogin(username, password)

    // 检查是否需要 2FA
    if (res.requires_2fa) {
      return res // 返回 temp_token，由 Login.vue 处理
    }

    token.value = res.token
    user.value = res.user
    localStorage.setItem('token', res.token)
    localStorage.setItem('user', JSON.stringify(res.user))
  }

  const logout = () => {
    token.value = ''
    user.value = null
    localStorage.removeItem('token')
    localStorage.removeItem('user')
  }

  return { token, user, login, logout }
})
