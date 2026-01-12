require 'rails_helper'

RSpec.describe RecipesHelper, type: :helper do
  describe "#recipe_thumbnail" do
    let(:recipe) { create(:recipe) }

    context "when recipe has no images" do
      it "returns a placeholder" do
        expect(helper.recipe_thumbnail(recipe)).to include("fa-cocktail")
      end
    end

    context "when recipe has only pending images" do
      let!(:pending_image) { create(:recipe_image, :with_image, :pending, recipe: recipe) }

      it "returns a placeholder" do
        expect(helper.recipe_thumbnail(recipe)).to include("fa-cocktail")
      end
    end

    context "when recipe has an approved image" do
      let!(:approved_image) { create(:recipe_image, :with_image, :approved, recipe: recipe) }

      it "returns the image tag" do
        expect(helper.recipe_thumbnail(recipe)).to include("img")
        expect(helper.recipe_thumbnail(recipe)).to include(url_for(approved_image.image.variant(:thumb)))
      end
    end

    context "when recipe has both approved and pending images" do
      let!(:pending_image) { create(:recipe_image, :with_image, :pending, recipe: recipe) }
      let!(:approved_image) { create(:recipe_image, :with_image, :approved, recipe: recipe) }

      it "returns the approved image" do
        expect(helper.recipe_thumbnail(recipe)).to include("img")
        # Since we use sample, it should always be the approved one as pending is filtered out
        # We can verify it's NOT the placeholder
        expect(helper.recipe_thumbnail(recipe)).not_to include("fa-cocktail")
      end
    end
  end
end
