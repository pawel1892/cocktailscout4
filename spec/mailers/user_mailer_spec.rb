require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "test_email" do
    let(:user) { User.new(username: "TestUser", email_address: "test@example.org") }
    let(:mail) { UserMailer.test_email(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("CocktailScout Test Email")
      expect(mail.to).to eq([ "test@example.org" ])
      expect(mail.from).to eq([ "no-reply@cocktailscout.de" ])
    end

    it "renders the body" do
      expect(mail.text_part.body.to_s).to include("Test Email für TestUser")
      expect(mail.html_part.body.to_s).to include("Test Email für TestUser")
      expect(mail.text_part.body.to_s).to include("CocktailScout System")
      expect(mail.html_part.body.to_s).to include("CocktailScout System")
    end
  end

  describe "password_reset" do
    let(:user) { create(:user, email_address: "reset@example.com", username: "ResetUser") }
    let(:mail) { UserMailer.password_reset(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Passwort zurücksetzen")
      expect(mail.to).to eq([ "reset@example.com" ])
      expect(mail.from).to eq([ "no-reply@cocktailscout.de" ])
    end

    it "renders the body" do
      expect(mail.html_part.body.to_s).to include("Passwort vergessen?")
      # The token might change between calls if not careful, but here we are calling it once.
      # However, let's just check if it contains the base url part for password edit
      expect(mail.html_part.body.to_s).to match(/passwords\/.*\/edit/)

      expect(mail.text_part.body.to_s).to include("du hast angefordert dein Passwort zurückzusetzen")
      expect(mail.text_part.body.to_s).to match(/passwords\/.*\/edit/)
    end
  end
end
