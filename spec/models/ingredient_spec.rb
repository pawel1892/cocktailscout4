require 'rails_helper'

RSpec.describe Ingredient, type: :model do
  describe "Associations" do
    it { should have_many(:collection_ingredients).dependent(:destroy) }
    it { should have_many(:ingredient_collections).through(:collection_ingredients) }
    it { should have_many(:recipe_ingredients).dependent(:destroy) }
    it { should have_many(:recipes).through(:recipe_ingredients) }
  end

  describe "Validations" do
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
    it { should validate_numericality_of(:alcoholic_content).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(100) }
  end

  describe "Scopes" do
    let!(:unused_ingredient) { create(:ingredient) }
    let!(:used_ingredient) { create(:ingredient) }
    let!(:alcoholic_ingredient) { create(:ingredient, :alcoholic) }
    let!(:non_alcoholic_ingredient) { create(:ingredient, alcoholic_content: 0) }
    let!(:recipe) { create(:recipe) }

    before do
      create(:recipe_ingredient, ingredient: used_ingredient, recipe: recipe)
    end

    describe ".unused" do
      it "returns ingredients not used in any recipes" do
        expect(Ingredient.unused).to include(unused_ingredient)
        expect(Ingredient.unused).not_to include(used_ingredient)
      end
    end

    describe ".used" do
      it "returns ingredients used in recipes" do
        expect(Ingredient.used).to include(used_ingredient)
        expect(Ingredient.used).not_to include(unused_ingredient)
      end
    end

    describe ".alcoholic" do
      it "returns ingredients with alcoholic content > 0" do
        expect(Ingredient.alcoholic).to include(alcoholic_ingredient)
        expect(Ingredient.alcoholic).not_to include(non_alcoholic_ingredient)
      end
    end

    describe ".non_alcoholic" do
      it "returns ingredients with no or zero alcoholic content" do
        expect(Ingredient.non_alcoholic).to include(non_alcoholic_ingredient)
        expect(Ingredient.non_alcoholic).not_to include(alcoholic_ingredient)
      end
    end
  end

  describe "#in_use?" do
    let(:ingredient) { create(:ingredient) }

    context "when ingredient is used in recipes" do
      let!(:recipe) { create(:recipe) }
      let!(:recipe_ingredient) { create(:recipe_ingredient, ingredient: ingredient, recipe: recipe) }

      it "returns true" do
        expect(ingredient.in_use?).to be true
      end
    end

    context "when ingredient is not used in recipes" do
      it "returns false" do
        expect(ingredient.in_use?).to be false
      end
    end
  end

  describe "#can_delete?" do
    let(:ingredient) { create(:ingredient) }

    context "when ingredient is used in recipes" do
      let!(:recipe) { create(:recipe) }
      let!(:recipe_ingredient) { create(:recipe_ingredient, ingredient: ingredient, recipe: recipe) }

      it "returns false" do
        expect(ingredient.can_delete?).to be false
      end
    end

    context "when ingredient is not used in recipes" do
      it "returns true" do
        expect(ingredient.can_delete?).to be true
      end
    end
  end

  describe "#recipes_count" do
    let(:ingredient) { create(:ingredient) }
    let!(:recipe1) { create(:recipe) }
    let!(:recipe2) { create(:recipe) }

    before do
      create(:recipe_ingredient, ingredient: ingredient, recipe: recipe1)
      create(:recipe_ingredient, ingredient: ingredient, recipe: recipe2)
    end

    it "returns the number of recipes using the ingredient" do
      expect(ingredient.recipes_count).to eq(2)
    end
  end

  describe "#destroy" do
    let(:ingredient) { create(:ingredient) }

    context "when ingredient is used in recipes" do
      let!(:recipe) { create(:recipe) }
      let!(:recipe_ingredient) { create(:recipe_ingredient, ingredient: ingredient, recipe: recipe) }

      it "prevents deletion" do
        expect(ingredient.destroy).to be false
      end

      it "adds an error" do
        ingredient.destroy
        expect(ingredient.errors[:base]).to include(/kann nicht gelöscht werden/)
      end

      it "does not delete the ingredient" do
        expect { ingredient.destroy }.not_to change(Ingredient, :count)
      end
    end

    context "when ingredient is not used in recipes" do
      it "allows deletion" do
        result = ingredient.destroy
        expect(result).not_to eq(false)
        expect(ingredient.destroyed?).to be true
      end

      it "deletes the ingredient" do
        ingredient_id = ingredient.id
        ingredient.destroy
        expect(Ingredient.exists?(ingredient_id)).to be false
      end
    end
  end
end
