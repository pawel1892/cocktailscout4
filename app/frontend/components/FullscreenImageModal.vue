<template>
  <Teleport to="body">
    <Transition name="gallery-modal">
      <div
        v-if="modelValue"
        class="fixed inset-0 z-50 bg-black flex items-center justify-center"
        @click="close"
      >
        <!-- Close button -->
        <button
          @click.stop="close"
          class="absolute top-3 right-3 z-10 text-white/80 hover:text-white bg-black/40 hover:bg-black/70 rounded-full p-2 transition-colors"
          aria-label="Schließen"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        <!-- Image -->
        <img
          :src="imageUrl"
          :alt="recipeTitle"
          class="max-w-full max-h-full object-contain"
          @click.stop
        />

        <!-- Prev arrow -->
        <button
          v-if="showPrev"
          @click.stop="$emit('prev')"
          class="absolute left-3 top-1/2 -translate-y-1/2 text-white/80 hover:text-white bg-black/40 hover:bg-black/70 rounded-full p-3 transition-colors"
          aria-label="Vorheriges Bild"
        >
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.75 19.5L8.25 12l7.5-7.5" />
          </svg>
        </button>

        <!-- Next arrow -->
        <button
          v-if="showNext"
          @click.stop="$emit('next')"
          class="absolute right-3 top-1/2 -translate-y-1/2 text-white/80 hover:text-white bg-black/40 hover:bg-black/70 rounded-full p-3 transition-colors"
          aria-label="Nächstes Bild"
        >
          <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
          </svg>
        </button>

        <!-- Bottom overlay -->
        <div
          class="absolute bottom-0 inset-x-0 bg-gradient-to-t from-black/80 to-transparent px-4 py-5"
          @click.stop
        >
          <div class="flex items-end justify-between">
            <div>
              <a
                v-if="recipeUrl"
                :href="recipeUrl"
                class="text-white font-semibold text-lg hover:text-cs-gold transition-colors block"
              >
                {{ recipeTitle }}
              </a>
              <span v-else-if="recipeTitle" class="text-white font-semibold text-lg block">{{ recipeTitle }}</span>
              <div v-if="userBadge" class="overlay-user-badge text-sm mt-0.5 flex items-center gap-1">
                von <span v-html="userBadge"></span>
              </div>
            </div>
            <span v-if="imageCount > 1" class="text-white/60 text-sm">
              {{ currentIndex + 1 }} / {{ imageCount }}
            </span>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup>
import { watch } from 'vue'

const props = defineProps({
  modelValue: { type: Boolean, required: true },
  imageUrl: { type: String, required: true },
  recipeTitle: { type: String, default: '' },
  recipeUrl: { type: String, default: '' },
  userBadge: { type: String, default: '' },
  showPrev: { type: Boolean, default: false },
  showNext: { type: Boolean, default: false },
  imageCount: { type: Number, default: 1 },
  currentIndex: { type: Number, default: 0 },
})

const emit = defineEmits(['update:modelValue', 'close', 'prev', 'next'])

const close = () => {
  emit('update:modelValue', false)
  emit('close')
}

const handleKeydown = (e) => {
  if (!props.modelValue) return
  if (e.key === 'Escape') close()
  if (e.key === 'ArrowLeft') emit('prev')
  if (e.key === 'ArrowRight') emit('next')
}

watch(() => props.modelValue, (newValue) => {
  if (newValue) {
    document.addEventListener('keydown', handleKeydown)
    document.body.style.overflow = 'hidden'
  } else {
    document.removeEventListener('keydown', handleKeydown)
    document.body.style.overflow = ''
  }
})
</script>

<style scoped>
.gallery-modal-enter-active,
.gallery-modal-leave-active {
  transition: opacity 0.2s ease;
}

.gallery-modal-enter-from,
.gallery-modal-leave-to {
  opacity: 0;
}

.overlay-user-badge {
  color: rgba(255, 255, 255, 0.8);
}

.overlay-user-badge :deep(button) {
  color: rgba(255, 255, 255, 0.8);
}

.overlay-user-badge :deep(button:hover) {
  color: rgba(255, 255, 255, 1);
}

.overlay-user-badge :deep(.text-zinc-900) {
  color: rgba(255, 255, 255, 0.85);
}
</style>
