<template>
  <div>
    <div v-if="users.length > 0" class="flex flex-wrap gap-3">
      <button
        v-for="user in users"
        :key="user.id"
        type="button"
        class="link inline-flex items-center gap-1 font-medium hover:underline cursor-pointer user-profile-trigger"
        :data-user-id="user.id"
      >
        <span class="text-zinc-900">{{ user.username }}</span>
        <i :class="`fa-solid fa-user rank-${user.rank}-color`"></i>
        <i class="fa-solid fa-wifi text-green-500 text-xs" title="Online"></i>
      </button>
    </div>
    <p v-else class="text-gray-500 italic">Derzeit sind keine User aktiv</p>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'

const props = defineProps({
  initialUsers: {
    type: Array,
    default: () => []
  }
})

const users = ref(props.initialUsers)

const fetchUsers = async () => {
  try {
    const response = await fetch('/community.json')
    if (response.ok) {
      const data = await response.json()
      users.value = data.online_users
    }
  } catch (error) {
    console.error('Failed to fetch online users:', error)
  }
}

onMounted(() => {
  setInterval(fetchUsers, 60000)
})
</script>
