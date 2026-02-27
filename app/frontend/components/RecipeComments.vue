<template>
  <div class="card">
    <div class="card-body p-4 sm:p-6">
      <!-- Header -->
      <h2 class="text-2xl font-bold mb-4 flex items-center gap-2">
        <i class="fas fa-comments text-cs-gold"></i>
        Kommentare
        <span class="text-base font-normal text-gray-500">({{ totalCommentCount }})</span>
      </h2>

      <!-- Filter Toolbar -->
      <div v-if="comments.length > 0" class="mb-4 space-y-2">
        <!-- Search -->
        <div class="relative">
          <i class="fas fa-search absolute left-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm pointer-events-none"></i>
          <input
            v-model="searchQuery"
            type="text"
            placeholder="Kommentare durchsuchen…"
            class="input-field pl-9 pr-9 text-sm"
          />
          <button
            v-if="searchQuery"
            @click="searchQuery = ''"
            class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 transition-colors"
            title="Suche zurücksetzen"
          >
            <i class="fas fa-times text-sm"></i>
          </button>
        </div>

        <!-- Tag Filter -->
        <div v-if="availableTags.length > 0" class="flex flex-wrap gap-1.5 items-center">
          <span class="text-xs text-gray-500">Tag:</span>
          <button
            @click="tagFilter = null"
            :class="tagFilter === null ? 'bg-blue-500 text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'"
            class="text-xs px-2 py-0.5 rounded-full font-medium transition-colors"
          >Alle</button>
          <button
            v-for="tag in availableTags"
            :key="tag"
            @click="tagFilter = tagFilter === tag ? null : tag"
            :class="tagFilter === tag ? 'bg-blue-500 text-white' : 'bg-gray-100 text-gray-500 hover:bg-gray-200'"
            class="text-xs px-2 py-0.5 rounded-full font-medium transition-colors"
          >{{ tag }}</button>
        </div>

        <!-- Active filter summary -->
        <p v-if="isFiltering" class="text-xs text-gray-500">
          {{ filteredComments.length }} von {{ comments.length }} Kommentar{{ comments.length !== 1 ? 'en' : '' }}
          <button @click="clearFilters" class="ml-1 text-cs-dark-red hover:underline">zurücksetzen</button>
        </p>
      </div>

      <!-- Comment List -->
      <div v-if="filteredComments.length > 0" class="space-y-4 mb-6">
        <CommentItem
          v-for="comment in filteredComments"
          :key="comment.id"
          :comment="comment"
          :is-authenticated="isAuthenticated"
          :is-moderator="isModerator"
          :current-user-id="currentUserId"
          :allowed-tags="allowedTags"
          @vote="handleVote"
          @delete="handleDelete"
          @submit-reply="handleSubmitReply"
          @tag-added="handleTagAdded"
          @tag-removed="handleTagRemoved"
          @edit-saved="handleEditSaved"
        />
      </div>
      <p v-else class="text-gray-500 text-sm mb-6">
        <template v-if="isFiltering">Keine Kommentare gefunden.</template>
        <template v-else>Noch keine Kommentare. Sei der Erste!</template>
      </p>

      <!-- New Comment Form -->
      <div class="border-t pt-6">
        <div v-if="isAuthenticated">
          <h3 class="text-lg font-semibold mb-3">Kommentar schreiben</h3>
          <form @submit.prevent="submitTopLevelComment" class="space-y-3">
            <div class="form-group">
              <textarea
                v-model="newCommentBody"
                class="input-field"
                :class="{ 'input-error': newCommentError }"
                rows="4"
                placeholder="Dein Kommentar..."
                maxlength="3000"
              ></textarea>
              <div class="flex justify-between items-center mt-1">
                <p v-if="newCommentError" class="form-error-message text-sm text-red-600">{{ newCommentError }}</p>
                <span class="text-xs text-gray-400 ml-auto">{{ newCommentBody.length }}/3000</span>
              </div>
            </div>
            <button
              type="submit"
              class="btn btn-primary"
              :disabled="submitting"
            >
              <span v-if="submitting"><i class="fas fa-spinner fa-spin mr-1"></i>Speichern...</span>
              <span v-else>Kommentar abschicken</span>
            </button>
          </form>
        </div>
        <div v-else class="bg-gray-50 rounded-lg p-4 border border-gray-200 text-center">
          <p class="text-gray-600 mb-2">Du musst angemeldet sein, um einen Kommentar zu schreiben.</p>
          <a href="/session/new" class="text-cs-dark-red hover:underline font-medium">Jetzt anmelden</a>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, defineProps } from 'vue'
import { useAuth } from '../composables/useAuth'
import CommentItem from './CommentItem.vue'

const props = defineProps({
  recipeSlug: { type: String, required: true }
})

const { isAuthenticated, user } = useAuth()

const comments = ref(window.recipeComments || [])
const isModerator = window.recipeCommentsMeta?.isModerator || false
const tagFilter = ref(null)
const searchQuery = ref('')
const newCommentBody = ref('')
const newCommentError = ref(null)
const submitting = ref(false)

const currentUserId = computed(() => user.value?.id ?? null)

const allowedTags = ['Markenempfehlung', 'Zubereitungstipp', 'Zutatenvariante', 'Erfahrungsbericht']

const availableTags = computed(() => {
  const tags = new Set()
  comments.value.forEach(c => c.tags?.forEach(t => tags.add(t)))
  return [...tags]
})

const isFiltering = computed(() => !!tagFilter.value || searchQuery.value.trim().length > 0)

const filteredComments = computed(() => {
  let result = comments.value

  if (tagFilter.value) {
    result = result.filter(c => c.tags?.includes(tagFilter.value))
  }

  const q = searchQuery.value.trim().toLowerCase()
  if (q) {
    result = result.filter(c =>
      c.body.toLowerCase().includes(q) ||
      c.replies?.some(r => r.body.toLowerCase().includes(q))
    )
  }

  return result
})

function clearFilters() {
  tagFilter.value = null
  searchQuery.value = ''
}

const totalCommentCount = computed(() => {
  return comments.value.reduce((sum, c) => sum + 1 + (c.replies?.length ?? 0), 0)
})

function csrfToken() {
  return document.querySelector('meta[name="csrf-token"]').content
}

async function submitTopLevelComment() {
  if (!newCommentBody.value.trim()) {
    newCommentError.value = 'Kommentar darf nicht leer sein.'
    return
  }
  newCommentError.value = null
  submitting.value = true
  try {
    const response = await fetch(`/rezepte/${props.recipeSlug}/comment`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': csrfToken()
      },
      body: JSON.stringify({ recipe_comment: { body: newCommentBody.value } })
    })
    const data = await response.json()
    if (response.ok) {
      comments.value.unshift(data)
      newCommentBody.value = ''
    } else {
      newCommentError.value = data.errors?.join(', ') || 'Fehler beim Speichern.'
    }
  } catch (e) {
    newCommentError.value = 'Netzwerkfehler. Bitte erneut versuchen.'
  } finally {
    submitting.value = false
  }
}

async function handleVote({ commentId, parentId, value }) {
  const comment = parentId
    ? comments.value.find(c => c.id === parentId)?.replies?.find(r => r.id === commentId)
    : comments.value.find(c => c.id === commentId)
  if (!comment) return

  // Optimistic update
  const previousVote = comment.current_user_vote
  const previousNet = comment.net_votes
  if (previousVote === value) {
    comment.current_user_vote = null
    comment.net_votes -= value
  } else {
    comment.net_votes = comment.net_votes - (previousVote || 0) + value
    comment.current_user_vote = value
  }

  try {
    const method = previousVote === value ? 'DELETE' : 'POST'
    const response = await fetch(`/recipe_comments/${commentId}/vote`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': csrfToken()
      },
      body: method === 'POST' ? JSON.stringify({ value }) : undefined
    })
    const data = await response.json()
    if (response.ok) {
      comment.net_votes = data.net_votes
      comment.current_user_vote = data.current_user_vote
    } else {
      // Revert
      comment.current_user_vote = previousVote
      comment.net_votes = previousNet
    }
  } catch (e) {
    comment.current_user_vote = previousVote
    comment.net_votes = previousNet
  }
}

async function handleDelete({ commentId, parentId }) {
  try {
    const response = await fetch(`/recipe_comments/${commentId}`, {
      method: 'DELETE',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': csrfToken()
      }
    })
    if (response.ok) {
      if (parentId) {
        const parent = comments.value.find(c => c.id === parentId)
        if (parent) parent.replies = parent.replies.filter(r => r.id !== commentId)
      } else {
        comments.value = comments.value.filter(c => c.id !== commentId)
      }
    }
  } catch (e) {
    console.error('Delete failed', e)
  }
}

async function handleSubmitReply({ parentId, body, resolve }) {
  try {
    const response = await fetch(`/rezepte/${props.recipeSlug}/comment`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': csrfToken()
      },
      body: JSON.stringify({ recipe_comment: { body, parent_id: parentId } })
    })
    const data = await response.json()
    if (response.ok) {
      const parent = comments.value.find(c => c.id === parentId)
      if (parent) {
        parent.replies = parent.replies || []
        parent.replies.push(data)
      }
      resolve?.({ success: true })
    } else {
      resolve?.({ success: false, error: data.errors?.join(', ') || 'Fehler.' })
    }
  } catch (e) {
    resolve?.({ success: false, error: 'Netzwerkfehler.' })
  }
}

async function handleTagAdded({ commentId, tag }) {
  try {
    const response = await fetch(`/recipe_comments/${commentId}/tag`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': csrfToken()
      },
      body: JSON.stringify({ tag })
    })
    const data = await response.json()
    if (response.ok) {
      const comment = comments.value.find(c => c.id === commentId)
      if (comment) comment.tags = data.tags
    }
  } catch (e) {
    console.error('Tag failed', e)
  }
}

async function handleTagRemoved({ commentId, tag }) {
  try {
    const response = await fetch(`/recipe_comments/${commentId}/tag?tag=${encodeURIComponent(tag)}`, {
      method: 'DELETE',
      headers: {
        'Accept': 'application/json',
        'X-CSRF-Token': csrfToken()
      }
    })
    const data = await response.json()
    if (response.ok) {
      const comment = comments.value.find(c => c.id === commentId)
      if (comment) comment.tags = data.tags
    }
  } catch (e) {
    console.error('Untag failed', e)
  }
}

async function handleEditSaved({ commentId, parentId, body, resolve }) {
  try {
    const response = await fetch(`/recipe_comments/${commentId}`, {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-CSRF-Token': csrfToken()
      },
      body: JSON.stringify({ recipe_comment: { body } })
    })
    const data = await response.json()
    if (response.ok) {
      if (parentId) {
        const parent = comments.value.find(c => c.id === parentId)
        const reply = parent?.replies?.find(r => r.id === commentId)
        if (reply) {
          reply.body = data.body
          reply.last_editor_username = data.last_editor_username
          reply.updated_at = data.updated_at
        }
      } else {
        const comment = comments.value.find(c => c.id === commentId)
        if (comment) {
          comment.body = data.body
          comment.last_editor_username = data.last_editor_username
          comment.updated_at = data.updated_at
        }
      }
      resolve?.({ success: true })
    } else {
      resolve?.({ success: false, error: data.errors?.join(', ') || 'Fehler.' })
    }
  } catch (e) {
    resolve?.({ success: false, error: 'Netzwerkfehler.' })
  }
}
</script>
