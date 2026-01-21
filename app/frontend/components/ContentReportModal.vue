<template>
  <div v-if="show" class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/50 backdrop-blur-sm" @click.self="close">
    <div class="relative bg-white rounded-lg shadow-xl w-full max-w-md overflow-hidden animate-in fade-in zoom-in-95 duration-200">
      
      <!-- Header -->
      <div class="bg-cs-dark-red text-white px-6 py-4 flex justify-between items-center">
        <h3 class="font-bold text-lg">Inhalt melden</h3>
        <button @click="close" class="text-white/80 hover:text-white">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
          </svg>
        </button>
      </div>

      <!-- Body -->
      <div class="p-6">
        <div v-if="success" class="text-center py-4">
          <div class="text-green-500 mb-2 flex justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-12 h-12">
              <path stroke-linecap="round" stroke-linejoin="round" d="M9 12.75 11.25 15 15 9.75M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z" />
            </svg>
          </div>
          <p class="text-gray-800 font-medium">{{ successMessage }}</p>
          <button @click="close" class="mt-4 btn btn-primary w-full">Schließen</button>
        </div>

        <form v-else @submit.prevent="submitReport" class="space-y-4">
          <p class="text-sm text-gray-600 mb-4">
            Bitte gib an, warum du diesen Inhalt melden möchtest. Unsere Moderatoren werden sich das ansehen.
          </p>

          <!-- Reason -->
          <div class="space-y-2">
            <label class="block text-sm font-medium text-gray-700">Grund</label>
            <div class="space-y-2">
              <label class="flex items-center gap-2 cursor-pointer">
                <input type="radio" v-model="form.reason" value="spam" class="text-cs-dark-red focus:ring-cs-dark-red">
                <span>Spam / Werbung</span>
              </label>
              <label class="flex items-center gap-2 cursor-pointer">
                <input type="radio" v-model="form.reason" value="inappropriate" class="text-cs-dark-red focus:ring-cs-dark-red">
                <span>Unangemessener Inhalt (NSFW, Gewalt)</span>
              </label>
              <label class="flex items-center gap-2 cursor-pointer">
                <input type="radio" v-model="form.reason" value="harassment" class="text-cs-dark-red focus:ring-cs-dark-red">
                <span>Belästigung / Beleidigung</span>
              </label>
              <label class="flex items-center gap-2 cursor-pointer">
                <input type="radio" v-model="form.reason" value="other" class="text-cs-dark-red focus:ring-cs-dark-red">
                <span>Sonstiges</span>
              </label>
            </div>
          </div>

          <!-- Description -->
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1">
              Beschreibung
              <span v-if="form.reason === 'other'" class="text-red-500">*</span>
            </label>
            <textarea
              v-model="form.description"
              rows="3"
              class="w-full rounded border-gray-300 focus:border-cs-dark-red focus:ring focus:ring-cs-dark-red/20 text-sm"
              placeholder="Zusätzliche Informationen..."
              :required="form.reason === 'other'"
            ></textarea>
          </div>

          <!-- Error -->
          <div v-if="error" class="text-red-600 text-sm bg-red-50 p-2 rounded">
            {{ error }}
          </div>

          <!-- Actions -->
          <div class="flex justify-end pt-2">
            <button
              type="submit"
              class="btn btn-primary w-full"
              :disabled="loading"
            >
              <span v-if="loading">Sende...</span>
              <span v-else>Meldung absenden</span>
            </button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted, reactive } from 'vue'

const show = ref(false)
const loading = ref(false)
const success = ref(false)
const successMessage = ref('')
const error = ref(null)

const reportable = reactive({
  type: null,
  id: null
})

const form = reactive({
  reason: 'spam',
  description: ''
})

const reset = () => {
  form.reason = 'spam'
  form.description = ''
  success.value = false
  error.value = null
  loading.value = false
}

const open = (detail) => {
  reportable.type = detail.type
  reportable.id = detail.id
  reset()
  show.value = true
}

const close = () => {
  show.value = false
}

const submitReport = async () => {
  loading.value = true
  error.value = null

  try {
    const response = await fetch('/reports', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        report: {
          reportable_type: reportable.type,
          reportable_id: reportable.id,
          reason: form.reason,
          description: form.description
        }
      })
    })

    const data = await response.json()

    if (response.ok) {
      success.value = true
      successMessage.value = data.message
    } else {
      error.value = data.error || data.errors?.join(', ') || 'Ein Fehler ist aufgetreten.'
    }
  } catch (e) {
    error.value = 'Netzwerkfehler. Bitte versuche es später erneut.'
  } finally {
    loading.value = false
  }
}

const handleOpenEvent = (event) => {
  open(event.detail)
}

onMounted(() => {
  window.addEventListener('open-report-modal', handleOpenEvent)
})

onUnmounted(() => {
  window.removeEventListener('open-report-modal', handleOpenEvent)
})
</script>
