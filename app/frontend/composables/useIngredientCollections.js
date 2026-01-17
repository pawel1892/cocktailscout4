import { ref, computed } from 'vue'

const state = ref({
  collections: [],
  loading: false,
  error: null
})

export function useIngredientCollections() {
  const getCSRFToken = () => {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }

  const fetchCollections = async () => {
    state.value.loading = true
    state.value.error = null

    try {
      const response = await fetch('/ingredient_collections', {
        headers: {
          'Accept': 'application/json'
        }
      })

      const data = await response.json()
      if (data.success) {
        state.value.collections = data.collections
      } else {
        state.value.error = 'Failed to fetch collections'
      }
    } catch (e) {
      state.value.error = 'Network error'
      console.error('Failed to fetch collections:', e)
    } finally {
      state.value.loading = false
    }
  }

  const createCollection = async (collectionData) => {
    try {
      const response = await fetch('/ingredient_collections', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': getCSRFToken()
        },
        body: JSON.stringify(collectionData)
      })

      const data = await response.json()
      if (data.success) {
        state.value.collections.push(data.collection)
        return { success: true, collection: data.collection }
      } else {
        return { success: false, errors: data.errors }
      }
    } catch (e) {
      return { success: false, errors: ['Network error'] }
    }
  }

  const updateCollection = async (id, collectionData) => {
    try {
      const response = await fetch(`/ingredient_collections/${id}`, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': getCSRFToken()
        },
        body: JSON.stringify(collectionData)
      })

      const data = await response.json()
      if (data.success) {
        const index = state.value.collections.findIndex(c => c.id === id)
        if (index !== -1) {
          state.value.collections[index] = data.collection
        }
        return { success: true, collection: data.collection }
      } else {
        return { success: false, errors: data.errors }
      }
    } catch (e) {
      return { success: false, errors: ['Network error'] }
    }
  }

  const deleteCollection = async (id) => {
    try {
      const response = await fetch(`/ingredient_collections/${id}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': getCSRFToken()
        }
      })

      const data = await response.json()
      if (data.success) {
        state.value.collections = state.value.collections.filter(c => c.id !== id)
        return { success: true }
      } else {
        return { success: false, error: data.error }
      }
    } catch (e) {
      return { success: false, error: 'Network error' }
    }
  }

  const addIngredients = async (collectionId, ingredientIds) => {
    try {
      const response = await fetch(`/ingredient_collections/${collectionId}/ingredients`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': getCSRFToken()
        },
        body: JSON.stringify({ ingredient_ids: ingredientIds })
      })

      const data = await response.json()
      if (data.success || data.added?.length > 0) {
        // Update collection in state
        const index = state.value.collections.findIndex(c => c.id === collectionId)
        if (index !== -1) {
          state.value.collections[index] = data.collection
        }
      }
      return data
    } catch (e) {
      return { success: false, error: 'Network error' }
    }
  }

  const removeIngredient = async (collectionId, ingredientId) => {
    try {
      const response = await fetch(`/ingredient_collections/${collectionId}/ingredients/${ingredientId}`, {
        method: 'DELETE',
        headers: {
          'Accept': 'application/json',
          'X-CSRF-Token': getCSRFToken()
        }
      })

      const data = await response.json()
      if (data.success) {
        // Update collection in state
        const index = state.value.collections.findIndex(c => c.id === collectionId)
        if (index !== -1) {
          state.value.collections[index] = data.collection
        }
        return { success: true }
      } else {
        return { success: false, error: data.error }
      }
    } catch (e) {
      return { success: false, error: 'Network error' }
    }
  }

  const replaceIngredients = async (collectionId, ingredientIds) => {
    try {
      const response = await fetch(`/ingredient_collections/${collectionId}/ingredients`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': getCSRFToken()
        },
        body: JSON.stringify({ ingredient_ids: ingredientIds })
      })

      const data = await response.json()
      if (data.success) {
        // Update collection in state
        const index = state.value.collections.findIndex(c => c.id === collectionId)
        if (index !== -1) {
          state.value.collections[index] = data.collection
        }
        return { success: true, collection: data.collection }
      } else {
        return { success: false, error: data.error }
      }
    } catch (e) {
      return { success: false, error: 'Network error' }
    }
  }

  return {
    collections: computed(() => state.value.collections),
    loading: computed(() => state.value.loading),
    error: computed(() => state.value.error),
    fetchCollections,
    createCollection,
    updateCollection,
    deleteCollection,
    addIngredients,
    removeIngredient,
    replaceIngredients
  }
}
