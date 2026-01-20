require "rails_helper"

RSpec.describe "Confirmations", type: :request do
  let(:user) { User.create!(username: "NewUser", email_address: "newuser@example.com", password: "password", password_confirmation: "password") } # This creates an unconfirmed user because create! triggers before_create hooks but doesn't use factory defaults if called directly like this, wait.
  # Actually factory usage is preferred.
  # But the spec uses User.create!.
  # If I change factory, User.create! is unaffected.
  # So the spec logic is fine as is (create! makes unconfirmed user).


  describe "GET /confirmations/edit" do
    it "confirms the user and logs them in with a valid token" do
      token = user.confirmation_token
      get edit_confirmation_path(token: token)

      user.reload
      expect(user.confirmed_at).to be_present
      expect(user.confirmation_token).to be_nil
      expect(response).to redirect_to(root_path) # after_authentication_url usually roots to root_path
      follow_redirect!
      expect(response.body).to include("Dein Konto wurde erfolgreich bestätigt")
    end

    it "does not confirm with an invalid token" do
      get edit_confirmation_path(token: "invalid-token")

      expect(response).to redirect_to(new_confirmation_path)
      follow_redirect!
      expect(response.body).to include("Der Bestätigungslink ist ungültig oder abgelaufen")
    end
  end

  describe "POST /confirmations" do
    it "resends confirmation instructions for an unconfirmed user" do
      expect {
        post confirmations_path, params: { email_address: user.email_address }
      }.to have_enqueued_job(ActionMailer::MailDeliveryJob).with("UserMailer", "confirmation_instructions", "deliver_now", { args: [ user ] })

      expect(response).to redirect_to(new_session_path)
      follow_redirect!
      expect(response.body).to include("Eine neue Bestätigungs-E-Mail wurde gesendet")
    end

    it "notifies if user is already confirmed" do
      user.confirm!
      post confirmations_path, params: { email_address: user.email_address }

      expect(response).to redirect_to(new_session_path)
      follow_redirect!
      expect(response.body).to include("Dein Konto ist bereits bestätigt")
    end
  end
end
