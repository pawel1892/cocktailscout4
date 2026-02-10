# PaperTrail Configuration
PaperTrail.config.enabled = true

# Set user info for tracking who made changes
# This will be used in controllers to track the current user
PaperTrail.request.whodunnit = lambda do
  # This will be set in ApplicationController
  # Returns nil by default, controllers should set PaperTrail.request.whodunnit = current_user.id
end
