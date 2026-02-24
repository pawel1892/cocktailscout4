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
    it { should have_many(:favorites).dependent(:destroy) }
    it { should have_many(:favorited_by_users).through(:favorites) }
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

    describe ".by_collection" do
      let(:user) { create(:user) }
      let(:collection) { create(:ingredient_collection, user: user) }
      let(:ingredient1) { create(:ingredient, name: "Vodka") }
      let(:ingredient2) { create(:ingredient, name: "Orange Juice") }
      let(:ingredient3) { create(:ingredient, name: "Rum") }

      let!(:doable_recipe) { create(:recipe, title: "Screwdriver") }
      let!(:not_doable_recipe) { create(:recipe, title: "Cuba Libre") }
      let!(:partially_doable) { create(:recipe, title: "Mixed Drink") }

      before do
        # Add ingredients to collection
        collection.ingredients << [ ingredient1, ingredient2 ]

        # doable_recipe only needs ingredients from collection
        create(:recipe_ingredient, recipe: doable_recipe, ingredient: ingredient1)
        create(:recipe_ingredient, recipe: doable_recipe, ingredient: ingredient2)

        # not_doable_recipe needs ingredient3 which is not in collection
        create(:recipe_ingredient, recipe: not_doable_recipe, ingredient: ingredient3)

        # partially_doable needs both collection and non-collection ingredients
        create(:recipe_ingredient, recipe: partially_doable, ingredient: ingredient1)
        create(:recipe_ingredient, recipe: partially_doable, ingredient: ingredient3)
      end

      it "returns only recipes that can be made with collection ingredients" do
        result = Recipe.by_collection(collection.id)
        expect(result).to include(doable_recipe)
        expect(result).not_to include(not_doable_recipe, partially_doable)
      end

      it "returns all recipes if collection_id is nil" do
        expect(Recipe.by_collection(nil)).to include(doable_recipe, not_doable_recipe, partially_doable)
      end

      it "returns none if collection doesn't exist" do
        expect(Recipe.by_collection(99999).count).to eq(0)
      end
    end

    describe ".search_by_title" do
      let!(:recipe1) { create(:recipe, title: "Mojito") }
      let!(:recipe2) { create(:recipe, title: "Moscow Mule") }
      let!(:recipe3) { create(:recipe, title: "Margarita") }

      it "returns recipes matching the search query" do
        results = Recipe.search_by_title("Moj")
        expect(results).to include(recipe1)
        expect(results).not_to include(recipe2, recipe3)
      end

      it "returns all recipes if query is blank" do
        expect(Recipe.search_by_title("")).to include(recipe1, recipe2, recipe3)
        expect(Recipe.search_by_title(nil)).to include(recipe1, recipe2, recipe3)
      end
    end

    describe "combined filters" do
      let(:user) { create(:user) }
      let(:collection) { create(:ingredient_collection, user: user) }
      let(:vodka) { create(:ingredient, name: "Vodka") }
      let(:juice) { create(:ingredient, name: "Orange Juice") }
      let(:rum) { create(:ingredient, name: "Rum") }

      let!(:high_rated_doable) { create(:recipe, title: "Premium Screwdriver", average_rating: 8.5) }
      let!(:low_rated_doable) { create(:recipe, title: "Simple Mix", average_rating: 5.0) }
      let!(:high_rated_not_doable) { create(:recipe, title: "Premium Rum Cocktail", average_rating: 9.0) }

      before do
        # Collection has vodka and juice
        collection.ingredients << [ vodka, juice ]

        # high_rated_doable uses only collection ingredients
        create(:recipe_ingredient, recipe: high_rated_doable, ingredient: vodka)
        create(:recipe_ingredient, recipe: high_rated_doable, ingredient: juice)

        # low_rated_doable uses only collection ingredients
        create(:recipe_ingredient, recipe: low_rated_doable, ingredient: vodka)
        create(:recipe_ingredient, recipe: low_rated_doable, ingredient: juice)

        # high_rated_not_doable uses rum (not in collection)
        create(:recipe_ingredient, recipe: high_rated_not_doable, ingredient: rum)

        # Tag the recipes
        high_rated_doable.tag_list.add("cocktail")
        high_rated_doable.save
        low_rated_doable.tag_list.add("simple")
        low_rated_doable.save
        high_rated_not_doable.tag_list.add("cocktail")
        high_rated_not_doable.save
      end

      it "can combine collection filter with min_rating filter" do
        results = Recipe.by_collection(collection.id).by_min_rating(8.0)
        expect(results).to include(high_rated_doable)
        expect(results).not_to include(low_rated_doable, high_rated_not_doable)
      end

      it "can combine collection filter with ingredient filter" do
        results = Recipe.by_collection(collection.id).by_ingredient(vodka.id)
        expect(results).to include(high_rated_doable, low_rated_doable)
        expect(results).not_to include(high_rated_not_doable)
      end

      it "can combine collection filter with tag filter" do
        results = Recipe.by_collection(collection.id).tagged_with("cocktail")
        expect(results).to include(high_rated_doable)
        expect(results).not_to include(low_rated_doable, high_rated_not_doable)
      end

      it "can combine collection filter with search" do
        results = Recipe.by_collection(collection.id).search_by_title("Premium")
        expect(results).to include(high_rated_doable)
        expect(results).not_to include(low_rated_doable, high_rated_not_doable)
      end

      it "can combine all filters together" do
        # Test: collection + min_rating + tag + search
        results = Recipe
          .by_collection(collection.id)
          .by_min_rating(8.0)
          .tagged_with("cocktail")
          .search_by_title("Premium")

        expect(results).to include(high_rated_doable)
        expect(results).not_to include(low_rated_doable, high_rated_not_doable)
      end

      it "preserves order when filters are chained" do
        # Ensure filters work in different orders
        result1 = Recipe.by_min_rating(8.0).by_collection(collection.id)
        result2 = Recipe.by_collection(collection.id).by_min_rating(8.0)

        expect(result1.pluck(:id).sort).to eq(result2.pluck(:id).sort)
      end
    end

    describe "visibility scopes" do
      let!(:published_recipe) { create(:recipe, is_public: true, is_deleted: false) }
      let!(:draft_recipe) { create(:recipe, :draft) }
      let!(:deleted_recipe) { create(:recipe, :deleted) }
      let!(:deleted_draft) { create(:recipe, is_public: false, is_deleted: true) }

      describe ".published" do
        it "returns only published recipes" do
          expect(Recipe.published).to include(published_recipe)
          expect(Recipe.published).not_to include(draft_recipe, deleted_recipe, deleted_draft)
        end
      end

      describe ".not_deleted" do
        it "returns only non-deleted recipes" do
          # Use unscoped to bypass default scope
          expect(Recipe.unscoped.not_deleted).to include(published_recipe, draft_recipe)
          expect(Recipe.unscoped.not_deleted).not_to include(deleted_recipe, deleted_draft)
        end
      end

      describe ".visible" do
        it "returns only published and non-deleted recipes" do
          expect(Recipe.visible).to include(published_recipe)
          expect(Recipe.visible).not_to include(draft_recipe, deleted_recipe, deleted_draft)
        end
      end

      describe ".drafts" do
        it "returns only draft recipes" do
          expect(Recipe.drafts).to include(draft_recipe)
          expect(Recipe.drafts).not_to include(published_recipe, deleted_recipe)
        end
      end

      describe "default scope" do
        it "excludes deleted recipes by default" do
          expect(Recipe.all).to include(published_recipe, draft_recipe)
          expect(Recipe.all).not_to include(deleted_recipe, deleted_draft)
        end

        it "can be bypassed with unscoped" do
          expect(Recipe.unscoped.all).to include(published_recipe, draft_recipe, deleted_recipe, deleted_draft)
        end
      end
    end
  end

  describe "Draft and publish methods" do
    let(:recipe) { create(:recipe, :draft) }

    describe "#draft?" do
      it "returns true for draft recipes" do
        expect(recipe.draft?).to be true
      end

      it "returns false for published recipes" do
        recipe.update!(is_public: true)
        expect(recipe.draft?).to be false
      end
    end

    describe "#publish!" do
      it "publishes a draft recipe" do
        expect {
          recipe.publish!
        }.to change { recipe.reload.is_public }.from(false).to(true)
      end

      it "makes the recipe visible" do
        recipe.publish!
        expect(Recipe.visible).to include(recipe)
      end
    end

    describe "#soft_delete!" do
      let(:published_recipe) { create(:recipe) }

      it "marks recipe as deleted" do
        expect {
          published_recipe.soft_delete!
        }.to change { published_recipe.reload.is_deleted }.from(false).to(true)
      end

      it "removes recipe from default scope" do
        published_recipe.soft_delete!
        expect(Recipe.all).not_to include(published_recipe)
      end

      it "can still be accessed with unscoped" do
        published_recipe.soft_delete!
        expect(Recipe.unscoped.find(published_recipe.id)).to eq(published_recipe)
      end
    end
  end

  describe "Alcohol calculations" do
    let(:recipe) { create(:recipe) }
    let(:cl_unit) { Unit.find_or_create_by!(name: "cl") { |u| u.display_name = "cl"; u.plural_name = "cl"; u.category = "volume"; u.ml_ratio = 10.0 } }
    let(:ml_unit) { Unit.find_or_create_by!(name: "ml") { |u| u.display_name = "ml"; u.plural_name = "ml"; u.category = "volume"; u.ml_ratio = 1.0 } }
    let(:vodka) { create(:ingredient, name: "Vodka", alcoholic_content: 40.0) }
    let(:orange_juice) { create(:ingredient, name: "Orange Juice", alcoholic_content: 0.0) }
    let(:triple_sec) { create(:ingredient, name: "Triple Sec", alcoholic_content: 30.0) }

    describe "#total_volume_in_ml" do
      it "calculates total volume from all ingredients" do
        create(:recipe_ingredient, recipe: recipe, ingredient: vodka, unit: cl_unit, amount: 5.0)
        create(:recipe_ingredient, recipe: recipe, ingredient: orange_juice, unit: cl_unit, amount: 10.0)
        recipe.reload

        expect(recipe.total_volume_in_ml.to_f).to eq(150.0) # 5cl + 10cl = 150ml
      end

      it "handles ingredients without volume" do
        create(:recipe_ingredient, recipe: recipe, ingredient: vodka, unit: cl_unit, amount: 5.0)
        create(:recipe_ingredient, recipe: recipe, ingredient: orange_juice, unit: nil, amount: nil)

        expect(recipe.total_volume_in_ml).to eq(50.0)
      end

      it "returns 0 when no ingredients have volume" do
        create(:recipe_ingredient, recipe: recipe, ingredient: vodka, unit: nil, amount: nil)

        expect(recipe.total_volume_in_ml).to eq(0.0)
      end
    end

    describe "#alcohol_volume_in_ml" do
      it "calculates total alcohol volume" do
        # 5cl vodka at 40% = 50ml * 0.4 = 20ml alcohol
        create(:recipe_ingredient, recipe: recipe, ingredient: vodka, unit: cl_unit, amount: 5.0)
        # 10cl OJ at 0% = 0ml alcohol
        create(:recipe_ingredient, recipe: recipe, ingredient: orange_juice, unit: cl_unit, amount: 10.0)

        expect(recipe.reload.alcohol_volume_in_ml.to_f).to eq(20.0)
      end

      it "handles multiple alcoholic ingredients" do
        # 5cl vodka at 40% = 50ml * 0.4 = 20ml
        create(:recipe_ingredient, recipe: recipe, ingredient: vodka, unit: cl_unit, amount: 5.0)
        # 2cl triple sec at 30% = 20ml * 0.3 = 6ml
        create(:recipe_ingredient, recipe: recipe, ingredient: triple_sec, unit: cl_unit, amount: 2.0)

        expect(recipe.reload.alcohol_volume_in_ml.to_f).to eq(26.0)
      end

      it "returns 0 when no alcoholic ingredients" do
        create(:recipe_ingredient, recipe: recipe, ingredient: orange_juice, unit: cl_unit, amount: 10.0)

        expect(recipe.reload.alcohol_volume_in_ml.to_f).to eq(0.0)
      end

      it "ignores ingredients without volume" do
        create(:recipe_ingredient, recipe: recipe, ingredient: vodka, unit: cl_unit, amount: 5.0)
        create(:recipe_ingredient, recipe: recipe, ingredient: triple_sec, unit: nil, amount: nil)

        expect(recipe.reload.alcohol_volume_in_ml.to_f).to eq(20.0)
      end
    end

    describe "#calculate_alcohol_content" do
      it "calculates ABV percentage" do
        # 5cl vodka (40%) + 10cl OJ (0%) = 15cl total
        # Alcohol: 50ml * 0.4 = 20ml
        # ABV: 20/150 * 100 = 13.3%
        create(:recipe_ingredient, recipe: recipe, ingredient: vodka, unit: cl_unit, amount: 5.0)
        create(:recipe_ingredient, recipe: recipe, ingredient: orange_juice, unit: cl_unit, amount: 10.0)

        expect(recipe.reload.calculate_alcohol_content.to_f).to eq(13.3)
      end

      it "rounds to 1 decimal place" do
        # 6cl vodka (40%) + 10cl OJ (0%) = 16cl total
        # Alcohol: 60ml * 0.4 = 24ml
        # ABV: 24/160 * 100 = 15.0%
        create(:recipe_ingredient, recipe: recipe, ingredient: vodka, unit: cl_unit, amount: 6.0)
        create(:recipe_ingredient, recipe: recipe, ingredient: orange_juice, unit: cl_unit, amount: 10.0)

        expect(recipe.reload.calculate_alcohol_content.to_f).to eq(15.0)
      end

      it "returns 0 when total volume is 0" do
        expect(recipe.reload.calculate_alcohol_content.to_f).to eq(0.0)
      end

      it "returns 0 when no alcoholic ingredients" do
        create(:recipe_ingredient, recipe: recipe, ingredient: orange_juice, unit: cl_unit, amount: 10.0)

        expect(recipe.reload.calculate_alcohol_content.to_f).to eq(0.0)
      end

      it "handles high-proof spirits correctly" do
        pure_alcohol = create(:ingredient, name: "Pure Alcohol", alcoholic_content: 100.0)
        create(:recipe_ingredient, recipe: recipe, ingredient: pure_alcohol, unit: cl_unit, amount: 5.0)

        expect(recipe.reload.calculate_alcohol_content.to_f).to eq(100.0)
      end
    end

    describe "#update_computed_fields!" do
      it "updates total_volume field in database" do
        create(:recipe_ingredient, recipe: recipe, ingredient: vodka, unit: cl_unit, amount: 5.0)
        create(:recipe_ingredient, recipe: recipe, ingredient: orange_juice, unit: cl_unit, amount: 10.0)

        recipe.reload.update_computed_fields!

        expect(recipe.reload.total_volume.to_f).to eq(150.0)
      end

      it "updates alcohol_content field in database" do
        create(:recipe_ingredient, recipe: recipe, ingredient: vodka, unit: cl_unit, amount: 5.0)
        create(:recipe_ingredient, recipe: recipe, ingredient: orange_juice, unit: cl_unit, amount: 10.0)

        recipe.reload.update_computed_fields!

        expect(recipe.reload.alcohol_content.to_f).to eq(13.3)
      end

      it "rounds total_volume to 1 decimal place" do
        create(:recipe_ingredient, recipe: recipe, ingredient: vodka, unit: ml_unit, amount: 33.333)

        recipe.update_computed_fields!

        expect(recipe.reload.total_volume.to_f).to eq(33.3)
      end
    end
  end
end
