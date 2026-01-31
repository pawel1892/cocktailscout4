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

// Navigation dropdown functionality for touch devices
const initDropdowns = () => {
  const dropdownButtons = document.querySelectorAll('.nav-dropdown-toggle');

  dropdownButtons.forEach(button => {
    button.addEventListener('click', function(e) {
      e.preventDefault();
      e.stopPropagation();

      const dropdown = this.closest('.nav-dropdown-container');
      const isOpen = dropdown.classList.contains('dropdown-open');

      // Close all other dropdowns
      document.querySelectorAll('.nav-dropdown-container').forEach(d => {
        d.classList.remove('dropdown-open');
      });

      // Toggle this dropdown
      if (!isOpen) {
        dropdown.classList.add('dropdown-open');
      }
    });
  });

  // Close dropdown when clicking outside
  if (!window.dropdownClickOutsideAttached) {
    document.addEventListener('click', function(e) {
      if (!e.target.closest('.nav-dropdown-container')) {
        document.querySelectorAll('.nav-dropdown-container').forEach(d => {
          d.classList.remove('dropdown-open');
        });
      }
    });
    window.dropdownClickOutsideAttached = true;
  }
};

// Initialize dropdowns when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initDropdowns);
} else {
  initDropdowns();
}
