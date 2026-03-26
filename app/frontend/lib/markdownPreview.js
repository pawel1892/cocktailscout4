import { marked } from 'marked'
import DOMPurify from 'dompurify'
import { SMILEYS } from './smileys.js'

// Wikilink pattern: [[type:ref]] or [[type:ref|Display Text]]
const WIKILINK = /\[\[([a-z]+):([a-zA-Z0-9-]+)(?:\|([^\]]+))?\]\]/g

function preprocessShortcodes(text) {
  let t = text

  // Internal wikilinks — client-side preview uses slug/id as label when no custom text;
  // the server-side renderer does DB lookups for actual titles.
  t = t.replace(WIKILINK, (_, type, ref, label) => {
    if (type === 'recipe') return `[${label || ref}](/rezepte/${ref})`
    if (type === 'thread') return `[${label || ref}](/cocktailforum/thema/${ref})`
    if (type === 'post')   return `[${label || `Beitrag #${ref}`}](/cocktailforum/beitrag/${ref})`
    return _ // unknown type: leave unchanged
  })

  // Quotes — process innermost first
  let found = true
  while (found) {
    found = false
    t = t.replace(/\[quote(?:=([^\]]*))?\]([\s\S]*?)\[\/quote\]/gi, (_, author, content) => {
      found = true
      if (author && author.trim()) {
        const a = author.trim()
        return `<figure class="md-quote"><figcaption>${a} schrieb:</figcaption><blockquote>${content.trim()}</blockquote></figure>`
      }
      return content.trim().split('\n').map(l => `> ${l}`).join('\n')
    })
  }

  return t
}

function applySmileys(html, smileys) {
  let result = html
  for (const s of smileys) {
    result = result.replace(
      s.expr,
      `<img src="/images/smileys/${s.filename}" alt="${s.name}" title="${s.shortcut}" class="inline-block align-middle h-5 w-auto">`
    )
  }
  return result
}

const ALLOWED_TAGS = [
  'p', 'br', 'strong', 'em', 'u', 'del', 's',
  'blockquote', 'figure', 'figcaption',
  'a', 'img',
  'ul', 'ol', 'li',
  'pre', 'code',
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'table', 'thead', 'tbody', 'tr', 'th', 'td',
]
const ALLOWED_ATTR = ['href', 'src', 'alt', 'title', 'class', 'rel', 'target']

export function renderMarkdown(text, smileys = SMILEYS) {
  if (!text) return ''
  try {
    const preprocessed = preprocessShortcodes(text)
    const html = marked.parse(preprocessed)
    const withSmileys = applySmileys(html, smileys)
    return DOMPurify.sanitize(withSmileys, { ALLOWED_TAGS, ALLOWED_ATTR, ALLOW_DATA_ATTR: false })
  } catch (e) {
    console.error('Markdown render error:', e)
    return '<p class="text-red-500">Fehler beim Rendern der Vorschau</p>'
  }
}
