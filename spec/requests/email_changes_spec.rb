require 'rails_helper'

RSpec.describe "EmailChanges", type: :request do
  let(:user) { create(:user, email_address: "old@example.com") }

  describe "GET /email_aendern" do
    before { sign_in user }

    it "returns http success" do
      get new_email_change_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /email_aendern" do
    before { sign_in user }

    context "with valid email" do
      it "updates unconfirmed_email and sends confirmation email" do
        expect {
          post email_change_path, params: { user: { unconfirmed_email: "new@example.com" } }
        }.to have_enqueued_mail(UserMailer, :email_change_confirmation)

        user.reload
        expect(user.unconfirmed_email).to eq("new@example.com")
        expect(flash[:notice]).to include("Bestätigungs-E-Mail")
      end
    end

    context "with invalid email" do
      it "does not update unconfirmed_email" do
        post email_change_path, params: { user: { unconfirmed_email: "invalid-email" } }
        user.reload
        expect(user.unconfirmed_email).to be_nil
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "with taken email" do
      let!(:other_user) { create(:user, email_address: "taken@example.com") }

      it "does not update unconfirmed_email" do
        post email_change_path, params: { user: { unconfirmed_email: "taken@example.com" } }
        user.reload
        expect(user.unconfirmed_email).to be_nil
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /email_aendern/edit" do
    before do
      user.update(unconfirmed_email: "new@example.com")
    end

    let(:token) { user.generate_token_for(:email_change) }

    context "when authenticated" do
      before { sign_in user }

      it "updates the email address" do
        get edit_email_change_path, params: { token: token }
        user.reload
        expect(user.email_address).to eq("new@example.com")
        expect(user.unconfirmed_email).to be_nil
        expect(flash[:notice]).to include("erfolgreich geändert")
        expect(response).to redirect_to(root_path)
      end
    end

    context "when unauthenticated (cross-browser)" do
      it "updates the email address and signs in the user" do
        get edit_email_change_path, params: { token: token }

        user.reload
        expect(user.email_address).to eq("new@example.com")
        expect(user.unconfirmed_email).to be_nil
        expect(flash[:notice]).to include("erfolgreich geändert")
        expect(response).to redirect_to(root_path)

        # Verify user is signed in (session cookie set)
        expect(cookies[:session_id]).to be_present
      end
    end

    context "with invalid token" do
      it "does not update the email address" do
        get edit_email_change_path, params: { token: "invalid_token" }
        user.reload
        expect(user.email_address).to eq("old@example.com")
        expect(flash[:alert]).to include("ungültig")
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
