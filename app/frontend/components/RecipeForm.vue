<template>
  <div>
    <!-- Draft Indicator -->
    <div v-if="editMode && !isPublic" class="callout callout-gold">
      <i class="fas fa-file-alt"></i>
      <strong>Entwurf:</strong> Dieses Rezept ist noch nicht veröffentlicht.
    </div>

    <!-- Title -->
    <div class="form-group">
      <label class="label-field">
        Titel <span class="text-red-500">*</span>
      </label>
      <input
        type="text"
        v-model="title"
        :name="`${formName}[title]`"
        class="input-field"
        placeholder="z.B. Mojito"
        required
      />
    </div>

    <!-- Description (Markdown) -->
    <div class="form-group">
      <markdown-editor
        v-model="description"
        label="Beschreibung"
        placeholder="Beschreibe die Zubereitung, Geschichte oder Besonderheiten des Cocktails..."
        :required="true"
      />
      <input type="hidden" :name="`${formName}[description]`" :value="description" />
    </div>

    <!-- Tags -->
    <div class="form-group">
      <label class="label-field">Tags</label>
      <input
        type="text"
        v-model="tagList"
        :name="`${formName}[tag_list]`"
        class="input-field"
        placeholder="z.B. Klassiker, Sommerdrink, IBA"
      />
      <p class="form-hint">Durch Komma trennen</p>
    </div>

    <!-- Ingredients -->
    <div class="form-group">
      <div class="flex justify-between items-center mb-4">
        <h3 class="text-lg font-bold">Zutaten</h3>
        <button
          v-if="ingredients.length > 0"
          type="button"
          @click="toggleAllPreview"
          class="link text-sm"
        >
          <i :class="allInPreview ? 'fas fa-pencil' : 'fas fa-eye'" class="mr-1"></i>
          {{ allInPreview ? 'Alle bearbeiten' : 'Alle Vorschau' }}
        </button>
      </div>

      <div v-for="(ingredient, index) in ingredients" :key="index" class="card p-4 mb-4">
        <!-- Preview Mode -->
        <div v-if="ingredient.isPreview" class="flex items-start gap-2">
          <span class="text-cs-gold mt-1">•</span>
          <span class="flex-1">
            <strong v-if="ingredient.amount">{{ formatIngredientAmount(ingredient) }}</strong>
            {{ ingredient.displayName || ingredient.selectedIngredient?.name || 'Zutat auswählen' }}
            <span v-if="ingredient.additionalInfo" class="text-gray-600">
              ({{ ingredient.additionalInfo }})
            </span>
            <span v-if="ingredient.isOptional" class="text-sm text-gray-500 italic ml-1">
              (optional)
            </span>
            <span v-if="!ingredient.isScalable" class="text-sm text-blue-600 ml-1">
              <i class="fa-solid fa-lock"></i>
            </span>
          </span>
          <div class="flex items-center gap-2 flex-shrink-0">
            <button
              type="button"
              @click="ingredient.isPreview = false"
              class="text-gray-500 hover:text-cs-dark-red transition-colors"
              title="Bearbeiten"
            >
              <i class="fas fa-pencil"></i>
            </button>
            <button
              type="button"
              @click="removeIngredient(index)"
              :disabled="ingredients.length <= 2"
              class="text-gray-400 hover:text-cs-error transition-colors"
              :class="{ 'opacity-30 cursor-not-allowed': ingredients.length <= 2 }"
              title="Entfernen"
            >
              <i class="fas fa-trash"></i>
            </button>
          </div>
        </div>

        <!-- Edit Mode -->
        <div v-else class="space-y-4">
          <!-- Header with Preview Button -->
          <div class="flex justify-between items-center mb-2">
            <span class="text-sm font-medium text-gray-700">Zutat {{ index + 1 }}</span>
            <button
              type="button"
              @click="ingredient.isPreview = true"
              class="text-gray-500 hover:text-cs-dark-red transition-colors text-sm"
              title="Vorschau"
            >
              <i class="fas fa-eye mr-1"></i>Vorschau
            </button>
          </div>

          <!-- Ingredient Name -->
          <div>
            <label class="label-field">
              Zutat <span class="text-red-500">*</span>
            </label>
            <ingredient-autocomplete
              v-model="ingredient.selectedIngredient"
              @update:modelValue="updateIngredient(index, $event)"
              placeholder="Zutat suchen..."
            />
          </div>

          <!-- Amount and Unit Row -->
          <div class="flex gap-4">
            <div class="flex-1">
              <label class="label-field">
                Menge <span class="text-red-500">*</span>
              </label>
              <input
                type="number"
                v-model="ingredient.amount"
                class="input-field"
                placeholder="4"
                step="0.01"
                min="0"
                required
              />
            </div>

            <div class="flex-1">
              <label class="label-field">Einheit</label>
              <select v-model="ingredient.unitId" class="input-field">
                <option :value="null">keine Einheit</option>
                <optgroup v-for="category in unitCategories" :key="category" :label="categoryLabel(category)">
                  <option v-for="unit in unitsByCategory[category]" :key="unit.id" :value="unit.id">
                    {{ unit.display_name }}
                  </option>
                </optgroup>
              </select>
            </div>

            <div class="flex items-end">
              <button
                type="button"
                @click="removeIngredient(index)"
                :disabled="ingredients.length <= 2"
                class="text-gray-400 hover:text-cs-error transition-colors"
                :class="{ 'opacity-30 cursor-not-allowed': ingredients.length <= 2 }"
                title="Entfernen"
              >
                <i class="fas fa-trash"></i>
              </button>
            </div>
          </div>

          <!-- Advanced Options Toggle -->
          <div>
            <button
              type="button"
              @click="ingredient.showAdvanced = !ingredient.showAdvanced"
              class="link text-sm"
            >
              <i :class="ingredient.showAdvanced ? 'fas fa-chevron-up' : 'fas fa-chevron-down'"></i>
              Erweiterte Optionen
            </button>

            <!-- Advanced Options Content -->
            <div v-if="ingredient.showAdvanced" class="space-y-4 mt-4 pt-4 border-t border-gray-200">
              <div class="form-group">
                <label class="label-field">Anzeigename (optional)</label>
                <input
                  type="text"
                  v-model="ingredient.displayName"
                  class="input-field"
                  placeholder="z.B. Minzzweig"
                />
                <p class="form-hint">Überschreibt den Zutatennamen</p>
              </div>

              <div class="form-group">
                <label class="label-field">Zusätzliche Info (optional)</label>
                <input
                  type="text"
                  v-model="ingredient.additionalInfo"
                  class="input-field"
                  placeholder="z.B. braun, frisch"
                />
              </div>

              <div class="flex gap-4">
                <label class="flex items-center gap-2">
                  <input
                    type="checkbox"
                    v-model="ingredient.isOptional"
                    class="h-4 w-4 text-cs-gold focus:ring-cs-gold border-gray-300 rounded"
                  />
                  <span class="text-sm">Optional</span>
                </label>

                <label class="flex items-center gap-2">
                  <input
                    type="checkbox"
                    v-model="ingredient.isScalable"
                    class="h-4 w-4 text-cs-gold focus:ring-cs-gold border-gray-300 rounded"
                  />
                  <span class="text-sm">Skalierbar</span>
                </label>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Add Ingredient Button -->
      <button
        type="button"
        @click="addIngredient"
        class="btn btn-outline w-full"
      >
        <i class="fas fa-plus mr-2"></i>Zutat hinzufügen
      </button>
    </div>

    <!-- Hidden field for ingredients JSON -->
    <input type="hidden" :name="`${formName}[ingredients_json]`" :value="ingredientsJson" />

    <!-- Visibility Checkbox (only for recipes, not for suggestions) -->
    <div v-if="formName === 'recipe'" class="form-group">
      <label class="flex items-center gap-2 cursor-pointer">
        <input
          type="checkbox"
          v-model="isPublic"
          class="h-5 w-5 text-cs-gold focus:ring-cs-gold border-gray-300 rounded"
        />
        <span class="text-sm font-medium text-gray-700">
          <i class="fas fa-eye mr-1"></i>Rezept veröffentlichen
        </span>
      </label>
      <p class="form-hint mt-1 ml-7">
        Wenn aktiviert, ist das Rezept öffentlich sichtbar. Andernfalls bleibt es ein Entwurf.
      </p>
    </div>

    <!-- Hidden field for is_public (only for recipes) -->
    <input v-if="formName === 'recipe'" type="hidden" :name="`${formName}[is_public]`" :value="isPublic ? 'true' : 'false'" />

    <!-- Submit Button -->
    <div class="flex justify-end">
      <button
        type="submit"
        class="btn btn-gold"
      >
        <i class="fas fa-save mr-2"></i>Speichern
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import IngredientAutocomplete from './IngredientAutocomplete.vue'
import MarkdownEditor from './MarkdownEditor.vue'

const props = defineProps({
  initialData: {
    type: Object,
    default: () => ({})
  },
  units: {
    type: Array,
    default: () => []
  },
  formName: {
    type: String,
    default: 'recipe'
  },
  editMode: {
    type: Boolean,
    default: false
  }
})

// Form fields
const title = ref(props.initialData.title || '')
const description = ref(props.initialData.description || '')
const tagList = ref(props.initialData.tagList || '')
const isPublic = ref(props.initialData.isPublic || false)

// Ingredients
const ingredients = ref([])

// Units organized by category
const unitsByCategory = computed(() => {
  const byCategory = {}
  props.units.forEach(unit => {
    if (!byCategory[unit.category]) {
      byCategory[unit.category] = []
    }
    byCategory[unit.category].push(unit)
  })
  return byCategory
})

const unitCategories = computed(() => {
  // Order categories: volume first (most common), then count, then special
  const categoryOrder = ['volume', 'count', 'special']
  const categories = Object.keys(unitsByCategory.value)

  return categoryOrder.filter(cat => categories.includes(cat))
})

const categoryLabel = (category) => {
  const labels = {
    volume: 'Volumen',
    count: 'Anzahl',
    special: 'Besondere Einheiten'
  }
  return labels[category] || category
}

// Initialize ingredients from initialData
const initializeIngredients = () => {
  if (props.initialData.ingredients && props.initialData.ingredients.length > 0) {
    ingredients.value = props.initialData.ingredients.map(ing => ({
      selectedIngredient: ing.ingredientId ? { id: ing.ingredientId, name: ing.ingredientName } : null,
      ingredientId: ing.ingredientId || null,
      ingredientName: ing.ingredientName || '',
      unitId: ing.unitId || null,
      amount: ing.amount || null,
      additionalInfo: ing.additionalInfo || '',
      displayName: ing.displayName || '',
      isOptional: ing.isOptional || false,
      isScalable: ing.isScalable !== false,
      showAdvanced: false,
      isPreview: false
    }))
  } else {
    // Start with 2 empty ingredients
    ingredients.value = [createEmptyIngredient(), createEmptyIngredient()]
  }
}

const createEmptyIngredient = () => {
  // Find cl unit as default (most common for cocktails)
  const clUnit = props.units.find(u => u.name === 'cl')

  return {
    selectedIngredient: null,
    ingredientId: null,
    ingredientName: '',
    unitId: clUnit?.id || null,
    amount: null,
    additionalInfo: '',
    displayName: '',
    isOptional: false,
    isScalable: true,
    showAdvanced: false,
    isPreview: false
  }
}

const addIngredient = () => {
  ingredients.value.push(createEmptyIngredient())
}

const removeIngredient = (index) => {
  if (ingredients.value.length > 2) {
    ingredients.value.splice(index, 1)
  }
}

const updateIngredient = (index, selectedIngredient) => {
  if (selectedIngredient) {
    ingredients.value[index].ingredientId = selectedIngredient.id
    ingredients.value[index].ingredientName = selectedIngredient.name
  }
}

// Get unit display name with correct plural form
const getUnitDisplayName = (unitId, amount) => {
  const unit = props.units.find(u => u.id === unitId)
  if (!unit) return ''

  // Use plural form if amount is not 1
  if (amount && parseFloat(amount) !== 1 && unit.plural_name) {
    return unit.plural_name
  }

  return unit.display_name
}

// Format ingredient amount with German number format and unit
const formatIngredientAmount = (ingredient) => {
  if (!ingredient.amount) return ''

  // Convert to German number format (comma as decimal separator)
  const amount = parseFloat(ingredient.amount)
  const germanAmount = amount.toString().replace('.', ',')

  // Add unit if present
  if (ingredient.unitId) {
    const unitName = getUnitDisplayName(ingredient.unitId, amount)
    return `${germanAmount} ${unitName}`
  }

  return germanAmount
}

// Check if all ingredients are in preview mode
const allInPreview = computed(() => {
  return ingredients.value.length > 0 && ingredients.value.every(ing => ing.isPreview)
})

// Toggle all ingredients between preview and edit mode
const toggleAllPreview = () => {
  const newPreviewState = !allInPreview.value
  ingredients.value.forEach(ing => {
    ing.isPreview = newPreviewState
  })
}

// Serialize ingredients to JSON for hidden field
const ingredientsJson = computed(() => {
  return JSON.stringify(ingredients.value.map(ing => ({
    ingredientId: ing.ingredientId,
    ingredientName: ing.ingredientName,
    unitId: ing.unitId,
    amount: ing.amount,
    additionalInfo: ing.additionalInfo,
    displayName: ing.displayName,
    isOptional: ing.isOptional,
    isScalable: ing.isScalable
  })))
})

onMounted(() => {
  initializeIngredients()
})
</script>

