require "rails_helper"

RSpec.describe RecipeIngredient, type: :model do
  let(:recipe) { create(:recipe) }
  let(:ingredient) { create(:ingredient, name: "Limette", plural_name: "Limetten") }
  let(:cl_unit) { Unit.find_or_create_by!(name: "cl") { |u| u.display_name = "cl"; u.plural_name = "cl"; u.category = "volume"; u.ml_ratio = 10.0; u.divisible = true } }
  # No longer using blank_unit - ingredients without explicit units use nil

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

    context "without explicit unit (fractions)" do
      it "formats 1/2 as fraction" do
        ri = RecipeIngredient.new(amount: 0.5, unit: nil)
        expect(ri.formatted_amount).to eq("1/2")
      end

      it "formats 1/4 as fraction" do
        ri = RecipeIngredient.new(amount: 0.25, unit: nil)
        expect(ri.formatted_amount).to eq("1/4")
      end

      it "formats 1/3 as fraction" do
        ri = RecipeIngredient.new(amount: 0.333333333, unit: nil)
        expect(ri.formatted_amount).to eq("1/3")
      end

      it "formats 3/4 as fraction" do
        ri = RecipeIngredient.new(amount: 0.75, unit: nil)
        expect(ri.formatted_amount).to eq("3/4")
      end

      it "formats 1 1/2 as mixed number" do
        ri = RecipeIngredient.new(amount: 1.5, unit: nil)
        expect(ri.formatted_amount).to eq("1 1/2")
      end

      it "formats whole numbers without fractions" do
        ri = RecipeIngredient.new(amount: 2.0, unit: nil)
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
    context "with display_name override" do
      it "uses display_name when set" do
        mint = create(:ingredient, name: "Minze")
        ri = RecipeIngredient.new(amount: 1.0, unit: nil, ingredient: mint, display_name: "Minzzweig")
        expect(ri.formatted_ingredient_name).to eq("Minzzweig")
      end

      it "uses display_name even when plural would normally be used" do
        ri = RecipeIngredient.new(amount: 2.0, unit: nil, ingredient: ingredient, display_name: "Custom Name")
        expect(ri.formatted_ingredient_name).to eq("Custom Name")
      end
    end

    context "without explicit unit" do
      it "uses singular form when amount is 1" do
        ri = RecipeIngredient.new(amount: 1.0, unit: nil, ingredient: ingredient)
        expect(ri.formatted_ingredient_name).to eq("Limette")
      end

      it "uses singular form when amount is less than 1" do
        ri = RecipeIngredient.new(amount: 0.5, unit: nil, ingredient: ingredient)
        expect(ri.formatted_ingredient_name).to eq("Limette")
      end

      it "uses plural form when amount is greater than 1" do
        ri = RecipeIngredient.new(amount: 2.0, unit: nil, ingredient: ingredient)
        expect(ri.formatted_ingredient_name).to eq("Limetten")
      end

      it "uses singular when plural_name is not set" do
        ingredient_without_plural = create(:ingredient, name: "Vodka", plural_name: nil)
        ri = RecipeIngredient.new(amount: 5.0, unit: nil, ingredient: ingredient_without_plural)
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

  describe "#scalable?" do
    it "returns true when amount, unit, is_scalable, and not needs_review" do
      ri = RecipeIngredient.new(amount: 4.0, unit: cl_unit, needs_review: false, is_scalable: true)
      expect(ri.scalable?).to be true
    end

    it "returns false when needs_review is true" do
      ri = RecipeIngredient.new(amount: 4.0, unit: cl_unit, needs_review: true, is_scalable: true)
      expect(ri.scalable?).to be false
    end

    it "returns false when is_scalable is false" do
      ri = RecipeIngredient.new(amount: 4.0, unit: cl_unit, needs_review: false, is_scalable: false)
      expect(ri.scalable?).to be false
    end

    it "returns false when amount is nil" do
      ri = RecipeIngredient.new(amount: nil, unit: cl_unit, needs_review: false, is_scalable: true)
      expect(ri.scalable?).to be false
    end

    it "returns true when unit is nil but has amount" do
      ri = RecipeIngredient.new(amount: 4.0, unit: nil, needs_review: false, is_scalable: true)
      expect(ri.scalable?).to be true
    end
  end

  describe "#display_text" do
    it "returns formatted text when scalable" do
      ri = RecipeIngredient.new(amount: 4.0, unit: cl_unit, ingredient: ingredient, needs_review: false, old_description: "4 cl Rum")
      expect(ri.display_text).to eq("4 cl Limette")
    end

    it "returns old_description when not scalable" do
      ri = RecipeIngredient.new(old_description: "Schuss Grenadine", needs_review: true, ingredient: ingredient)
      expect(ri.display_text).to eq("Schuss Grenadine")
    end

    it "returns old_description when amount is nil" do
      ri = RecipeIngredient.new(amount: nil, old_description: "Orangensaft", ingredient: ingredient)
      expect(ri.display_text).to eq("Orangensaft")
    end
  end

  describe "#scale" do
    it "scales the amount by the given factor" do
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 4.0, unit: cl_unit)
      scaled = ri.scale(2)
      expect(scaled.amount).to eq(8.0)
    end

    it "works with fractional amounts" do
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 0.5, unit: nil)
      scaled = ri.scale(2)
      expect(scaled.amount).to eq(1.0)
    end

    it "works with scaling down" do
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 1.0, unit: nil)
      scaled = ri.scale(0.5)
      expect(scaled.amount).to eq(0.5)
    end

    it "does not scale non-scalable ingredients" do
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 2.0, unit: nil, is_scalable: false)
      scaled = ri.scale(2)
      expect(scaled.amount).to eq(2.0)
    end

    it "scales scalable ingredients normally" do
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 2.0, unit: nil, is_scalable: true)
      scaled = ri.scale(2)
      expect(scaled.amount).to eq(4.0)
    end

    it "does not scale ingredients that need review" do
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 2.0, unit: nil, needs_review: true)
      scaled = ri.scale(2)
      expect(scaled.amount).to eq(2.0)
    end

    it "returns self when amount is nil" do
      ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: nil)
      scaled = ri.scale(2)
      expect(scaled).to eq(ri)
    end

    context "with non-divisible units" do
      let(:spritzer_unit) { Unit.find_or_create_by!(name: "spritzer") { |u| u.display_name = "Spritzer"; u.plural_name = "Spritzer"; u.category = "special"; u.ml_ratio = 0.9; u.divisible = false } }

      it "rounds non-divisible units" do
        ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 1.0, unit: spritzer_unit)
        scaled = ri.scale(1.5)
        expect(scaled.amount).to eq(2.0)  # Rounded from 1.5
      end

      it "does not round divisible units" do
        ri = create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 4.0, unit: cl_unit)
        scaled = ri.scale(1.5)
        expect(scaled.amount).to eq(6.0)  # Not rounded
      end
    end
  end

  describe "#amount_in_ml" do
    it "converts amount to ml using unit ratio" do
      ri = RecipeIngredient.new(amount: 5.0, unit: cl_unit)
      expect(ri.amount_in_ml).to eq(50.0)
    end

    it "returns nil for count units" do
      ri = RecipeIngredient.new(amount: 2.0, unit: nil)
      expect(ri.amount_in_ml).to be_nil
    end

    it "returns nil when amount is nil" do
      ri = RecipeIngredient.new(amount: nil, unit: cl_unit)
      expect(ri.amount_in_ml).to be_nil
    end
  end

  describe "callbacks" do
    let(:vodka) { create(:ingredient, name: "Vodka", alcoholic_content: 40.0) }
    let(:fresh_recipe) { create(:recipe, total_volume: nil, alcohol_content: nil) }

    describe "after_save" do
      it "updates recipe computed fields when ingredient is added" do
        expect(fresh_recipe.total_volume).to be_nil
        expect(fresh_recipe.alcohol_content).to be_nil

        create(:recipe_ingredient, recipe: fresh_recipe, ingredient: vodka, unit: cl_unit, amount: 5.0)
        fresh_recipe.reload

        expect(fresh_recipe.total_volume.to_f).to eq(50.0)
        expect(fresh_recipe.alcohol_content.to_f).to eq(40.0)
      end

      it "updates recipe computed fields when ingredient amount changes" do
        ri = create(:recipe_ingredient, recipe: fresh_recipe, ingredient: vodka, unit: cl_unit, amount: 5.0)
        fresh_recipe.reload
        expect(fresh_recipe.total_volume.to_f).to eq(50.0)

        ri.update(amount: 10.0)
        fresh_recipe.reload

        expect(fresh_recipe.total_volume.to_f).to eq(100.0)
      end
    end

    describe "after_destroy" do
      it "updates recipe computed fields when ingredient is removed" do
        ri = create(:recipe_ingredient, recipe: fresh_recipe, ingredient: vodka, unit: cl_unit, amount: 5.0)
        fresh_recipe.reload
        expect(fresh_recipe.total_volume.to_f).to eq(50.0)

        ri.destroy
        fresh_recipe.reload

        expect(fresh_recipe.total_volume.to_f).to eq(0.0)
        expect(fresh_recipe.alcohol_content.to_f).to eq(0.0)
      end
    end
  end
end
