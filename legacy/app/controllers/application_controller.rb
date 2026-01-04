class ApplicationController < ActionController::Base

  protect_from_forgery with: :null_session

  before_action :set_user_activity
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :store_current_location, :unless => :devise_controller?
  before_action :set_paper_trail_whodunnit

  add_flash_types :error

  add_breadcrumb "Startseite", :root_path

  rescue_from CanCan::AccessDenied do |exception|
    if current_user
      flash[:error] = 'Zugriff verweigert'
      redirect_to root_url
    else
      flash[:error] = 'Bitte melde Dich an'
      redirect_to new_user_session_path
    end
  end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name, :email, :password, :password_confirmation])
  end

  private

  def set_user_activity
    if current_user
      current_user.touch :last_active_at
    end
  end

  # override the devise helper to store the current location so we can
  # redirect to it after loggin in or out. This override makes signing in
  # and signing up work automatically.
  def store_current_location
    store_location_for(:user, request.url) unless request.format.json?
  end
end
