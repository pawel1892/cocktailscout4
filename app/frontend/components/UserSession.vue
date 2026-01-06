<template>
  <div class="flex space-x-4">
    <template v-if="isAuthenticated">
      <span>Willkommen, {{ user.username }}</span>
      <button @click="logout" class="hover:underline bg-transparent border-0 p-0 text-cs-gold cursor-pointer">
        Logout
      </button>
    </template>
    <template v-else>
      <button @click="openLogin" class="hover:underline bg-transparent border-0 p-0 text-cs-gold cursor-pointer">Login</button>
      <button @click="openRegister" class="hover:underline bg-transparent border-0 p-0 text-cs-gold cursor-pointer">Registrieren</button>
    </template>

    <!-- Modal -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm" @click.self="closeModal">
      <div class="relative bg-white rounded-lg shadow-xl w-full max-w-md py-10 px-6">
        <button @click="closeModal" class="absolute top-4 right-4 text-gray-500 hover:text-gray-700">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
          </svg>
        </button>
        <auth-form @success="closeModal" :initial-mode="initialMode" />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useAuth } from '../composables/useAuth'
import AuthForm from './AuthForm.vue'

const { user, isAuthenticated, logout } = useAuth()
const showModal = ref(false)
const initialMode = ref('login') // 'login' or 'register'

const openLogin = () => {
  initialMode.value = 'login'
  showModal.value = true
}

const openRegister = () => {
  initialMode.value = 'register'
  showModal.value = true
}

const closeModal = () => {
  showModal.value = false
}
</script>
