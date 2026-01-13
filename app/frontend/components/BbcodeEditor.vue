<template>
  <div class="bbcode-editor">
    <!-- Toolbar -->
    <div class="flex flex-wrap gap-2 mb-2 p-2 bg-gray-50 border border-gray-200 rounded-t">
      <button type="button" @click="wrapText('[b]', '[/b]')" class="p-1 px-2 rounded hover:bg-gray-200 font-bold" title="Fett">B</button>
      <button type="button" @click="wrapText('[i]', '[/i]')" class="p-1 px-2 rounded hover:bg-gray-200 italic" title="Kursiv">I</button>
      <button type="button" @click="wrapText('[u]', '[/u]')" class="p-1 px-2 rounded hover:bg-gray-200 underline" title="Unterstrichen">U</button>
      <button type="button" @click="insertUrl" class="p-1 px-2 rounded hover:bg-gray-200" title="Link"><i class="fas fa-link"></i></button>
      <button type="button" @click="insertImage" class="p-1 px-2 rounded hover:bg-gray-200" title="Bild"><i class="far fa-image"></i></button>
      <button type="button" @click="wrapText('[quote]', '[/quote]')" class="p-1 px-2 rounded hover:bg-gray-200" title="Zitat"><i class="fas fa-quote-right"></i></button>
      
      <!-- Smiley Toggle -->
      <div class="relative ml-auto">
        <button type="button" @click="showSmileys = !showSmileys" class="p-1 px-2 rounded hover:bg-gray-200" title="Smileys">
          <i class="far fa-smile"></i>
        </button>
        <!-- Smiley Picker -->
        <div v-if="showSmileys" class="absolute right-0 top-full mt-1 w-64 p-2 bg-white border border-gray-200 shadow-lg rounded z-10 grid grid-cols-5 gap-1">
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
    </div>

    <!-- Textarea -->
    <textarea
      ref="textareaRef"
      v-model="content"
      :id="textareaId"
      :name="textareaName"
      class="w-full px-4 py-3 border border-gray-300 rounded-b-lg focus:ring-2 focus:ring-cs-dark-red focus:border-transparent resize-y min-h-[300px] font-mono text-sm"
      placeholder="Schreibe deinen Beitrag..."
      @input="$emit('update:modelValue', content)"
    ></textarea>
  </div>
</template>

<script setup>
import { ref, defineProps, defineEmits } from 'vue'

const props = defineProps({
  modelValue: { type: String, default: '' },
  textareaId: { type: String, required: true },
  textareaName: { type: String, required: true },
  smileys: { type: Array, default: () => [] }
})

const emit = defineEmits(['update:modelValue'])

const content = ref(props.modelValue)
const textareaRef = ref(null)
const showSmileys = ref(false)

const wrapText = (openTag, closeTag) => {
  const textarea = textareaRef.value
  if (!textarea) return

  const start = textarea.selectionStart
  const end = textarea.selectionEnd
  const selectedText = content.value.substring(start, end)
  
  const replacement = openTag + selectedText + closeTag
  
  content.value = content.value.substring(0, start) + replacement + content.value.substring(end)
  
  // Restore cursor/selection
  // We need to wait for Vue to update DOM? No, v-model is synchronous enough here usually
  // but let's use nextTick if needed. For now simple logic.
  emit('update:modelValue', content.value)
  
  setTimeout(() => {
    textarea.focus()
    textarea.selectionStart = start + openTag.length
    textarea.selectionEnd = end + openTag.length
  }, 0)
}

const insertText = (text) => {
  const textarea = textareaRef.value
  if (!textarea) return

  const start = textarea.selectionStart
  const end = textarea.selectionEnd
  
  content.value = content.value.substring(0, start) + text + content.value.substring(end)
  emit('update:modelValue', content.value)
  
  setTimeout(() => {
    textarea.focus()
    textarea.selectionStart = textarea.selectionEnd = start + text.length
  }, 0)
}

const insertUrl = () => {
  const url = prompt("Bitte gib die URL ein:", "https://")
  if (url) {
    wrapText(`[url=${url}]`, "[/url]")
  }
}

const insertImage = () => {
  const url = prompt("Bitte gib die Bild-URL ein:", "https://")
  if (url) {
    insertText(`[img]${url}[/img]`)
  }
}
</script>

<style scoped>
/* Optional specific styles */
</style>
