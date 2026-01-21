class EmailChangesController < ApplicationController
  allow_unauthenticated_access only: :edit
  before_action :set_user, only: [ :new, :create ]

  def new
  end

  def create
    if @user.update(email_change_params)
      UserMailer.email_change_confirmation(@user).deliver_later
      redirect_to new_email_change_path, notice: "Eine Bestätigungs-E-Mail wurde an #{@user.unconfirmed_email} gesendet."
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
    if user = User.find_by_token_for(:email_change, params[:token])
      user.update!(email_address: user.unconfirmed_email, unconfirmed_email: nil)
      start_new_session_for(user)
      redirect_to root_path, notice: "Deine E-Mail-Adresse wurde erfolgreich geändert."
    else
      redirect_to root_path, alert: "Der Bestätigungslink ist ungültig oder abgelaufen."
    end
  end

  private

  def set_user
    @user = Current.user
  end

  def email_change_params
    params.require(:user).permit(:unconfirmed_email)
  end
end
