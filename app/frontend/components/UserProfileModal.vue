<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import BaseModal from './BaseModal.vue'
import ProfileEditForm from './ProfileEditForm.vue'

const show = ref(false)
const userId = ref(null)
const loading = ref(false)
const profile = ref(null)
const error = ref(null)
const isEditing = ref(false)

const currentUser = computed(() => {
  const meta = document.querySelector('meta[name="current-user"]')
  if (!meta || !meta.content) return null
  try {
    return JSON.parse(meta.content)
  } catch {
    return null
  }
})

const isOwnProfile = computed(() => {
  return currentUser.value && profile.value && currentUser.value.id === profile.value.id
})

const fetchProfile = async () => {
  if (!userId.value) return

  loading.value = true
  error.value = null

  try {
    const response = await fetch(`/user_profiles/${userId.value}.json`)
    if (!response.ok) {
      throw new Error('Profil konnte nicht geladen werden')
    }
    profile.value = await response.json()
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}

const openProfile = (event) => {
  userId.value = event.detail.userId
  show.value = true
  fetchProfile()
}

const closeModal = () => {
  show.value = false
  isEditing.value = false
  // Clear data after modal closes
  setTimeout(() => {
    profile.value = null
    error.value = null
  }, 300)
}

const startEditing = () => {
  isEditing.value = true
}

const cancelEditing = () => {
  isEditing.value = false
}

const handleSaved = (updatedProfile) => {
  profile.value = updatedProfile
  isEditing.value = false
}

onMounted(() => {
  window.addEventListener('open-user-profile', openProfile)
})

onUnmounted(() => {
  window.removeEventListener('open-user-profile', openProfile)
})

const formatDate = (dateString) => {
  if (!dateString) return '-'
  const date = new Date(dateString)
  return date.toLocaleDateString('de-DE', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const formatDateTime = (dateString) => {
  if (!dateString) return '-'
  const date = new Date(dateString)
  return date.toLocaleString('de-DE', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit'
  })
}

const getRankColor = (rank) => {
  return `rank-${rank}-color`
}

const getGenderText = (gender) => {
  if (gender === 'm') return 'Männlich'
  if (gender === 'w') return 'Weiblich'
  return '-'
}
</script>

<template>
  <BaseModal :model-value="show" @close="closeModal" max-width="max-w-2xl">
    <template #header>
      <div class="flex items-center justify-between">
        <h3 class="text-xl font-bold text-gray-900">Benutzerprofil</h3>
        <button
          v-if="isOwnProfile && !isEditing && !loading"
          @click="startEditing"
          type="button"
          class="px-3 py-1.5 text-sm text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition"
        >
          <i class="fa-solid fa-pen mr-2"></i>
          Bearbeiten
        </button>
      </div>
    </template>

    <template #content>
      <div v-if="loading" class="py-8 text-center">
        <i class="fa-solid fa-spinner fa-spin text-3xl text-gray-400"></i>
        <p class="mt-2 text-gray-600">Profil wird geladen...</p>
      </div>

      <div v-else-if="error" class="py-8 text-center">
        <i class="fa-solid fa-circle-exclamation text-3xl text-red-500"></i>
        <p class="mt-2 text-red-600">{{ error }}</p>
      </div>

      <div v-else-if="profile && isEditing">
        <ProfileEditForm
          :profile="profile"
          @saved="handleSaved"
          @cancel="cancelEditing"
        />
      </div>

      <div v-else-if="profile" class="space-y-6">
        <!-- User Header -->
        <div class="border-b pb-4">
          <div class="flex items-center gap-3">
            <i class="fa-solid fa-user text-3xl" :class="getRankColor(profile.rank)"></i>
            <div>
              <h2 class="text-2xl font-bold text-gray-900">{{ profile.username }}</h2>
              <div class="flex items-center gap-2 mt-1">
                <span class="text-sm font-medium text-gray-900">
                  {{ profile.points }} Punkte
                </span>
              </div>
            </div>
          </div>
        </div>

        <!-- Profile Data -->
        <div class="space-y-4">
          <h3 class="font-semibold text-gray-900">Profildaten</h3>

          <div class="grid grid-cols-2 gap-4">
            <div v-if="profile.prename">
              <label class="text-sm font-medium text-gray-700">Vorname</label>
              <p class="mt-1 text-gray-900">{{ profile.prename }}</p>
            </div>

            <div v-if="profile.gender">
              <label class="text-sm font-medium text-gray-700">Geschlecht</label>
              <p class="mt-1 text-gray-900">{{ getGenderText(profile.gender) }}</p>
            </div>

            <div v-if="profile.location">
              <label class="text-sm font-medium text-gray-700">Ort</label>
              <p class="mt-1 text-gray-900">{{ profile.location }}</p>
            </div>

            <div v-if="profile.title">
              <label class="text-sm font-medium text-gray-700">Titel</label>
              <p class="mt-1 text-gray-900">{{ profile.title }}</p>
            </div>
          </div>

          <div v-if="profile.homepage">
            <label class="text-sm font-medium text-gray-700">Homepage</label>
            <p class="mt-1">
              <a :href="profile.homepage" target="_blank" rel="noopener noreferrer"
                 class="text-blue-600 hover:underline">
                {{ profile.homepage }}
                <i class="fa-solid fa-arrow-up-right-from-square text-xs ml-1"></i>
              </a>
            </p>
          </div>
        </div>

        <!-- Statistics -->
        <div class="space-y-4 border-t pt-4">
          <h3 class="font-semibold text-gray-900">Statistiken</h3>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm font-medium text-gray-700">Rezepte</label>
              <p class="mt-1 text-gray-900">{{ profile.recipes_count }}</p>
            </div>

            <div>
              <label class="text-sm font-medium text-gray-700">Rezeptbilder</label>
              <p class="mt-1 text-gray-900">{{ profile.recipe_images_count }}</p>
            </div>

            <div>
              <label class="text-sm font-medium text-gray-700">Kommentare</label>
              <p class="mt-1 text-gray-900">{{ profile.recipe_comments_count }}</p>
            </div>

            <div>
              <label class="text-sm font-medium text-gray-700">Bewertungen</label>
              <p class="mt-1 text-gray-900">{{ profile.ratings_count }}</p>
            </div>

            <div>
              <label class="text-sm font-medium text-gray-700">Forenbeiträge</label>
              <p class="mt-1 text-gray-900">{{ profile.forum_posts_count }}</p>
            </div>

            <div>
              <label class="text-sm font-medium text-gray-700">Anmeldungen</label>
              <p class="mt-1 text-gray-900">{{ profile.sign_in_count }}</p>
            </div>
          </div>
        </div>

        <!-- Account Info -->
        <div class="space-y-4 border-t pt-4">
          <h3 class="font-semibold text-gray-900">Account-Informationen</h3>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="text-sm font-medium text-gray-700">Mitglied seit</label>
              <p class="mt-1 text-gray-900">{{ formatDate(profile.created_at) }}</p>
            </div>

            <div v-if="profile.last_active_at">
              <label class="text-sm font-medium text-gray-700">Zuletzt aktiv</label>
              <p class="mt-1 text-gray-900">{{ formatDateTime(profile.last_active_at) }}</p>
            </div>
          </div>
        </div>
      </div>
    </template>
  </BaseModal>
</template>
