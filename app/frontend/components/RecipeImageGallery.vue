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

    <!-- Modal -->
    <BaseModal v-model="isModalOpen" @close="closeModal" max-width="max-w-4xl">
      <template #header>
        <div class="flex items-center justify-between w-full">
          <h3 class="text-lg font-semibold">Rezeptbilder</h3>
          <span class="text-sm text-gray-500">{{ currentIndex + 1 }} / {{ images.length }}</span>
        </div>
      </template>

      <template #content>
        <div class="relative">
          <!-- Main Image -->
          <div class="flex items-center justify-center min-h-[400px] max-h-[60vh] bg-white border border-gray-200 rounded-lg p-4">
            <img
              :src="images[currentIndex].largeUrl"
              class="max-w-full max-h-[60vh] object-contain"
              alt="Recipe image"
            />
          </div>

          <!-- Image Info -->
          <div class="mt-3 flex items-center justify-between text-sm">
            <div class="flex items-center gap-2">
              <span class="text-gray-600">Foto von</span>
              <span v-html="images[currentIndex].userBadge"></span>
            </div>
            <span class="text-gray-400 text-xs">{{ images[currentIndex].uploadDate }}</span>
          </div>

          <!-- Navigation Arrows -->
          <button
            v-if="images.length > 1"
            @click.stop="previousImage"
            class="absolute left-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 text-white p-3 rounded-full transition-colors"
            :disabled="currentIndex === 0"
            :class="{ 'opacity-50 cursor-not-allowed': currentIndex === 0 }"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
              <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
            </svg>
          </button>

          <button
            v-if="images.length > 1"
            @click.stop="nextImage"
            class="absolute right-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 text-white p-3 rounded-full transition-colors"
            :disabled="currentIndex === images.length - 1"
            :class="{ 'opacity-50 cursor-not-allowed': currentIndex === images.length - 1 }"
          >
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-6 h-6">
              <path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
            </svg>
          </button>
        </div>

        <!-- Thumbnail Strip -->
        <div v-if="images.length > 1" class="mt-4 flex gap-2 overflow-x-auto pb-2">
          <div
            v-for="(image, index) in images"
            :key="image.id"
            @click="currentIndex = index"
            class="flex-shrink-0 w-16 h-16 rounded cursor-pointer border-2 transition-all overflow-hidden"
            :class="index === currentIndex ? 'border-cs-gold' : 'border-gray-300 hover:border-gray-400'"
          >
            <img
              :src="image.mediumUrl"
              class="w-full h-full object-cover"
              alt="Thumbnail"
            />
          </div>
        </div>
      </template>
    </BaseModal>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import BaseModal from './BaseModal.vue'

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

// Keyboard navigation
onMounted(() => {
  const handleKeydown = (e) => {
    if (!isModalOpen.value) return

    if (e.key === 'ArrowRight') {
      nextImage()
    } else if (e.key === 'ArrowLeft') {
      previousImage()
    }
  }

  window.addEventListener('keydown', handleKeydown)

  return () => {
    window.removeEventListener('keydown', handleKeydown)
  }
})
</script>
