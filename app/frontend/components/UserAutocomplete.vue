<template>
  <div class="relative">
    <input type="hidden" name="user_id" :value="selectedUserId" />

    <div class="relative">
      <input
        type="text"
        v-model="searchQuery"
        @input="onInput"
        @focus="onFocus"
        @blur="onBlur"
        placeholder="Benutzer suchen..."
        class="input-field w-full py-1.5 text-sm"
        autocomplete="off"
      />
      <button
        v-if="selectedUserId"
        type="button"
        @click="clearSelection"
        class="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600"
      >
        <i class="fas fa-times text-xs"></i>
      </button>
      <div v-else-if="searching" class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400">
        <i class="fas fa-spinner fa-spin text-xs"></i>
      </div>
    </div>

    <div
      v-if="showDropdown && results.length > 0"
      class="absolute z-10 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-md max-h-60 overflow-y-auto"
    >
      <button
        v-for="user in results"
        :key="user.id"
        type="button"
        @mousedown.prevent="selectUser(user)"
        class="w-full px-4 py-2 text-left hover:bg-gray-50 focus:bg-gray-50 focus:outline-none transition-colors"
      >
        <div class="font-medium text-gray-900">{{ user.username }}</div>
      </button>
    </div>

    <div
      v-if="showDropdown && searchQuery.length >= 2 && results.length === 0 && !searching"
      class="absolute z-10 w-full mt-1 bg-white border border-gray-200 rounded-lg shadow-md px-4 py-2 text-gray-500 text-sm"
    >
      Kein Benutzer gefunden.
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const props = defineProps({
  initialUsername: {
    type: String,
    default: ''
  },
  initialUserId: {
    type: String,
    default: ''
  }
})

const searchQuery = ref('')
const selectedUserId = ref('')
const searching = ref(false)
const results = ref([])
const showDropdown = ref(false)
let debounceTimeout = null

onMounted(() => {
  if (props.initialUsername) searchQuery.value = props.initialUsername
  if (props.initialUserId) selectedUserId.value = props.initialUserId
})

const onInput = () => {
  selectedUserId.value = ''
  if (debounceTimeout) clearTimeout(debounceTimeout)
  debounceTimeout = setTimeout(() => { search() }, 300)
}

const onFocus = () => {
  if (searchQuery.value.length >= 2 && results.value.length > 0) {
    showDropdown.value = true
  }
}

const search = async () => {
  if (searchQuery.value.length < 2) {
    results.value = []
    showDropdown.value = false
    return
  }

  searching.value = true
  showDropdown.value = true

  try {
    const response = await fetch(`/benutzer.json?q=${encodeURIComponent(searchQuery.value)}`)
    const data = await response.json()
    results.value = data.users || []
  } catch (error) {
    console.error('Error searching users:', error)
    results.value = []
  } finally {
    searching.value = false
  }
}

const selectUser = (user) => {
  searchQuery.value = user.username
  selectedUserId.value = String(user.id)
  showDropdown.value = false
  results.value = []
}

const clearSelection = () => {
  searchQuery.value = ''
  selectedUserId.value = ''
  results.value = []
  showDropdown.value = false
}

const onBlur = () => {
  setTimeout(() => {
    showDropdown.value = false
    if (searchQuery.value && !selectedUserId.value) {
      searchQuery.value = ''
    }
  }, 200)
}
</script>
