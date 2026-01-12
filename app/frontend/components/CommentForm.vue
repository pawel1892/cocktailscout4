<template>
  <div>
    <textarea
      v-model="commentText"
      :id="textareaId"
      :name="textareaName"
      :class="textareaClasses"
      placeholder="Schreibe deinen Kommentar..."
      @input="$emit('update:modelValue', commentText)"
    ></textarea>

    <div class="flex justify-between items-center mt-2">
      <div :class="counterColorClass" class="text-sm font-medium">
        {{ characterCount }} / {{ maxLength }}
      </div>
      <div v-if="isOverLimit" class="text-xs text-red-600">
        Maximale Länge überschritten
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, defineProps, defineEmits } from 'vue'

const props = defineProps({
  modelValue: { type: String, default: '' },
  maxLength: { type: Number, default: 3000 },
  textareaId: { type: String, required: true },
  textareaName: { type: String, required: true },
  hasError: { type: Boolean, default: false }
})

const emit = defineEmits(['update:modelValue'])

const commentText = ref(props.modelValue)

const characterCount = computed(() => {
  return commentText.value.length
})

const isOverLimit = computed(() => {
  return characterCount.value > props.maxLength
})

const textareaClasses = computed(() => {
  const baseClasses = 'w-full px-4 py-3 border rounded-lg focus:ring-2 resize-y min-h-[100px]'

  if (props.hasError) {
    // Only apply red border, not red text color (so user can still type in normal color)
    return `${baseClasses} border-cs-error focus:border-cs-error focus:ring-cs-error`
  }

  return `${baseClasses} border-gray-300 focus:ring-cs-dark-red focus:border-transparent`
})

const counterColorClass = computed(() => {
  const count = characterCount.value
  if (count > props.maxLength) {
    return 'text-red-600 font-bold'
  } else if (count > props.maxLength * 0.95) {
    return 'text-orange-500'
  } else if (count > props.maxLength * 0.85) {
    return 'text-yellow-600'
  }
  return 'text-gray-500'
})
</script>
