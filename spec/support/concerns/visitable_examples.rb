RSpec.shared_examples "visitable" do
  include ActiveSupport::Testing::TimeHelpers

  let(:user) { create(:user) }
  let(:model_symbol) { described_class.model_name.param_key.to_sym }
  let(:visitable) { create(model_symbol) }

  describe "associations" do
    it { is_expected.to have_many(:visits).dependent(:destroy) }
  end

  describe "#track_visit" do
    context "when user is present" do
      it "creates a new visit record if none exists" do
        expect {
          visitable.track_visit(user)
        }.to change(Visit, :count).by(1)
      end

      it "increments the count if record exists" do
        visitable.track_visit(user)
        expect {
          visitable.track_visit(user)
        }.not_to change(Visit, :count)

        expect(visitable.visits.find_by(user: user).count).to eq(2)
      end

      it "updates the last_visited_at timestamp" do
        visitable.track_visit(user)
        initial_time = visitable.visits.find_by(user: user).last_visited_at

        travel 1.hour do
          visitable.track_visit(user)
          expect(visitable.visits.find_by(user: user).last_visited_at).to be > initial_time
        end
      end
    end

    context "when user is nil (anonymous)" do
      it "creates a new visit record for anonymous if none exists" do
        expect {
          visitable.track_visit(nil)
        }.to change(Visit, :count).by(1)

        visit = visitable.visits.last
        expect(visit.user).to be_nil
        expect(visit.count).to eq(1)
      end

      it "increments the count for the single anonymous record" do
        visitable.track_visit(nil)
        expect {
          visitable.track_visit(nil)
        }.not_to change(Visit, :count)

        expect(visitable.visits.find_by(user: nil).count).to eq(2)
      end
    end
  end

  describe "#total_visits" do
    it "returns the sum of all visits" do
      visitable.track_visit(user)      # 1
      visitable.track_visit(user)      # 2
      visitable.track_visit(nil)       # 1 (anon)
      visitable.track_visit(nil)       # 2 (anon)

      other_user = create(:user)
      visitable.track_visit(other_user) # 1

      expect(visitable.total_visits).to eq(5)
    end
  end

  describe "#visits_by" do
    it "returns the count for a specific user" do
      visitable.track_visit(user)
      visitable.track_visit(user)

      expect(visitable.visits_by(user)).to eq(2)
    end

    it "returns 0 if user has not visited" do
      expect(visitable.visits_by(user)).to eq(0)
    end
  end
end
