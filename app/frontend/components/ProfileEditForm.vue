<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  profile: {
    type: Object,
    required: true
  }
})

const emit = defineEmits(['saved', 'cancel'])

const formData = ref({
  prename: '',
  gender: '',
  location: '',
  homepage: ''
})

const loading = ref(false)
const errors = ref([])

// Initialize form data from profile
watch(() => props.profile, (newProfile) => {
  if (newProfile) {
    formData.value = {
      prename: newProfile.prename || '',
      gender: newProfile.gender || '',
      location: newProfile.location || '',
      homepage: newProfile.homepage || ''
    }
  }
}, { immediate: true })

const saveProfile = async () => {
  loading.value = true
  errors.value = []

  try {
    const response = await fetch(`/user_profiles/${props.profile.id}.json`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        user: formData.value
      })
    })

    if (!response.ok) {
      const data = await response.json()
      throw new Error(data.errors?.join(', ') || 'Fehler beim Speichern')
    }

    const updatedProfile = await response.json()
    emit('saved', updatedProfile)
  } catch (e) {
    errors.value = [e.message]
  } finally {
    loading.value = false
  }
}

const cancel = () => {
  errors.value = []
  emit('cancel')
}
</script>

<template>
  <div class="space-y-4">
    <div v-if="errors.length > 0" class="bg-red-50 border border-red-200 rounded-md p-3">
      <ul class="text-sm text-red-600">
        <li v-for="error in errors" :key="error">{{ error }}</li>
      </ul>
    </div>

    <div>
      <label for="prename" class="block text-sm font-medium text-gray-700 mb-1">
        Vorname
      </label>
      <input
        id="prename"
        v-model="formData.prename"
        type="text"
        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        :disabled="loading"
      />
    </div>

    <div>
      <label for="gender" class="block text-sm font-medium text-gray-700 mb-1">
        Geschlecht
      </label>
      <select
        id="gender"
        v-model="formData.gender"
        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        :disabled="loading"
      >
        <option value="">Keine Angabe</option>
        <option value="m">Männlich</option>
        <option value="w">Weiblich</option>
      </select>
    </div>

    <div>
      <label for="location" class="block text-sm font-medium text-gray-700 mb-1">
        Ort
      </label>
      <input
        id="location"
        v-model="formData.location"
        type="text"
        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        :disabled="loading"
      />
    </div>

    <div>
      <label for="homepage" class="block text-sm font-medium text-gray-700 mb-1">
        Homepage
      </label>
      <input
        id="homepage"
        v-model="formData.homepage"
        type="url"
        class="w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500"
        placeholder="https://"
        :disabled="loading"
      />
    </div>

    <div class="flex gap-3 pt-4 border-t">
      <button
        type="button"
        @click="cancel"
        :disabled="loading"
        class="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition disabled:opacity-50"
      >
        Abbrechen
      </button>
      <button
        type="button"
        @click="saveProfile"
        :disabled="loading"
        class="px-4 py-2 bg-cs-dark-red text-white rounded-lg hover:bg-cs-dark-red/90 transition disabled:opacity-50 disabled:cursor-not-allowed"
      >
        <i v-if="loading" class="fa-solid fa-spinner fa-spin mr-2"></i>
        <i v-else class="fa-solid fa-save mr-2"></i>
        {{ loading ? 'Speichert...' : 'Speichern' }}
      </button>
    </div>
  </div>
</template>
