<template>
  <div>
    <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-5 xl:grid-cols-6 gap-3 sm:gap-4">
      <div
        v-for="image in images"
        :key="image.id"
        class="card overflow-hidden hover:shadow-md transition-all duration-200 group cursor-pointer"
        @click="openImage(image)"
      >
        <div class="aspect-square bg-gray-200 relative">
          <img
            :src="image.thumbnailUrl"
            :alt="image.recipeTitle"
            class="object-cover w-full h-full"
            loading="lazy"
          />
          <div class="absolute inset-0 bg-black/0 group-hover:bg-black/20 transition-colors duration-300"></div>
        </div>

        <div class="card-body p-2 sm:p-3">
          <h3 class="font-bold text-sm sm:text-base mb-1 truncate">
            {{ image.recipeTitle }}
          </h3>
          <p class="text-xs text-gray-600 flex items-center gap-1 truncate">
            von <span v-html="image.userBadge"></span>
          </p>
          <p class="text-[10px] sm:text-xs text-gray-500">{{ image.uploadDate }}</p>
        </div>
      </div>
    </div>

    <ImageModal
      v-model="showModal"
      :image-url="selectedImage?.largeUrl || ''"
      :recipe-title="selectedImage?.recipeTitle || ''"
      :recipe-url="selectedImage?.recipeUrl || ''"
      :user-badge="selectedImage?.userBadge || ''"
      :upload-date="selectedImage?.uploadDate || ''"
    />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import ImageModal from './ImageModal.vue'

const images = ref([])
const showModal = ref(false)
const selectedImage = ref(null)

onMounted(() => {
  if (window.galleryImages) {
    images.value = window.galleryImages
  }
})

const openImage = (image) => {
  selectedImage.value = image
  showModal.value = true
}
</script>
