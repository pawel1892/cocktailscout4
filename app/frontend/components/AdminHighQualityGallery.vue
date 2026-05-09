<template>
  <div>
    <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3">
      <div
        v-for="image in images"
        :key="image.id"
        class="group relative aspect-square overflow-hidden rounded-xl shadow-sm hover:shadow-lg transition-all duration-300"
      >
        <img
          :src="image.thumbnailUrl"
          :alt="image.recipeTitle"
          class="object-cover w-full h-full transition-transform duration-500 group-hover:scale-[1.05]"
          loading="lazy"
        />
        <div class="absolute inset-0 bg-gradient-to-t from-black/65 via-black/5 to-transparent"></div>
        <div class="absolute bottom-0 left-0 right-0 p-2.5">
          <p class="font-display font-semibold text-white text-[13px] leading-tight line-clamp-2 drop-shadow">{{ image.recipeTitle }}</p>
        </div>

        <button
          @click="toggleHQ(image)"
          :disabled="image.loading"
          class="absolute top-2 right-2 rounded-full p-1.5 shadow transition-all"
          :class="image.highQuality
            ? 'bg-cs-gold-500 hover:bg-cs-gold-600'
            : 'bg-black/40 hover:bg-black/60'"
          :title="image.highQuality ? 'Hochwertig-Markierung entfernen' : 'Als hochwertig markieren'"
        >
          <i
            class="text-white text-sm leading-none"
            :class="[
              image.highQuality ? 'fa-solid fa-star' : 'fa-regular fa-star',
              image.loading ? 'animate-pulse' : ''
            ]"
          ></i>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const images = ref([])

onMounted(() => {
  if (window.adminGalleryImages) {
    images.value = window.adminGalleryImages.map(img => ({ ...img, loading: false }))
  }
})

const csrfToken = () => document.querySelector('meta[name="csrf-token"]').content

const toggleHQ = async (image) => {
  if (image.loading) return
  image.loading = true

  try {
    let response
    if (image.highQuality) {
      response = await fetch(`/admin/high_quality_recipe_images/${image.id}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken()
        }
      })
    } else {
      response = await fetch('/admin/high_quality_recipe_images', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken()
        },
        body: JSON.stringify({ recipe_image_id: image.id })
      })
    }

    if (response.ok) {
      image.highQuality = !image.highQuality
    } else {
      console.error('Failed to toggle high quality', response.status)
    }
  } catch (e) {
    console.error(e)
  } finally {
    image.loading = false
  }
}
</script>
