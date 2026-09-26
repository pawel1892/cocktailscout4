require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  include AuthenticationHelpers

  describe "POST /session with a banned user" do
    let(:user) { create(:user, :banned) }

    it "rejects an HTML login" do
      post session_path, params: { email_address: user.email_address, password: "password" }

      expect(response).to redirect_to(new_session_path)
      expect(flash[:alert]).to eq("Dein Konto ist gesperrt.")
      expect(user.sessions.count).to eq(0)
    end

    it "rejects a JSON login" do
      post session_path, params: { email_address: user.email_address, password: "password" }, as: :json

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body["error"]).to eq("Dein Konto ist gesperrt.")
    end

    it "mentions the end date of a temporary ban" do
      user.update!(banned_until: 3.days.from_now)
      post session_path, params: { email_address: user.email_address, password: "password" }

      expect(flash[:alert]).to start_with("Dein Konto ist bis zum")
    end

    it "allows login after the ban has expired" do
      user.update!(banned_at: 2.days.ago, banned_until: 1.day.ago)
      post session_path, params: { email_address: user.email_address, password: "password" }

      expect(user.sessions.count).to eq(1)
    end
  end

  describe "existing session of a user who gets banned" do
    let(:user) { create(:user) }

    it "is no longer accepted" do
      post session_path, params: { email_address: user.email_address, password: "password" }
      user.update_columns(banned_at: Time.current)

      get new_email_change_path

      expect(response).to redirect_to(new_session_path)
      expect(user.sessions.count).to eq(0)
    end
  end

  describe "DELETE /session (logout)" do
    let(:user) { create(:user, last_active_at: 1.minute.ago, last_seen_at: 1.minute.ago) }

    before { sign_in(user) }

    it "clears last_active_at so the user disappears from the online list immediately" do
      delete session_path
      expect(user.reload.last_active_at).to be_nil
    end

    it "preserves last_seen_at as a permanent record of last activity" do
      delete session_path
      expect(user.reload.last_seen_at).not_to be_nil
    end

    it "redirects to the login page" do
      delete session_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
