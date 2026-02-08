<script setup>
const props = defineProps({
  roles: {
    type: Array,
    default: () => []
  },
  size: {
    type: String,
    default: 'normal',
    validator: (value) => ['normal', 'small'].includes(value)
  }
})

const getRoleClass = (roleName) => {
  return roleName === 'admin' ? 'tag-gold' : 'tag-light-blue'
}

const getSizeClass = () => {
  return props.size === 'small' ? 'text-[10px]' : ''
}
</script>

<template>
  <div v-if="roles && roles.length > 0" class="flex flex-wrap gap-1">
    <span
      v-for="role in roles"
      :key="role.name"
      :class="['tag', getRoleClass(role.name), getSizeClass()]"
    >
      {{ role.display_name || role.name }}
    </span>
  </div>
</template>
