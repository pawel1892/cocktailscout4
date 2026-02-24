<template>
  <div>
    <h2 class="text-2xl font-bold mb-4 flex items-center gap-2">
      <i class="fas fa-camera text-cs-gold"></i>
      Foto hochladen
    </h2>

    <!-- Success state -->
    <div v-if="state === 'success'" class="space-y-4">
      <div class="flex items-start gap-3 p-4 bg-green-50 border border-green-200 rounded-lg text-green-800">
        <i class="fas fa-check-circle mt-0.5 flex-shrink-0"></i>
        <span class="text-sm">{{ successMessage }}</span>
      </div>
      <button type="button" class="btn btn-outline btn-sm" @click="reset">
        <i class="fas fa-camera mr-1"></i> Weiteres Foto hochladen
      </button>
    </div>

    <!-- Upload state -->
    <div v-else class="space-y-4">
      <!-- Drop zone -->
      <div
        class="relative border-2 border-dashed rounded-lg transition-colors cursor-pointer"
        :class="[
          isDragging ? 'border-cs-gold bg-amber-50' : 'border-gray-300 hover:border-cs-gold hover:bg-gray-50',
          previewUrl ? 'p-2' : 'p-8'
        ]"
        @dragover.prevent="isDragging = true"
        @dragleave.prevent="isDragging = false"
        @drop.prevent="handleDrop"
        @click="fileInput.click()"
      >
        <input
          ref="fileInput"
          type="file"
          class="sr-only"
          :accept="acceptedTypes"
          @change="handleFileChange"
        />

        <!-- Preview -->
        <div v-if="previewUrl" class="flex flex-col items-center gap-3">
          <img :src="previewUrl" alt="Vorschau" class="max-h-64 rounded-lg object-contain" />
          <span class="text-xs text-gray-500">{{ selectedFile?.name }}</span>
        </div>

        <!-- Placeholder -->
        <div v-else class="flex flex-col items-center gap-3 text-center">
          <i class="fas fa-cloud-upload-alt text-4xl text-gray-300"></i>
          <div>
            <p class="text-gray-600 font-medium">Bild hierher ziehen</p>
            <p class="text-gray-400 text-sm mt-1">oder klicken zum Auswählen</p>
          </div>
          <p class="text-xs text-gray-400">JPEG, PNG, WebP oder GIF · max. {{ maxSizeMb }} MB</p>
        </div>
      </div>

      <!-- Client-side error -->
      <div v-if="clientError" class="flex items-start gap-2 p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm">
        <i class="fas fa-exclamation-circle mt-0.5 flex-shrink-0"></i>
        <span>{{ clientError }}</span>
      </div>

      <!-- Server errors -->
      <div v-if="serverErrors.length" class="p-3 bg-red-50 border border-red-200 rounded-lg text-red-700 text-sm space-y-1">
        <p class="font-medium flex items-center gap-2">
          <i class="fas fa-exclamation-circle"></i>
          Fehler beim Hochladen:
        </p>
        <ul class="list-disc list-inside space-y-0.5 pl-1">
          <li v-for="error in serverErrors" :key="error">{{ error }}</li>
        </ul>
      </div>

      <!-- Actions -->
      <div class="flex items-center gap-3">
        <button
          type="button"
          class="btn btn-primary"
          :disabled="!selectedFile || state === 'uploading'"
          @click="upload"
        >
          <span v-if="state === 'uploading'" class="flex items-center gap-2">
            <i class="fas fa-spinner fa-spin"></i>
            Wird hochgeladen…
          </span>
          <span v-else>Hochladen</span>
        </button>

        <button
          v-if="selectedFile"
          type="button"
          class="btn btn-outline btn-sm"
          :disabled="state === 'uploading'"
          @click="reset"
        >
          Abbrechen
        </button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'

const props = defineProps({
  uploadUrl:     { type: String, required: true },
  maxSizeMb:     { type: Number, default: 10 },
  acceptedTypes: { type: String, default: 'image/jpeg,image/png,image/webp,image/gif' }
})

const fileInput    = ref(null)
const selectedFile = ref(null)
const previewUrl   = ref(null)
const isDragging   = ref(false)
const state        = ref('idle')   // idle | uploading | success
const clientError  = ref(null)
const serverErrors = ref([])
const successMessage = ref('')

function validateFile(file) {
  const accepted = props.acceptedTypes.split(',')
  if (!accepted.includes(file.type)) {
    return 'Ungültiges Dateiformat. Erlaubt: JPEG, PNG, WebP, GIF.'
  }
  if (file.size > props.maxSizeMb * 1024 * 1024) {
    return `Die Datei ist zu groß. Maximale Größe: ${props.maxSizeMb} MB.`
  }
  return null
}

function applyFile(file) {
  clientError.value  = null
  serverErrors.value = []
  const error = validateFile(file)
  if (error) {
    clientError.value = error
    return
  }
  selectedFile.value = file
  const reader = new FileReader()
  reader.onload = e => { previewUrl.value = e.target.result }
  reader.readAsDataURL(file)
}

function handleFileChange(event) {
  const file = event.target.files[0]
  if (file) applyFile(file)
}

function handleDrop(event) {
  isDragging.value = false
  const file = event.dataTransfer.files[0]
  if (file) applyFile(file)
}

async function upload() {
  if (!selectedFile.value || state.value === 'uploading') return

  state.value        = 'uploading'
  serverErrors.value = []

  const formData = new FormData()
  formData.append('image', selectedFile.value)

  try {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const response = await fetch(props.uploadUrl, {
      method: 'POST',
      headers: { 'X-CSRF-Token': csrfToken },
      body: formData
    })

    const data = await response.json()

    if (response.ok && data.success) {
      successMessage.value = data.message
      state.value = 'success'
    } else {
      serverErrors.value = data.errors || ['Ein unbekannter Fehler ist aufgetreten.']
      state.value = 'idle'
    }
  } catch {
    serverErrors.value = ['Verbindungsfehler. Bitte versuche es erneut.']
    state.value = 'idle'
  }
}

function reset() {
  selectedFile.value = null
  previewUrl.value   = null
  clientError.value  = null
  serverErrors.value = []
  state.value        = 'idle'
  successMessage.value = ''
  if (fileInput.value) fileInput.value.value = ''
}
</script>
