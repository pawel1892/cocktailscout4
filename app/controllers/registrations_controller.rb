class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      @user.send_confirmation_email!
      respond_to do |format|
        format.html { redirect_to root_path, notice: "Registrierung erfolgreich! Bitte überprüfe deine E-Mails, um dein Konto zu bestätigen." }
        format.json { render json: { message: "Registrierung erfolgreich! Bitte überprüfe deine E-Mails." }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_content }
        format.json { render json: { errors: @user.errors.full_messages }, status: :unprocessable_content }
      end
    end
  end

  private

  def user_params
    params.require(:user).permit(:email_address, :password, :password_confirmation, :username)
  end
end
