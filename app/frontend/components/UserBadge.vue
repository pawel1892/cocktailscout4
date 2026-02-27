<template>
  <span v-if="!user || !user.id" class="inline-flex items-center gap-1 opacity-80">
    <span class="text-gray-500 font-medium">Gelöschter Benutzer</span>
    <i class="fa-solid fa-user text-gray-400"></i>
  </span>
  <button
    v-else
    type="button"
    class="link inline-flex items-center gap-1 font-medium hover:underline cursor-pointer user-profile-trigger"
    :data-user-id="user.id"
  >
    <span class="text-zinc-900">{{ user.username }}</span>
    <i :class="`fa-solid fa-user rank-${user.rank}-color`"></i>
    <i v-if="user.online" class="fa-solid fa-wifi text-green-500 text-xs" title="Online"></i>
  </button>
</template>

<script setup>
defineProps({
  user: { type: Object, default: null }
})
</script>
