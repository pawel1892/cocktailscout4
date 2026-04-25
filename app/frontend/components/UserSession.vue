<template>
  <div class="flex flex-wrap items-center justify-start gap-2">
    <template v-if="isAuthenticated">
      <div class="relative inline-block">
        <button
          @click.stop="toggleUserMenu"
          class="relative inline-flex h-11 items-center justify-center gap-2 rounded-full border border-cs-red-100 bg-white py-1 pl-1 pr-3 text-[13px] font-semibold text-cs-red-900 shadow-xs transition hover:border-cs-gold-500 hover:bg-cs-gold-50 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cs-gold-500"
          type="button"
          aria-haspopup="menu"
          :aria-expanded="showUserMenu ? 'true' : 'false'"
        >
          <AvatarDisplay :user="user" :avatarUrl="user?.avatar_url_small" size="md" />
          <span class="hidden max-w-28 truncate lg:inline">{{ user?.username || 'Profil' }}</span>
          <span
            v-if="totalNotifications > 0"
            class="hidden h-5 min-w-5 items-center justify-center rounded-full bg-cs-red-900 px-1.5 text-[11px] font-bold text-white lg:inline-flex"
          >
            {{ totalNotifications }}
          </span>
          <i class="fa-solid fa-chevron-down text-[10px] text-cs-ink-400"></i>
        </button>

        <div
          v-if="showUserMenu"
          class="absolute right-0 z-[100] mt-2 w-60 overflow-hidden rounded-lg border border-cs-ink-200 bg-white text-cs-ink-900 shadow-lg"
          role="menu"
          @click="closeUserMenu"
        >
          <div class="border-b border-cs-ink-100 px-4 py-3">
            <div class="text-[11px] font-bold uppercase tracking-wider text-cs-ink-400">Angemeldet als</div>
            <div class="mt-0.5 truncate text-sm font-semibold text-cs-ink-900">{{ user?.username }}</div>
          </div>

          <div class="py-1">
            <button
              @click="openProfile"
              class="flex w-full items-center gap-2 px-4 py-2.5 text-left text-sm text-cs-ink-700 transition hover:bg-cs-ink-100 hover:text-cs-red-900"
              type="button"
              role="menuitem"
            >
              <i class="fa-solid fa-user w-4 text-cs-ink-400"></i>
              Mein Profil
            </button>
            <a
              href="/nachrichten"
              class="flex items-center gap-2 px-4 py-2.5 text-sm text-cs-ink-700 no-underline transition hover:bg-cs-ink-100 hover:text-cs-red-900"
              role="menuitem"
            >
              <i class="fa-solid fa-envelope w-4 text-cs-ink-400"></i>
              Meine Nachrichten
              <span
                v-if="unreadCount > 0"
                class="ml-auto inline-flex items-center justify-center rounded-full bg-cs-red-900 px-2 py-0.5 text-xs font-bold text-white"
              >
                {{ unreadCount }}
              </span>
            </a>
            <a
              href="/rezeptvorschlaege"
              class="flex items-center gap-2 px-4 py-2.5 text-sm text-cs-ink-700 no-underline transition hover:bg-cs-ink-100 hover:text-cs-red-900"
              role="menuitem"
            >
              <i class="fa-solid fa-lightbulb w-4 text-cs-ink-400"></i>
              Meine Rezeptvorschläge
            </a>
            <a
              href="/email_aendern"
              class="flex items-center gap-2 px-4 py-2.5 text-sm text-cs-ink-700 no-underline transition hover:bg-cs-ink-100 hover:text-cs-red-900"
              role="menuitem"
            >
              <i class="fa-solid fa-at w-4 text-cs-ink-400"></i>
              E-Mail ändern
            </a>
            <a
              href="/passwort_aendern"
              class="flex items-center gap-2 px-4 py-2.5 text-sm text-cs-ink-700 no-underline transition hover:bg-cs-ink-100 hover:text-cs-red-900"
              role="menuitem"
            >
              <i class="fa-solid fa-key w-4 text-cs-ink-400"></i>
              Passwort ändern
            </a>
            <a
              v-if="user?.is_moderator"
              href="/admin/reports"
              class="mt-1 flex items-center gap-2 border-t border-cs-ink-100 px-4 py-2.5 text-sm text-cs-ink-700 no-underline transition hover:bg-cs-ink-100 hover:text-cs-red-900"
              role="menuitem"
            >
              <i class="fa-solid fa-shield-halved w-4 text-cs-ink-400"></i>
              Admin Bereich
              <span
                v-if="reportCount > 0"
                class="ml-auto inline-flex items-center justify-center rounded-full bg-cs-red-900 px-2 py-0.5 text-xs font-bold text-white"
              >
                {{ reportCount }}
              </span>
            </a>
            <a
              v-if="user?.can_moderate_recipe"
              href="/admin/recipe_suggestions"
              class="flex items-center gap-2 px-4 py-2.5 text-sm text-cs-ink-700 no-underline transition hover:bg-cs-ink-100 hover:text-cs-red-900"
              role="menuitem"
            >
              <i class="fa-solid fa-lightbulb w-4 text-cs-ink-400"></i>
              Rezeptvorschläge
              <span
                v-if="suggestionCount > 0"
                class="ml-auto inline-flex items-center justify-center rounded-full bg-cs-red-900 px-2 py-0.5 text-xs font-bold text-white"
              >
                {{ suggestionCount }}
              </span>
            </a>
          </div>

          <button
            @click="logout"
            class="flex w-full items-center gap-2 border-t border-cs-ink-100 px-4 py-2.5 text-left text-sm font-semibold text-cs-red-900 transition hover:bg-cs-red-50"
            type="button"
            role="menuitem"
          >
            <i class="fa-solid fa-right-from-bracket w-4"></i>
            Logout
          </button>
        </div>
      </div>
    </template>
    <template v-else>
      <button
        @click="openLogin"
        class="h-9 border-0 bg-transparent px-1.5 text-[12px] font-bold uppercase tracking-[0.13em] text-cs-red-900 transition hover:text-cs-red-700 focus-visible:rounded-sm focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cs-gold-500"
        type="button"
      >
        Login
      </button>
      <button
        @click="openRegister"
        class="h-9 rounded-md border border-cs-red-950 bg-cs-red-900 px-3 text-[12px] font-bold uppercase tracking-[0.13em] text-cs-gold-200 shadow-[inset_0_1px_0_rgba(255,255,255,.08),0_4px_10px_-8px_rgba(24,21,19,.7)] transition hover:bg-cs-red-800 hover:text-cs-gold-300 focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-cs-gold-500"
        type="button"
      >
        Registrieren
      </button>
    </template>

    <Teleport to="body">
      <div v-if="showModal" class="fixed inset-0 z-[120] flex items-center justify-center overflow-y-auto p-4 bg-black/50 backdrop-blur-sm" @click.self="closeModal">
        <div class="relative my-auto bg-white rounded-lg shadow-xl w-full max-w-md py-10 px-6 text-cs-ink-900">
          <button @click="closeModal" class="absolute top-4 right-4 text-cs-ink-500 hover:text-cs-ink-700" type="button" aria-label="Schließen">
            <i class="fa-solid fa-xmark text-xl"></i>
          </button>
          <auth-form @success="closeModal" :initial-mode="initialMode" />
        </div>
      </div>
    </Teleport>
  </div>
</template>

<script setup>
import { ref, onMounted, watch, computed } from 'vue'
import { useAuth } from '../composables/useAuth'
import AuthForm from './AuthForm.vue'
import AvatarDisplay from './AvatarDisplay.vue'

const { user, isAuthenticated, logout } = useAuth()
const showModal = ref(false)
const initialMode = ref('login') // 'login' or 'register'
const showUserMenu = ref(false)
const unreadCount = ref(0)
const reportCount = ref(0)
const suggestionCount = ref(0)

const totalNotifications = computed(() => unreadCount.value + reportCount.value + suggestionCount.value)

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

const fetchReportCount = async () => {
  if (!isAuthenticated.value || !user.value?.is_moderator) return

  try {
    const response = await fetch('/admin/reports/count')
    if (response.ok) {
      const data = await response.json()
      reportCount.value = data.count
    }
  } catch (error) {
    console.error('Failed to fetch report count:', error)
  }
}

const fetchSuggestionCount = async () => {
  if (!isAuthenticated.value || !user.value?.can_moderate_recipe) return

  try {
    const response = await fetch('/admin/recipe_suggestions/count')
    if (response.ok) {
      const data = await response.json()
      suggestionCount.value = data.count
    }
  } catch (error) {
    console.error('Failed to fetch suggestion count:', error)
  }
}

// Fetch unread count on mount and when authentication status changes
watch(isAuthenticated, (newValue) => {
  if (newValue) {
    fetchUnreadCount()
    if (user.value?.is_moderator) fetchReportCount()
    if (user.value?.can_moderate_recipe) fetchSuggestionCount()
  } else {
    unreadCount.value = 0
    reportCount.value = 0
    suggestionCount.value = 0
  }
}, { immediate: true })

// Poll for unread count every 60 seconds
onMounted(() => {
  if (isAuthenticated.value) {
    fetchUnreadCount()
    if (user.value?.is_moderator) fetchReportCount()
    if (user.value?.can_moderate_recipe) fetchSuggestionCount()

    setInterval(() => {
      fetchUnreadCount()
      if (user.value?.is_moderator) fetchReportCount()
      if (user.value?.can_moderate_recipe) fetchSuggestionCount()
    }, 60000)
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
