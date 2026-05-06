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

    <!-- Empty state -->
    <div v-if="collections.length === 0" class="card card-ghost p-12 text-center">
      <div class="text-cs-ink-300 mb-4">
        <i class="fas fa-wine-bottle text-5xl"></i>
      </div>
      <h3 class="font-display font-bold text-xl text-cs-ink-800 mb-2">Noch keine Liste erstellt</h3>
      <p class="text-cs-ink-500 mb-6 max-w-sm mx-auto">Erstelle deine erste Zutatenliste und finde heraus, welche Cocktails du mixen kannst.</p>
      <button @click="showCreateModal = true" class="btn btn-primary">
        <i class="fas fa-plus text-xs mr-1"></i> Erste Liste erstellen
      </button>
    </div>

    <!-- Collections -->
    <div v-else class="space-y-6">

      <!-- Action bar -->
      <div class="flex justify-end">
        <button @click="showCreateModal = true" class="btn btn-primary">
          <i class="fas fa-plus text-xs mr-1"></i> Neue Liste
        </button>
      </div>

      <!-- Grid -->
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <div v-for="collection in collections" :key="collection.id" class="card">

          <!-- Header -->
          <div class="card-header">
            <div class="min-w-0">
              <div class="flex items-center gap-2 flex-wrap">
                <span class="font-display font-semibold text-[18px] text-cs-ink-900 leading-snug">{{ collection.name }}</span>
                <span v-if="collection.is_default" class="tag-gold">Standard</span>
              </div>
              <p class="text-xs text-cs-ink-500 font-normal mt-0.5">
                {{ collection.ingredient_count }} {{ collection.ingredient_count === 1 ? 'Zutat' : 'Zutaten' }}
              </p>
            </div>
            <button
              @click="openEditModal(collection)"
              class="text-cs-ink-400 hover:text-cs-ink-700 transition p-1 shrink-0 ml-2"
              title="Bearbeiten"
            >
              <i class="fas fa-pen text-sm"></i>
            </button>
          </div>

          <!-- Body -->
          <div class="card-body">

            <!-- Doable recipes -->
            <a
              v-if="collection.doable_recipes_count > 0"
              :href="`/rezepte?collection_id=${collection.id}`"
              class="link font-medium text-sm inline-flex items-center gap-1.5 mb-3"
            >
              <i class="fas fa-cocktail text-xs"></i>
              {{ collection.doable_recipes_count }} {{ collection.doable_recipes_count === 1 ? 'Rezept möglich' : 'Rezepte möglich' }}
            </a>
            <p v-else class="text-cs-ink-400 text-sm mb-3">Keine Rezepte möglich</p>

            <!-- Notes -->
            <div v-if="collection.notes" class="mb-3 text-sm text-cs-ink-600 bg-cs-ink-50 rounded-md px-3 py-2">
              {{ truncate(collection.notes, 100) }}
            </div>

            <!-- Ingredients -->
            <div v-if="collection.ingredients && collection.ingredients.length > 0" class="flex flex-wrap gap-1">
              <span
                v-for="ingredient in collection.ingredients.slice(0, 8)"
                :key="ingredient.id"
                class="tag-neutral"
              >{{ ingredient.name }}</span>
              <span v-if="collection.ingredients.length > 8" class="tag-neutral">
                +{{ collection.ingredients.length - 8 }}
              </span>
            </div>
            <p v-else class="text-cs-ink-400 text-sm italic">Noch keine Zutaten hinzugefügt</p>

          </div>

          <!-- Footer -->
          <div class="card-footer">
            <a
              :href="`/ingredient_collections/${collection.id}/edit`"
              class="btn btn-primary btn-sm w-full text-center"
            >
              Zutaten verwalten
            </a>
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

const { collections, loading, fetchCollections } = useIngredientCollections()

const showCreateModal = ref(false)
const showEditModal = ref(false)
const editingCollection = ref(null)

onMounted(() => {
  fetchCollections()
})

const openEditModal = (collection) => {
  editingCollection.value = collection
  showEditModal.value = true
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

const truncate = (text, length) => {
  if (!text) return ''
  return text.length > length ? text.substring(0, length) + '…' : text
}
</script>
