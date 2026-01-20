require "rails_helper"

RSpec.describe User, type: :model do
  describe "confirmation" do
    let(:user) { User.new(username: "Test", email_address: "test@example.com", password: "password") }

    it "generates a confirmation token before create" do
      user.save!
      expect(user.confirmation_token).to be_present
      expect(user.confirmation_sent_at).to be_present
      expect(user.confirmed_at).to be_nil
    end

    it "confirms the user" do
      user.save!
      user.confirm!
      expect(user.confirmed?).to be true
      expect(user.confirmation_token).to be_nil
    end

    it "knows if it is confirmed" do
      expect(user.confirmed?).to be false
      user.confirmed_at = Time.current
      expect(user.confirmed?).to be true
    end
  end
end
