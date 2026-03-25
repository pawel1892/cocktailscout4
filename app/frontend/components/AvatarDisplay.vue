<template>
  <div :class="containerClass" :style="containerStyle">
    <img
      v-if="avatarUrl"
      :src="avatarUrl"
      :alt="user?.username"
      class="w-full h-full object-cover rounded-full"
    />
    <span v-else :class="initialClass">{{ initial }}</span>
  </div>
</template>

<script setup>
import { computed } from 'vue'

const props = defineProps({
  user:      { type: Object, default: null },
  avatarUrl: { type: String, default: null },
  size:      { type: String, default: 'sm' } // 'sm' | 'md' | 'lg'
})

const sizeMap = {
  sm: { px: 28, text: 'text-xs' },
  md: { px: 40, text: 'text-sm' },
  lg: { px: 128, text: 'text-4xl' },
}

const current = computed(() => sizeMap[props.size] || sizeMap.sm)

const containerStyle = computed(() => ({
  width:  `${current.value.px}px`,
  height: `${current.value.px}px`,
}))

const rank = computed(() => props.user?.rank ?? 0)

const containerClass = computed(() => [
  'rounded-full flex-shrink-0 overflow-hidden flex items-center justify-center',
  !props.avatarUrl ? `rank-${rank.value}-bg` : '',
])

const initialClass = computed(() => [
  'font-bold select-none text-white leading-none',
  current.value.text,
])

const initial = computed(() => {
  const name = props.user?.username
  return name ? name[0].toUpperCase() : '?'
})
</script>
