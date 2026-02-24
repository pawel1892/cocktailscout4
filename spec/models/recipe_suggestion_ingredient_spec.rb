require 'rails_helper'

RSpec.describe RecipeSuggestionIngredient, type: :model do
  describe "associations" do
    it { should belong_to(:recipe_suggestion) }
    it { should belong_to(:ingredient) }
    it { should belong_to(:unit).optional }
  end

  describe "validations" do
    it { should validate_numericality_of(:amount).is_greater_than_or_equal_to(0).allow_nil }
    it { should validate_presence_of(:position) }
  end

  describe "acts_as_list" do
    let(:user) { create(:user) }
    let(:suggestion) { RecipeSuggestion.create!(user: user, title: "Test", description: "Test") }
    let(:rum) { create(:ingredient, name: "Rum") }
    let(:lime) { create(:ingredient, name: "Limette") }

    it "automatically assigns position" do
      ingredient1 = suggestion.recipe_suggestion_ingredients.create!(ingredient: rum, amount: 5)
      ingredient2 = suggestion.recipe_suggestion_ingredients.create!(ingredient: lime, amount: 1)

      expect(ingredient1.position).to eq(1)
      expect(ingredient2.position).to eq(2)
    end

    it "maintains position order" do
      ingredient1 = suggestion.recipe_suggestion_ingredients.create!(ingredient: rum, amount: 5, position: 1)
      ingredient2 = suggestion.recipe_suggestion_ingredients.create!(ingredient: lime, amount: 1, position: 2)

      expect(suggestion.recipe_suggestion_ingredients.order(:position).to_a).to eq([ ingredient1, ingredient2 ])
    end
  end

  describe "default values" do
    let(:user) { create(:user) }
    let(:suggestion) { RecipeSuggestion.create!(user: user, title: "Test", description: "Test") }
    let(:rum) { create(:ingredient, name: "Rum") }

    it "defaults is_optional to false" do
      ingredient = suggestion.recipe_suggestion_ingredients.create!(ingredient: rum)
      expect(ingredient.is_optional).to be false
    end

    it "defaults is_scalable to true" do
      ingredient = suggestion.recipe_suggestion_ingredients.create!(ingredient: rum)
      expect(ingredient.is_scalable).to be true
    end

    it "defaults position to 0" do
      ingredient = RecipeSuggestionIngredient.new(
        recipe_suggestion: suggestion,
        ingredient: rum
      )
      expect(ingredient.position).to eq(0)
    end
  end
end
