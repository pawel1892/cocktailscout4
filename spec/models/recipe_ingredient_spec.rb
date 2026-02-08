require "rails_helper"

RSpec.describe RecipeIngredient, type: :model do
  let(:recipe) { create(:recipe) }
  let(:ingredient) { create(:ingredient, name: "Limette", plural_name: "Limetten") }
  let(:cl_unit) { Unit.find_or_create_by!(name: "cl") { |u| u.display_name = "cl"; u.plural_name = "cl"; u.category = "volume"; u.ml_ratio = 10.0; u.divisible = true } }
  let(:blank_unit) { Unit.find_or_create_by!(name: "x") { |u| u.display_name = ""; u.plural_name = ""; u.category = "count"; u.ml_ratio = nil; u.divisible = true } }

  describe "associations" do
    it { is_expected.to belong_to(:recipe) }
    it { is_expected.to belong_to(:ingredient) }
    it { is_expected.to belong_to(:unit).optional }
  end

  describe "#formatted_amount" do
    context "with regular unit" do
      it "formats integer amounts without decimals" do
        ri = RecipeIngredient.new(amount: 4.0, unit: cl_unit)
        expect(ri.formatted_amount).to eq("4 cl")
      end

      it "formats decimal amounts with German format (comma)" do
        ri = RecipeIngredient.new(amount: 1.5, unit: cl_unit)
        expect(ri.formatted_amount).to eq("1,5 cl")
      end
    end

    context "with blank unit (fractions)" do
      it "formats 1/2 as fraction" do
        ri = RecipeIngredient.new(amount: 0.5, unit: blank_unit)
        expect(ri.formatted_amount).to eq("1/2")
      end

      it "formats 1/4 as fraction" do
        ri = RecipeIngredient.new(amount: 0.25, unit: blank_unit)
        expect(ri.formatted_amount).to eq("1/4")
      end

      it "formats 1/3 as fraction" do
        ri = RecipeIngredient.new(amount: 0.333333333, unit: blank_unit)
        expect(ri.formatted_amount).to eq("1/3")
      end

      it "formats 3/4 as fraction" do
        ri = RecipeIngredient.new(amount: 0.75, unit: blank_unit)
        expect(ri.formatted_amount).to eq("3/4")
      end

      it "formats 1 1/2 as mixed number" do
        ri = RecipeIngredient.new(amount: 1.5, unit: blank_unit)
        expect(ri.formatted_amount).to eq("1 1/2")
      end

      it "formats whole numbers without fractions" do
        ri = RecipeIngredient.new(amount: 2.0, unit: blank_unit)
        expect(ri.formatted_amount).to eq("2")
      end
    end

    context "with additional_info only" do
      it "returns additional_info when no amount" do
        ri = RecipeIngredient.new(additional_info: "Minzzweig")
        expect(ri.formatted_amount).to eq("Minzzweig")
      end
    end
  end

  describe "#formatted_ingredient_name" do
    context "with blank unit" do
      it "uses singular form when amount is 1" do
        ri = RecipeIngredient.new(amount: 1.0, unit: blank_unit, ingredient: ingredient)
        expect(ri.formatted_ingredient_name).to eq("Limette")
      end

      it "uses singular form when amount is less than 1" do
        ri = RecipeIngredient.new(amount: 0.5, unit: blank_unit, ingredient: ingredient)
        expect(ri.formatted_ingredient_name).to eq("Limette")
      end

      it "uses plural form when amount is greater than 1" do
        ri = RecipeIngredient.new(amount: 2.0, unit: blank_unit, ingredient: ingredient)
        expect(ri.formatted_ingredient_name).to eq("Limetten")
      end

      it "uses singular when plural_name is not set" do
        ingredient_without_plural = create(:ingredient, name: "Vodka", plural_name: nil)
        ri = RecipeIngredient.new(amount: 5.0, unit: blank_unit, ingredient: ingredient_without_plural)
        expect(ri.formatted_ingredient_name).to eq("Vodka")
      end
    end

    context "with regular unit" do
      it "always uses singular form" do
        ri = RecipeIngredient.new(amount: 5.0, unit: cl_unit, ingredient: ingredient)
        expect(ri.formatted_ingredient_name).to eq("Limette")
      end
    end
  end

  describe "#scale" do
    it "scales the amount by the given factor" do
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 4.0, unit: cl_unit)
      scaled = ri.scale(2)
      expect(scaled.amount).to eq(8.0)
    end

    it "works with fractional amounts" do
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 0.5, unit: blank_unit)
      scaled = ri.scale(2)
      expect(scaled.amount).to eq(1.0)
    end

    it "works with scaling down" do
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 1.0, unit: blank_unit)
      scaled = ri.scale(0.5)
      expect(scaled.amount).to eq(0.5)
    end

    it "does not scale garnishes" do
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 2.0, unit: blank_unit, is_garnish: true)
      scaled = ri.scale(2)
      expect(scaled.amount).to eq(2.0)
    end

    it "returns self when amount is nil" do
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: nil)
      scaled = ri.scale(2)
      expect(scaled).to eq(ri)
    end
  end

  describe "#amount_in_ml" do
    it "converts amount to ml using unit ratio" do
      ri = RecipeIngredient.new(amount: 5.0, unit: cl_unit)
      expect(ri.amount_in_ml).to eq(50.0)
    end

    it "returns nil for count units" do
      ri = RecipeIngredient.new(amount: 2.0, unit: blank_unit)
      expect(ri.amount_in_ml).to be_nil
    end

    it "returns nil when amount is nil" do
      ri = RecipeIngredient.new(amount: nil, unit: cl_unit)
      expect(ri.amount_in_ml).to be_nil
    end
  end
end
