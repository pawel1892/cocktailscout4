<template>
  <div class="space-y-4">
    <!-- File picker (hidden, triggered by button) -->
    <input
      ref="fileInput"
      type="file"
      accept="image/jpeg,image/png,image/webp"
      class="sr-only"
      @change="onFileChange"
    />

    <!-- Step 1: no file selected -->
    <div v-if="!imageDataUrl" class="flex items-center gap-3 flex-wrap">
      <button type="button" class="btn btn-outline btn-sm" @click="fileInput.click()">
        <i class="fa-solid fa-camera mr-2"></i>
        {{ hasAvatar ? 'Foto ändern' : 'Foto hochladen' }}
      </button>
      <button
        v-if="hasAvatar"
        type="button"
        class="btn btn-sm text-red-600 border border-red-200 hover:bg-red-50"
        :disabled="deleting"
        @click="deleteAvatar"
      >
        <i v-if="deleting" class="fa-solid fa-spinner fa-spin mr-1"></i>
        <i v-else class="fa-solid fa-trash mr-1"></i>
        Avatar löschen
      </button>
    </div>

    <!-- Client error -->
    <div v-if="clientError" class="text-sm text-red-600">
      <i class="fa-solid fa-exclamation-circle mr-1"></i>{{ clientError }}
    </div>

    <!-- Step 2: crop UI -->
    <div v-if="imageDataUrl" class="space-y-3">
      <p class="text-xs text-cs-ink-500">
        <i class="fa-solid fa-circle-info mr-1"></i>
        Bereich auswählen – wird als Kreis angezeigt
      </p>
      <div class="avatar-crop-container relative overflow-hidden rounded bg-cs-ink-900">
        <img ref="cropperImg" :src="imageDataUrl" class="block max-w-full" alt="" style="opacity:0" />
      </div>
      <div class="flex gap-2">
        <button
          type="button"
          class="btn btn-primary btn-sm"
          :disabled="uploading"
          @click="upload"
        >
          <i v-if="uploading" class="fa-solid fa-spinner fa-spin mr-2"></i>
          <i v-else class="fa-solid fa-check mr-2"></i>
          {{ uploading ? 'Wird gespeichert…' : 'Speichern' }}
        </button>
        <button type="button" class="btn btn-outline btn-sm" :disabled="uploading" @click="cancel">
          Abbrechen
        </button>
      </div>
      <div v-if="serverErrors.length" class="text-sm text-red-600 space-y-1">
        <p v-for="err in serverErrors" :key="err">{{ err }}</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onBeforeUnmount } from 'vue'
import Cropper from 'cropperjs'

const props = defineProps({
  hasAvatar: { type: Boolean, default: false }
})

const emit = defineEmits(['uploaded', 'deleted'])

const fileInput    = ref(null)
const cropperImg   = ref(null)
const imageDataUrl = ref(null)
const clientError  = ref(null)
const serverErrors = ref([])
const uploading    = ref(false)
const deleting     = ref(false)

let cropperInstance = null

function onFileChange(event) {
  const file = event.target.files[0]
  if (!file) return

  if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
    clientError.value = 'Erlaubte Formate: JPEG, PNG, WebP.'
    return
  }
  if (file.size > 5 * 1024 * 1024) {
    clientError.value = 'Maximale Dateigröße: 5 MB.'
    return
  }

  clientError.value = null
  const reader = new FileReader()
  reader.onload = (e) => {
    imageDataUrl.value = e.target.result
    setTimeout(initCropper, 50)
  }
  reader.readAsDataURL(file)
}

function initCropper() {
  if (cropperInstance) {
    cropperInstance.destroy()
    cropperInstance = null
  }

  cropperInstance = new Cropper(cropperImg.value, {
    template: `
      <cropper-canvas background>
        <cropper-image rotatable scalable translatable></cropper-image>
        <cropper-handle action="select" plain></cropper-handle>
        <cropper-selection
          initial-coverage="0.8"
          aspect-ratio="1"
          movable
          resizable
        >
          <cropper-grid role="grid" covered></cropper-grid>
          <cropper-crosshair centered></cropper-crosshair>
          <cropper-handle action="move" theme-color="rgba(255,255,255,0.35)"></cropper-handle>
          <cropper-handle action="n-resize"></cropper-handle>
          <cropper-handle action="e-resize"></cropper-handle>
          <cropper-handle action="s-resize"></cropper-handle>
          <cropper-handle action="w-resize"></cropper-handle>
          <cropper-handle action="ne-resize"></cropper-handle>
          <cropper-handle action="nw-resize"></cropper-handle>
          <cropper-handle action="se-resize"></cropper-handle>
          <cropper-handle action="sw-resize"></cropper-handle>
        </cropper-selection>
      </cropper-canvas>
    `,
  })
}

async function upload() {
  if (!cropperInstance || uploading.value) return
  uploading.value    = true
  serverErrors.value = []

  try {
    const selection = cropperInstance.getCropperSelection()
    // Apply circular clip via beforeDraw so the stored image is a circle (transparent corners).
    // Saved as PNG to preserve transparency.
    const canvas = await selection.$toCanvas({
      width: 400,
      height: 400,
      beforeDraw(ctx, cvs) {
        ctx.beginPath()
        ctx.arc(cvs.width / 2, cvs.height / 2, cvs.width / 2, 0, Math.PI * 2)
        ctx.clip()
      },
    })

    canvas.toBlob(async (blob) => {
      const formData = new FormData()
      formData.append('avatar', blob, 'avatar.png')

      try {
        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
        const response = await fetch('/user_avatar', {
          method: 'POST',
          headers: { 'X-CSRF-Token': csrfToken },
          body: formData,
        })
        const data = await response.json()
        if (response.ok) {
          emit('uploaded', data)
          cancel()
        } else {
          serverErrors.value = data.errors || ['Ein Fehler ist aufgetreten.']
        }
      } catch {
        serverErrors.value = ['Verbindungsfehler. Bitte versuche es erneut.']
      } finally {
        uploading.value = false
      }
    }, 'image/png')
  } catch (e) {
    serverErrors.value = ['Zuschneiden fehlgeschlagen. Bitte versuche es erneut.']
    uploading.value = false
  }
}

async function deleteAvatar() {
  if (deleting.value) return
  deleting.value = true
  try {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const response = await fetch('/user_avatar', {
      method: 'DELETE',
      headers: { 'X-CSRF-Token': csrfToken },
    })
    const data = await response.json()
    if (response.ok) emit('deleted', data)
  } catch {
    // silent
  } finally {
    deleting.value = false
  }
}

function cancel() {
  if (cropperInstance) {
    cropperInstance.destroy()
    cropperInstance = null
  }
  imageDataUrl.value  = null
  serverErrors.value  = []
  if (fileInput.value) fileInput.value.value = ''
}

onBeforeUnmount(() => {
  if (cropperInstance) cropperInstance.destroy()
})
</script>
