class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :track_user_activity

  private

  def track_user_activity
    if Current.user && (Current.user.last_active_at.nil? || Current.user.last_active_at < 10.minutes.ago)
      Current.user.touch(:last_active_at)
    end
  end

  def require_admin!
    authorization_redirect unless Current.user&.admin?
  end

  def require_forum_moderator!
    authorization_redirect unless Current.user&.admin? || Current.user&.forum_moderator?
  end

  def require_recipe_moderator!
    authorization_redirect unless Current.user&.admin? || Current.user&.recipe_moderator?
  end

  def require_image_moderator!
    authorization_redirect unless Current.user&.admin? || Current.user&.image_moderator?
  end

  def authorization_redirect
    redirect_to root_path, alert: "Access denied."
  end
end
