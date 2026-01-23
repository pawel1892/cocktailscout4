require 'rails_helper'

RSpec.describe RecipeComment, type: :model do
  describe "associations" do
    it { should belong_to(:recipe) }
    it { should belong_to(:user).optional }
    it { should belong_to(:last_editor).class_name('User').optional }
  end

  describe "validations" do
    it { should validate_presence_of(:body) }

    it "is valid with body, recipe, and user" do
      user = create(:user)
      recipe = create(:recipe)
      comment = RecipeComment.new(body: "Great cocktail!", recipe: recipe, user: user)

      expect(comment).to be_valid
    end

    it "is invalid without body" do
      user = create(:user)
      recipe = create(:recipe)
      comment = RecipeComment.new(body: nil, recipe: recipe, user: user)

      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to be_present
    end

    it "is invalid with empty body" do
      user = create(:user)
      recipe = create(:recipe)
      comment = RecipeComment.new(body: "", recipe: recipe, user: user)

      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to be_present
    end

    it "is invalid with whitespace-only body" do
      user = create(:user)
      recipe = create(:recipe)
      comment = RecipeComment.new(body: "   ", recipe: recipe, user: user)

      expect(comment).not_to be_valid
      expect(comment.errors[:body]).to be_present
    end
  end

  describe "user deletion behavior" do
    it "persists comment when associated user is deleted" do
      user = create(:user)
      recipe = create(:recipe)
      comment = RecipeComment.create!(body: "Great!", recipe: recipe, user: user)

      expect {
        user.destroy
      }.not_to change { RecipeComment.count }

      comment.reload
      expect(comment.user_id).to be_nil
      expect(comment.body).to eq("Great!")
    end

    it "nullifies user_id for all user comments when user is deleted" do
      user = create(:user)
      recipe1 = create(:recipe)
      recipe2 = create(:recipe)

      comment1 = RecipeComment.create!(body: "Comment 1", recipe: recipe1, user: user)
      comment2 = RecipeComment.create!(body: "Comment 2", recipe: recipe2, user: user)

      user.destroy

      comment1.reload
      comment2.reload

      expect(comment1.user_id).to be_nil
      expect(comment2.user_id).to be_nil
      expect(RecipeComment.count).to eq(2)
    end
  end

  describe "required recipe association" do
    it "is invalid without a recipe" do
      user = create(:user)
      comment = RecipeComment.new(body: "Great cocktail!", recipe: nil, user: user)

      expect(comment).not_to be_valid
      expect(comment.errors[:recipe]).to be_present
    end

    it "is destroyed when recipe is deleted" do
      user = create(:user)
      recipe = create(:recipe)
      comment = RecipeComment.create!(body: "Great!", recipe: recipe, user: user)

      expect {
        recipe.destroy
      }.to change { RecipeComment.count }.by(-1)

      expect(RecipeComment.exists?(comment.id)).to be false
    end

    it "destroys all comments when recipe is deleted" do
      recipe = create(:recipe)
      user1 = create(:user)
      user2 = create(:user)

      comment1 = RecipeComment.create!(body: "Comment 1", recipe: recipe, user: user1)
      comment2 = RecipeComment.create!(body: "Comment 2", recipe: recipe, user: user2)
      comment3 = RecipeComment.create!(body: "Comment 3", recipe: recipe, user: user1)

      expect {
        recipe.destroy
      }.to change { RecipeComment.count }.by(-3)

      expect(RecipeComment.exists?(comment1.id)).to be false
      expect(RecipeComment.exists?(comment2.id)).to be false
      expect(RecipeComment.exists?(comment3.id)).to be false
    end
  end

  describe "timestamps" do
    it "sets created_at when created" do
      user = create(:user)
      recipe = create(:recipe)
      comment = RecipeComment.create!(body: "Great!", recipe: recipe, user: user)

      expect(comment.created_at).to be_present
      expect(comment.created_at).to be_within(1.second).of(Time.current)
    end

    it "updates updated_at when modified" do
      user = create(:user)
      recipe = create(:recipe)
      comment = RecipeComment.create!(body: "Great!", recipe: recipe, user: user)

      original_updated_at = comment.updated_at
      sleep 0.1

      comment.update!(body: "Even better!")

      expect(comment.updated_at).to be > original_updated_at
    end
  end

  describe "body content" do
    let(:user) { create(:user) }
    let(:recipe) { create(:recipe) }

    it "accepts long text content" do
      long_body = "A" * 1000
      comment = RecipeComment.new(body: long_body, recipe: recipe, user: user)

      expect(comment).to be_valid
    end

    it "preserves line breaks" do
      body_with_breaks = "First line\nSecond line\nThird line"
      comment = RecipeComment.create!(body: body_with_breaks, recipe: recipe, user: user)

      comment.reload
      expect(comment.body).to eq(body_with_breaks)
    end

    it "preserves special characters" do
      body = "Great! 🍹 Best cocktail ever! <3 @bartender #amazing"
      comment = RecipeComment.create!(body: body, recipe: recipe, user: user)

      comment.reload
      expect(comment.body).to eq(body)
    end
  end

  describe "multiple comments on same recipe" do
    it "allows multiple comments from same user on one recipe" do
      user = create(:user)
      recipe = create(:recipe)

      comment1 = RecipeComment.create!(body: "First comment", recipe: recipe, user: user)
      comment2 = RecipeComment.create!(body: "Second comment", recipe: recipe, user: user)

      expect(comment1).to be_valid
      expect(comment2).to be_valid
      expect(recipe.recipe_comments.count).to eq(2)
    end

    it "allows comments from different users on one recipe" do
      user1 = create(:user)
      user2 = create(:user)
      recipe = create(:recipe)

      comment1 = RecipeComment.create!(body: "Comment 1", recipe: recipe, user: user1)
      comment2 = RecipeComment.create!(body: "Comment 2", recipe: recipe, user: user2)

      expect(recipe.recipe_comments.count).to eq(2)
      expect(recipe.recipe_comments).to include(comment1, comment2)
    end
  end

  describe "user stats update" do
    let(:user) { create(:user) }
    let(:recipe) { create(:recipe) }

    it "updates user stats after creating a comment" do
      expect {
        RecipeComment.create!(body: "Great cocktail!", recipe: recipe, user: user)
      }.to change { user.stat.reload.points }.by(2)
    end

    it "updates user stats after destroying a comment" do
      comment = RecipeComment.create!(body: "Great cocktail!", recipe: recipe, user: user)
      initial_points = user.stat.reload.points

      comment.destroy

      expect(user.stat.reload.points).to eq(initial_points - 2)
    end

    it "does not raise error when user is nil" do
      expect {
        RecipeComment.create!(body: "Anonymous comment", recipe: recipe, user: nil)
      }.not_to raise_error
    end
  end
end
