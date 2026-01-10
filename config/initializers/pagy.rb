# frozen_string_literal: true

# Pagy configuration
# https://ddnexus.github.io/pagy/
Pagy.options[:limit] = 50

# Use Rails I18n
Pagy.translate_with_the_slower_i18n_gem!
