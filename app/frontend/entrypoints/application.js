import { createApp } from 'vue'
import ComponentRegistry from '../registry/components'
import './application.css'

const startApp = () => {
  const app = createApp({})

  // Initialize the registry
  app.use(ComponentRegistry)

  const el = document.getElementById('app')
  if (el) {
    app.mount('#app')
    console.log("CocktailScout 4: Vue initialized with Smart Registry.")
  }

  // Global click handler for user profile triggers
  document.addEventListener('click', (e) => {
    const trigger = e.target.closest('.user-profile-trigger')
    if (trigger) {
      const userId = parseInt(trigger.dataset.userId)
      if (userId) {
        window.dispatchEvent(new CustomEvent('open-user-profile', {
          detail: { userId }
        }))
      }
    }
  })
}

// Start once DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', startApp)
} else {
  startApp()
}
