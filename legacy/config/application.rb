require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Cocktailperlen
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.autoload_paths += %W(#{config.root}/lib/)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]

    config.time_zone = 'Berlin'
    config.i18n.enforce_available_locales = true
    config.i18n.default_locale = :de

    config.action_mailer.default_url_options = { host: 'www.cocktailscout.de' }

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'

    # from old rails 3.2 app
    # still needed?
    # config.encoding = "utf-8"
    # config.active_support.escape_html_entities_in_json = true

    # config.assets.enabled = true

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end


require File.expand_path('../boot', __FILE__)

require 'rails/all'

Bundler.require(:default, Rails.env)
