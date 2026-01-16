require 'rails_helper'

RSpec.describe Recipe, type: :model do
  include_examples "visitable"

  describe "Associations" do
    it { should belong_to(:user) }
    it { should have_many(:recipe_ingredients).dependent(:destroy) }
    it { should have_many(:ingredients).through(:recipe_ingredients) }
    it { should have_many(:recipe_comments).dependent(:destroy) }
    it { should have_many(:recipe_images).dependent(:destroy) }
    it { should have_many(:ratings).dependent(:destroy) }
  end

  describe "Validations" do
    subject { build(:recipe) }
    it { should validate_presence_of(:title) }
    it { should validate_uniqueness_of(:slug).case_insensitive }
  end

  describe "Scopes" do
    describe ".by_min_rating" do
      let!(:recipe1) { create(:recipe, average_rating: 4.0) }
      let!(:recipe2) { create(:recipe, average_rating: 5.0) }
      let!(:recipe3) { create(:recipe, average_rating: 3.0) }

      it "returns recipes with rating >= min_rating" do
        expect(Recipe.by_min_rating(4.0)).to include(recipe1, recipe2)
        expect(Recipe.by_min_rating(4.0)).not_to include(recipe3)
      end

      it "returns all recipes if min_rating is nil" do
        expect(Recipe.by_min_rating(nil)).to include(recipe1, recipe2, recipe3)
      end
    end

    describe ".by_ingredient" do
      let(:ingredient) { create(:ingredient) }
      let(:other_ingredient) { create(:ingredient) }
      let!(:recipe_with_ingredient) { create(:recipe) }
      let!(:recipe_without_ingredient) { create(:recipe) }

      before do
        create(:recipe_ingredient, recipe: recipe_with_ingredient, ingredient: ingredient)
        create(:recipe_ingredient, recipe: recipe_without_ingredient, ingredient: other_ingredient)
      end

      it "returns recipes containing the ingredient" do
        expect(Recipe.by_ingredient(ingredient.id)).to include(recipe_with_ingredient)
        expect(Recipe.by_ingredient(ingredient.id)).not_to include(recipe_without_ingredient)
      end

      it "returns all recipes if ingredient_id is nil" do
        expect(Recipe.by_ingredient(nil)).to include(recipe_with_ingredient, recipe_without_ingredient)
      end
    end
  end
end
