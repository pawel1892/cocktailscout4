<template>
  <button 
    @click="toggleFavorite" 
    class="flex items-center justify-center transition-all focus:outline-none"
    :class="[isFavorited ? 'text-red-600' : 'text-gray-400 hover:text-red-400']"
    :title="isFavorited ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen'"
    :disabled="loading"
  >
    <i 
      :class="[
        isFavorited ? 'fas fa-heart' : 'far fa-heart',
        loading ? 'animate-pulse' : '',
        size
      ]"
      class="transition-transform active:scale-90"
    ></i>
  </button>
</template>

<script setup>
import { ref, defineProps } from 'vue'
import { useAuth } from '../composables/useAuth'

const props = defineProps({
  favoritableType: { type: String, required: true },
  favoritableId: { type: Number, required: true },
  initialFavorited: { type: Boolean, default: false },
  size: { type: String, default: 'text-3xl' }
})

const { isAuthenticated } = useAuth()
const isFavorited = ref(props.initialFavorited)
const loading = ref(false)

const toggleFavorite = async () => {
  if (!isAuthenticated.value) {
    window.location.href = '/session/new'
    return
  }

  if (loading.value) return
  loading.value = true

  const method = isFavorited.value ? 'DELETE' : 'POST'

  try {
    const response = await fetch('/favorite', {
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        favoritable_type: props.favoritableType,
        favoritable_id: props.favoritableId
      })
    })

    if (response.ok) {
      isFavorited.value = !isFavorited.value
    } else {
      console.error("Failed to toggle favorite")
    }
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}
</script>
