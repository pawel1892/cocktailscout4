require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "test_email" do
    let(:user) { User.new(username: "TestUser", email_address: "test@example.org") }
    let(:mail) { UserMailer.test_email(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("CocktailScout Test Email")
      expect(mail.to).to eq([ "test@example.org" ])
      expect(mail.from).to eq([ "from@example.com" ])
    end

    it "renders the body" do
      expect(mail.text_part.body.to_s).to include("Test Email für TestUser")
      expect(mail.html_part.body.to_s).to include("Test Email für TestUser")
      expect(mail.text_part.body.to_s).to include("CocktailScout System")
      expect(mail.html_part.body.to_s).to include("CocktailScout System")
    end
  end
end
