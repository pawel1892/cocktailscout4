class ConfirmationsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create edit ]

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      if user.confirmed?
        redirect_to new_session_path, notice: "Dein Konto ist bereits bestätigt. Bitte melde dich an."
      else
        user.send_confirmation_email!
        redirect_to new_session_path, notice: "Eine neue Bestätigungs-E-Mail wurde gesendet."
      end
    else
      redirect_to new_confirmation_path, alert: "Diese E-Mail-Adresse ist uns nicht bekannt."
    end
  end

  def edit
    if user = User.find_by(confirmation_token: params[:token])
      user.confirm!
      start_new_session_for user
      redirect_to after_authentication_url, notice: "Dein Konto wurde erfolgreich bestätigt! Du bist jetzt angemeldet."
    else
      redirect_to new_confirmation_path, alert: "Der Bestätigungslink ist ungültig oder abgelaufen."
    end
  end
end
