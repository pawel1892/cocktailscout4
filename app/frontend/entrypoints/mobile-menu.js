const menu = () => document.getElementById('mobile-menu')
const backdrop = () => document.getElementById('mobile-menu-backdrop')
const button = () => document.getElementById('mobile-menu-btn')
const menuContent = () => document.getElementById('mobile-menu-content')
const siteHeader = () => document.getElementById('site-header')

const setExpanded = (expanded) => {
  const btn = button()
  if (btn) btn.setAttribute('aria-expanded', expanded ? 'true' : 'false')
}

window.openMobileMenu = function() {
  const panel = menu()
  const scrim = backdrop()
  if (!panel || !scrim) return

  scrim.classList.remove('hidden')
  panel.setAttribute('aria-hidden', 'false')
  document.documentElement.classList.add('overflow-hidden')
  setExpanded(true)

  requestAnimationFrame(() => {
    scrim.classList.remove('opacity-0')
    panel.classList.remove('translate-x-full')
  })
}

window.closeMobileMenu = function() {
  const panel = menu()
  const scrim = backdrop()
  if (!panel || !scrim) return

  scrim.classList.add('opacity-0')
  panel.classList.add('translate-x-full')
  panel.setAttribute('aria-hidden', 'true')
  document.documentElement.classList.remove('overflow-hidden')
  setExpanded(false)

  menuContent()?.classList.remove('opacity-50', 'pointer-events-none')

  window.setTimeout(() => {
    if (panel.classList.contains('translate-x-full')) {
      scrim.classList.add('hidden')
    }
  }, 200)
}

window.toggleMobileMenu = function(event) {
  event?.stopPropagation()
  const panel = menu()
  if (!panel) return

  if (panel.classList.contains('translate-x-full')) {
    window.openMobileMenu()
  } else {
    window.closeMobileMenu()
  }
}

if (!window.mobileMenuListenersAttached) {
  let rafPending = false
  let scrollLocked = false
  const updateHeaderState = () => {
    if (rafPending || scrollLocked) return
    rafPending = true
    requestAnimationFrame(() => {
      const header = siteHeader()
      if (header) {
        const scrolled = header.hasAttribute('data-scrolled')
        let changed = false
        if (!scrolled && window.scrollY > 32) {
          header.setAttribute('data-scrolled', 'true')
          changed = true
        } else if (scrolled && window.scrollY < 16) {
          header.removeAttribute('data-scrolled')
          changed = true
        }
        if (changed) {
          scrollLocked = true
          setTimeout(() => { scrollLocked = false }, 400)
        }
      }
      rafPending = false
    })
  }

  updateHeaderState()
  window.addEventListener('scroll', updateHeaderState, { passive: true })

  document.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') window.closeMobileMenu()
  })

  document.addEventListener('click', (event) => {
    const panel = menu()
    const btn = button()
    if (!panel || panel.classList.contains('translate-x-full')) return
    if (!panel.contains(event.target) && (!btn || !btn.contains(event.target))) {
      window.closeMobileMenu()
    }
  })

  document.addEventListener('click', (event) => {
    const target = event.target
    if (target instanceof Element && target.closest('#mobile-menu a')) {
      window.closeMobileMenu()
    }
  })

  window.addEventListener('drawer-user-menu', (e) => {
    const content = menuContent()
    if (!content) return
    content.classList.toggle('opacity-50', e.detail.open)
    content.classList.toggle('pointer-events-none', e.detail.open)
  })

  window.mobileMenuListenersAttached = true
}
