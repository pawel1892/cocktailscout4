import { marked } from 'marked'
import DOMPurify from 'dompurify'
import { SMILEYS } from './smileys.js'

const IMAGE_SIZE_CLASSES = { medium: 'max-w-lg', small: 'max-w-xs' }

marked.use({
  renderer: {
    image(href, title, text) {
      const sizeKey      = title?.toLowerCase() ?? ''
      const sizeClass    = IMAGE_SIZE_CLASSES[sizeKey] ?? 'max-w-full'
      const displayTitle = IMAGE_SIZE_CLASSES[sizeKey] ? null : title
      const titleAttr    = displayTitle ? ` title="${displayTitle}"` : ''
      return `<img src="${href}" alt="${text ?? ''}"${titleAttr} class="${sizeClass} h-auto rounded my-2">`
    }
  }
})

// Wikilink pattern: [[type:ref]] or [[type:ref|Display Text]]
const WIKILINK = /\[\[([a-z]+):([a-zA-Z0-9-]+)(?:\|([^\]]+))?\]\]/g

function preprocessShortcodes(text) {
  let t = text

  // Protect fenced code blocks and inline code spans from shortcode processing.
  const placeholders = new Map()
  let idx = 0
  const placeholder = () => `\x00PLACEHOLDER_${idx++}\x00`

  // Fenced code blocks: ```...```
  t = t.replace(/^(`{3,}|~{3,}).*?\n[\s\S]*?\n\1[ \t]*$/gm, match => {
    const key = placeholder()
    placeholders.set(key, match)
    return key
  })

  // Inline code spans: ` or ``
  t = t.replace(/(`{1,2})(?!`)(.+?)\1(?!`)/gs, match => {
    const key = placeholder()
    placeholders.set(key, match)
    return key
  })

  // Strip leading spaces from table row lines so marked recognises them as tables.
  t = t.replace(/^ +(\|)/gm, '$1')

  // Internal wikilinks — client-side preview uses slug/id as label when no custom text;
  // the server-side renderer does DB lookups for actual titles.
  t = t.replace(WIKILINK, (_, type, ref, label) => {
    if (type === 'recipe') return `[${label || ref}](/rezepte/${ref})`
    if (type === 'thread') return `[${label || ref}](/cocktailforum/thema/${ref})`
    if (type === 'post')   return `[${label || `Beitrag #${ref}`}](/cocktailforum/beitrag/${ref})`
    if (type === 'wiki')   return `[${label || ref}](/wiki/${ref})`
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

  // Restore protected code spans and blocks
  for (const [key, value] of placeholders) {
    t = t.replaceAll(key, value)
  }

  return t
}

function applySmileys(html, smileys) {
  // Protect <code> and <pre> content from smiley replacement
  const safe = new Map()
  let idx = 0
  let result = html.replace(/<(pre|code)(\s[^>]*)?>[\s\S]*?<\/\1>/gi, match => {
    const key = `\x00SMILEY_SAFE_${idx++}\x00`
    safe.set(key, match)
    return key
  })

  for (const s of smileys) {
    result = result.replace(
      s.expr,
      `<img src="/images/smileys/${s.filename}" alt="${s.name}" title="${s.shortcut}" class="inline-block align-middle h-5 w-auto">`
    )
  }

  for (const [key, value] of safe) result = result.replaceAll(key, value)
  return result
}

const ALLOWED_TAGS = [
  'p', 'br', 'hr', 'strong', 'em', 'u', 'del', 's',
  'blockquote', 'figure', 'figcaption',
  'a', 'img',
  'ul', 'ol', 'li',
  'pre', 'code',
  'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
  'table', 'thead', 'tbody', 'tr', 'th', 'td',
]
const ALLOWED_ATTR = ['href', 'src', 'alt', 'title', 'class', 'rel', 'target', 'align']

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
