require 'rails_helper'

RSpec.describe "Heartbeats", type: :request do
  include AuthenticationHelpers

  describe "POST /heartbeat" do
    context "when authenticated" do
      let(:user) { create(:user, last_active_at: nil, last_seen_at: nil) }

      before { sign_in(user) }

      it "returns no content" do
        post heartbeat_path
        expect(response).to have_http_status(:no_content)
      end

      it "updates last_active_at" do
        expect {
          post heartbeat_path
        }.to change { user.reload.last_active_at }

        expect(user.last_active_at).to be_within(1.second).of(Time.current)
      end

      it "updates last_seen_at" do
        expect {
          post heartbeat_path
        }.to change { user.reload.last_seen_at }

        expect(user.last_seen_at).to be_within(1.second).of(Time.current)
      end

      it "bypasses the navigation throttle — always touches even if recently active" do
        user.update(last_active_at: 30.seconds.ago)

        expect {
          post heartbeat_path
        }.to change { user.reload.last_active_at }
      end
    end

    context "when not authenticated" do
      it "returns no content without error" do
        post heartbeat_path
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
