require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  include AuthenticationHelpers

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
