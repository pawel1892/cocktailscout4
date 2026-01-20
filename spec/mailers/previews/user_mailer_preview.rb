# Preview all emails at http://localhost:3000/rails/mailers/user_mailer_mailer
class UserMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/test_email
  def test_email
    user = User.new(username: "Zoidberg", email_address: "zoidberg@example.com")
    UserMailer.test_email(user)
  end

  # Preview this email at http://localhost:3000/rails/mailers/user_mailer/confirmation_instructions
  def confirmation_instructions
    user = User.new(username: "Bender", email_address: "bender@example.com", confirmation_token: "fake-token")
    UserMailer.confirmation_instructions(user)
  end
end
