require 'rails_helper'

describe RecipeImage do

  context ".approved" do

    let! (:recipe_image) {create :recipe_image}
    let! (:approved_recipe_image) {create :recipe_image, is_approved: true}

    it "selects only approved images" do
      expect(RecipeImage.approved).to include(approved_recipe_image)
      expect(RecipeImage.approved).to_not include(recipe_image)
    end

  end

end
