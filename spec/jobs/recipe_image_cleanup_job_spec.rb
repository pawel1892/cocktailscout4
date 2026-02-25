require "rails_helper"

RSpec.describe RecipeImageCleanupJob, type: :job do
  describe "#perform" do
    let(:recipe_image_old) do
      create(:recipe_image, :approved, :with_image, deleted_at: 2.months.ago)
    end
    let(:recipe_image_recent) do
      create(:recipe_image, :approved, :with_image, deleted_at: 2.weeks.ago)
    end
    let(:recipe_image_not_deleted) do
      create(:recipe_image, :approved, :with_image)
    end

    before do
      recipe_image_old
      recipe_image_recent
      recipe_image_not_deleted
    end

    it "destroys soft-deleted images older than 1 month" do
      expect {
        described_class.new.perform
      }.to change(RecipeImage, :count).by(-1)

      expect(RecipeImage.exists?(recipe_image_old.id)).to be false
    end

    it "keeps soft-deleted images deleted less than 1 month ago" do
      described_class.new.perform
      expect(RecipeImage.exists?(recipe_image_recent.id)).to be true
    end

    it "keeps images that are not soft-deleted" do
      described_class.new.perform
      expect(RecipeImage.exists?(recipe_image_not_deleted.id)).to be true
    end
  end
end
