<template>
  <div>

    <!-- Back link -->
    <div class="mb-6">
      <a href="/meine-bar" class="link inline-flex items-center gap-1.5 text-sm font-medium">
        <i class="fas fa-arrow-left text-xs"></i>
        Zurück zur Übersicht
      </a>
    </div>

    <!-- Header -->
    <div class="mb-8">
      <h1 class="font-display font-semibold text-[38px] sm:text-[48px] leading-none tracking-tight text-cs-red-900">{{ collectionName }}</h1>
      <div class="w-10 h-0.5 bg-cs-gold-400 mt-3 mb-2.5"></div>
      <div class="flex flex-wrap items-center gap-x-4 gap-y-1 text-sm text-cs-ink-500">
        <span>Klicke auf Zutaten, um sie hinzuzufügen oder zu entfernen</span>
        <a
          v-if="doableRecipesCount > 0"
          :href="`/rezepte?collection_id=${collectionId}`"
          class="link inline-flex items-center gap-1.5 font-medium"
        >
          <i class="fas fa-cocktail text-xs"></i>
          {{ doableRecipesCount }} {{ doableRecipesCount === 1 ? 'Rezept möglich' : 'Rezepte möglich' }}
        </a>
        <span v-else class="text-cs-ink-400">Keine Rezepte möglich</span>
      </div>
    </div>

    <!-- Search & sort -->
    <div class="mb-8 flex flex-col sm:flex-row gap-3">
      <div class="relative flex-1 max-w-md">
        <i class="fas fa-search absolute left-2.5 top-1/2 -translate-y-1/2 text-cs-ink-400 text-xs pointer-events-none"></i>
        <input
          v-model="searchQuery"
          type="text"
          placeholder="Zutaten filtern…"
          class="input-field pl-8 w-full"
        />
      </div>
      <select v-model="sortBy" class="input-field w-full sm:w-auto sm:min-w-[180px]">
        <option value="alphabetical">Alphabetisch</option>
        <option value="recipe_count">Nach Rezeptanzahl</option>
      </select>
    </div>

    <!-- Current ingredients -->
    <div class="mb-10">
      <div class="flex items-center gap-3 mb-4">
        <span class="font-sans font-bold uppercase text-[11px] tracking-widest text-cs-ink-400">
          In deiner Liste
        </span>
        <span class="font-mono text-[11px] text-cs-ink-400">({{ currentIngredients.length }})</span>
        <span class="flex-1 h-px bg-cs-ink-200"></span>
      </div>

      <div v-if="filteredCurrentIngredients.length > 0" class="flex flex-wrap gap-2">
        <button
          v-for="ingredient in filteredCurrentIngredients"
          :key="ingredient.id"
          @click.prevent.stop="removeIngredient(ingredient)"
          type="button"
          :disabled="pendingIds.has(ingredient.id)"
          class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-cs-red-900 text-white text-[13px] font-medium hover:bg-cs-red-800 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          {{ ingredient.name }}
          <span class="opacity-60 font-mono text-[11px]">({{ ingredient.recipes_count }})</span>
          <i class="fas fa-times text-[10px] opacity-75 ml-0.5"></i>
        </button>
      </div>
      <p v-else class="text-sm text-cs-ink-400 italic">
        {{ searchQuery ? 'Keine passenden Zutaten in deiner Liste' : 'Noch keine Zutaten hinzugefügt' }}
      </p>
    </div>

    <!-- Available ingredients -->
    <div>
      <div class="flex items-center gap-3 mb-4">
        <span class="font-sans font-bold uppercase text-[11px] tracking-widest text-cs-ink-400">
          Verfügbar
        </span>
        <span class="font-mono text-[11px] text-cs-ink-400">({{ availableIngredients.length }})</span>
        <span class="flex-1 h-px bg-cs-ink-200"></span>
      </div>

      <div v-if="filteredAvailableIngredients.length > 0" class="flex flex-wrap gap-2">
        <button
          v-for="ingredient in filteredAvailableIngredients"
          :key="ingredient.id"
          @click.prevent="addIngredient(ingredient)"
          type="button"
          :disabled="pendingIds.has(ingredient.id)"
          class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-cs-ink-100 text-cs-ink-700 text-[13px] font-medium hover:bg-cs-ink-200 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
        >
          <i class="fas fa-plus text-[10px] opacity-60"></i>
          {{ ingredient.name }}
          <span class="opacity-50 font-mono text-[11px]">({{ ingredient.recipes_count }})</span>
        </button>
      </div>
      <p v-else class="text-sm text-cs-ink-400 italic">
        {{ searchQuery ? 'Keine passenden Zutaten gefunden' : 'Alle Zutaten wurden hinzugefügt' }}
      </p>
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
const pendingIds = ref(new Set())
const doableRecipesCount = ref(0)

const getCSRFToken = () => {
  return document.querySelector('meta[name="csrf-token"]')?.content
}

const sortIngredients = (ingredients) => {
  const sorted = [...ingredients]
  if (sortBy.value === 'recipe_count') {
    sorted.sort((a, b) => {
      const countDiff = (b.recipes_count || 0) - (a.recipes_count || 0)
      if (countDiff !== 0) return countDiff
      return a.name.localeCompare(b.name)
    })
  } else {
    sorted.sort((a, b) => a.name.localeCompare(b.name))
  }
  return sorted
}

const availableIngredients = computed(() => {
  const currentIds = new Set(currentIngredients.value.map(i => i.id))
  return allIngredients.value.filter(i => !currentIds.has(i.id))
})

const filteredCurrentIngredients = computed(() => {
  let filtered = currentIngredients.value
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(i => i.name.toLowerCase().includes(query))
  }
  return sortIngredients(filtered)
})

const filteredAvailableIngredients = computed(() => {
  let filtered = availableIngredients.value
  if (searchQuery.value) {
    const query = searchQuery.value.toLowerCase()
    filtered = filtered.filter(i => i.name.toLowerCase().includes(query))
  }
  return sortIngredients(filtered)
})

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

const addIngredient = async (ingredient) => {
  if (pendingIds.value.has(ingredient.id)) return
  pendingIds.value = new Set([...pendingIds.value, ingredient.id])
  currentIngredients.value.push(ingredient)
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
    const data = await response.json()
    if (data.success || data.added?.length > 0) {
      doableRecipesCount.value = data.collection?.doable_recipes_count || 0
    } else {
      currentIngredients.value = currentIngredients.value.filter(i => i.id !== ingredient.id)
    }
  } catch (e) {
    currentIngredients.value = currentIngredients.value.filter(i => i.id !== ingredient.id)
  } finally {
    const next = new Set(pendingIds.value)
    next.delete(ingredient.id)
    pendingIds.value = next
  }
}

const removeIngredient = async (ingredient) => {
  if (pendingIds.value.has(ingredient.id)) return
  pendingIds.value = new Set([...pendingIds.value, ingredient.id])
  currentIngredients.value = currentIngredients.value.filter(i => i.id !== ingredient.id)
  try {
    const response = await fetch(`/ingredient_collections/${props.collectionId}/ingredients/${ingredient.id}`, {
      method: 'DELETE',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': getCSRFToken()
      }
    })
    const data = await response.json()
    if (data.success) {
      doableRecipesCount.value = data.collection?.doable_recipes_count || 0
    } else {
      currentIngredients.value.push(ingredient)
    }
  } catch (e) {
    currentIngredients.value.push(ingredient)
  } finally {
    const next = new Set(pendingIds.value)
    next.delete(ingredient.id)
    pendingIds.value = next
  }
}

onMounted(() => {
  Promise.all([loadCollection(), loadAllIngredients()])
})
</script>
