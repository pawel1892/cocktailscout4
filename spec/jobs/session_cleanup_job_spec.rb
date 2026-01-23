require "rails_helper"

RSpec.describe SessionCleanupJob, type: :job do
  describe "#perform" do
    let(:user) { create(:user) }

    it "deletes sessions older than 30 days" do
      old_session = create(:session, user: user, updated_at: 31.days.ago)
      new_session = create(:session, user: user, updated_at: 29.days.ago)

      expect {
        described_class.new.perform
      }.to change(Session, :count).from(2).to(1)

      expect(Session.exists?(old_session.id)).to be false
      expect(Session.exists?(new_session.id)).to be true
    end
  end
end
