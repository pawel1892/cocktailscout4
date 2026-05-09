<template><!-- renderless --></template>

<script setup>
import { onMounted, onUnmounted } from 'vue'

const menu = () => document.getElementById('mobile-menu')
const backdrop = () => document.getElementById('mobile-menu-backdrop')
const button = () => document.getElementById('mobile-menu-btn')
const menuContent = () => document.getElementById('mobile-menu-content')
const siteHeader = () => document.getElementById('site-header')

// ── Mobile menu ──────────────────────────────────────────────────────────────

function openMobileMenu() {
  const panel = menu()
  const scrim = backdrop()
  if (!panel || !scrim) return

  scrim.classList.remove('hidden')
  panel.setAttribute('aria-hidden', 'false')
  document.documentElement.classList.add('overflow-hidden')
  button()?.setAttribute('aria-expanded', 'true')

  requestAnimationFrame(() => {
    scrim.classList.remove('opacity-0')
    panel.classList.remove('translate-x-full')
  })
}

function closeMobileMenu() {
  const panel = menu()
  const scrim = backdrop()
  if (!panel || !scrim) return

  scrim.classList.add('opacity-0')
  panel.classList.add('translate-x-full')
  panel.setAttribute('aria-hidden', 'true')
  document.documentElement.classList.remove('overflow-hidden')
  button()?.setAttribute('aria-expanded', 'false')
  menuContent()?.classList.remove('opacity-50', 'pointer-events-none')

  setTimeout(() => {
    if (panel.classList.contains('translate-x-full')) scrim.classList.add('hidden')
  }, 200)
}

function toggleMobileMenu(event) {
  event?.stopPropagation()
  const panel = menu()
  if (!panel) return
  panel.classList.contains('translate-x-full') ? openMobileMenu() : closeMobileMenu()
}

// Expose to window for ERB inline onclick handlers
window.openMobileMenu = openMobileMenu
window.closeMobileMenu = closeMobileMenu
window.toggleMobileMenu = toggleMobileMenu

// ── Desktop megamenu ─────────────────────────────────────────────────────────

const CLOSED = ['invisible', 'pointer-events-none', 'opacity-0', 'translate-y-1']
const OPEN = ['opacity-100', 'translate-y-0']

function suppressActiveNavIndicators(exceptButton = null) {
  document.querySelectorAll('[data-desktop-nav-button][aria-current="page"]').forEach((btn) => {
    if (btn === exceptButton) return
    btn.classList.remove('after:scale-x-100', 'text-white')
    btn.classList.add('after:scale-x-0', 'text-cs-ink-50/70')
  })
}

function restoreActiveNavIndicators() {
  document.querySelectorAll('[data-desktop-nav-button][aria-current="page"]').forEach((btn) => {
    btn.classList.remove('after:scale-x-0', 'text-cs-ink-50/70')
    btn.classList.add('after:scale-x-100', 'text-white')
  })
}

function closeDesktopNavMenus(except = null) {
  document.querySelectorAll('[data-desktop-nav-menu]').forEach((el) => {
    if (el === except) return
    el.querySelector('[data-desktop-nav-button]')?.setAttribute('aria-expanded', 'false')
    const panel = el.querySelector('[data-desktop-nav-panel]')
    panel?.classList.add(...CLOSED)
    panel?.classList.remove(...OPEN)
    el.querySelector('[data-desktop-nav-chevron]')?.classList.remove('rotate-180', 'opacity-85')
  })
  if (!except) restoreActiveNavIndicators()
}

function toggleDesktopNavMenu(trigger) {
  const menuEl = trigger.closest('[data-desktop-nav-menu]')
  const panel = menuEl?.querySelector('[data-desktop-nav-panel]')
  const chevron = menuEl?.querySelector('[data-desktop-nav-chevron]')
  if (!menuEl || !panel) return

  const open = trigger.getAttribute('aria-expanded') === 'true'
  closeDesktopNavMenus(menuEl)

  trigger.setAttribute('aria-expanded', open ? 'false' : 'true')
  panel.classList.toggle('invisible', open)
  panel.classList.toggle('pointer-events-none', open)
  panel.classList.toggle('opacity-0', open)
  panel.classList.toggle('translate-y-1', open)
  panel.classList.toggle('opacity-100', !open)
  panel.classList.toggle('translate-y-0', !open)
  chevron?.classList.toggle('rotate-180', !open)
  chevron?.classList.toggle('opacity-85', !open)

  if (!open) {
    suppressActiveNavIndicators(trigger)
  } else {
    restoreActiveNavIndicators()
  }
}

// ── Scroll state ─────────────────────────────────────────────────────────────

let rafPending = false
let scrollLocked = false

function updateHeaderState() {
  if (rafPending || scrollLocked) return
  rafPending = true
  requestAnimationFrame(() => {
    const header = siteHeader()
    if (header) {
      const scrolled = header.hasAttribute('data-scrolled')
      if (!scrolled && window.scrollY > 32) {
        header.setAttribute('data-scrolled', 'true')
        scrollLocked = true
        setTimeout(() => { scrollLocked = false }, 400)
      } else if (scrolled && window.scrollY < 16) {
        header.removeAttribute('data-scrolled')
        scrollLocked = true
        setTimeout(() => { scrollLocked = false }, 400)
      }
    }
    rafPending = false
  })
}

// ── Event handlers ────────────────────────────────────────────────────────────

function handleKeydown(e) {
  if (e.key === 'Escape') {
    closeMobileMenu()
    closeDesktopNavMenus()
  }
}

function handleClick(e) {
  const target = e.target
  if (!(target instanceof Element)) return

  const desktopTrigger = target.closest('[data-desktop-nav-button]')
  if (desktopTrigger) {
    e.stopPropagation()
    toggleDesktopNavMenu(desktopTrigger)
    return
  }

  if (!target.closest('[data-desktop-nav-menu]')) closeDesktopNavMenus()

  // Close mobile menu on outside click
  const panel = menu()
  const btn = button()
  if (panel && !panel.classList.contains('translate-x-full')) {
    if (!panel.contains(target) && !btn?.contains(target)) closeMobileMenu()
  }

  // Close mobile menu when a nav link inside it is followed
  if (target.closest('#mobile-menu a')) closeMobileMenu()
}

function handleFocusin(e) {
  if (e.target instanceof Element && !e.target.closest('[data-desktop-nav-menu]')) {
    closeDesktopNavMenus()
  }
}

function handleDrawerUserMenu(e) {
  const content = menuContent()
  if (!content) return
  content.classList.toggle('opacity-50', e.detail.open)
  content.classList.toggle('pointer-events-none', e.detail.open)
}

// ── Lifecycle ─────────────────────────────────────────────────────────────────

onMounted(() => {
  updateHeaderState()
  window.addEventListener('scroll', updateHeaderState, { passive: true })
  document.addEventListener('keydown', handleKeydown)
  document.addEventListener('click', handleClick)
  document.addEventListener('focusin', handleFocusin)
  window.addEventListener('drawer-user-menu', handleDrawerUserMenu)
})

onUnmounted(() => {
  window.removeEventListener('scroll', updateHeaderState)
  document.removeEventListener('keydown', handleKeydown)
  document.removeEventListener('click', handleClick)
  document.removeEventListener('focusin', handleFocusin)
  window.removeEventListener('drawer-user-menu', handleDrawerUserMenu)
  delete window.openMobileMenu
  delete window.closeMobileMenu
  delete window.toggleMobileMenu
})
</script>
