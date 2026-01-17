<template>
  <BaseModal :model-value="show" @close="$emit('close')" max-width="max-w-2xl">
    <template #header>
      <div>
        <h3 class="text-xl font-bold text-gray-900">Zutaten verwalten</h3>
        <p v-if="collection" class="text-sm text-gray-500 mt-1">{{ collection.name }}</p>
      </div>
    </template>

    <template #content>
      <div class="space-y-4">
        <!-- Search -->
        <div>
          <label for="ingredient-search" class="block text-sm font-medium text-gray-700 mb-2">
            Zutaten hinzufügen
          </label>
          <div class="relative">
            <input
              id="ingredient-search"
              v-model="searchQuery"
              @input="searchIngredients"
              type="text"
              class="w-full px-3 py-2 pl-10 border border-gray-300 rounded-lg focus:ring-2 focus:ring-cs-dark-red focus:border-transparent"
              placeholder="Suche nach Zutaten..."
            />
            <svg
              class="absolute left-3 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>

          <!-- Search Results -->
          <div
            v-if="searchResults.length > 0"
            class="mt-2 bg-white border border-gray-200 rounded-lg shadow-lg max-h-60 overflow-y-auto"
          >
            <button
              v-for="ingredient in searchResults"
              :key="ingredient.id"
              @click="addIngredient(ingredient)"
              class="w-full text-left px-4 py-2 hover:bg-gray-50 transition flex items-center justify-between"
            >
              <span>{{ ingredient.name }}</span>
              <svg
                class="w-5 h-5 text-green-600"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
              </svg>
            </button>
          </div>

          <p v-if="searching" class="mt-2 text-sm text-gray-500">Suche...</p>
          <p v-else-if="searchQuery && searchResults.length === 0" class="mt-2 text-sm text-gray-500">
            Keine Zutaten gefunden
          </p>
        </div>

        <!-- Current Ingredients -->
        <div>
          <h4 class="text-sm font-medium text-gray-700 mb-2">
            Aktuelle Zutaten ({{ currentIngredients.length }})
          </h4>

          <div v-if="currentIngredients.length === 0" class="text-sm text-gray-500 italic py-4 text-center">
            Noch keine Zutaten hinzugefügt
          </div>

          <div v-else class="space-y-2 max-h-80 overflow-y-auto">
            <div
              v-for="ingredient in currentIngredients"
              :key="ingredient.id"
              class="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition"
            >
              <span class="text-gray-900">{{ ingredient.name }}</span>
              <button
                @click="removeIngredient(ingredient)"
                class="text-red-600 hover:text-red-700 p-1"
                title="Entfernen"
              >
                <svg
                  class="w-5 h-5"
                  fill="none"
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                >
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>
        </div>

        <!-- Error Messages -->
        <div v-if="error" class="bg-red-50 border border-red-200 rounded-lg p-3">
          <p class="text-sm text-red-600">{{ error }}</p>
        </div>
      </div>
    </template>

    <template #footer>
      <div class="flex justify-end">
        <button
          @click="$emit('close')"
          type="button"
          class="px-4 py-2 text-gray-700 bg-gray-100 rounded-lg hover:bg-gray-200 transition"
        >
          Fertig
        </button>
      </div>
    </template>
  </BaseModal>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import BaseModal from './BaseModal.vue'
import { useIngredientCollections } from '../composables/useIngredientCollections'

const props = defineProps({
  show: Boolean,
  collection: Object
})

const emit = defineEmits(['close', 'updated'])

const { addIngredients, removeIngredient: removeIngredientFromCollection } = useIngredientCollections()

const searchQuery = ref('')
const searchResults = ref([])
const searching = ref(false)
const error = ref(null)
const currentIngredients = ref([])

let searchTimeout = null

watch([() => props.show, () => props.collection], ([show, collection]) => {
  if (show && collection) {
    currentIngredients.value = [...(collection.ingredients || [])]
    searchQuery.value = ''
    searchResults.value = []
    error.value = null
  }
})

const searchIngredients = async () => {
  if (!searchQuery.value || searchQuery.value.length < 2) {
    searchResults.value = []
    return
  }

  // Debounce search
  clearTimeout(searchTimeout)
  searchTimeout = setTimeout(async () => {
    searching.value = true
    error.value = null

    try {
      // Search ingredients via API (you'll need to implement this endpoint)
      const response = await fetch(`/ingredients.json?q=${encodeURIComponent(searchQuery.value)}`)
      const data = await response.json()

      // Filter out ingredients already in collection
      const currentIds = currentIngredients.value.map(i => i.id)
      searchResults.value = data.ingredients.filter(i => !currentIds.includes(i.id))
    } catch (e) {
      error.value = 'Fehler beim Suchen von Zutaten'
      console.error('Search error:', e)
    } finally {
      searching.value = false
    }
  }, 300)
}

const addIngredient = async (ingredient) => {
  if (!props.collection) return

  error.value = null
  const result = await addIngredients(props.collection.id, [ingredient.id])

  if (result.success || result.added?.length > 0) {
    currentIngredients.value.push(ingredient)
    searchQuery.value = ''
    searchResults.value = []
    emit('updated')
  } else {
    error.value = result.error || 'Fehler beim Hinzufügen'
  }
}

const removeIngredient = async (ingredient) => {
  if (!props.collection) return

  error.value = null
  const result = await removeIngredientFromCollection(props.collection.id, ingredient.id)

  if (result.success) {
    currentIngredients.value = currentIngredients.value.filter(i => i.id !== ingredient.id)
    emit('updated')
  } else {
    error.value = result.error || 'Fehler beim Entfernen'
  }
}
</script>
