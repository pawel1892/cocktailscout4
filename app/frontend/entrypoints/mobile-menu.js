// Mobile menu functionality
window.toggleMobileMenu = function(e) {
  e.stopPropagation();
  const menu = document.getElementById('mobile-menu');
  if (menu) {
    menu.classList.toggle('hidden');
  }
};

// Close menu when clicking outside
if (!window.mobileMenuClickOutsideAttached) {
  document.addEventListener('click', (e) => {
    const menu = document.getElementById('mobile-menu');
    const btn = document.getElementById('mobile-menu-btn');

    if (menu && !menu.classList.contains('hidden')) {
      if (!menu.contains(e.target) && (!btn || !btn.contains(e.target))) {
        menu.classList.add('hidden');
      }
    }
  });
  window.mobileMenuClickOutsideAttached = true;
}
