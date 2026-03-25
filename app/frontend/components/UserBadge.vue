<template>
  <!-- Deleted user -->
  <span v-if="!resolvedUser || !resolvedUser.id" :class="deletedClass">
    <AvatarDisplay :user="{ username: 'deleted', rank: 0 }" :avatarUrl="null" :size="avatarSize" />
    <span :class="usernameClass">Gelöschter Benutzer</span>
  </span>

  <!-- Active user — text only -->
  <button
    v-else-if="isText"
    type="button"
    class="link font-medium hover:underline cursor-pointer user-profile-trigger"
    :data-user-id="resolvedUser.id"
  >{{ resolvedUser.username }}</button>

  <!-- Active user — with avatar -->
  <button
    v-else
    type="button"
    :class="buttonClass"
    :data-user-id="resolvedUser.id"
  >
    <AvatarDisplay :user="resolvedUser" :avatarUrl="isVertical ? (resolvedUser.avatar_url_medium || resolvedUser.avatar_url_small) : resolvedUser.avatar_url_small" :size="avatarSize" />
    <span :class="usernameClass">{{ resolvedUser.username }}</span>
    <i v-if="resolvedUser.online" class="fa-solid fa-wifi text-green-500 text-xs" title="Online"></i>
  </button>
</template>

<script setup>
import { computed } from 'vue'
import AvatarDisplay from './AvatarDisplay.vue'

const props = defineProps({
  // Used when composed inside other Vue components
  user: { type: Object, default: null },
  // Used when mounted as a custom element from ERB
  userId:        { type: [Number, String], default: null },
  username:      { type: String, default: null },
  rank:          { type: [Number, String], default: 0 },
  avatarUrlSmall:  { type: String, default: null },
  avatarUrlMedium: { type: String, default: null },
  online:        { type: [Boolean, String], default: false },
  // Layout: 'horizontal' (default inline) | 'vertical' (avatar above username) | 'text' (username only)
  layout:        { type: String, default: 'horizontal' },
})

const isVertical = computed(() => props.layout === 'vertical')
const isText     = computed(() => props.layout === 'text')
const avatarSize = computed(() => isVertical.value ? 'forum' : 'sm')

const buttonClass = computed(() => isVertical.value
  ? 'link flex flex-col items-center gap-0.5 hover:opacity-80 cursor-pointer user-profile-trigger text-center'
  : 'link inline-flex items-center gap-1.5 font-medium hover:underline cursor-pointer user-profile-trigger'
)

const deletedClass = computed(() => isVertical.value
  ? 'flex flex-col items-center gap-1 opacity-50 text-center'
  : 'inline-flex items-center gap-1.5 font-medium opacity-50'
)

const usernameClass = computed(() => isVertical.value
  ? 'text-xs text-zinc-800 font-bold leading-tight max-w-[100px] break-words'
  : 'text-zinc-900'
)

const resolvedUser = computed(() => {
  if (props.user) return props.user
  if (props.userId || props.username) {
    return {
      id: props.userId ? Number(props.userId) : null,
      username: props.username,
      rank: Number(props.rank) || 0,
      avatar_url_small:  props.avatarUrlSmall  || null,
      avatar_url_medium: props.avatarUrlMedium || null,
      online: props.online === true || props.online === 'true',
    }
  }
  return null
})
</script>
