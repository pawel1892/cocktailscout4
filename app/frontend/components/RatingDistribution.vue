<template>
  <div class="space-y-4">

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
              <UserBadge :user="{ id: r.user_id, username: r.username, rank: r.rank, online: r.online }" />
            </div>
            <div class="text-xs text-gray-400 flex-shrink-0">{{ r.updated_at }}</div>
          </div>
        </div>
      </div>
    </div>

    <!-- Card 2: Distribution -->
    <div class="card">
      <div class="card-body p-4 sm:p-6">
        <!-- Header: average + total -->
        <div class="flex items-center gap-4 mb-6">
          <div :class="averageColorClass" class="text-white font-bold text-2xl px-4 py-2 rounded-lg">
            {{ displayAverage }}
          </div>
          <div class="text-gray-600">
            <div class="font-semibold">Durchschnittsbewertung</div>
            <div class="text-sm">{{ countLabel }}</div>
          </div>
          <button
            v-if="data.total > 0"
            @click="toggleAll"
            class="ml-auto text-sm text-cs-dark-red hover:underline"
          >
            {{ allExpanded ? 'Alle zuklappen' : 'Alle ausklappen' }}
          </button>
        </div>

        <!-- No ratings -->
        <div v-if="data.total === 0" class="text-gray-500 text-center py-8">
          <i class="fas fa-star text-3xl text-gray-300 mb-3"></i>
          <p>Keine Bewertungen vorhanden</p>
        </div>

        <!-- Distribution rows -->
        <div v-else class="space-y-2">
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

            <div v-if="expanded[row.score] && row.users.length > 0" class="ml-11 mb-2">
              <ul class="space-y-1">
                <li v-for="u in row.users" :key="u.id ?? u.username" class="text-sm">
                  <UserBadge :user="u" />
                </li>
              </ul>
            </div>
          </div>
        </div>
      </div>
    </div>

  </div>
</template>

<script setup>
import { computed, reactive } from 'vue'
import UserBadge from './UserBadge.vue'

const data = window.ratingDistribution || { total: 0, average: 0, distribution: [] }

const expanded = reactive({})
const allExpanded = computed(() => {
  return data.distribution
    .filter(r => r.count > 0)
    .every(r => expanded[r.score])
})

const toggle = (score) => {
  expanded[score] = !expanded[score]
}

const toggleAll = () => {
  const shouldExpand = !allExpanded.value
  data.distribution.forEach(r => {
    if (r.count > 0) expanded[r.score] = shouldExpand
  })
}

const displayAverage = computed(() => {
  if (!data.average) return '–'
  return Number(data.average).toFixed(1).replace('.', ',')
})

const countLabel = computed(() => {
  if (data.total === 0) return 'Keine Bewertungen'
  return `${data.total} Bewertung${data.total !== 1 ? 'en' : ''}`
})

const getColorForScore = (score) => {
  if (!score || score === 0) return 'bg-gray-400'
  if (score < 4) return 'bg-red-600'
  if (score < 6) return 'bg-orange-500'
  if (score < 7.5) return 'bg-yellow-500'
  if (score < 9) return 'bg-lime-600'
  return 'bg-green-700'
}

const averageColorClass = computed(() => getColorForScore(data.average))
const scoreColorClass = (score) => getColorForScore(score)
const barColorClass = (score) => getColorForScore(score) + ' opacity-80'
</script>
