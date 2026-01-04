require 'rails_helper'

RSpec.describe User, type: :model do
  describe "associations" do
    it "nullifies recipe comments when user is deleted" do
      user = create(:user)
      other_user = create(:user)
      recipe = create(:recipe, user: other_user)
      comment = create(:recipe_comment, user: user, recipe: recipe)

      user.destroy

      expect(RecipeComment.exists?(comment.id)).to be true
      expect(comment.reload.user_id).to be_nil
    end
  end
end