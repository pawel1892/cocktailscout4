<template>
  <div :id="`comment-${comment.id}`" :class="isReply ? 'bg-gray-50' : 'bg-white rounded-lg border border-gray-200'" class="group">
    <!-- Top-level comment body -->
    <div class="p-3 sm:p-4">
      <div class="flex gap-3">
        <!-- Vote Column -->
        <div v-if="!isReply" class="flex flex-col items-center gap-1 flex-shrink-0 pt-1">
          <button
            @click="vote(1)"
            :disabled="!isAuthenticated"
            :class="comment.current_user_vote === 1 ? 'text-green-600' : 'text-gray-400 hover:text-green-500'"
            class="transition-colors disabled:opacity-40 disabled:cursor-not-allowed leading-none"
            title="Hilfreich"
          >
            <i class="fas fa-chevron-up text-sm"></i>
          </button>
          <span
            class="text-xs font-bold leading-none"
            :class="comment.net_votes > 0 ? 'text-green-600' : comment.net_votes < 0 ? 'text-red-500' : 'text-gray-500'"
          >{{ comment.net_votes }}</span>
          <button
            @click="vote(-1)"
            :disabled="!isAuthenticated"
            :class="comment.current_user_vote === -1 ? 'text-red-500' : 'text-gray-400 hover:text-red-400'"
            class="transition-colors disabled:opacity-40 disabled:cursor-not-allowed leading-none"
            title="Nicht hilfreich"
          >
            <i class="fas fa-chevron-down text-sm"></i>
          </button>
        </div>

        <!-- Comment Content -->
        <div class="flex-1 min-w-0">
          <!-- Meta row -->
          <div class="flex justify-between items-start mb-2 gap-2">
            <div class="flex items-center gap-2 flex-wrap">
              <UserBadge :user="comment.user" class="text-sm" />
              <span class="text-xs text-gray-400">{{ formatDate(comment.created_at) }}</span>
              <!-- Tags: view mode (static badges + edit trigger for mods) -->
              <template v-if="!editingTags">
                <span
                  v-for="tag in comment.tags"
                  :key="tag"
                  class="inline-flex items-center bg-blue-100 text-blue-700 text-xs px-2 py-0.5 rounded-full font-medium"
                >{{ tag }}</span>
                <button
                  v-if="comment.can_tag && !isReply"
                  @click="editingTags = true"
                  class="text-gray-300 hover:text-gray-500 transition-colors leading-none opacity-0 group-hover:opacity-100 transition-opacity"
                  title="Tags bearbeiten"
                ><i class="fas fa-tag text-xs"></i></button>
              </template>

              <!-- Tags: edit mode (toggle buttons for all allowed tags) -->
              <template v-else>
                <button
                  v-for="tag in allowedTags"
                  :key="tag"
                  @click="toggleTag(tag)"
                  :class="comment.tags?.includes(tag)
                    ? 'bg-blue-500 text-white'
                    : 'bg-gray-100 text-gray-500 hover:bg-gray-200'"
                  class="text-xs px-2 py-0.5 rounded-full font-medium transition-colors"
                >{{ tag }}</button>
                <button
                  @click="editingTags = false"
                  class="text-xs text-gray-400 hover:text-gray-600 transition-colors"
                >Fertig</button>
              </template>
            </div>

            <!-- Action buttons -->
            <div class="flex items-center gap-2 flex-shrink-0 opacity-0 group-hover:opacity-100 transition-opacity">
              <button
                v-if="comment.can_edit && !editing"
                @click="startEdit"
                class="text-gray-400 hover:text-cs-gold transition-colors"
                title="Bearbeiten"
              >
                <i class="fas fa-pencil-alt text-xs"></i>
              </button>
              <button
                v-if="comment.can_delete"
                @click="confirmDelete"
                class="text-gray-400 hover:text-cs-error transition-colors"
                title="Löschen"
              >
                <i class="fas fa-trash text-xs"></i>
              </button>
            </div>
          </div>

          <!-- Body (view mode) -->
          <div v-if="!editing" class="text-gray-700 text-sm whitespace-pre-wrap break-words">{{ comment.body }}</div>

          <!-- Body (edit mode) -->
          <div v-else class="space-y-2">
            <textarea
              v-model="editBody"
              class="input-field text-sm"
              rows="4"
              maxlength="3000"
            ></textarea>
            <div class="flex gap-2">
              <button @click="saveEdit" :disabled="editSaving" class="btn btn-primary btn-sm">
                <span v-if="editSaving"><i class="fas fa-spinner fa-spin mr-1"></i></span>Speichern
              </button>
              <button @click="cancelEdit" class="btn btn-outline btn-sm">Abbrechen</button>
            </div>
            <p v-if="editError" class="text-red-600 text-xs">{{ editError }}</p>
          </div>

          <!-- Last editor note -->
          <div v-if="comment.last_editor_username" class="text-xs text-gray-400 mt-1">
            Bearbeitet von {{ comment.last_editor_username }}
          </div>

          <!-- Reply + collapse controls (top-level only) -->
          <div v-if="!isReply" class="mt-3 flex items-center gap-4 text-xs text-gray-500">
            <button
              v-if="isAuthenticated"
              @click="showReplyForm = !showReplyForm"
              class="hover:text-cs-dark-red transition-colors font-medium"
            >
              <i class="fas fa-reply mr-1"></i>{{ showReplyForm ? 'Abbrechen' : 'Antworten' }}
            </button>
            <button
              v-if="comment.replies?.length > 0"
              @click="repliesExpanded = !repliesExpanded"
              class="hover:text-gray-700 transition-colors"
            >
              <i :class="repliesExpanded ? 'fas fa-chevron-up' : 'fas fa-chevron-down'" class="mr-1"></i>
              {{ repliesExpanded ? 'Antworten ausblenden' : `${comment.replies.length} Antwort${comment.replies.length !== 1 ? 'en' : ''} anzeigen` }}
            </button>
          </div>
        </div>
      </div>
    </div>

    <!-- Reply Form -->
    <div v-if="!isReply && showReplyForm" class="border-t border-gray-200 px-3 pb-3 sm:px-4 sm:pb-4 pt-3">
      <form @submit.prevent="submitReply" class="space-y-2">
        <textarea
          v-model="replyBody"
          class="input-field text-sm"
          :class="{ 'input-error': replyError }"
          rows="3"
          placeholder="Deine Antwort..."
          maxlength="3000"
        ></textarea>
        <div class="flex items-center gap-2">
          <button type="submit" :disabled="replySubmitting" class="btn btn-primary btn-sm">
            <span v-if="replySubmitting"><i class="fas fa-spinner fa-spin mr-1"></i></span>Antworten
          </button>
          <p v-if="replyError" class="text-red-600 text-xs">{{ replyError }}</p>
        </div>
      </form>
    </div>

    <!-- Replies -->
    <div v-if="!isReply && repliesExpanded && comment.replies?.length > 0" class="border-t border-gray-200">
      <div class="pl-4 sm:pl-8 space-y-0 divide-y divide-gray-100">
        <CommentItem
          v-for="reply in comment.replies"
          :key="reply.id"
          :comment="reply"
          :is-reply="true"
          :parent-id="comment.id"
          :is-authenticated="isAuthenticated"
          :is-moderator="false"
          :current-user-id="currentUserId"
          :allowed-tags="allowedTags"
          @vote="$emit('vote', $event)"
          @delete="$emit('delete', $event)"
          @submit-reply="$emit('submit-reply', $event)"
          @tag-added="$emit('tag-added', $event)"
          @tag-removed="$emit('tag-removed', $event)"
          @edit-saved="$emit('edit-saved', $event)"
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, defineProps, defineEmits } from 'vue'
import UserBadge from './UserBadge.vue'

const props = defineProps({
  comment: { type: Object, required: true },
  isReply: { type: Boolean, default: false },
  parentId: { type: Number, default: null },
  isAuthenticated: { type: Boolean, default: false },
  isModerator: { type: Boolean, default: false },
  currentUserId: { type: Number, default: null },
  allowedTags: { type: Array, default: () => [] }
})

const emit = defineEmits(['vote', 'delete', 'submit-reply', 'tag-added', 'tag-removed', 'edit-saved'])

// Replies collapsed by default when > 3
const repliesExpanded = ref((props.comment.replies?.length ?? 0) <= 3)
const showReplyForm = ref(false)
const replyBody = ref('')
const replyError = ref(null)
const replySubmitting = ref(false)

const editing = ref(false)
const editBody = ref('')
const editError = ref(null)
const editSaving = ref(false)

const editingTags = ref(false)

function formatDate(iso) {
  if (!iso) return ''
  return new Date(iso).toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit', year: 'numeric' })
}

function vote(value) {
  emit('vote', { commentId: props.comment.id, parentId: props.parentId, value })
}

function confirmDelete() {
  if (confirm('Kommentar wirklich löschen?')) {
    emit('delete', { commentId: props.comment.id, parentId: props.parentId })
  }
}

function startEdit() {
  editBody.value = props.comment.body
  editError.value = null
  editing.value = true
}

function cancelEdit() {
  editing.value = false
}

async function saveEdit() {
  if (!editBody.value.trim()) {
    editError.value = 'Kommentar darf nicht leer sein.'
    return
  }
  editSaving.value = true
  editError.value = null
  const result = await new Promise(resolve => {
    emit('edit-saved', {
      commentId: props.comment.id,
      parentId: props.parentId,
      body: editBody.value,
      resolve
    })
    // Parent will call resolve via the event handling chain
    // Use timeout fallback
    setTimeout(() => resolve({ success: false, error: 'Timeout' }), 10000)
  })
  editSaving.value = false
  if (result?.success) {
    editing.value = false
  } else {
    editError.value = result?.error || 'Fehler beim Speichern.'
  }
}

async function submitReply() {
  if (!replyBody.value.trim()) {
    replyError.value = 'Antwort darf nicht leer sein.'
    return
  }
  replyError.value = null
  replySubmitting.value = true
  const result = await new Promise(resolve => {
    emit('submit-reply', {
      parentId: props.comment.id,
      body: replyBody.value,
      resolve
    })
    setTimeout(() => resolve({ success: false, error: 'Timeout' }), 10000)
  })
  replySubmitting.value = false
  if (result?.success) {
    replyBody.value = ''
    showReplyForm.value = false
    repliesExpanded.value = true
  } else {
    replyError.value = result?.error || 'Fehler beim Senden.'
  }
}

function toggleTag(tag) {
  if (props.comment.tags?.includes(tag)) {
    emit('tag-removed', { commentId: props.comment.id, tag })
  } else {
    emit('tag-added', { commentId: props.comment.id, tag })
  }
}
</script>
