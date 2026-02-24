<template>
  <div class="card">
    <div class="card-body p-4 sm:p-6">
      <!-- Header with scaling controls -->
      <div class="flex flex-col sm:flex-row items-start sm:items-center justify-between mb-4 gap-3">
        <h2 class="text-2xl font-bold flex items-center gap-2">
          <i class="fas fa-list text-cs-gold"></i>
          Zutaten
        </h2>
        <!-- Scaling controls (only shown if recipe is scalable) -->
        <div v-if="scalable" class="flex items-center gap-2 flex-wrap">
          <span class="text-sm text-gray-600">Portionen:</span>
          <div class="flex gap-1 flex-wrap">
            <button v-for="factor in scaleFactors"
                    :key="factor.value"
                    @click="fetchScaledIngredients(factor.value)"
                    :class="buttonClasses(factor.value)"
                    :disabled="loading">
              {{ factor.label }}
            </button>
          </div>
        </div>
      </div>

      <!-- Loading indicator -->
      <div v-if="loading" class="flex justify-center py-4">
        <i class="fas fa-spinner fa-spin text-cs-gold text-2xl"></i>
      </div>

      <!-- Ingredients list -->
      <ul v-else class="space-y-2">
        <li v-for="ingredient in ingredients"
            :key="ingredient.id"
            class="flex items-start gap-2">
          <span class="text-cs-gold mt-1">•</span>
          <span v-if="ingredient.needs_review">
            <!-- Uncertain ingredient: show original description -->
            {{ ingredient.old_description }}
            <!-- Warning icon when recipe is scaled -->
            <span v-if="scaleFactor !== 1"
                  class="inline-block ml-1 text-amber-600 cursor-help"
                  :title="warningMessage">
              ⚠️
            </span>
          </span>
          <span v-else-if="ingredient.amount !== null">
            <!-- Structured data: show formatted_amount + ingredient_name + optional additional_info -->
            <strong>{{ ingredient.formatted_amount }}</strong>
            {{ ingredient.ingredient_name }}
            <span v-if="ingredient.additional_info"
                  class="text-gray-600">({{ ingredient.additional_info }})</span>
          </span>
          <span v-else>
            <!-- Unstructured data: formatted_amount already contains everything -->
            <strong>{{ ingredient.formatted_amount }}</strong>
          </span>
        </li>
      </ul>

      <!-- Warning for uncertain ingredients when scaled -->
      <div v-if="!loading && scaleFactor !== 1 && hasUncertainIngredients" class="mt-3 p-3 bg-amber-50 border border-amber-200 rounded text-amber-800 text-sm flex items-start gap-2">
        <i class="fas fa-exclamation-triangle mt-0.5"></i>
        <div>
          <strong>Hinweis:</strong> Einige Zutaten (mit ⚠️ markiert) konnten nicht automatisch skaliert werden und sollten manuell angepasst werden.
        </div>
      </div>

      <!-- Alcohol information (compact with icons) -->
      <div v-if="!loading && alcoholInfo && alcoholInfo.total_volume_ml > 0" class="mt-4 pt-3 border-t border-gray-200">
        <div class="text-xs text-gray-500 flex items-center gap-3 flex-wrap">
          <span title="Gesamtvolumen">
            <i class="fas fa-flask"></i> {{ formatVolume(alcoholInfo.total_volume_ml / 10) }} cl
          </span>
          <span v-if="alcoholInfo.alcohol_content_percent > 0" title="Alkoholgehalt">
            <i class="fas fa-wine-glass-alt"></i> {{ formatPercent(alcoholInfo.alcohol_content_percent) }} % Vol.
          </span>
        </div>
      </div>

      <!-- Error message -->
      <div v-if="error" class="mt-4 p-3 bg-red-50 border border-red-200 rounded text-red-700 text-sm">
        {{ error }}
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  recipeSlug: {
    type: String,
    required: true
  },
  initialIngredients: {
    type: Array,
    required: true
  },
  initialAlcoholInfo: {
    type: Object,
    default: null
  },
  scalable: {
    type: Boolean,
    default: true
  }
})

const scaleFactors = [
  { value: 0.5, label: '½' },
  { value: 0.75, label: '¾' },
  { value: 1, label: '1' },
  { value: 1.5, label: '1½' },
  { value: 2, label: '2' },
  { value: 3, label: '3' },
  { value: 4, label: '4' }
]

const scaleFactor = ref(1)
const ingredients = ref(props.initialIngredients)
const alcoholInfo = ref(props.initialAlcoholInfo)
const loading = ref(false)
const error = ref(null)
const warningMessage = "Diese Zutat kann nicht automatisch skaliert werden, da die Menge nicht eindeutig ist. Bitte manuell anpassen."

// Check if there are any ingredients that need review
const hasUncertainIngredients = computed(() => {
  return ingredients.value.some(ingredient => ingredient.needs_review)
})

async function fetchScaledIngredients(factor) {
  if (factor === scaleFactor.value) return // Already at this scale

  scaleFactor.value = factor
  loading.value = true
  error.value = null

  try {
    const response = await fetch(`/rezepte/${props.recipeSlug}/zutaten?scale=${factor}`, {
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      }
    })

    if (!response.ok) {
      throw new Error('Fehler beim Laden der skalierten Zutaten')
    }

    const data = await response.json()
    ingredients.value = data.ingredients
    alcoholInfo.value = data.alcohol_info
  } catch (e) {
    console.error('Error fetching scaled ingredients:', e)
    error.value = 'Fehler beim Laden der skalierten Zutaten. Bitte versuchen Sie es erneut.'
  } finally {
    loading.value = false
  }
}

function buttonClasses(value) {
  const baseClasses = 'px-3 py-1 rounded text-sm transition-colors disabled:opacity-50'
  const activeClasses = 'bg-cs-dark-red text-white font-semibold'
  const inactiveClasses = 'bg-gray-100 text-gray-700 hover:bg-gray-200'

  return scaleFactor.value === value
    ? `${baseClasses} ${activeClasses}`
    : `${baseClasses} ${inactiveClasses}`
}

function formatVolume(ml) {
  // Format with German decimal separator
  const num = parseFloat(ml)
  if (isNaN(num)) return '0'

  if (num % 1 === 0) {
    return num.toFixed(0)
  }
  return num.toFixed(1).replace('.', ',')
}

function formatPercent(percent) {
  // Format percentage with German decimal separator
  const num = parseFloat(percent)
  if (isNaN(num)) return '0'

  if (num % 1 === 0) {
    return num.toFixed(0)
  }
  return num.toFixed(1).replace('.', ',')
}
</script>
