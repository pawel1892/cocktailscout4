# Configure Solid Cable to use the cable database
# This runs after Rails is fully initialized
Rails.application.configure do
  config.after_initialize do
    if defined?(SolidCable) && SolidCable.respond_to?(:connects_to=)
      SolidCable.connects_to = { database: { writing: :cable } }
    end
  end
end
