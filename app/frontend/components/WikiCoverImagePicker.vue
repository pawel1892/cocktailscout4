<template>
  <div>
    <!-- Remove flag -->
    <input type="hidden" name="wiki_article[remove_cover_image]" :value="removing ? '1' : '0'">

    <!-- File input: always in DOM so it submits with the form -->
    <input
      ref="fileInput"
      type="file"
      name="wiki_article[cover_image]"
      class="sr-only"
      accept="image/jpeg,image/png,image/webp"
      @change="handleFileChange"
    >

    <!-- Image preview (new selection or existing) -->
    <div v-if="previewUrl && !removing" class="relative mb-3 rounded-lg overflow-hidden bg-gray-100 inline-block max-w-full">
      <img :src="previewUrl" alt="Titelbild" class="block max-h-72 max-w-full">
      <div class="absolute inset-0 flex items-start justify-end p-2 gap-2">
        <button
          type="button"
          @click="fileInput.click()"
          class="bg-black/50 hover:bg-black/70 text-white rounded-full w-8 h-8 flex items-center justify-center transition-colors"
          title="Anderes Bild wählen"
        >
          <i class="fas fa-pencil-alt text-xs"></i>
        </button>
        <button
          type="button"
          @click="remove"
          class="bg-black/50 hover:bg-black/70 text-white rounded-full w-8 h-8 flex items-center justify-center transition-colors"
          title="Bild entfernen"
        >
          <i class="fas fa-times text-sm"></i>
        </button>
      </div>
    </div>

    <!-- Drop zone (shown when no image) -->
    <div v-if="!previewUrl || removing">
      <div
        class="border-2 border-dashed rounded-lg transition-colors cursor-pointer"
        :class="isDragging ? 'border-cs-gold bg-amber-50' : 'border-gray-300 hover:border-cs-gold hover:bg-gray-50'"
        @dragover.prevent="isDragging = true"
        @dragleave.prevent="isDragging = false"
        @drop.prevent="handleDrop"
        @click="fileInput.click()"
      >
        <div class="p-6 flex flex-col items-center gap-2 text-center">
          <i class="fas fa-image text-3xl text-gray-300"></i>
          <p class="text-gray-500 text-sm">Titelbild hierher ziehen oder <span class="text-cs-dark-red font-medium">auswählen</span></p>
          <p class="text-xs text-gray-400">JPEG, PNG, WebP · empfohlen min. 1200 × 600 px</p>
        </div>
      </div>
      <p v-if="error" class="mt-1 text-xs text-cs-error">{{ error }}</p>
    </div>

    <!-- Restore when removing existing image -->
    <button
      v-if="removing && initialUrl"
      type="button"
      class="mt-1 text-xs text-gray-400 hover:text-gray-600"
      @click="cancelRemove"
    >
      <i class="fas fa-undo mr-1"></i> Rückgängig
    </button>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const props = defineProps({
  initialUrl: { type: String, default: '' },
  maxSizeMb:  { type: Number, default: 10 }
})

const fileInput  = ref(null)
const isDragging = ref(false)
const removing   = ref(false)
const error      = ref(null)
const previewUrl = ref(props.initialUrl || null)

const applyFile = (file) => {
  error.value = null
  if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
    error.value = 'Ungültiges Format. Erlaubt: JPEG, PNG, WebP.'
    return
  }
  if (file.size > props.maxSizeMb * 1024 * 1024) {
    error.value = `Zu groß. Maximum: ${props.maxSizeMb} MB.`
    return
  }
  removing.value = false
  const reader = new FileReader()
  reader.onload = e => { previewUrl.value = e.target.result }
  reader.readAsDataURL(file)
}

const handleFileChange = (e) => {
  if (e.target.files[0]) applyFile(e.target.files[0])
}

const handleDrop = (e) => {
  isDragging.value = false
  if (e.dataTransfer.files[0]) applyFile(e.dataTransfer.files[0])
}

const remove = () => {
  previewUrl.value = null
  if (props.initialUrl) removing.value = true
  if (fileInput.value) fileInput.value.value = ''
}

const cancelRemove = () => {
  removing.value   = false
  previewUrl.value = props.initialUrl
}
</script>
