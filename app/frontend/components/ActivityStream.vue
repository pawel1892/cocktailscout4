<template>
  <div class="space-y-3">
    <p v-if="items.length === 0" class="text-gray-400 italic text-sm py-4">Keine Aktivitäten vorhanden.</p>
    <div
      v-for="(item, idx) in items"
      :key="idx"
      class="flex gap-3 py-2"
      :class="{ 'border-b border-gray-100': idx < items.length - 1 }"
    >
      <div class="flex-shrink-0 w-7 h-7 flex items-center justify-center mt-0.5">
        <i :class="`fa-solid ${item.icon} ${item.iconColor} text-sm`"></i>
      </div>
      <div class="flex-1 min-w-0">
        <div class="text-sm leading-snug flex items-center flex-wrap gap-1">
          <UserBadge :user="item.user" />
          <span v-html="item.actionHtml"></span>
        </div>
        <div v-if="!compact && item.excerpt" class="text-xs text-gray-500 mt-1 line-clamp-2">{{ item.excerpt }}</div>
        <div v-if="item.thumbUrl" class="mt-2">
          <img :src="item.thumbUrl" class="rounded object-cover w-[50px] h-[50px]" alt="">
        </div>
        <div class="text-xs text-gray-400 mt-1">{{ item.time }}</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import UserBadge from './UserBadge.vue'

const props = defineProps({
  compact: {
    type: Boolean,
    default: false
  }
})

const stream = ref([])

onMounted(() => {
  stream.value = window.activityStream || []
})

const TYPE_CONFIG = {
  forum_post:        { icon: 'fa-comments',     iconColor: 'text-blue-500' },
  rating:            { icon: 'fa-star',          iconColor: 'text-cs-gold' },
  recipe_image:      { icon: 'fa-camera',        iconColor: 'text-purple-500' },
  recipe:            { icon: 'fa-martini-glass', iconColor: 'text-cs-dark-red' },
  user_registration: { icon: 'fa-user-plus',     iconColor: 'text-green-500' },
  recipe_comment:    { icon: 'fa-message',       iconColor: 'text-orange-400' },
}

function escapeHtml(str) {
  if (!str) return ''
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

function linkHtml(url, text) {
  if (!url || !text) return escapeHtml(text)
  return `<a href="${escapeHtml(url)}" class="link font-medium hover:underline">${escapeHtml(text)}</a>`
}

// Builds the action text that follows the UserBadge (no user data here)
function buildActionHtml(event) {
  const { type, url, meta } = event

  switch (type) {
    case 'forum_post': {
      const postLink = linkHtml(url, meta.thread_title)
      return `hat im Forum kommentiert${postLink ? ': ' + postLink : ''}`
    }
    case 'rating': {
      const recipeLink = linkHtml(meta.recipe_url, meta.recipe_title)
      return `hat ${escapeHtml(String(meta.score))}/10 Punkte für ${recipeLink} vergeben`
    }
    case 'recipe_image': {
      const recipeLink = linkHtml(url, meta.recipe_title)
      return `hat ein Foto für ${recipeLink} hochgeladen`
    }
    case 'recipe': {
      const recipeLink = linkHtml(url, meta.recipe_title)
      return `hat das Rezept ${recipeLink} veröffentlicht`
    }
    case 'user_registration':
      return 'hat sich registriert'
    case 'recipe_comment': {
      const recipeLink = linkHtml(meta.recipe_url, meta.recipe_title)
      return `hat ${recipeLink} kommentiert`
    }
    default:
      return escapeHtml(type)
  }
}

function timeAgoDE(dateStr) {
  const diff = Math.floor((Date.now() - new Date(dateStr).getTime()) / 1000)
  if (diff < 60) return 'gerade eben'
  if (diff < 3600) {
    const m = Math.floor(diff / 60)
    return `vor ${m} Minute${m === 1 ? '' : 'n'}`
  }
  if (diff < 86400) {
    const h = Math.floor(diff / 3600)
    return `vor ${h} Stunde${h === 1 ? '' : 'n'}`
  }
  if (diff < 2592000) {
    const d = Math.floor(diff / 86400)
    return `vor ${d} Tag${d === 1 ? '' : 'en'}`
  }
  if (diff < 31536000) {
    const mo = Math.floor(diff / 2592000)
    return `vor ${mo} Monat${mo === 1 ? '' : 'en'}`
  }
  const y = Math.floor(diff / 31536000)
  return `vor ${y} Jahr${y === 1 ? '' : 'en'}`
}

const items = computed(() =>
  stream.value.map(event => {
    const config = TYPE_CONFIG[event.type] || { icon: 'fa-circle', iconColor: 'text-gray-400' }
    return {
      icon: config.icon,
      iconColor: config.iconColor,
      user: event.user,
      actionHtml: buildActionHtml(event),
      excerpt: event.meta?.excerpt || null,
      thumbUrl: event.meta?.thumb_url || null,
      time: timeAgoDE(event.created_at),
    }
  })
)
</script>
