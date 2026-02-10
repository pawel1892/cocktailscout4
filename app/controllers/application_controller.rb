class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Method
  include MetaTagsHelper
  helper BreadcrumbsHelper
  helper NavigationHelper
  helper_method :breadcrumbs

  # HTTP Basic Auth for beta environment
  if Rails.env.beta?
    http_basic_authenticate_with(
      name: ENV.fetch("BETA_AUTH_USERNAME", "hemingway"),
      password: ENV.fetch("BETA_AUTH_PASSWORD")
    )
  end

  before_action :set_initial_breadcrumbs
  before_action :track_user_activity
  before_action :set_paper_trail_whodunnit

  def add_breadcrumb(name, path = nil)
    breadcrumbs << { name: name, path: path }
  end

  def breadcrumbs
    @breadcrumbs ||= []
  end

  private

  def set_initial_breadcrumbs
    add_breadcrumb "Startseite", root_path
  end

  def track_user_activity
    if Current.user && (Current.user.last_active_at.nil? || Current.user.last_active_at < 10.minutes.ago)
      Current.user.touch(:last_active_at)
    end
  end

  def require_admin!
    authorization_redirect unless Current.user&.admin?
  end

  def require_forum_moderator!
    authorization_redirect unless Current.user&.can_moderate_forum?
  end

  def require_recipe_moderator!
    authorization_redirect unless Current.user&.can_moderate_recipe?
  end

  def require_image_moderator!
    authorization_redirect unless Current.user&.can_moderate_image?
  end

  def authorization_redirect
    redirect_to root_path, alert: "Access denied."
  end

  def set_paper_trail_whodunnit
    PaperTrail.request.whodunnit = Current.user&.id
  end
end
