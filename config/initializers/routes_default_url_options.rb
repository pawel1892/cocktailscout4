Rails.application.config.after_initialize do
  options = Rails.application.config.action_controller.default_url_options
  Rails.application.routes.default_url_options = options if options.present?
end
