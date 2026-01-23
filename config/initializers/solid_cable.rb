# Configure Solid Cable to use the cable database
# This runs after Rails is fully initialized
Rails.application.configure do
  config.after_initialize do
    SolidCable.connects_to = { database: { writing: :cable } } if defined?(SolidCable)
  end
end
