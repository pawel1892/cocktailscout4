<template>
  <div
    class="markdown-editor"
    @dragover.prevent="isDragging = true"
    @dragleave="isDragging = false"
    @drop.prevent="onDrop"
    :class="{ 'ring-2 ring-cs-gold ring-opacity-50': isDragging }"
  >
    <!-- Toolbar -->
    <div class="flex flex-wrap gap-1 mb-0 p-2 bg-gray-50 border border-gray-300 rounded-t-md">
      <!-- Text formatting -->
      <button type="button" @click="insertMarkdown('bold')" class="toolbar-btn" title="Fett (Strg+B)"><i class="fas fa-bold"></i></button>
      <button type="button" @click="insertMarkdown('italic')" class="toolbar-btn" title="Kursiv (Strg+I)"><i class="fas fa-italic"></i></button>
      <button type="button" @click="insertMarkdown('underline')" class="toolbar-btn" title="Unterstrichen"><u>U</u></button>
      <div class="border-l border-gray-300 mx-1"></div>

      <!-- Headings -->
      <button type="button" @click="insertMarkdown('h2')" class="toolbar-btn" title="Überschrift 2"><i class="fas fa-heading text-xs"></i>2</button>
      <button type="button" @click="insertMarkdown('h3')" class="toolbar-btn" title="Überschrift 3"><i class="fas fa-heading text-xs"></i>3</button>
      <div class="border-l border-gray-300 mx-1"></div>

      <!-- Lists, quote, link -->
      <button type="button" @click="insertMarkdown('unordered-list')" class="toolbar-btn" title="Unsortierte Liste"><i class="fas fa-list-ul"></i></button>
      <button type="button" @click="insertMarkdown('ordered-list')" class="toolbar-btn" title="Sortierte Liste"><i class="fas fa-list-ol"></i></button>
      <button type="button" @click="insertMarkdown('quote')" class="toolbar-btn" title="Zitat"><i class="fas fa-quote-right"></i></button>
      <button type="button" @click="insertMarkdown('link')" class="toolbar-btn" title="Link"><i class="fas fa-link"></i></button>
      <div class="border-l border-gray-300 mx-1"></div>

      <!-- Image upload (only when uploadUrl provided) -->
      <template v-if="uploadUrl">
        <div class="relative">
          <button
            type="button"
            @click="toggleImagePopover"
            :disabled="uploadState === 'uploading'"
            class="toolbar-btn"
            :title="uploadState === 'uploading' ? 'Hochladen...' : 'Bild einfügen'"
          >
            <i v-if="uploadState === 'uploading'" class="fas fa-spinner fa-spin"></i>
            <i v-else class="far fa-image"></i>
          </button>

          <div
            v-if="showImagePopover"
            class="absolute left-0 top-full mt-1 w-72 bg-white border border-gray-200 shadow-lg rounded z-20"
          >
            <!-- Tabs -->
            <div class="flex border-b border-gray-200">
              <button
                type="button"
                @click="imageTab = 'upload'"
                :class="['flex-1 px-3 py-2 text-sm font-medium', imageTab === 'upload' ? 'text-cs-gold border-b-2 border-cs-gold' : 'text-gray-500 hover:text-gray-700']"
              >Hochladen</button>
              <button
                type="button"
                @click="imageTab = 'url'"
                :class="['flex-1 px-3 py-2 text-sm font-medium', imageTab === 'url' ? 'text-cs-gold border-b-2 border-cs-gold' : 'text-gray-500 hover:text-gray-700']"
              >URL</button>
            </div>

            <!-- Upload tab -->
            <div v-if="imageTab === 'upload'" class="p-3">
              <button type="button" @click="triggerFileInput" class="btn btn-outline btn-sm w-full">
                <i class="fas fa-upload mr-1"></i> Datei auswählen
              </button>
              <p class="text-xs text-gray-400 mt-2">oder per Drag &amp; Drop / Einfügen (Strg+V)</p>
            </div>

            <!-- URL tab -->
            <div v-if="imageTab === 'url'" class="p-3">
              <input
                v-model="imageUrlInput"
                type="url"
                placeholder="https://..."
                class="input-field w-full text-sm mb-2"
                @keydown.enter.prevent="insertImageFromUrl"
              />
              <button
                type="button"
                @click="insertImageFromUrl"
                :disabled="!imageUrlInput.trim()"
                class="btn btn-primary btn-sm w-full"
              >Einfügen</button>
            </div>

            <!-- Size selector -->
            <div class="px-3 pb-3 border-t border-gray-100 pt-2">
              <p class="text-xs text-gray-500 mb-1">Größe:</p>
              <div class="flex gap-1">
                <button
                  v-for="size in imageSizes"
                  :key="size.value"
                  type="button"
                  @click="imageSize = size.value"
                  :class="['toolbar-btn text-xs flex-1', imageSize === size.value ? '!bg-cs-dark-red !border-cs-dark-red text-white' : '']"
                >{{ size.label }}</button>
              </div>
            </div>
          </div>
        </div>
        <input ref="fileInputRef" type="file" accept="image/*" class="hidden" @change="onFileSelected" />
        <div class="border-l border-gray-300 mx-1"></div>
      </template>

      <!-- Internal links (forum/wiki) -->
      <template v-if="showInternalLinks">
        <!-- Recipe link with autocomplete -->
        <div class="relative">
          <button
            type="button"
            @click="toggleRecipeSearch"
            class="toolbar-btn"
            title="Rezept verlinken"
          >
            <i class="fas fa-cocktail"></i>
          </button>
          <div
            v-if="showRecipeSearch"
            class="absolute left-0 top-full mt-1 w-72 bg-white border border-gray-200 shadow-lg rounded z-20"
          >
            <div class="p-2">
              <input
                v-model="recipeQuery"
                @input="searchRecipes"
                placeholder="Rezept suchen..."
                class="input-field w-full text-sm"
                ref="recipeSearchRef"
                @keydown.escape="showRecipeSearch = false"
              />
            </div>
            <div v-if="recipeResults.length" class="border-t border-gray-100 max-h-48 overflow-y-auto">
              <button
                v-for="recipe in recipeResults"
                :key="recipe.slug"
                type="button"
                @click="selectRecipe(recipe)"
                class="w-full text-left px-3 py-2 text-sm hover:bg-gray-50 flex items-center gap-2"
              >
                <img v-if="recipe.thumbnail_url" :src="recipe.thumbnail_url" class="w-8 h-8 object-cover rounded" />
                <span>{{ recipe.title }}</span>
              </button>
            </div>
            <div v-else-if="recipeQuery.length >= 2" class="px-3 py-2 text-sm text-gray-400">Keine Rezepte gefunden</div>
          </div>
        </div>

        <button type="button" @click="insertThreadLink" class="toolbar-btn" title="Forum-Thema verlinken"><i class="fas fa-comments"></i></button>
        <button type="button" @click="insertPostLink" class="toolbar-btn" title="Forum-Beitrag verlinken"><i class="fas fa-comment"></i></button>
        <div class="border-l border-gray-300 mx-1"></div>
      </template>

      <!-- Smiley picker (only when smileys provided) -->
      <template v-if="smileys && smileys.length">
        <div class="relative ml-auto">
          <button
            type="button"
            @click="() => { const next = !showSmileys; closeAllPopovers(); showSmileys = next }"
            class="toolbar-btn"
            title="Smileys"
          >
            <i class="far fa-smile"></i>
          </button>
          <div
            v-if="showSmileys"
            class="absolute right-0 top-full mt-1 w-64 p-2 bg-white border border-gray-200 shadow-lg rounded z-20 grid grid-cols-5 gap-1"
          >
            <img
              v-for="smiley in smileys"
              :key="smiley.filename"
              :src="`/images/smileys/${smiley.filename}`"
              :alt="smiley.name"
              :title="smiley.shortcut"
              class="cursor-pointer hover:scale-110 transition-transform p-1"
              @click="insertText(smiley.shortcut); showSmileys = false"
            />
          </div>
        </div>
      </template>
    </div>

    <!-- Tab Switcher -->
    <div class="flex border-x border-gray-300 bg-white">
      <button
        type="button"
        @click="activeTab = 'edit'"
        :class="[
          'px-4 py-2 font-medium text-sm',
          activeTab === 'edit'
            ? 'text-cs-gold border-b-2 border-cs-gold'
            : 'text-gray-500 hover:text-gray-700'
        ]"
      >
        Bearbeiten
      </button>
      <button
        type="button"
        @click="activeTab = 'preview'"
        :class="[
          'px-4 py-2 font-medium text-sm',
          activeTab === 'preview'
            ? 'text-cs-gold border-b-2 border-cs-gold'
            : 'text-gray-500 hover:text-gray-700'
        ]"
      >
        Vorschau
      </button>
    </div>

    <!-- Edit Tab -->
    <div v-show="activeTab === 'edit'">
      <textarea
        ref="textareaRef"
        v-model="markdownText"
        :id="textareaId"
        :name="textareaName"
        :placeholder="placeholder"
        :required="required"
        class="w-full px-4 py-3 border border-gray-300 rounded-b-md focus:ring-2 focus:ring-cs-dark-red focus:border-transparent resize-y min-h-[300px] font-mono text-sm"
        @input="onInput"
        @paste="onPaste"
        @keydown="onKeydown"
      ></textarea>
    </div>

    <!-- Preview Tab -->
    <div v-show="activeTab === 'preview'" class="border-x border-b border-gray-300 rounded-b-md p-4 min-h-[300px] bg-white">
      <div v-if="markdownText" class="prose prose-cs prose-sm max-w-none" v-html="renderedHtml"></div>
      <div v-else class="text-gray-400 italic">Keine Vorschau verfügbar</div>
    </div>

    <!-- Upload error -->
    <p v-if="uploadError" class="text-cs-error text-sm mt-1">{{ uploadError }}</p>

    <!-- Character counter -->
    <p v-if="markdownText.length > 0" class="form-hint mt-1">{{ markdownText.length }} Zeichen</p>

    <!-- Help section -->
    <div class="mt-2 p-3 bg-gray-50 border border-gray-200 rounded text-xs text-gray-600">
      <button
        type="button"
        @click="showHelp = !showHelp"
        class="flex items-center gap-1 text-cs-dark-red hover:underline"
      >
        <i class="fas fa-info-circle"></i>
        <span>{{ showHelp ? 'Formatierungs-Hilfe ausblenden' : 'Formatierungs-Hilfe einblenden' }}</span>
      </button>
      <div v-if="showHelp" class="mt-2 space-y-1">
        <div><strong>Fett:</strong> **Text** oder __Text__</div>
        <div><strong>Kursiv:</strong> *Text* oder _Text_</div>
        <div><strong>Unterstrichen:</strong> &lt;u&gt;Text&lt;/u&gt;</div>
        <div><strong>Link:</strong> [Link-Text](https://example.com)</div>
        <div><strong>Bild:</strong> ![Alt-Text](https://example.com/bild.jpg)</div>
        <div><strong>Zitat:</strong> &gt; Text</div>
        <div><strong>Zitat mit Autor:</strong> [quote=Name]Text[/quote]</div>
        <template v-if="showInternalLinks">
          <div><strong>Rezept verlinken:</strong> [[recipe:rezept-slug]] oder [[recipe:rezept-slug|Eigener Text]]</div>
          <div><strong>Thema verlinken:</strong> [[thread:thema-slug]] oder [[thread:thema-slug|Eigener Text]]</div>
          <div><strong>Beitrag verlinken:</strong> [[post:abc123xy]] oder [[post:abc123xy|Eigener Text]]</div>
        </template>
        <template v-if="uploadUrl">
          <div><strong>Bild:</strong> Hochladen oder URL einfügen über den Bild-Button</div>
          <div><strong>Bild (schnell):</strong> Bild per Strg+V oder Drag &amp; Drop – nutzt die zuletzt gewählte Größe</div>
        </template>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import { renderMarkdown } from '../lib/markdownPreview.js'

const props = defineProps({
  modelValue: { type: String, default: '' },
  textareaId: { type: String, default: '' },
  textareaName: { type: String, default: '' },
  placeholder: { type: String, default: 'Markdown-Text eingeben...' },
  required: { type: Boolean, default: false },
  // Image upload endpoint — if absent, image upload toolbar button is hidden
  uploadUrl: { type: String, default: '' },
  // Array of smiley objects — if absent or empty, smiley picker is hidden
  smileys: { type: Array, default: null },
  // Show recipe/thread/post wikilink buttons (set true for forum, wiki, etc.)
  showInternalLinks: { type: Boolean, default: false },
  // Legacy prop: label (used by recipe forms)
  label: { type: String, default: '' },
})

const emit = defineEmits(['update:modelValue'])

// ── State ────────────────────────────────────────────────────────────────────
const markdownText   = ref(props.modelValue)
const activeTab      = ref('edit')
const textareaRef    = ref(null)
const fileInputRef   = ref(null)
const isDragging     = ref(false)
const showSmileys    = ref(false)
const showHelp       = ref(false)
const uploadState    = ref('idle') // 'idle' | 'uploading'
const uploadError    = ref('')

// Image popover
const showImagePopover = ref(false)
const imageTab         = ref('upload') // 'upload' | 'url'
const imageUrlInput    = ref('')
const imageSize        = ref('full')   // 'full' | 'medium' | 'small'
const imageSizes       = [
  { value: 'full',   label: 'Voll'   },
  { value: 'medium', label: 'Mittel' },
  { value: 'small',  label: 'Klein'  },
]

// Recipe autocomplete
const showRecipeSearch = ref(false)
const recipeQuery      = ref('')
const recipeResults    = ref([])
const recipeSearchRef  = ref(null)
let recipeDebounceTimer = null

// ── Watch ────────────────────────────────────────────────────────────────────
watch(() => props.modelValue, (v) => { markdownText.value = v })

// ── Preview ──────────────────────────────────────────────────────────────────
const renderedHtml = computed(() => renderMarkdown(markdownText.value, props.smileys || undefined))

// ── Helpers ──────────────────────────────────────────────────────────────────
const onInput = () => emit('update:modelValue', markdownText.value)

function getSelectedText() {
  const ta = textareaRef.value
  if (!ta) return ''
  return markdownText.value.substring(ta.selectionStart, ta.selectionEnd)
}

function insertText(text) {
  const ta = textareaRef.value
  if (!ta) return

  const start = ta.selectionStart
  const end   = ta.selectionEnd
  markdownText.value = markdownText.value.substring(0, start) + text + markdownText.value.substring(end)
  emit('update:modelValue', markdownText.value)

  nextTick(() => {
    ta.focus()
    ta.setSelectionRange(start + text.length, start + text.length)
  })
}

function wrapText(before, after, placeholder = 'Text') {
  const ta = textareaRef.value
  if (!ta) return

  const start    = ta.selectionStart
  const end      = ta.selectionEnd
  const selected = markdownText.value.substring(start, end) || placeholder
  const replacement = before + selected + after

  markdownText.value = markdownText.value.substring(0, start) + replacement + markdownText.value.substring(end)
  emit('update:modelValue', markdownText.value)

  nextTick(() => {
    ta.focus()
    if (selected === placeholder) {
      ta.setSelectionRange(start + before.length, start + before.length + placeholder.length)
    } else {
      ta.setSelectionRange(start + replacement.length, start + replacement.length)
    }
  })
}

// ── Toolbar actions ───────────────────────────────────────────────────────────
function insertMarkdown(type) {
  switch (type) {
    case 'bold':          return wrapText('**', '**')
    case 'italic':        return wrapText('*', '*')
    case 'underline':     return wrapText('<u>', '</u>')
    case 'h2':            return wrapText('## ', '', getSelectedText() || 'Überschrift')
    case 'h3':            return wrapText('### ', '', getSelectedText() || 'Überschrift')
    case 'quote': {
      const sel = getSelectedText()
      if (sel) {
        insertText(sel.split('\n').map(l => `> ${l}`).join('\n'))
      } else {
        insertText('> ')
      }
      break
    }
    case 'link': {
      const sel = getSelectedText()
      if (sel) {
        // selected text becomes the link label; place cursor inside ()
        const before = markdownText.value.substring(0, textareaRef.value.selectionStart)
        const after  = markdownText.value.substring(textareaRef.value.selectionEnd)
        const replacement = `[${sel}](url)`
        markdownText.value = before + replacement + after
        emit('update:modelValue', markdownText.value)
        nextTick(() => {
          const ta = textareaRef.value
          ta.focus()
          const pos = before.length + sel.length + 3 // inside "(url)"
          ta.setSelectionRange(pos, pos + 3)
        })
      } else {
        insertText('[](url)')
      }
      break
    }
    case 'unordered-list': {
      const sel = getSelectedText()
      if (sel) {
        insertText(sel.split('\n').map(l => `- ${l}`).join('\n'))
      } else {
        insertText('- ')
      }
      break
    }
    case 'ordered-list': {
      const sel = getSelectedText()
      if (sel) {
        insertText(sel.split('\n').map((l, i) => `${i + 1}. ${l}`).join('\n'))
      } else {
        insertText('1. ')
      }
      break
    }
  }
}

// ── Popover management ────────────────────────────────────────────────────────
function closeAllPopovers() {
  showRecipeSearch.value = false
  showImagePopover.value = false
  showSmileys.value      = false
}

// ── Internal link buttons ─────────────────────────────────────────────────────
function toggleRecipeSearch() {
  const next = !showRecipeSearch.value
  closeAllPopovers()
  showRecipeSearch.value = next
  if (next) nextTick(() => recipeSearchRef.value?.focus())
}

async function searchRecipes() {
  clearTimeout(recipeDebounceTimer)
  if (recipeQuery.value.length < 2) { recipeResults.value = []; return }
  recipeDebounceTimer = setTimeout(async () => {
    try {
      const res = await fetch(`/rezepte.json?q=${encodeURIComponent(recipeQuery.value)}&limit=10`)
      const data = await res.json()
      recipeResults.value = data.recipes || []
    } catch {
      recipeResults.value = []
    }
  }, 300)
}

function selectRecipe(recipe) {
  const label = getSelectedText()
  insertText(label ? `[[recipe:${recipe.slug}|${label}]]` : `[[recipe:${recipe.slug}]]`)
  showRecipeSearch.value = false
  recipeQuery.value = ''
  recipeResults.value = []
}

function insertThreadLink() {
  const slug = prompt('Thema-Slug eingeben:', '')
  if (!slug?.trim()) return
  if (!/^[a-z0-9-]+$/.test(slug.trim())) {
    alert('Bitte einen gültigen Slug eingeben (nur Kleinbuchstaben, Zahlen, Bindestriche).')
    return
  }
  const label = getSelectedText()
  insertText(label ? `[[thread:${slug.trim()}|${label}]]` : `[[thread:${slug.trim()}]]`)
}

function insertPostLink() {
  const raw = prompt('Beitrags-ID eingeben:', '')
  const id = raw?.trim().replace(/^#/, '')
  if (!id) return
  if (!/^[a-zA-Z0-9]+$/.test(id)) {
    alert('Bitte eine gültige Beitrags-ID eingeben (z.B. abc123xy).')
    return
  }
  const label = getSelectedText()
  insertText(label ? `[[post:${id}|${label}]]` : `[[post:${id}]]`)
}

// ── Image upload ──────────────────────────────────────────────────────────────
function toggleImagePopover() {
  const next = !showImagePopover.value
  closeAllPopovers()
  showImagePopover.value = next
  if (next) {
    imageTab.value = 'upload'
    imageUrlInput.value = ''
  }
}

function triggerFileInput() {
  fileInputRef.value?.click()
}

function insertImageWithSize(url) {
  const md = imageSize.value === 'full'
    ? `![](${url})`
    : `![](${url} "${imageSize.value}")`
  insertText(md)
  showImagePopover.value = false
}

function insertImageFromUrl() {
  const url = imageUrlInput.value.trim()
  if (!url) return
  insertImageWithSize(url)
  imageUrlInput.value = ''
}

function onFileSelected(event) {
  const file = event.target.files?.[0]
  if (file) uploadAndInsert(file)
  // Reset input so the same file can be re-selected
  event.target.value = ''
}

function onPaste(event) {
  if (!props.uploadUrl) return
  const items = event.clipboardData?.items
  if (!items) return
  for (const item of items) {
    if (item.type.startsWith('image/')) {
      event.preventDefault()
      uploadAndInsert(item.getAsFile())
      return
    }
  }
}

function onDrop(event) {
  isDragging.value = false
  if (!props.uploadUrl) return
  const file = event.dataTransfer.files?.[0]
  if (file?.type.startsWith('image/')) uploadAndInsert(file)
}

async function uploadAndInsert(file) {
  if (!props.uploadUrl) return
  uploadError.value = ''
  uploadState.value = 'uploading'

  const formData = new FormData()
  formData.append('image', file)
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

  try {
    const res = await fetch(props.uploadUrl, {
      method: 'POST',
      headers: { 'X-CSRF-Token': csrfToken },
      body: formData,
    })
    const data = await res.json()
    if (data.success) {
      insertImageWithSize(data.url)
    } else {
      uploadError.value = data.errors?.join(', ') || 'Upload fehlgeschlagen'
    }
  } catch (e) {
    uploadError.value = 'Verbindungsfehler beim Upload'
  } finally {
    uploadState.value = 'idle'
  }
}

// ── Keyboard shortcuts ────────────────────────────────────────────────────────
function onKeydown(event) {
  if ((event.ctrlKey || event.metaKey) && event.key === 'b') {
    event.preventDefault()
    insertMarkdown('bold')
  }
  if ((event.ctrlKey || event.metaKey) && event.key === 'i') {
    event.preventDefault()
    insertMarkdown('italic')
  }
}
</script>

<style>
@reference "../entrypoints/application.css";

.toolbar-btn {
  @apply px-2 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-cs-gold;
}

.md-quote {
  @apply bg-gray-50 border-l-4 border-cs-gold my-4 rounded-r;
}
.md-quote figcaption {
  @apply font-bold text-sm text-cs-dark-red px-4 pt-3 block;
}
.md-quote blockquote {
  @apply italic text-gray-700 px-4 pb-3 m-0 border-0;
}
</style>
