<template>
    <div style="background: red; color: white; padding: 20px; border: 5px solid yellow;">
      <h1>VUE IS WORKING!</h1>
      <p>If you see this red box, the architecture is perfect.</p>
      
      <div style="margin-top: 10px; padding: 10px; background: rgba(0,0,0,0.2);">
        <h3>Auth Status Check:</h3>
        <p v-if="isAuthenticated">✅ Logged in as: <strong>{{ user.email_address }}</strong></p>
        <p v-else>❌ Not logged in</p>
      </div>
    </div>
</template>
  
<script setup>
  import { useAuth } from '../composables/useAuth'
  
  const { user, isAuthenticated } = useAuth()
  
  console.log("Test component has been initialized!")
</script>
