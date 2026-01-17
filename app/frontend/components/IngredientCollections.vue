<template>
  <div>
    <CreateCollectionModal
      :show="showCreateModal"
      @close="showCreateModal = false"
      @created="handleCollectionCreated"
    />

    <EditCollectionModal
      :show="showEditModal"
      :collection="editingCollection"
      @close="showEditModal = false"
      @updated="handleCollectionUpdated"
      @deleted="handleCollectionDeleted"
    />

    <ManageIngredientsModal
      :show="showIngredientsModal"
      :collection="managingCollection"
      @close="showIngredientsModal = false"
      @updated="handleIngredientsUpdated"
    />

    <!-- Empty State -->
    <div v-if="collections.length === 0" class="bg-white rounded-lg shadow-sm border border-gray-200 p-12 text-center">
      <div class="max-w-sm mx-auto">
        <svg class="mx-auto h-16 w-16 text-gray-400 mb-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="1.5" d="M20.25 7.5l-.625 10.632a2.25 2.25 0 01-2.247 2.118H6.622a2.25 2.25 0 01-2.247-2.118L3.75 7.5M10 11.25h4M3.375 7.5h17.25c.621 0 1.125-.504 1.125-1.125v-1.5c0-.621-.504-1.125-1.125-1.125H3.375c-.621 0-1.125.504-1.125 1.125v1.5c0 .621.504 1.125 1.125 1.125z" />
        </svg>
        <h3 class="text-lg font-semibold text-gray-900 mb-2">Noch keine Liste erstellt</h3>
        <p class="text-gray-600 mb-6">Erstelle deine erste Zutatenliste und verwalte deine Bar.</p>
        <button
          @click="showCreateModal = true"
          class="bg-cs-dark-red text-white px-6 py-2 rounded-lg hover:bg-cs-dark-red/90 transition"
        >
          Erste Liste erstellen
        </button>
      </div>
    </div>

    <!-- Collections List -->
    <div v-else class="space-y-6">
      <!-- Action Bar -->
      <div class="flex justify-end">
        <button
          @click="showCreateModal = true"
          class="bg-cs-dark-red text-white px-4 py-2 rounded-lg hover:bg-cs-dark-red/90 transition flex items-center gap-2"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          Neue Liste
        </button>
      </div>

      <!-- Collections Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div
          v-for="collection in collections"
          :key="collection.id"
          class="bg-white rounded-lg shadow-sm border border-gray-200 overflow-hidden hover:shadow-md transition"
        >
          <div class="p-6">
            <!-- Header -->
            <div class="flex items-start justify-between mb-4">
              <div class="flex-1">
                <div class="flex items-center gap-2 mb-1">
                  <h3 class="text-xl font-semibold text-gray-900">{{ collection.name }}</h3>
                  <span
                    v-if="collection.is_default"
                    class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium bg-cs-gold text-white"
                  >
                    Standard
                  </span>
                </div>
                <p class="text-sm text-gray-500">
                  {{ collection.ingredient_count }} {{ collection.ingredient_count === 1 ? 'Zutat' : 'Zutaten' }}
                </p>
                <a
                  v-if="collection.doable_recipes_count > 0"
                  :href="`/rezepte?collection_id=${collection.id}`"
                  class="text-sm text-cs-dark-red hover:text-cs-dark-red/80 font-medium flex items-center gap-1"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 0 0 2.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 0 0-2.456 2.456Z" />
                  </svg>
                  {{ collection.doable_recipes_count }} {{ collection.doable_recipes_count === 1 ? 'Rezept möglich' : 'Rezepte möglich' }}
                </a>
                <p v-else class="text-sm text-gray-400 italic">
                  Keine Rezepte möglich
                </p>
              </div>
              <button
                @click="openEditModal(collection)"
                class="text-gray-400 hover:text-gray-600 transition p-1"
                title="Bearbeiten"
              >
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
                  <path stroke-linecap="round" stroke-linejoin="round" d="m16.862 4.487 1.687-1.688a1.875 1.875 0 1 1 2.652 2.652L10.582 16.07a4.5 4.5 0 0 1-1.897 1.13L6 18l.8-2.685a4.5 4.5 0 0 1 1.13-1.897l8.932-8.931Zm0 0L19.5 7.125M18 14v4.75A2.25 2.25 0 0 1 15.75 21H5.25A2.25 2.25 0 0 1 3 18.75V8.25A2.25 2.25 0 0 1 5.25 6H10" />
                </svg>
              </button>
            </div>

            <!-- Notes Preview -->
            <div v-if="collection.notes" class="mb-4 p-3 bg-gray-50 rounded text-sm text-gray-700">
              {{ truncate(collection.notes, 100) }}
            </div>

            <!-- Ingredients Preview -->
            <div v-if="collection.ingredients && collection.ingredients.length > 0" class="mb-4">
              <div class="flex flex-wrap gap-1.5">
                <span
                  v-for="ingredient in collection.ingredients.slice(0, 8)"
                  :key="ingredient.id"
                  class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-100 text-gray-700"
                >
                  {{ ingredient.name }}
                </span>
                <span
                  v-if="collection.ingredients.length > 8"
                  class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium bg-gray-200 text-gray-600"
                >
                  +{{ collection.ingredients.length - 8 }} weitere
                </span>
              </div>
            </div>
            <div v-else class="mb-4 text-sm text-gray-500 italic">
              Noch keine Zutaten hinzugefügt
            </div>

            <!-- Actions -->
            <div class="pt-4 border-t border-gray-100">
              <button
                @click="openIngredientsModal(collection)"
                class="w-full bg-cs-dark-red hover:bg-cs-dark-red/90 text-white px-4 py-2 rounded-lg transition text-sm font-medium"
              >
                Zutaten verwalten
              </button>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useIngredientCollections } from '../composables/useIngredientCollections'
import CreateCollectionModal from './CreateCollectionModal.vue'
import EditCollectionModal from './EditCollectionModal.vue'
import ManageIngredientsModal from './ManageIngredientsModal.vue'

const { collections, loading, fetchCollections } = useIngredientCollections()

const showCreateModal = ref(false)
const showEditModal = ref(false)
const showIngredientsModal = ref(false)
const editingCollection = ref(null)
const managingCollection = ref(null)

onMounted(() => {
  fetchCollections()
})

const openEditModal = (collection) => {
  editingCollection.value = collection
  showEditModal.value = true
}

const openIngredientsModal = (collection) => {
  managingCollection.value = collection
  showIngredientsModal.value = true
}

const handleCollectionCreated = () => {
  showCreateModal.value = false
  fetchCollections()
}

const handleCollectionUpdated = () => {
  showEditModal.value = false
  fetchCollections()
}

const handleCollectionDeleted = () => {
  showEditModal.value = false
  fetchCollections()
}

const handleIngredientsUpdated = () => {
  fetchCollections()
}

const truncate = (text, length) => {
  if (!text) return ''
  return text.length > length ? text.substring(0, length) + '...' : text
}
</script>
