<template>
  <div :class="containerClass" :style="containerStyle">
    <img
      v-if="avatarUrl"
      :src="avatarUrl"
      :alt="user?.username"
      class="w-full h-full object-cover rounded-full"
    />
    <img
      v-else
      :src="fallbackSvg"
      :alt="user?.username"
      class="w-full h-full rounded-full"
    />
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { createAvatar } from '@dicebear/core'
import * as thumbs from '@dicebear/thumbs'

const props = defineProps({
  user:      { type: Object, default: null },
  avatarUrl: { type: String, default: null },
  size:      { type: String, default: 'sm' } // 'sm' | 'md' | 'lg'
})

const sizeMap = {
  sm:    28,
  md:    40,
  forum: 64,
  lg:    128,
}

const px = computed(() => sizeMap[props.size] ?? sizeMap.sm)

const containerStyle = computed(() => ({
  width:  `${px.value}px`,
  height: `${px.value}px`,
}))

const containerClass = 'rounded-full flex-shrink-0 overflow-hidden ring-1 ring-cs-ink-200'

const fallbackSvg = computed(() => {
  const seed = props.user?.username ?? 'unknown'
  const avatar = createAvatar(thumbs, { seed, size: px.value })
  return `data:image/svg+xml;utf8,${encodeURIComponent(avatar.toString())}`
})
</script>
