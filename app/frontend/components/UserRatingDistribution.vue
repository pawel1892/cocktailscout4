<template>
  <div class="space-y-4">

    <!-- Empty state -->
    <div v-if="data.total === 0" class="card card-ghost p-12 text-center">
      <i class="fas fa-star text-4xl text-cs-ink-300 mb-4"></i>
      <p class="text-cs-ink-500">Dieser Benutzer hat noch keine Rezepte bewertet.</p>
    </div>

    <template v-else>

      <!-- Recent ratings -->
      <div v-if="data.recent && data.recent.length > 0" class="card">
        <div class="card-header">
          <span class="font-sans font-bold uppercase text-[11px] tracking-widest text-cs-ink-400">Letzte Bewertungen</span>
          <span class="font-mono text-[11px] text-cs-ink-400">{{ data.recent.length }}</span>
        </div>
        <div class="card-body p-0">
          <div class="divide-y divide-cs-ink-100">
            <div
              v-for="(r, index) in data.recent"
              :key="index"
              class="flex items-center gap-3 px-[18px] py-3"
            >
              <div :class="scoreBadgeClass(r.score)" class="text-white font-mono font-bold text-[13px] w-8 h-8 flex items-center justify-center rounded shrink-0">
                {{ r.score }}
              </div>
              <div class="flex-1 min-w-0">
                <a v-if="r.recipe_slug" :href="`/rezepte/${r.recipe_slug}`" class="link font-medium truncate inline-block max-w-full">
                  {{ r.recipe_title }}
                </a>
                <span v-else class="text-cs-ink-400 italic text-sm">Rezept gelöscht</span>
              </div>
              <div class="text-xs text-cs-ink-400 shrink-0">{{ r.updated_at }}</div>
            </div>
          </div>
        </div>
      </div>

      <!-- Distribution by score -->
      <div class="card">
        <div class="card-header">
          <span class="font-sans font-bold uppercase text-[11px] tracking-widest text-cs-ink-400">Nach Punktzahl</span>
          <button @click="toggleAll" class="link text-xs">
            {{ allExpanded ? 'Alle zuklappen' : 'Alle ausklappen' }}
          </button>
        </div>
        <div class="card-body">
          <div class="space-y-1.5">
            <div v-for="row in data.distribution" :key="row.score">
              <div
                class="flex items-center gap-3 cursor-pointer rounded-lg px-2 py-1.5 hover:bg-cs-ink-50 transition-colors"
                @click="toggle(row.score)"
              >
                <div :class="scoreBadgeClass(row.score)" class="text-white font-mono font-bold text-[13px] w-8 h-8 flex items-center justify-center rounded shrink-0">
                  {{ row.score }}
                </div>
                <div class="flex-1 bg-cs-ink-100 rounded-full h-2.5 overflow-hidden">
                  <div
                    :class="barColorClass(row.score)"
                    class="h-full rounded-full transition-all duration-500"
                    :style="{ width: row.percentage + '%' }"
                  ></div>
                </div>
                <div class="font-mono text-[13px] text-cs-ink-700 w-24 text-right shrink-0">
                  {{ row.count }} <span class="text-cs-ink-400 font-normal">({{ row.percentage }}%)</span>
                </div>
                <div class="text-cs-ink-300 w-4 shrink-0 text-xs">
                  <i v-if="row.count > 0" :class="expanded[row.score] ? 'fas fa-chevron-up' : 'fas fa-chevron-down'"></i>
                </div>
              </div>

              <div v-if="expanded[row.score] && row.recipes && row.recipes.length > 0" class="ml-11 mt-1 mb-2">
                <ul class="space-y-1">
                  <li v-for="(recipe, idx) in row.recipes" :key="idx" class="flex items-center gap-2 text-sm">
                    <a v-if="recipe.slug" :href="`/rezepte/${recipe.slug}`" class="link">{{ recipe.title }}</a>
                    <span v-else class="text-cs-ink-400 italic">Rezept gelöscht</span>
                    <span v-if="recipe.average_rating" class="text-xs text-cs-ink-400">
                      Ø {{ formatRating(recipe.average_rating) }}
                    </span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Unrated own recipes -->
      <div v-if="data.unrated && data.unrated.length > 0" class="card">
        <div class="card-header">
          <span class="font-sans font-bold uppercase text-[11px] tracking-widest text-cs-ink-400">Noch nicht bewertet</span>
          <span class="font-mono text-[11px] text-cs-ink-400">{{ data.unrated.length }}</span>
        </div>
        <div class="card-body p-0">
          <div class="divide-y divide-cs-ink-100">
            <div
              v-for="(recipe, idx) in data.unrated"
              :key="idx"
              class="flex items-center gap-3 px-[18px] py-3"
            >
              <div class="flex-1 min-w-0">
                <a :href="`/rezepte/${recipe.slug}`" class="link font-medium truncate inline-block max-w-full">{{ recipe.title }}</a>
              </div>
              <div class="text-xs text-cs-ink-400 shrink-0 text-right">
                <span v-if="recipe.average_rating > 0">
                  Ø {{ formatRating(recipe.average_rating) }}
                  <span class="text-cs-ink-300 mx-0.5">·</span>
                  {{ recipe.ratings_count }} Bew.
                </span>
                <span v-else class="text-cs-ink-300">Keine Bewertungen</span>
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

const getScoreColor = (score) => {
  if (!score || score === 0) return 'bg-cs-ink-400'
  if (score < 4) return 'bg-cs-error-500'
  if (score < 6) return 'bg-cs-warning-500'
  if (score < 7.5) return 'bg-cs-warning-400'
  if (score < 9) return 'bg-cs-success-400'
  return 'bg-cs-success-700'
}

const scoreBadgeClass = (score) => getScoreColor(score)
const barColorClass = (score) => getScoreColor(score)
</script>
