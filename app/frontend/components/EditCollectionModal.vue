<template>
  <BaseModal :model-value="show" @close="$emit('close')" max-width="max-w-md">
    <template #header>
      <h3 class="text-xl font-bold text-gray-900">Liste bearbeiten</h3>
    </template>

    <template #content>
      <form @submit.prevent="submit" class="space-y-4">
        <div>
          <label for="edit-name" class="block text-sm font-medium text-gray-700 mb-1">
            Name <span class="text-red-500">*</span>
          </label>
          <input
            id="edit-name"
            v-model="form.name"
            type="text"
            required
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-cs-dark-red focus:border-transparent"
            placeholder="z.B. Meine Hausbar, Party 2024"
          />
        </div>

        <div>
          <label for="edit-notes" class="block text-sm font-medium text-gray-700 mb-1">
            Notizen
          </label>
          <textarea
            id="edit-notes"
            v-model="form.notes"
            rows="3"
            class="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-cs-dark-red focus:border-transparent"
            placeholder="Optionale Notizen, z.B. Einkaufsliste..."
          ></textarea>
        </div>

        <div class="flex items-center">
          <input
            id="edit-is-default"
            v-model="form.is_default"
            type="checkbox"
            class="h-4 w-4 text-cs-dark-red focus:ring-cs-dark-red border-gray-300 rounded"
          />
          <label for="edit-is-default" class="ml-2 block text-sm text-gray-700">
            Als Standard-Liste festlegen
          </label>
        </div>

        <div v-if="errors.length > 0" class="bg-red-50 border border-red-200 rounded-lg p-3">
          <ul class="text-sm text-red-600 space-y-1">
            <li v-for="(error, index) in errors" :key="index">{{ error }}</li>
          </ul>
        </div>

        <!-- Delete Section -->
        <div class="pt-4 border-t border-gray-200">
          <button
            @click="confirmDelete"
            type="button"
            class="text-sm text-red-600 hover:text-red-700 font-medium"
          >
            Liste löschen
          </button>
        </div>
      </form>
    </template>

    <template #footer>
      <div class="flex gap-3 justify-end">
        <button
          @click="$emit('close')"
          type="button"
          class="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition"
        >
          Abbrechen
        </button>
        <button
          @click="submit"
          :disabled="loading"
          class="px-4 py-2 bg-cs-dark-red text-white rounded-lg hover:bg-cs-dark-red/90 transition disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {{ loading ? 'Speichere...' : 'Speichern' }}
        </button>
      </div>
    </template>
  </BaseModal>
</template>

<script setup>
import { ref, watch } from 'vue'
import BaseModal from './BaseModal.vue'
import { useIngredientCollections } from '../composables/useIngredientCollections'

const props = defineProps({
  show: Boolean,
  collection: Object
})

const emit = defineEmits(['close', 'updated', 'deleted'])

const { updateCollection, deleteCollection } = useIngredientCollections()

const form = ref({
  name: '',
  notes: '',
  is_default: false
})

const loading = ref(false)
const errors = ref([])

watch([() => props.show, () => props.collection], ([show, collection]) => {
  if (show && collection) {
    form.value = {
      name: collection.name || '',
      notes: collection.notes || '',
      is_default: collection.is_default || false
    }
    errors.value = []
  }
})

const submit = async () => {
  if (!props.collection) return

  loading.value = true
  errors.value = []

  const result = await updateCollection(props.collection.id, form.value)

  loading.value = false

  if (result.success) {
    emit('updated', result.collection)
  } else {
    errors.value = result.errors || ['Ein Fehler ist aufgetreten']
  }
}

const confirmDelete = async () => {
  if (!props.collection) return

  if (!confirm(`Möchtest du die Liste "${props.collection.name}" wirklich löschen?`)) {
    return
  }

  loading.value = true
  const result = await deleteCollection(props.collection.id)
  loading.value = false

  if (result.success) {
    emit('deleted')
  } else {
    errors.value = [result.error || 'Fehler beim Löschen']
  }
}
</script>
