<template>
  <div class="flex space-x-4">
    <template v-if="isAuthenticated">
      <span class="text-white">Willkommen,
        <div class="relative inline-block">
          <button
            @click="toggleUserMenu"
            class="hover:underline bg-transparent border-0 p-0 text-white cursor-pointer relative"
          >
            {{ user.username }}
            <span
              v-if="unreadCount > 0"
              class="ml-2 inline-flex items-center justify-center w-5 h-5 text-xs font-bold text-white bg-cs-dark-red rounded-full"
            >
              {{ unreadCount }}
            </span>
          </button>

          <!-- Dropdown Menu -->
          <div
            v-if="showUserMenu"
            class="absolute right-0 mt-2 w-48 bg-white rounded-lg shadow-xl ring-1 ring-black ring-opacity-5 z-50"
            @click="closeUserMenu"
          >
            <div class="py-1">
              <button
                @click="openProfile"
                class="w-full text-left px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center gap-2"
              >
                <i class="fa-solid fa-user"></i>
                Mein Profil
              </button>
              <a
                href="/nachrichten"
                class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center gap-2"
              >
                <i class="fa-solid fa-envelope"></i>
                Meine Nachrichten
                <span
                  v-if="unreadCount > 0"
                  class="ml-auto inline-flex items-center justify-center px-2 py-0.5 text-xs font-bold text-white bg-cs-dark-red rounded-full"
                >
                  {{ unreadCount }}
                </span>
              </a>
              <a
                href="/email_aendern"
                class="block px-4 py-2 text-sm text-gray-700 hover:bg-gray-100 flex items-center gap-2"
              >
                <i class="fa-solid fa-at"></i>
                E-Mail ändern
              </a>
            </div>
          </div>
        </div>
      </span>
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
      <div class="relative bg-white rounded-lg shadow-xl w-full max-w-md py-10 px-6 text-gray-900">
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
import { ref, onMounted, watch } from 'vue'
import { useAuth } from '../composables/useAuth'
import AuthForm from './AuthForm.vue'

const { user, isAuthenticated, logout } = useAuth()
const showModal = ref(false)
const initialMode = ref('login') // 'login' or 'register'
const showUserMenu = ref(false)
const unreadCount = ref(0)

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

const toggleUserMenu = () => {
  showUserMenu.value = !showUserMenu.value
}

const closeUserMenu = () => {
  showUserMenu.value = false
}

const openProfile = () => {
  if (user.value) {
    window.dispatchEvent(new CustomEvent('open-user-profile', {
      detail: { userId: user.value.id }
    }))
  }
}

const fetchUnreadCount = async () => {
  if (!isAuthenticated.value) return

  try {
    const response = await fetch('/nachrichten/unread_count')
    const data = await response.json()
    if (data.success) {
      unreadCount.value = data.count
    }
  } catch (error) {
    console.error('Failed to fetch unread count:', error)
  }
}

// Fetch unread count on mount and when authentication status changes
watch(isAuthenticated, (newValue) => {
  if (newValue) {
    fetchUnreadCount()
  } else {
    unreadCount.value = 0
  }
}, { immediate: true })

// Poll for unread count every 60 seconds
onMounted(() => {
  if (isAuthenticated.value) {
    fetchUnreadCount()
    setInterval(fetchUnreadCount, 60000)
  }
})

// Close dropdown when clicking outside
onMounted(() => {
  const handleClickOutside = (event) => {
    if (showUserMenu.value && !event.target.closest('.relative.inline-block')) {
      showUserMenu.value = false
    }
  }
  document.addEventListener('click', handleClickOutside)
})
</script>
