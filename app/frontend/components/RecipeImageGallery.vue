<template>
  <div>
    <!-- Thumbnail - clickable, smaller on sm, full size on md+ -->
    <div
      v-if="images.length > 0"
      class="w-48 md:w-full aspect-square bg-white rounded-lg overflow-hidden cursor-pointer hover:opacity-90 transition-opacity group relative mx-auto md:mx-0 border-2 border-gray-200 shadow-sm"
      @click="openModal(0)"
    >
      <img
        :src="images[0].mediumUrl"
        class="object-cover w-full h-full"
        alt="Recipe image"
      />
      <div
        v-if="images.length > 1"
        class="absolute bottom-2 right-2 bg-black/60 text-white text-xs px-2 py-1 rounded"
      >
        +{{ images.length - 1 }} {{ images.length === 2 ? 'Foto' : 'Fotos' }}
      </div>
    </div>

    <FullscreenImageModal
      v-model="isModalOpen"
      :image-url="images[currentIndex]?.largeUrl || ''"
      :recipe-title="images[currentIndex]?.recipeTitle || ''"
      :recipe-url="images[currentIndex]?.recipeUrl || ''"
      :user-badge="images[currentIndex]?.userBadge || ''"
      :show-prev="currentIndex > 0"
      :show-next="currentIndex < images.length - 1"
      :image-count="images.length"
      :current-index="currentIndex"
      @prev="previousImage"
      @next="nextImage"
      @close="closeModal"
    />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import FullscreenImageModal from './FullscreenImageModal.vue'

const images = ref([])
const isModalOpen = ref(false)
const currentIndex = ref(0)

onMounted(() => {
  if (window.recipeImages) {
    images.value = window.recipeImages
  }
})

const openModal = (index) => {
  currentIndex.value = index
  isModalOpen.value = true
}

const closeModal = () => {
  isModalOpen.value = false
}

const nextImage = () => {
  if (currentIndex.value < images.value.length - 1) {
    currentIndex.value++
  }
}

const previousImage = () => {
  if (currentIndex.value > 0) {
    currentIndex.value--
  }
}
</script>
