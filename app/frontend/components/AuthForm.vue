<template>
  <div class="auth-form p-6 border rounded shadow-md bg-white max-w-sm mx-auto">
    <div v-if="isAuthenticated" class="text-center">
      <p class="mb-4 text-green-600">You are logged in as <strong>{{ user.email_address }}</strong></p>
      <button @click="logout" class="px-4 py-2 bg-red-500 text-white rounded hover:bg-red-600 w-full">
        Sign Out
      </button>
    </div>

    <div v-else>
      <h2 class="text-xl font-bold mb-4 text-center">{{ isLoginMode ? 'Sign In' : 'Sign Up' }}</h2>
      
      <form @submit.prevent="handleSubmit">
        <div class="mb-4">
          <label class="block text-gray-700 text-sm font-bold mb-2" for="email">
            Email Address
          </label>
          <input 
            v-model="form.email_address"
            id="email" 
            type="email" 
            required
            autocomplete="username"
            class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
          >
        </div>

        <div class="mb-6">
          <label class="block text-gray-700 text-sm font-bold mb-2" for="password">
            Password
          </label>
          <input 
            v-model="form.password"
            id="password" 
            type="password" 
            required
            autocomplete="current-password"
            class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
          >
        </div>

        <div v-if="!isLoginMode" class="mb-6">
          <label class="block text-gray-700 text-sm font-bold mb-2" for="password_confirmation">
            Confirm Password
          </label>
          <input 
            v-model="form.password_confirmation"
            id="password_confirmation" 
            type="password" 
            required
            autocomplete="new-password"
            class="shadow appearance-none border rounded w-full py-2 px-3 text-gray-700 leading-tight focus:outline-none focus:shadow-outline"
          >
        </div>

        <div v-if="error" class="mb-4 text-red-500 text-sm">
          {{ error }}
        </div>
        
        <div v-if="errors.length" class="mb-4 text-red-500 text-sm">
          <ul class="list-disc pl-5">
            <li v-for="(err, index) in errors" :key="index">{{ err }}</li>
          </ul>
        </div>

        <div class="flex items-center justify-between">
          <button 
            type="submit" 
            class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded focus:outline-none focus:shadow-outline w-full"
            :disabled="loading"
          >
            {{ loading ? 'Processing...' : (isLoginMode ? 'Sign In' : 'Sign Up') }}
          </button>
        </div>
        
        <div class="mt-4 text-center">
            <a href="#" @click.prevent="toggleMode" class="text-blue-500 hover:text-blue-700 text-sm">
                {{ isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Sign In" }}
            </a>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useAuth } from '../composables/useAuth'

const { user, isAuthenticated, login, register, logout } = useAuth()

const isLoginMode = ref(true)
const loading = ref(false)
const error = ref(null)
const errors = ref([])

const form = reactive({
  email_address: '',
  password: '',
  password_confirmation: ''
})

const toggleMode = () => {
  isLoginMode.value = !isLoginMode.value
  error.value = null
  errors.value = []
  form.password = ''
  form.password_confirmation = ''
}

const handleSubmit = async () => {
  loading.value = true
  error.value = null
  errors.value = []

  let result
  if (isLoginMode.value) {
    result = await login({ email_address: form.email_address, password: form.password })
  } else {
    result = await register(form)
  }

  loading.value = false

  if (!result.success) {
    if (result.error) {
        error.value = result.error
    }
    if (result.errors) {
        errors.value = result.errors
    }
  } else {
      // Clear form on success
      form.email_address = ''
      form.password = ''
      form.password_confirmation = ''
  }
}
</script>
