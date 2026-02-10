<template>
  <div class="markdown-editor">
    <label v-if="label" class="label-field">
      {{ label }}
      <span v-if="required" class="text-red-500">*</span>
    </label>

    <!-- Toolbar -->
    <div class="toolbar flex flex-wrap gap-1 mb-2 p-2 bg-gray-50 border border-gray-300 rounded-t-md">
      <button type="button" @click="insertMarkdown('h1')" class="px-3 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-cs-gold" title="Überschrift 1">
        <i class="fas fa-heading"></i> H1
      </button>
      <button type="button" @click="insertMarkdown('h2')" class="px-3 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-cs-gold" title="Überschrift 2">
        <i class="fas fa-heading"></i> H2
      </button>
      <button type="button" @click="insertMarkdown('h3')" class="px-3 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-cs-gold" title="Überschrift 3">
        <i class="fas fa-heading"></i> H3
      </button>
      <div class="border-l border-gray-300 mx-1"></div>
      <button type="button" @click="insertMarkdown('bold')" class="px-3 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-cs-gold" title="Fett">
        <i class="fas fa-bold"></i>
      </button>
      <button type="button" @click="insertMarkdown('italic')" class="px-3 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-cs-gold" title="Kursiv">
        <i class="fas fa-italic"></i>
      </button>
      <div class="border-l border-gray-300 mx-1"></div>
      <button type="button" @click="insertMarkdown('link')" class="px-3 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-cs-gold" title="Link">
        <i class="fas fa-link"></i>
      </button>
      <button type="button" @click="insertMarkdown('unordered-list')" class="px-3 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-cs-gold" title="Unsortierte Liste">
        <i class="fas fa-list-ul"></i>
      </button>
      <button type="button" @click="insertMarkdown('ordered-list')" class="px-3 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-cs-gold" title="Sortierte Liste">
        <i class="fas fa-list-ol"></i>
      </button>
      <button type="button" @click="insertMarkdown('code')" class="px-3 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-cs-gold" title="Code">
        <i class="fas fa-code"></i>
      </button>
      <button type="button" @click="insertMarkdown('quote')" class="px-3 py-1 text-sm bg-white border border-gray-300 rounded hover:bg-gray-100 focus:outline-none focus:ring-2 focus:ring-cs-gold" title="Zitat">
        <i class="fas fa-quote-right"></i>
      </button>
    </div>

    <!-- Tab Switcher -->
    <div class="flex border-b border-gray-300">
      <button
        type="button"
        @click="activeTab = 'edit'"
        :class="[
          'px-4 py-2 font-medium',
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
          'px-4 py-2 font-medium',
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
        @input="onInput"
        :placeholder="placeholder"
        :required="required"
        class="input-field w-full min-h-[300px] rounded-t-none font-mono text-sm"
      ></textarea>
    </div>

    <!-- Preview Tab -->
    <div v-show="activeTab === 'preview'" class="border-x border-b border-gray-300 rounded-b-md p-4 min-h-[300px] bg-white">
      <div v-if="markdownText" class="prose prose-cs max-w-none" v-html="renderedHtml"></div>
      <div v-else class="text-gray-400 italic">Keine Vorschau verfügbar</div>
    </div>

    <!-- Character Counter (optional) -->
    <p v-if="markdownText.length > 0" class="form-hint">
      {{ markdownText.length }} Zeichen
    </p>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import { marked } from 'marked'
import DOMPurify from 'dompurify'

const props = defineProps({
  modelValue: {
    type: String,
    default: ''
  },
  label: {
    type: String,
    default: ''
  },
  placeholder: {
    type: String,
    default: 'Markdown-Text eingeben...'
  },
  required: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['update:modelValue'])

const markdownText = ref(props.modelValue)
const activeTab = ref('edit')
const textareaRef = ref(null)

// Watch for external changes
watch(() => props.modelValue, (newValue) => {
  markdownText.value = newValue
})

const onInput = () => {
  emit('update:modelValue', markdownText.value)
}

// Render markdown to HTML with sanitization
const renderedHtml = computed(() => {
  if (!markdownText.value) return ''

  try {
    const html = marked.parse(markdownText.value)
    // Sanitize HTML to prevent XSS
    return DOMPurify.sanitize(html)
  } catch (error) {
    console.error('Error rendering markdown:', error)
    return '<p class="text-red-500">Fehler beim Rendern der Vorschau</p>'
  }
})

const insertMarkdown = (type) => {
  const textarea = textareaRef.value
  if (!textarea) return

  const start = textarea.selectionStart
  const end = textarea.selectionEnd
  const selectedText = markdownText.value.substring(start, end)
  const hasSelection = start !== end

  let replacement = ''
  let cursorOffset = 0 // Where to place cursor after insertion

  switch (type) {
    case 'h1':
      if (hasSelection) {
        replacement = `# ${selectedText}`
        cursorOffset = replacement.length
      } else {
        replacement = '# '
        cursorOffset = 2 // After "# "
      }
      break
    case 'h2':
      if (hasSelection) {
        replacement = `## ${selectedText}`
        cursorOffset = replacement.length
      } else {
        replacement = '## '
        cursorOffset = 3 // After "## "
      }
      break
    case 'h3':
      if (hasSelection) {
        replacement = `### ${selectedText}`
        cursorOffset = replacement.length
      } else {
        replacement = '### '
        cursorOffset = 4 // After "### "
      }
      break
    case 'bold':
      if (hasSelection) {
        replacement = `**${selectedText}**`
        cursorOffset = replacement.length
      } else {
        replacement = '****'
        cursorOffset = 2 // Between the asterisks
      }
      break
    case 'italic':
      if (hasSelection) {
        replacement = `*${selectedText}*`
        cursorOffset = replacement.length
      } else {
        replacement = '**'
        cursorOffset = 1 // Between the asterisks
      }
      break
    case 'link':
      if (hasSelection) {
        replacement = `[${selectedText}](url)`
        cursorOffset = replacement.length - 4 // Before "url)"
      } else {
        replacement = '[](url)'
        cursorOffset = 1 // Inside the brackets
      }
      break
    case 'unordered-list':
      if (hasSelection) {
        replacement = selectedText.split('\n').map(line => `- ${line}`).join('\n')
        cursorOffset = replacement.length
      } else {
        replacement = '- '
        cursorOffset = 2 // After "- "
      }
      break
    case 'ordered-list':
      if (hasSelection) {
        replacement = selectedText.split('\n').map((line, i) => `${i + 1}. ${line}`).join('\n')
        cursorOffset = replacement.length
      } else {
        replacement = '1. '
        cursorOffset = 3 // After "1. "
      }
      break
    case 'code':
      if (hasSelection) {
        if (selectedText.includes('\n')) {
          replacement = `\`\`\`\n${selectedText}\n\`\`\``
          cursorOffset = replacement.length
        } else {
          replacement = `\`${selectedText}\``
          cursorOffset = replacement.length
        }
      } else {
        replacement = '``'
        cursorOffset = 1 // Between the backticks
      }
      break
    case 'quote':
      if (hasSelection) {
        replacement = selectedText.split('\n').map(line => `> ${line}`).join('\n')
        cursorOffset = replacement.length
      } else {
        replacement = '> '
        cursorOffset = 2 // After "> "
      }
      break
  }

  const beforeText = markdownText.value.substring(0, start)
  const afterText = markdownText.value.substring(end)
  const newText = beforeText + replacement + afterText

  markdownText.value = newText
  emit('update:modelValue', newText)

  // Use nextTick to ensure DOM is updated before setting cursor position
  nextTick(() => {
    textarea.focus()
    const newCursorPos = start + cursorOffset
    textarea.setSelectionRange(newCursorPos, newCursorPos)
  })
}
</script>

