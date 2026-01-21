class PasswordChangesController < ApplicationController
  before_action :set_user

  def new
  end

  def create
    if @user.authenticate(params[:current_password])
      if @user.update(password_params)
        @user.sessions.where.not(id: Current.session).destroy_all
        redirect_to root_path, notice: "Dein Passwort wurde erfolgreich geändert."
      else
        render :new, status: :unprocessable_content
      end
    else
      flash.now[:alert] = "Das aktuelle Passwort ist falsch."
      render :new, status: :unprocessable_content
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def password_params
    params.permit(:password, :password_confirmation)
  end
end
