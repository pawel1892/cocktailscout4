Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Capture 10% of transactions for performance monitoring
  config.traces_sample_rate = 0.1

  # Only enable in production/beta
  config.enabled_environments = %w[production beta]
end
