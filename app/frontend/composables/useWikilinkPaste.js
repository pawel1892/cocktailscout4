// Intercepts paste events and converts internal URLs to wikilink shortcodes.
// Handles: /rezepte/:slug → [[recipe:slug]]
//          /cocktailforum/thema/:slug → [[thread:slug]]
//          /cocktailforum/beitrag/:public_id → [[post:public_id]]
export function useWikilinkPaste({ insertText }) {
  function urlToWikilink(raw) {
    const path = raw.trim().replace(/^https?:\/\/[^/]+/, '').replace(/[?#].*$/, '')

    const recipe = path.match(/^\/rezepte\/([a-z0-9-]+)/)
    if (recipe) return `[[recipe:${recipe[1]}]]`

    const post = path.match(/^\/cocktailforum\/beitrag\/([a-zA-Z0-9]+)/)
    if (post) return `[[post:${post[1]}]]`

    const thread = path.match(/^\/cocktailforum\/thema\/([a-z0-9-]+)/)
    if (thread) return `[[thread:${thread[1]}]]`

    return null
  }

  function handlePaste(event) {
    const text = event.clipboardData?.getData('text/plain')?.trim()
    if (!text) return false

    const wikilink = urlToWikilink(text)
    if (!wikilink) return false

    event.preventDefault()
    insertText(wikilink)
    return true
  }

  return { handlePaste }
}
