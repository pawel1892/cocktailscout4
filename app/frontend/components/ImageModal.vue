<template>
  <BaseModal v-model="isOpen" @close="handleClose">
    <template #header>
      <div>
        <h3 class="text-xl font-bold">
          <a :href="recipeUrl" class="link hover:text-cs-gold transition-colors">
            {{ recipeTitle }}
          </a>
        </h3>
        <p class="text-sm text-gray-600 mt-1 flex items-center gap-1">
          von <span v-html="userBadge"></span>
        </p>
      </div>
    </template>

    <template #content>
      <div class="flex items-center justify-center">
        <img
          :src="imageUrl"
          :alt="recipeTitle"
          class="max-w-full max-h-[70vh] object-contain rounded"
        />
      </div>
      <div v-if="uploadDate" class="text-xs text-gray-500 text-center mt-2">
        Hochgeladen am {{ uploadDate }}
      </div>
    </template>

    <template #footer>
      <div class="flex justify-end items-center w-full">
        <button @click="handleClose" class="btn btn-primary">
          Schließen
        </button>
      </div>
    </template>
  </BaseModal>
</template>

<script setup>
import { ref, watch } from 'vue'
import BaseModal from './BaseModal.vue'

const props = defineProps({
  modelValue: {
    type: Boolean,
    required: true
  },
  imageUrl: {
    type: String,
    required: true
  },
  recipeTitle: {
    type: String,
    required: true
  },
  recipeUrl: {
    type: String,
    required: true
  },
  userBadge: {
    type: String,
    required: true
  },
  uploadDate: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['update:modelValue'])

const isOpen = ref(props.modelValue)

watch(() => props.modelValue, (newValue) => {
  isOpen.value = newValue
})

watch(isOpen, (newValue) => {
  emit('update:modelValue', newValue)
})

const handleClose = () => {
  isOpen.value = false
}
</script>
