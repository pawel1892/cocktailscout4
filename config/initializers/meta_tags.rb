# frozen_string_literal: true

# Configure default meta tags for the application
MetaTags.configure do |config|
  # Set default values for meta tags
  config.title_limit        = 70
  config.description_limit  = 160
  config.keywords_limit     = 255
  config.keywords_separator = ", "
end
