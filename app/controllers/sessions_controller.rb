class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create show ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def show
    if authenticated?
      render json: { user: Current.user, message: "Authenticated" }, status: :ok
    else
      render json: { user: nil, message: "Not authenticated" }, status: :ok
    end
  end

  def new
  end

  def create
    login = params[:email_address]
    user = User.find_by(email_address: login) || User.find_by(username: login)

    if user && user.authenticate(params[:password])
      user.increment!(:sign_in_count)
      start_new_session_for user
      respond_to do |format|
        format.html { redirect_to after_authentication_url }
        format.json { render json: { user: user, message: "Signed in successfully", redirect_url: after_authentication_url }, status: :ok }
      end
    else
      respond_to do |format|
        format.html { redirect_to new_session_path, alert: "Try another email address or password." }
        format.json { render json: { error: "Try another email address or password." }, status: :unauthorized }
      end
    end
  end

  def destroy
    terminate_session
    respond_to do |format|
      format.html { redirect_to new_session_path, status: :see_other }
      format.json { render json: { message: "Signed out successfully" }, status: :ok }
    end
  end
end
