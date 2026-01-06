# frozen_string_literal: true

require "pagy/extras/overflow"
require "pagy/extras/metadata"
require "pagy/extras/i18n"

# Pagy Variables
# https://ddnexus.github.io/pagy/docs/api/pagy#variables
Pagy::DEFAULT[:limit]    = 50
Pagy::DEFAULT[:overflow] = :last_page
