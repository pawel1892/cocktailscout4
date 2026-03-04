<template>
  <div class="space-y-4">

    <!-- Empty state -->
    <div v-if="data.total === 0" class="card">
      <div class="card-body p-4 sm:p-6 text-gray-500 text-center py-8">
        <i class="fas fa-star text-3xl text-gray-300 mb-3"></i>
        <p>Dieser Benutzer hat noch keine Rezepte bewertet.</p>
      </div>
    </div>

    <template v-else>

      <!-- Card 1: Recent ratings -->
      <div v-if="data.recent && data.recent.length > 0" class="card">
        <div class="card-body p-4 sm:p-6">
          <h2 class="text-lg font-semibold text-gray-800 mb-3">Letzte Bewertungen</h2>
          <div class="space-y-2">
            <div
              v-for="(r, index) in data.recent"
              :key="index"
              class="flex items-center gap-3 py-2 border-b border-gray-100 last:border-0"
            >
              <div
                :class="scoreColorClass(r.score)"
                class="text-white font-bold text-sm w-8 h-8 flex items-center justify-center rounded flex-shrink-0"
              >
                {{ r.score }}
              </div>
              <div class="flex-1 min-w-0">
                <a
                  v-if="r.recipe_slug"
                  :href="`/rezepte/${r.recipe_slug}`"
                  class="text-blue-600 hover:underline font-medium truncate block"
                >
                  {{ r.recipe_title }}
                </a>
                <span v-else class="text-gray-400 italic">Rezept gelöscht</span>
              </div>
              <div class="text-xs text-gray-400 flex-shrink-0">{{ r.updated_at }}</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Card 2: Distribution by score -->
      <div class="card">
        <div class="card-body p-4 sm:p-6">
          <div class="flex items-center justify-between mb-3">
            <h2 class="text-lg font-semibold text-gray-800">Alle Bewertungen nach Punktzahl</h2>
            <button @click="toggleAll" class="text-sm text-cs-dark-red hover:underline">
              {{ allExpanded ? 'Alle zuklappen' : 'Alle ausklappen' }}
            </button>
          </div>

          <div class="space-y-2">
            <div v-for="row in data.distribution" :key="row.score">
              <div
                class="flex items-center gap-3 cursor-pointer rounded p-1 hover:bg-gray-50 transition-colors"
                @click="toggle(row.score)"
              >
                <div
                  :class="scoreColorClass(row.score)"
                  class="text-white font-bold text-sm w-8 h-8 flex items-center justify-center rounded flex-shrink-0"
                >
                  {{ row.score }}
                </div>
                <div class="flex-1 bg-gray-100 rounded-full h-4 overflow-hidden">
                  <div
                    :class="barColorClass(row.score)"
                    class="h-full rounded-full transition-all duration-500"
                    :style="{ width: row.percentage + '%' }"
                  ></div>
                </div>
                <div class="text-sm text-gray-600 w-24 text-right flex-shrink-0">
                  {{ row.count }} <span class="text-gray-400">({{ row.percentage }}%)</span>
                </div>
                <div class="text-gray-400 w-4 flex-shrink-0">
                  <i v-if="row.count > 0" :class="expanded[row.score] ? 'fas fa-chevron-up' : 'fas fa-chevron-down'"></i>
                </div>
              </div>

              <div v-if="expanded[row.score] && row.recipes && row.recipes.length > 0" class="ml-11 mb-2">
                <ul class="space-y-1">
                  <li v-for="(recipe, idx) in row.recipes" :key="idx" class="text-sm flex items-center gap-2">
                    <a v-if="recipe.slug" :href="`/rezepte/${recipe.slug}`" class="text-blue-600 hover:underline">
                      {{ recipe.title }}
                    </a>
                    <span v-else class="text-gray-400 italic">Rezept gelöscht</span>
                    <span v-if="recipe.average_rating" class="text-xs text-gray-400">
                      Ø {{ formatRating(recipe.average_rating) }}
                    </span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Card 3: Unrated recipes -->
      <div v-if="data.unrated && data.unrated.length > 0" class="card">
        <div class="card-body p-4 sm:p-6">
          <h2 class="text-lg font-semibold text-gray-800 mb-3">
            Noch nicht bewertet
            <span class="text-sm font-normal text-gray-400 ml-1">({{ data.unrated.length }} Rezepte)</span>
          </h2>
          <div class="space-y-1">
            <div
              v-for="(recipe, idx) in data.unrated"
              :key="idx"
              class="flex items-center gap-3 py-1.5 border-b border-gray-100 last:border-0"
            >
              <div class="flex-1 min-w-0">
                <a :href="`/rezepte/${recipe.slug}`" class="text-blue-600 hover:underline font-medium truncate block">
                  {{ recipe.title }}
                </a>
              </div>
              <div class="text-xs text-gray-500 flex-shrink-0 text-right">
                <span v-if="recipe.average_rating > 0">
                  Ø {{ formatRating(recipe.average_rating) }}
                  <span class="text-gray-300 mx-0.5">·</span>
                  {{ recipe.ratings_count }} Bew.
                </span>
                <span v-else class="text-gray-300">Keine Bewertungen</span>
              </div>
            </div>
          </div>
        </div>
      </div>

    </template>
  </div>
</template>

<script setup>
import { computed, reactive } from 'vue'

const data = window.userRatingData || { username: '', user_id: null, total: 0, recent: [], distribution: [], unrated: [] }

const expanded = reactive({})

const allExpanded = computed(() =>
  data.distribution.filter(r => r.count > 0).every(r => expanded[r.score])
)

const toggle = (score) => { expanded[score] = !expanded[score] }

const toggleAll = () => {
  const shouldExpand = !allExpanded.value
  data.distribution.forEach(r => { if (r.count > 0) expanded[r.score] = shouldExpand })
}

const formatRating = (value) => Number(value).toFixed(1).replace('.', ',')

const getColorForScore = (score) => {
  if (!score || score === 0) return 'bg-gray-400'
  if (score < 4) return 'bg-red-600'
  if (score < 6) return 'bg-orange-500'
  if (score < 7.5) return 'bg-yellow-500'
  if (score < 9) return 'bg-lime-600'
  return 'bg-green-700'
}

const scoreColorClass = (score) => getColorForScore(score)
const barColorClass = (score) => getColorForScore(score) + ' opacity-80'
</script>
