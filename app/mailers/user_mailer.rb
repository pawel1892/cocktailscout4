class UserMailer < ApplicationMailer
  # Subject can be set in your I18n file at config/locales/en.yml
  # with the following lookup:
  #
  #   en.user_mailer.welcome.subject
  #
  def test_email(user)
    @user = user
    @greeting = "Hallo"

    attachments.inline["logo.svg"] = File.read(Rails.root.join("public/logo.svg"))
    mail to: @user.email_address, subject: "CocktailScout Test Email"
  end

  def confirmation_instructions(user)
    @user = user
    @token = user.confirmation_token

    attachments.inline["logo.svg"] = File.read(Rails.root.join("public/logo.svg"))
    mail to: @user.email_address, subject: "Bestätigung deines CocktailScout Kontos"
  end

  def password_reset(user)
    @user = user
    @token = user.password_reset_token

    attachments.inline["logo.svg"] = File.read(Rails.root.join("public/logo.svg"))
    mail to: @user.email_address, subject: "Passwort zurücksetzen"
  end
end
