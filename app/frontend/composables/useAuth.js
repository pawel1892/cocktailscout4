import { reactive, computed } from 'vue'

const state = reactive({
  user: null,
  initialized: false
})

export function useAuth() {
  
  // Initialize from Meta Tag on first load
  if (!state.initialized) {
    const meta = document.querySelector('meta[name="current-user"]')
    if (meta && meta.content) {
      try {
        state.user = JSON.parse(meta.content)
      } catch (e) {
        console.error("Failed to parse current-user meta tag", e)
      }
    }
    state.initialized = true
  }

  const login = async (formData) => {
    try {
      const response = await fetch('/session.json', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify(formData)
      })
      
      const data = await response.json()
      if (response.ok) {
        state.user = data.user
        return { success: true, user: data.user }
      } else {
        return { success: false, error: data.error }
      }
    } catch (e) {
      return { success: false, error: "An unexpected error occurred." }
    }
  }

  const register = async (formData) => {
    try {
      const response = await fetch('/registration.json', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: JSON.stringify({ user: formData })
      })

      const data = await response.json()
      if (response.ok) {
        state.user = data.user
        return { success: true, user: data.user }
      } else {
        return { success: false, errors: data.errors }
      }
    } catch (e) {
        return { success: false, errors: ["An unexpected error occurred."] }
    }
  }

  const logout = async () => {
    try {
      await fetch('/session.json', {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
    } catch (e) {
      console.error("Logout failed", e)
    } finally {
      state.user = null
      window.location.href = '/' 
    }
  }

  return {
    user: computed(() => state.user),
    isAuthenticated: computed(() => !!state.user),
    login,
    register,
    logout
  }
}
