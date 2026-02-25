require 'rails_helper'

RSpec.describe "User Activity Tracking", type: :request do
  include AuthenticationHelpers

  let(:user) { create(:user, password: "password", sign_in_count: 0) }

  describe "Sign in count" do
    it "increments sign_in_count on successful login" do
      expect {
        post session_path, params: { email_address: user.email_address, password: "password" }
      }.to change { user.reload.sign_in_count }.by(1)
    end

    it "does not increment sign_in_count on failed login" do
      expect {
        post session_path, params: { email_address: user.email_address, password: "wrong_password" }
      }.not_to change { user.reload.sign_in_count }
    end
  end

  describe "Last active at" do
    before { sign_in(user) }

    it "updates last_active_at on request" do
      user.update(last_active_at: 1.hour.ago)

      expect {
        get root_path
      }.to change { user.reload.last_active_at }

      expect(user.last_active_at).to be_within(1.second).of(Time.current)
    end

    it "does not update last_active_at if updated recently (within 2 minutes)" do
      user.update(last_active_at: 1.minute.ago)
      original_time = user.last_active_at

      get root_path

      expect(user.reload.last_active_at).to eq(original_time)
    end

    it "updates last_active_at if exactly 2 minutes ago (boundary check)" do
      user.update(last_active_at: 2.minutes.ago - 1.second)

      expect {
        get root_path
      }.to change { user.reload.last_active_at }
    end
  end

  describe "Last seen at" do
    before { sign_in(user) }

    it "updates last_seen_at on navigation" do
      user.update(last_active_at: 1.hour.ago, last_seen_at: 1.hour.ago)

      expect {
        get root_path
      }.to change { user.reload.last_seen_at }

      expect(user.last_seen_at).to be_within(1.second).of(Time.current)
    end

    it "does not update last_seen_at if active recently" do
      user.update(last_active_at: 1.minute.ago, last_seen_at: 1.minute.ago)
      original_time = user.last_seen_at

      get root_path

      expect(user.reload.last_seen_at).to eq(original_time)
    end
  end
end
