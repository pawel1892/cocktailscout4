<template>
  <div class="relative">
    <input
      type="text"
      v-model="searchQuery"
      @input="onInput"
      @focus="showDropdown = true"
      @blur="onBlur"
      :placeholder="placeholder"
      class="input-field w-full"
      autocomplete="off"
    />

    <div v-if="searching" class="absolute right-3 top-3 text-gray-400">
      <i class="fas fa-spinner fa-spin"></i>
    </div>

    <div
      v-if="showDropdown && results.length > 0"
      class="absolute z-10 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-md max-h-60 overflow-y-auto"
    >
      <button
        v-for="ingredient in results"
        :key="ingredient.id"
        type="button"
        @mousedown.prevent="selectIngredient(ingredient)"
        class="w-full px-4 py-2 text-left hover:bg-gray-50 focus:bg-gray-50 focus:outline-none transition-colors"
      >
        <div class="font-medium text-gray-900">{{ ingredient.name }}</div>
        <div class="text-sm text-gray-500">{{ ingredient.recipes_count }} Rezepte</div>
      </button>
    </div>

    <div
      v-if="showDropdown && searchQuery.length > 0 && results.length === 0 && !searching"
      class="absolute z-10 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-md px-4 py-2 text-gray-500 text-sm"
    >
      Keine Zutat gefunden. Gib einen neuen Namen ein.
    </div>
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'

const props = defineProps({
  modelValue: {
    type: Object,
    default: null
  },
  placeholder: {
    type: String,
    default: 'Zutat suchen...'
  }
})

const emit = defineEmits(['update:modelValue'])

const searchQuery = ref('')
const searching = ref(false)
const results = ref([])
const showDropdown = ref(false)
let debounceTimeout = null

// Watch for external changes to modelValue
watch(() => props.modelValue, (newValue) => {
  if (newValue) {
    searchQuery.value = newValue.name || ''
  } else {
    searchQuery.value = ''
  }
}, { immediate: true })

const onInput = () => {
  // Clear previous timeout
  if (debounceTimeout) {
    clearTimeout(debounceTimeout)
  }

  // Debounce search by 300ms
  debounceTimeout = setTimeout(() => {
    search()
  }, 300)
}

const search = async () => {
  if (searchQuery.value.length < 2) {
    results.value = []
    return
  }

  searching.value = true
  showDropdown.value = true

  try {
    const response = await fetch(`/ingredients.json?q=${encodeURIComponent(searchQuery.value)}`)
    const data = await response.json()
    results.value = data.ingredients || []
  } catch (error) {
    console.error('Error searching ingredients:', error)
    results.value = []
  } finally {
    searching.value = false
  }
}

const selectIngredient = (ingredient) => {
  searchQuery.value = ingredient.name
  showDropdown.value = false
  emit('update:modelValue', ingredient)
}

const onBlur = () => {
  // Delay hiding dropdown to allow click events to fire
  setTimeout(() => {
    showDropdown.value = false

    // If user typed but didn't select, emit the typed name as a new ingredient
    if (searchQuery.value && !props.modelValue) {
      emit('update:modelValue', { id: null, name: searchQuery.value })
    }
  }, 200)
}
</script>
