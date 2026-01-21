require 'rails_helper'

RSpec.describe PasswordsController, type: :controller do
  describe "POST #create" do
    context "with valid email" do
      let!(:user) { create(:user, email_address: "user@example.com") }

      it "sends a password reset email" do
        expect {
          post :create, params: { email_address: "user@example.com" }
        }.to have_enqueued_mail(UserMailer, :password_reset).with(user)
      end

      it "redirects to the session new page with a notice" do
        post :create, params: { email_address: "user@example.com" }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "with invalid email" do
      it "does not send a password reset email" do
        expect {
          post :create, params: { email_address: "nonexistent@example.com" }
        }.not_to have_enqueued_mail(UserMailer, :password_reset)
      end

      it "redirects to the session new page with a notice" do
        post :create, params: { email_address: "nonexistent@example.com" }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to be_present
      end
    end
  end

  describe "PUT #update" do
    let!(:user) { create(:user, password: "old_password") }
    let(:token) { user.password_reset_token }

    context "with valid token and matching passwords" do
      it "updates the user's password" do
        put :update, params: { token: token, password: "new_password", password_confirmation: "new_password" }
        user.reload
        expect(user.authenticate("new_password")).to be_truthy
      end

      it "redirects to the session new page with a notice" do
        put :update, params: { token: token, password: "new_password", password_confirmation: "new_password" }
        expect(response).to redirect_to(new_session_path)
        expect(flash[:notice]).to be_present
      end

      it "destroys all user sessions" do
        # Create a session for the user (mocking the relationship)
        create(:session, user: user)

        expect {
          put :update, params: { token: token, password: "new_password", password_confirmation: "new_password" }
        }.to change { user.sessions.count }.to(0)
      end
    end

    context "with valid token but non-matching passwords" do
      it "does not update the password" do
        put :update, params: { token: token, password: "new_password", password_confirmation: "different_password" }
        user.reload
        expect(user.authenticate("old_password")).to be_truthy
      end

      it "redirects to the edit password page with an alert" do
        put :update, params: { token: token, password: "new_password", password_confirmation: "different_password" }
        expect(response).to redirect_to(edit_password_path(token))
        expect(flash[:alert]).to include("Bestätigung stimmt nicht mit Passwort überein")
      end
    end

    context "with valid token but too short password" do
      it "does not update the password" do
        put :update, params: { token: token, password: "short", password_confirmation: "short" }
        user.reload
        expect(user.authenticate("old_password")).to be_truthy
      end

      it "redirects to the edit password page with an alert" do
        put :update, params: { token: token, password: "short", password_confirmation: "short" }
        expect(response).to redirect_to(edit_password_path(token))
        expect(flash[:alert]).to include("zu kurz")
      end
    end

    context "with invalid token" do
      it "redirects to the new password page with an alert" do
        put :update, params: { token: "invalid_token", password: "new_password", password_confirmation: "new_password" }
        expect(response).to redirect_to(new_password_path)
        expect(flash[:alert]).to be_present
      end
    end
  end
end
