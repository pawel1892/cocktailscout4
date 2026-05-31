<template>
  <div>
    <!-- Selected chips -->
    <div v-if="selected.length > 0" class="flex flex-wrap gap-1.5 mb-2">
      <span
        v-for="item in selected"
        :key="item.id"
        class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-sm bg-cs-dark-red/10 text-cs-dark-red border border-cs-dark-red/20"
      >
        {{ item.label }}
        <button
          type="button"
          @click="remove(item.id)"
          class="ml-0.5 hover:text-cs-dark-red/60 transition-colors leading-none"
          :aria-label="`${item.label} entfernen`"
        >
          <i class="fas fa-times text-xs"></i>
        </button>
      </span>
    </div>

    <!-- Hidden inputs (always include one empty so the param key exists on submit) -->
    <input type="hidden" :name="inputName" value="">
    <input
      v-for="item in selected"
      :key="`hidden-${item.id}`"
      type="hidden"
      :name="inputName"
      :value="item.id"
    >

    <!-- Search input -->
    <div class="relative">
      <input
        ref="inputEl"
        v-model="query"
        type="text"
        :placeholder="placeholder"
        class="input-field w-full"
        autocomplete="off"
        @input="onInput"
        @focus="onFocus"
        @blur="onBlur"
        @keydown.escape="closeDropdown"
        @keydown.enter.prevent="selectFirst"
      >
      <div v-if="searching" class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400">
        <i class="fas fa-spinner fa-spin text-sm"></i>
      </div>

      <!-- Dropdown -->
      <div
        v-if="showDropdown && (filteredResults.length > 0 || (query.length >= 2 && !searching))"
        class="absolute z-20 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-md max-h-56 overflow-y-auto"
      >
        <button
          v-for="item in filteredResults"
          :key="item.id"
          type="button"
          @mousedown.prevent="add(item)"
          class="w-full px-4 py-2 text-left hover:bg-gray-50 transition-colors"
        >
          <div class="font-medium text-gray-900 text-sm">{{ item.label }}</div>
          <div v-if="item.sub" class="text-xs text-gray-400">{{ item.sub }}</div>
        </button>
        <div
          v-if="filteredResults.length === 0 && query.length >= 2 && !searching"
          class="px-4 py-2 text-sm text-gray-400"
        >
          Nichts gefunden.
        </div>
      </div>
    </div>

    <!-- Suggestions (e.g. from version history) -->
    <div v-if="availableSuggestions.length > 0" class="mt-2 flex flex-wrap items-center gap-1.5">
      <span class="text-xs text-gray-400">Vorgeschlagen:</span>
      <button
        v-for="sug in availableSuggestions"
        :key="sug.id"
        type="button"
        @click="add(sug)"
        class="inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-xs border border-gray-300 text-gray-600 hover:border-cs-dark-red hover:text-cs-dark-red transition-colors"
      >
        <i class="fas fa-plus text-[10px]"></i>
        {{ sug.label }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  initialItems: {
    type: Array,
    default: () => []
  },
  suggestions: {
    type: Array,
    default: () => []
  },
  searchUrl: {
    type: String,
    required: true
  },
  responseKey: {
    type: String,
    required: true
  },
  displayKey: {
    type: String,
    required: true
  },
  subKey: {
    type: String,
    default: null
  },
  inputName: {
    type: String,
    required: true
  },
  placeholder: {
    type: String,
    default: 'Suchen…'
  }
})

const selected = ref(props.initialItems.map(i => ({ id: i.id, label: i.label })))
const query = ref('')
const results = ref([])
const searching = ref(false)
const showDropdown = ref(false)
const inputEl = ref(null)
let debounceTimer = null

const selectedIds = computed(() => new Set(selected.value.map(i => i.id)))

const availableSuggestions = computed(() =>
  props.suggestions.filter(s => !selectedIds.value.has(s.id))
)

const filteredResults = computed(() =>
  results.value.filter(r => !selectedIds.value.has(r.id))
)

const onInput = () => {
  if (debounceTimer) clearTimeout(debounceTimer)
  if (query.value.length < 2) {
    results.value = []
    showDropdown.value = false
    return
  }
  debounceTimer = setTimeout(search, 300)
}

const onFocus = () => {
  if (results.value.length > 0) showDropdown.value = true
}

const onBlur = () => {
  setTimeout(() => {
    showDropdown.value = false
    query.value = ''
    results.value = []
  }, 200)
}

const closeDropdown = () => {
  showDropdown.value = false
  query.value = ''
  results.value = []
}

const search = async () => {
  searching.value = true
  showDropdown.value = true
  try {
    const res = await fetch(`${props.searchUrl}${encodeURIComponent(query.value)}`)
    const data = await res.json()
    const raw = data[props.responseKey] || []
    results.value = raw.map(item => ({
      id: item.id,
      label: item[props.displayKey],
      sub: props.subKey ? item[props.subKey] : null
    }))
  } catch {
    results.value = []
  } finally {
    searching.value = false
  }
}

const add = (item) => {
  if (!selectedIds.value.has(item.id)) {
    selected.value.push({ id: item.id, label: item.label })
  }
  query.value = ''
  results.value = []
  showDropdown.value = false
  inputEl.value?.focus()
}

const remove = (id) => {
  selected.value = selected.value.filter(i => i.id !== id)
}

const selectFirst = () => {
  if (filteredResults.value.length > 0) add(filteredResults.value[0])
}
</script>
