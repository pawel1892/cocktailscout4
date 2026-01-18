<template>
  <div>
    <!-- Back Link -->
    <div class="mb-6">
      <a href="/meine-bar" class="text-cs-dark-red hover:text-cs-dark-red/80 font-medium flex items-center gap-2">
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
          <path stroke-linecap="round" stroke-linejoin="round" d="M10.5 19.5 3 12m0 0 7.5-7.5M3 12h18" />
        </svg>
        Zurück zur Übersicht
      </a>
    </div>

    <!-- Header -->
    <div class="mb-8">
      <h1 class="text-3xl font-bold mb-2">{{ collectionName }}</h1>
      <div class="flex flex-col sm:flex-row sm:items-center gap-2 sm:gap-4 text-gray-600">
        <p>Klicke auf Zutaten, um sie hinzuzufügen oder zu entfernen</p>
        <span class="hidden sm:inline text-gray-400">•</span>
        <a
          v-if="doableRecipesCount > 0"
          :href="`/rezepte?collection_id=${collectionId}`"
          class="text-cs-dark-red hover:text-cs-dark-red/80 font-medium flex items-center gap-1"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9.813 15.904 9 18.75l-.813-2.846a4.5 4.5 0 0 0-3.09-3.09L2.25 12l2.846-.813a4.5 4.5 0 0 0 3.09-3.09L9 5.25l.813 2.846a4.5 4.5 0 0 0 3.09 3.09L15.75 12l-2.846.813a4.5 4.5 0 0 0-3.09 3.09ZM18.259 8.715 18 9.75l-.259-1.035a3.375 3.375 0 0 0-2.455-2.456L14.25 6l1.036-.259a3.375 3.375 0 0 0 2.455-2.456L18 2.25l.259 1.035a3.375 3.375 0 0 0 2.456 2.456L21.75 6l-1.035.259a3.375 3.375 0 0 0-2.456 2.456Z" />
          </svg>
          {{ doableRecipesCount }} {{ doableRecipesCount === 1 ? 'Rezept möglich' : 'Rezepte möglich' }}
        </a>
        <span v-else class="text-gray-400 italic">Keine Rezepte möglich</span>
      </div>
    </div>

    <!-- Search & Sort Filter -->
    <div class="mb-6 flex flex-col sm:flex-row gap-4">
      <input
        v-model="searchQuery"
        type="text"
        placeholder="Zutaten filtern..."
        class="input-field flex-1 max-w-md"
      />
      <select v-model="sortBy" class="input-field w-full sm:w-auto">
        <option value="alphabetical">Alphabetisch</option>
        <option value="recipe_count">Nach Rezeptanzahl</option>
      </select>
    </div>

    <!-- Current Ingredients -->
    <div class="mb-12">
      <h2 class="text-xl font-semibold mb-4 text-cs-dark-red">
        In deiner Liste ({{ currentIngredients.length }})
      </h2>
      <div v-if="filteredCurrentIngredients.length > 0" class="flex flex-wrap gap-2">
        <button
          v-for="ingredient in filteredCurrentIngredients"
          :key="ingredient.id"
          @click.prevent.stop="removeIngredient(ingredient)"
          type="button"
          class="px-3 py-2 bg-cs-dark-red text-white rounded-lg hover:bg-cs-dark-red/80 transition text-sm font-medium flex items-center gap-2"
        >
          {{ ingredient.name }} <span class="opacity-75">({{ ingredient.recipes_count }})</span>
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M6 18 18 6M6 6l12 12" />
          </svg>
        </button>
      </div>
      <div v-else class="text-gray-500 italic">
        {{ searchQuery ? 'Keine passenden Zutaten in deiner Liste' : 'Noch keine Zutaten hinzugefügt' }}
      </div>
    </div>

    <!-- Available Ingredients -->
    <div>
      <h2 class="text-xl font-semibold mb-4 text-gray-700">
        Verfügbare Zutaten ({{ availableIngredients.length }})
      </h2>
      <div v-if="filteredAvailableIngredients.length > 0" class="flex flex-wrap gap-2">
        <button
          v-for="ingredient in filteredAvailableIngredients"
          :key="ingredient.id"
          @click.prevent="addIngredient(ingredient)"
          type="button"
          class="px-3 py-2 bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition text-sm font-medium flex items-center gap-2"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
          </svg>
          {{ ingredient.name }} <span class="opacity-60">({{ ingredient.recipes_count }})</span>
        </button>
      </div>
      <div v-else class="text-gray-500 italic">
        {{ searchQuery ? 'Keine passenden Zutaten gefunden' : 'Alle Zutaten wurden hinzugefügt' }}
      </div>
    </div>

    <!-- Loading State -->
    <div v-if="loading" class="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div class="bg-white rounded-lg p-6 shadow-xl">
        <div class="animate-spin rounded-full h-12 w-12 border-b-2 border-cs-dark-red mx-auto"></div>
        <p class="mt-4 text-gray-700">Wird gespeichert...</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'

const props = defineProps({
  collectionId: {
    type: [String, Number],
    required: true
  },
  collectionName: {
    type: String,
    required: true
  }
})

const searchQuery = ref('')
const sortBy = ref('alphabetical')
const currentIngredients = ref([])
const allIngredients = ref([])
const loading = ref(false)
const doableRecipesCount = ref(0)

const getCSRFToken = () => {
  return document.querySelector('meta[name="csrf-token"]')?.content
}

// Sort function based on sortBy value
const sortIngredients = (ingredients) => {
  const sorted = [...ingredients]
  if (sortBy.value === 'recipe_count') {
    sorted.sort((a, b) => {
      const countDiff = (b.recipes_count || 0) - (a.recipes_count || 0)
      if (countDiff !== 0) return countDiff
      return a.name.localeCompare(b.name) // Alphabetical as tiebreaker
    })
  } else {
    sorted.sort((a, b) => a.name.localeCompare(b.name))
  }
  return sorted
}

// Computed: Available ingredients (not in current)
const availableIngredients = computed(() => {
  const currentIds = new Set(currentIngredients.value.map(i => i.id))
  return allIngredients.value.filter(i => !currentIds.has(i.id))
})

// Computed: Filtered current ingredients
const filteredCurrentIngredients = computed(() => {
  let filtered = currentIngredients.value
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(i => i.name.toLowerCase().includes(query))
  }
  return sortIngredients(filtered)
})

// Computed: Filtered available ingredients
const filteredAvailableIngredients = computed(() => {
  let filtered = availableIngredients.value
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(i => i.name.toLowerCase().includes(query))
  }
  return sortIngredients(filtered)
})

// Load collection data
const loadCollection = async () => {
  try {
    const response = await fetch(`/ingredient_collections/${props.collectionId}`, {
      headers: { 'Accept': 'application/json' }
    })
    const data = await response.json()
    if (data.success) {
      currentIngredients.value = data.collection.ingredients
      doableRecipesCount.value = data.collection.doable_recipes_count || 0
    }
  } catch (e) {
    console.error('Failed to load collection:', e)
  }
}

// Load all ingredients
const loadAllIngredients = async () => {
  try {
    const response = await fetch('/ingredients', {
      headers: { 'Accept': 'application/json' }
    })
    const data = await response.json()
    if (data.success) {
      allIngredients.value = data.ingredients
    }
  } catch (e) {
    console.error('Failed to load ingredients:', e)
  }
}

// Add ingredient
const addIngredient = async (ingredient) => {
  loading.value = true
  try {
    const response = await fetch(`/ingredient_collections/${props.collectionId}/ingredients`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': getCSRFToken()
      },
      body: JSON.stringify({ ingredient_id: ingredient.id })
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()
    if (data.success || data.added?.length > 0) {
      // Add to current (sorting handled by computed property)
      currentIngredients.value.push(ingredient)
      // Update doable recipes count
      doableRecipesCount.value = data.collection?.doable_recipes_count || 0
    } else {
      console.error('Failed to add ingredient:', data.errors)
      alert('Fehler beim Hinzufügen der Zutat')
    }
  } catch (e) {
    console.error('Network error adding ingredient:', e)
    alert('Netzwerkfehler beim Hinzufügen der Zutat')
  } finally {
    loading.value = false
  }
}

// Remove ingredient
const removeIngredient = async (ingredient) => {
  loading.value = true
  try {
    const response = await fetch(`/ingredient_collections/${props.collectionId}/ingredients/${ingredient.id}`, {
      method: 'DELETE',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': getCSRFToken()
      }
    })

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`)
    }

    const data = await response.json()
    if (data.success) {
      // Remove from current
      currentIngredients.value = currentIngredients.value.filter(i => i.id !== ingredient.id)
      // Update doable recipes count
      doableRecipesCount.value = data.collection?.doable_recipes_count || 0
    } else {
      console.error('Failed to remove ingredient:', data.error)
      alert('Fehler beim Entfernen der Zutat')
    }
  } catch (e) {
    console.error('Network error removing ingredient:', e)
    alert('Netzwerkfehler beim Entfernen der Zutat')
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  Promise.all([loadCollection(), loadAllIngredients()])
})
</script>
