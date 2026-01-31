<template>
  <div ref="dropdownContainer" class="relative group">
    <!-- Split Button: Link + Chevron -->
    <div class="flex items-center gap-0">
      <!-- Main Link (Clickable Navigation) -->
      <a
        :href="path"
        class="hover:text-cs-gold transition py-2"
      >
        {{ label }}
      </a>

      <!-- Chevron Button (Dropdown Trigger) -->
      <button
        @click="toggleDropdown"
        class="flex items-center gap-1 hover:text-cs-gold transition focus:outline-none py-2 pl-1"
        :aria-expanded="isOpen"
        aria-label="Toggle dropdown"
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          fill="none"
          viewBox="0 0 24 24"
          stroke-width="2"
          stroke="currentColor"
          class="w-4 h-4 transition-transform duration-200"
          :class="{ 'rotate-180': isOpen }"
        >
          <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
        </svg>
      </button>
    </div>

    <!-- Dropdown Menu -->
    <div
      class="absolute left-1/2 -translate-x-1/2 mt-0 pt-2 w-48 transition-all duration-200 z-50 transform origin-top"
      :class="isOpen ? 'opacity-100 visible' : 'opacity-0 invisible group-hover:opacity-100 group-hover:visible group-focus-within:opacity-100 group-focus-within:visible'"
    >
      <div class="bg-white text-gray-800 rounded shadow-xl ring-1 ring-black ring-opacity-5 overflow-hidden">
        <a
          v-for="item in items"
          :key="item.path"
          :href="item.path"
          class="block px-4 py-2 hover:bg-gray-100 hover:text-cs-dark-red transition text-sm sm:text-base"
          @click="closeDropdown"
        >
          {{ item.label }}
        </a>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'

const props = defineProps({
  label: { type: String, required: true },
  path: { type: String, required: true },
  items: { type: Array, required: true }
})

const isOpen = ref(false)
const dropdownContainer = ref(null)

const toggleDropdown = (event) => {
  event.stopPropagation()
  isOpen.value = !isOpen.value
}

const closeDropdown = () => {
  isOpen.value = false
}

const handleClickOutside = (event) => {
  if (dropdownContainer.value && !dropdownContainer.value.contains(event.target)) {
    closeDropdown()
  }
}

onMounted(() => {
  document.addEventListener('click', handleClickOutside)
})

onBeforeUnmount(() => {
  document.removeEventListener('click', handleClickOutside)
})
</script>
