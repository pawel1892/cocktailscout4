<template>
  <div>
    <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3">
      <div
        v-for="image in images"
        :key="image.id"
        class="group relative aspect-square overflow-hidden rounded-xl cursor-pointer shadow-sm hover:shadow-lg transition-all duration-300"
        @click="openImage(image)"
      >
        <img
          :src="image.thumbnailUrl"
          :alt="image.recipeTitle"
          class="object-cover w-full h-full transition-transform duration-500 group-hover:scale-[1.05]"
          loading="lazy"
        />
        <!-- gradient overlay -->
        <div class="absolute inset-0 bg-gradient-to-t from-black/65 via-black/5 to-transparent"></div>
        <!-- text overlay -->
        <div class="absolute bottom-0 left-0 right-0 p-2.5">
          <p class="font-display font-semibold text-white text-[13px] leading-tight line-clamp-2 mb-0.5 drop-shadow">{{ image.recipeTitle }}</p>
          <p class="text-[11px] text-white/65 truncate">{{ image.user?.username }}</p>
        </div>
      </div>
    </div>

    <FullscreenImageModal
      v-model="showModal"
      :image-url="images[currentIndex]?.largeUrl || ''"
      :recipe-title="images[currentIndex]?.recipeTitle || ''"
      :recipe-url="images[currentIndex]?.recipeUrl || ''"
      :image-user="images[currentIndex]?.user || null"
      :show-prev="currentIndex > 0"
      :show-next="currentIndex < images.length - 1"
      :image-count="images.length"
      :current-index="currentIndex"
      @prev="currentIndex--"
      @next="currentIndex++"
    />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import FullscreenImageModal from './FullscreenImageModal.vue'

const images = ref([])
const showModal = ref(false)
const currentIndex = ref(0)

onMounted(() => {
  if (window.galleryImages) {
    images.value = window.galleryImages
  }
})

const openImage = (image) => {
  currentIndex.value = images.value.indexOf(image)
  showModal.value = true
}
</script>
