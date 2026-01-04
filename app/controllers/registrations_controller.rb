class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
  end

  def create
    user = User.new(user_params)
    if user.save
      start_new_session_for user
      respond_to do |format|
        format.html { redirect_to root_path, notice: "Welcome!" }
        format.json { render json: { user: user, message: "Welcome!" }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: user.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end
