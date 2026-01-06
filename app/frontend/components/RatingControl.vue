<template>
  <div class="flex items-center space-x-4">
    <!-- Score Display -->
    <div class="flex items-center space-x-2">
      <div :class="badgeColorClass" class="text-white font-bold text-xl px-3 py-2 rounded-lg transition-colors duration-300">
        {{ displayAverage }}
      </div>
      <div class="text-sm text-gray-600">
        <div>{{ countLabel }}</div>
        <button 
          v-if="canRate && !showInput" 
          @click="showInput = true" 
          class="text-cs-dark-red hover:underline font-medium"
        >
          Jetzt bewerten
        </button>
      </div>
    </div>

    <!-- Rating Input -->
    <div v-if="showInput" class="flex flex-col space-y-2 bg-white p-4 rounded shadow-lg border absolute z-10 mt-12">
      <div class="text-sm font-semibold mb-1">Deine Bewertung:</div>
      <div class="flex space-x-1">
        <button 
          v-for="i in 10" 
          :key="i"
          @click="submitRating(i)"
          @mouseenter="hoverScore = i"
          @mouseleave="hoverScore = 0"
          :class="getScoreClass(i)"
          class="w-8 h-8 flex items-center justify-center rounded border transition"
        >
          {{ i }}
        </button>
      </div>
      <button @click="showInput = false" class="text-xs text-gray-500 hover:text-gray-700 self-end mt-2">
        Abbrechen
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, defineProps } from 'vue'
import { useAuth } from '../composables/useAuth'

const props = defineProps({
  rateableType: { type: String, required: true },
  rateableId: { type: Number, required: true },
  initialAverage: { type: Number, default: 0 },
  initialCount: { type: Number, default: 0 },
  userRating: { type: Number, default: null }
})

const { isAuthenticated } = useAuth()

const average = ref(props.initialAverage)
const count = ref(props.initialCount)
const myRating = ref(props.userRating)
const showInput = ref(false)
const hoverScore = ref(0)
const loading = ref(false)

const canRate = computed(() => isAuthenticated.value)

const displayAverage = computed(() => {
  return Number(average.value).toFixed(1).replace('.', ',')
})

const countLabel = computed(() => {
  if (count.value === 0) return 'Keine Bewertungen'
  return `${count.value} Bewertung${count.value !== 1 ? 'en' : ''}`
})

const getColorForScore = (score) => {
  if (score === 0) return 'bg-gray-400 border-gray-400 text-white'
  if (score < 4) return 'bg-red-600 border-red-600 text-white'
  if (score < 6) return 'bg-orange-500 border-orange-500 text-white'
  if (score < 7.5) return 'bg-yellow-500 border-yellow-500 text-white'
  if (score < 9) return 'bg-lime-600 border-lime-600 text-white'
  return 'bg-green-700 border-green-700 text-white'
}

const badgeColorClass = computed(() => {
  const score = average.value
  if (score === 0) return 'bg-gray-400'
  if (score < 4) return 'bg-red-600'
  if (score < 6) return 'bg-orange-500'
  if (score < 7.5) return 'bg-yellow-500'
  if (score < 9) return 'bg-lime-600'
  return 'bg-green-700'
})

const getScoreClass = (i) => {
  if (loading.value) return 'opacity-50 cursor-not-allowed bg-gray-100 text-gray-400'
  
  if (hoverScore.value >= i || (myRating.value >= i && hoverScore.value === 0)) {
    const activeScore = hoverScore.value > 0 ? hoverScore.value : myRating.value
    return getColorForScore(activeScore)
  }
  
  return 'bg-white text-gray-700 border-gray-300 hover:border-gray-400'
}

const submitRating = async (score) => {
  if (loading.value) return
  loading.value = true

  try {
    const response = await fetch('/rate', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        rateable_type: props.rateableType,
        rateable_id: props.rateableId,
        score: score
      })
    })

    const data = await response.json()
    if (response.ok) {
      average.value = data.average
      count.value = data.count
      myRating.value = score
      showInput.value = false
    } else {
      alert("Fehler beim Bewerten.")
    }
  } catch (e) {
    console.error(e)
  } finally {
    loading.value = false
  }
}
</script>
