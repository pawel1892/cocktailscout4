<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import BaseModal from './BaseModal.vue'
import ProfileEditForm from './ProfileEditForm.vue'
import UserRoleBadges from './UserRoleBadges.vue'
import AvatarDisplay from './AvatarDisplay.vue'

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
    if (!response.ok) throw new Error('Profil konnte nicht geladen werden')
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
  setTimeout(() => {
    profile.value = null
    error.value = null
  }, 300)
}

const startEditing = () => { isEditing.value = true }
const cancelEditing = () => { isEditing.value = false }

const handleSaved = (updatedProfile) => {
  profile.value = updatedProfile
  isEditing.value = false
}

const handleAvatarUploaded = (avatarUrls) => {
  profile.value = { ...profile.value, ...avatarUrls }
}

const handleAvatarDeleted = (avatarUrls) => {
  profile.value = { ...profile.value, ...avatarUrls }
}

onMounted(() => { window.addEventListener('open-user-profile', openProfile) })
onUnmounted(() => { window.removeEventListener('open-user-profile', openProfile) })

const formatDate = (dateString) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleDateString('de-DE', { year: 'numeric', month: 'long', day: 'numeric' })
}

const formatDateTime = (dateString) => {
  if (!dateString) return '-'
  return new Date(dateString).toLocaleString('de-DE', { year: 'numeric', month: 'long', day: 'numeric', hour: '2-digit', minute: '2-digit' })
}

const formatNumber = (n) => (n ?? 0).toLocaleString('de-DE')

const getGenderText = (gender) => {
  if (gender === 'm') return 'Männlich'
  if (gender === 'w') return 'Weiblich'
  return '-'
}
</script>

<template>
  <BaseModal :model-value="show" @close="closeModal" max-width="max-w-xl">

    <template #header>
      <div class="flex items-center justify-between w-full">
        <span class="font-sans font-bold uppercase text-[11px] tracking-widest text-cs-ink-400">Benutzerprofil</span>
        <div class="flex gap-2 mr-8">
          <a
            v-if="!isOwnProfile && !loading && profile && currentUser"
            :href="`/nachrichten/new?receiver_id=${profile.id}`"
            class="btn btn-sm btn-primary"
          >
            <i class="fas fa-envelope mr-1.5"></i> Nachricht
          </a>
          <button
            v-if="isOwnProfile && !isEditing && !loading"
            @click="startEditing"
            type="button"
            class="btn btn-sm btn-soft"
          >
            <i class="fas fa-pen mr-1.5"></i> Bearbeiten
          </button>
        </div>
      </div>
    </template>

    <template #content>

      <!-- Loading -->
      <div v-if="loading" class="py-12 text-center">
        <i class="fas fa-spinner fa-spin text-3xl text-cs-ink-300"></i>
        <p class="mt-3 text-sm text-cs-ink-400">Profil wird geladen…</p>
      </div>

      <!-- Error -->
      <div v-else-if="error" class="py-12 text-center">
        <i class="fas fa-circle-exclamation text-3xl text-cs-error-400"></i>
        <p class="mt-3 text-sm text-cs-error-600">{{ error }}</p>
      </div>

      <!-- Edit form -->
      <div v-else-if="profile && isEditing">
        <ProfileEditForm
          :profile="profile"
          @saved="handleSaved"
          @cancel="cancelEditing"
          @avatar-uploaded="handleAvatarUploaded"
          @avatar-deleted="handleAvatarDeleted"
        />
      </div>

      <!-- Profile view -->
      <div v-else-if="profile">

        <!-- User hero -->
        <div class="flex items-center gap-5 mb-6 pb-6 border-b border-cs-ink-100">
          <AvatarDisplay :user="profile" :avatarUrl="profile.avatar_url_medium" size="lg" />
          <div class="min-w-0">
            <h2 class="font-display font-semibold text-[32px] leading-tight tracking-tight text-cs-red-900">
              {{ profile.username }}
            </h2>
            <div class="flex items-center gap-2 mt-1">
              <span class="font-mono text-[13px] font-medium text-cs-ink-700">{{ formatNumber(profile.points) }} Punkte</span>
            </div>
            <UserRoleBadges
              v-if="profile.roles && profile.roles.length > 0"
              :roles="profile.roles"
              size="normal"
              class="mt-2"
            />
          </div>
        </div>

        <!-- Stats strip -->
        <div class="grid grid-cols-5 gap-1 mb-6 pb-6 border-b border-cs-ink-100 text-center">
          <a :href="`/rezepte?user_id=${profile.id}`" class="group py-2 rounded-lg hover:bg-cs-ink-50 transition-colors">
            <div class="font-mono font-semibold text-[18px] text-cs-ink-900 group-hover:text-cs-red-900 transition-colors">{{ profile.recipes_count }}</div>
            <div class="font-sans font-bold uppercase text-[9px] tracking-widest text-cs-ink-400 mt-0.5">Rezepte</div>
          </a>
          <a :href="`/cocktailgalerie?user_id=${profile.id}`" class="group py-2 rounded-lg hover:bg-cs-ink-50 transition-colors">
            <div class="font-mono font-semibold text-[18px] text-cs-ink-900 group-hover:text-cs-red-900 transition-colors">{{ profile.recipe_images_count }}</div>
            <div class="font-sans font-bold uppercase text-[9px] tracking-widest text-cs-ink-400 mt-0.5">Bilder</div>
          </a>
          <div class="py-2">
            <div class="font-mono font-semibold text-[18px] text-cs-ink-900">{{ profile.recipe_comments_count }}</div>
            <div class="font-sans font-bold uppercase text-[9px] tracking-widest text-cs-ink-400 mt-0.5">Kommentare</div>
          </div>
          <a :href="`/benutzer/${profile.id}/bewertungen`" class="group py-2 rounded-lg hover:bg-cs-ink-50 transition-colors">
            <div class="font-mono font-semibold text-[18px] text-cs-ink-900 group-hover:text-cs-red-900 transition-colors">{{ profile.ratings_count }}</div>
            <div class="font-sans font-bold uppercase text-[9px] tracking-widest text-cs-ink-400 mt-0.5">Bewertungen</div>
          </a>
          <div class="py-2">
            <div class="font-mono font-semibold text-[18px] text-cs-ink-900">{{ profile.forum_posts_count }}</div>
            <div class="font-sans font-bold uppercase text-[9px] tracking-widest text-cs-ink-400 mt-0.5">Beiträge</div>
          </div>
        </div>

        <!-- Profile details (only if any exist) -->
        <div
          v-if="profile.prename || profile.location || profile.gender || profile.homepage"
          class="mb-6 pb-6 border-b border-cs-ink-100"
        >
          <span class="font-sans font-bold uppercase text-[11px] tracking-widest text-cs-ink-400 block mb-3">Profil</span>
          <div class="grid grid-cols-2 gap-3">
            <div v-if="profile.prename">
              <p class="font-sans font-bold uppercase text-[10px] tracking-widest text-cs-ink-400 mb-0.5">Vorname</p>
              <p class="text-sm text-cs-ink-900">{{ profile.prename }}</p>
            </div>
            <div v-if="profile.gender">
              <p class="font-sans font-bold uppercase text-[10px] tracking-widest text-cs-ink-400 mb-0.5">Geschlecht</p>
              <p class="text-sm text-cs-ink-900">{{ getGenderText(profile.gender) }}</p>
            </div>
            <div v-if="profile.location">
              <p class="font-sans font-bold uppercase text-[10px] tracking-widest text-cs-ink-400 mb-0.5">Ort</p>
              <p class="text-sm text-cs-ink-900">
                <i class="fas fa-map-marker-alt text-cs-ink-300 mr-1 text-xs"></i>{{ profile.location }}
              </p>
            </div>
            <div v-if="profile.homepage" class="col-span-2">
              <p class="font-sans font-bold uppercase text-[10px] tracking-widest text-cs-ink-400 mb-0.5">Homepage</p>
              <a :href="profile.homepage" target="_blank" rel="noopener noreferrer" class="link text-sm">
                {{ profile.homepage }}
                <i class="fas fa-arrow-up-right-from-square text-[10px] ml-1"></i>
              </a>
            </div>
          </div>
        </div>

        <!-- Account info -->
        <div class="flex flex-wrap gap-x-6 gap-y-1 text-xs text-cs-ink-400">
          <span><i class="fas fa-calendar-alt mr-1.5"></i>Dabei seit {{ formatDate(profile.created_at) }}</span>
          <span v-if="profile.last_seen_at"><i class="far fa-clock mr-1.5"></i>Zuletzt gesehen {{ formatDateTime(profile.last_seen_at) }}</span>
        </div>

      </div>
    </template>
  </BaseModal>
</template>
