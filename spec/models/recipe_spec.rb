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
  end
end
