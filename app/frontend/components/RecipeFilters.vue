<template>
  <div>
  <!-- Desktop sidebar (always visible on lg+, inside the grid column) -->
  <aside
    class="hidden lg:block lg:sticky"
    :style="{ top: sidebarTop, maxHeight: `calc(100vh - ${sidebarTop})`, overflowY: 'auto' }"
  >
    <div class="card">
      <div class="card-header">
        <span class="font-semibold text-cs-ink-800">Filter</span>
      </div>
      <div class="card-body space-y-4">
        <form :action="action" method="get" data-turbo-frame="_top">
          <input v-if="currentSort" type="hidden" name="sort" :value="currentSort" />
          <input v-if="currentDirection" type="hidden" name="direction" :value="currentDirection" />

          <div class="form-group">
            <label class="label-field" for="rf-q">Suche</label>
            <div class="relative">
              <input id="rf-q" type="text" name="q" :value="currentQ" placeholder="Rezeptname…"
                     class="input-field pl-8" autocomplete="off" />
              <i class="fas fa-search absolute left-2.5 top-1/2 -translate-y-1/2 text-cs-ink-400 text-xs pointer-events-none"></i>
            </div>
          </div>

          <div class="form-group">
            <label class="label-field" for="rf-min-rating">Mindestbewertung</label>
            <select id="rf-min-rating" name="min_rating" class="input-field">
              <option value="" :selected="!currentMinRating">Alle</option>
              <option v-for="n in [5, 6, 7, 8, 9]" :key="n" :value="n" :selected="currentMinRating == n">{{ n }}+</option>
            </select>
          </div>

          <div class="form-group">
            <label class="label-field" for="rf-tag">Kategorie</label>
            <select id="rf-tag" name="tag" class="input-field">
              <option value="" :selected="!currentTag">Alle</option>
              <option v-for="tag in tags" :key="tag.name" :value="tag.name" :selected="currentTag === tag.name">{{ tag.name }}</option>
            </select>
          </div>

          <div class="form-group">
            <label class="label-field" for="rf-ingredient">Zutat</label>
            <select id="rf-ingredient" name="ingredient_id" class="input-field">
              <option value="" :selected="!currentIngredientId">Alle</option>
              <option v-for="ing in ingredients" :key="ing.id" :value="ing.id" :selected="currentIngredientId == ing.id">{{ ing.name }}</option>
            </select>
          </div>

          <div class="form-group">
            <label class="label-field">Benutzer</label>
            <user-autocomplete
              :initial-username="initialUsername"
              :initial-user-id="currentUserId"
            ></user-autocomplete>
          </div>

          <div v-if="collections && collections.length > 0" class="form-group">
            <label class="label-field" for="rf-collection">Meine Liste</label>
            <select id="rf-collection" name="collection_id" class="input-field">
              <option value="" :selected="!currentCollectionId">Alle Rezepte</option>
              <option v-for="col in collections" :key="col.id" :value="col.id" :selected="currentCollectionId == col.id">{{ col.name }}</option>
            </select>
          </div>

          <label v-if="authenticated" class="check-label">
            <input type="checkbox" name="filter" value="favorites" class="check-field"
                   :checked="currentFilter === 'favorites'"
                   @change="$event.target.form.submit()" />
            <span class="text-sm text-cs-ink-700">Nur Favoriten</span>
          </label>

          <div class="pt-1">
            <button type="submit" class="btn btn-primary w-full">Filtern</button>
          </div>

          <div v-if="activeFiltersCount > 0" class="text-center pb-1">
            <a :href="resetUrl" class="text-sm text-cs-ink-400 hover:text-cs-ink-700 underline">Alle Filter zurücksetzen</a>
          </div>
        </form>
      </div>
    </div>
  </aside>

  <!-- Mobile drawer + overlay via Teleport (avoids layout/overflow issues) -->
  <Teleport to="body">
    <Transition name="fade">
      <div
        v-if="isOpen"
        class="fixed inset-0 bg-cs-ink-900/60 z-40"
        @click="close"
      ></div>
    </Transition>

    <Transition name="filter-slide">
      <aside
        v-if="isOpen"
        class="fixed top-0 right-0 h-full w-80 bg-white shadow-2xl z-50 overflow-y-auto flex flex-col"
      >
        <div class="flex items-center justify-between px-4 py-3 border-b border-cs-ink-200 shrink-0">
          <span class="font-semibold text-cs-ink-900">Filter</span>
          <button @click="close" class="p-1 text-cs-ink-400 hover:text-cs-ink-900 transition-colors">
            <i class="fas fa-times text-lg"></i>
          </button>
        </div>

        <div class="p-4 space-y-4 overflow-y-auto">
          <form :action="action" method="get" data-turbo-frame="_top">
            <input v-if="currentSort" type="hidden" name="sort" :value="currentSort" />
            <input v-if="currentDirection" type="hidden" name="direction" :value="currentDirection" />

            <div class="form-group">
              <label class="label-field" for="mrf-q">Suche</label>
              <div class="relative">
                <input id="mrf-q" type="text" name="q" :value="currentQ" placeholder="Rezeptname…"
                       class="input-field pl-8" autocomplete="off" />
                <i class="fas fa-search absolute left-2.5 top-1/2 -translate-y-1/2 text-cs-ink-400 text-xs pointer-events-none"></i>
              </div>
            </div>

            <div class="form-group">
              <label class="label-field" for="mrf-min-rating">Mindestbewertung</label>
              <select id="mrf-min-rating" name="min_rating" class="input-field">
                <option value="" :selected="!currentMinRating">Alle</option>
                <option v-for="n in [5, 6, 7, 8, 9]" :key="n" :value="n" :selected="currentMinRating == n">{{ n }}+</option>
              </select>
            </div>

            <div class="form-group">
              <label class="label-field" for="mrf-tag">Kategorie</label>
              <select id="mrf-tag" name="tag" class="input-field">
                <option value="" :selected="!currentTag">Alle</option>
                <option v-for="tag in tags" :key="tag.name" :value="tag.name" :selected="currentTag === tag.name">{{ tag.name }}</option>
              </select>
            </div>

            <div class="form-group">
              <label class="label-field" for="mrf-ingredient">Zutat</label>
              <select id="mrf-ingredient" name="ingredient_id" class="input-field">
                <option value="" :selected="!currentIngredientId">Alle</option>
                <option v-for="ing in ingredients" :key="ing.id" :value="ing.id" :selected="currentIngredientId == ing.id">{{ ing.name }}</option>
              </select>
            </div>

            <div class="form-group">
              <label class="label-field">Benutzer</label>
              <user-autocomplete
                :initial-username="initialUsername"
                :initial-user-id="currentUserId"
              ></user-autocomplete>
            </div>

            <div v-if="collections && collections.length > 0" class="form-group">
              <label class="label-field" for="mrf-collection">Meine Liste</label>
              <select id="mrf-collection" name="collection_id" class="input-field">
                <option value="" :selected="!currentCollectionId">Alle Rezepte</option>
                <option v-for="col in collections" :key="col.id" :value="col.id" :selected="currentCollectionId == col.id">{{ col.name }}</option>
              </select>
            </div>

            <label v-if="authenticated" class="check-label">
              <input type="checkbox" name="filter" value="favorites" class="check-field"
                     :checked="currentFilter === 'favorites'"
                     @change="$event.target.form.submit()" />
              <span class="text-sm text-cs-ink-700">Nur Favoriten</span>
            </label>

            <div class="pt-1">
              <button type="submit" class="btn btn-primary w-full">Filtern</button>
            </div>

            <div v-if="activeFiltersCount > 0" class="text-center pb-1">
              <a :href="resetUrl" class="text-sm text-cs-ink-400 hover:text-cs-ink-700 underline">Alle Filter zurücksetzen</a>
            </div>
          </form>
        </div>
      </aside>
    </Transition>
  </Teleport>
  </div>
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'

const props = defineProps({
  action:              { type: String,  required: true },
  tags:                { type: Array,   default: () => [] },
  ingredients:         { type: Array,   default: () => [] },
  collections:         { type: Array,   default: () => [] },
  activeFiltersCount:  { type: Number,  default: 0 },
  resetUrl:            { type: String,  default: '' },
  currentQ:            { type: String,  default: '' },
  currentMinRating:    { type: String,  default: '' },
  currentTag:          { type: String,  default: '' },
  currentIngredientId: { type: String,  default: '' },
  currentUserId:       { type: String,  default: '' },
  currentCollectionId: { type: String,  default: '' },
  currentFilter:       { type: String,  default: '' },
  currentSort:         { type: String,  default: '' },
  currentDirection:    { type: String,  default: '' },
  initialUsername:     { type: String,  default: '' },
  authenticated:       { type: Boolean, default: false },
})

const isOpen = ref(false)
const sidebarTop = ref('80px')

function open() {
  isOpen.value = true
  document.body.style.overflow = 'hidden'
}

function close() {
  isOpen.value = false
  document.body.style.overflow = ''
}

function updateSidebarTop() {
  const header = document.getElementById('site-header')
  if (header) {
    sidebarTop.value = (header.getBoundingClientRect().height + 8) + 'px'
  }
}

let ro = null
onMounted(() => {
  updateSidebarTop()
  const header = document.getElementById('site-header')
  if (header) {
    ro = new ResizeObserver(updateSidebarTop)
    ro.observe(header)
  }
  window.addEventListener('open-recipe-filters', open)
})
onUnmounted(() => {
  ro?.disconnect()
  window.removeEventListener('open-recipe-filters', open)
  document.body.style.overflow = ''
})
</script>

<style scoped>
.filter-slide-enter-active {
  animation: filterSlideIn 0.25s ease-out;
}
.filter-slide-leave-active {
  animation: filterSlideIn 0.2s ease-in reverse;
}
@keyframes filterSlideIn {
  from { transform: translateX(100%); }
  to   { transform: translateX(0); }
}

.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.2s;
}
.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
