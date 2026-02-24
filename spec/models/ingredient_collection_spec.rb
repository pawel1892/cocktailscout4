require 'rails_helper'

RSpec.describe IngredientCollection, type: :model do
  describe "Associations" do
    it { should belong_to(:user) }
    it { should have_many(:collection_ingredients).dependent(:destroy) }
    it { should have_many(:ingredients).through(:collection_ingredients) }
  end

  describe "Validations" do
    subject { create(:ingredient_collection) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).scoped_to(:user_id).case_insensitive }
    it { should validate_length_of(:name).is_at_least(1).is_at_most(100) }
  end

  describe "Callbacks" do
    describe "before_validation" do
      context "when name is not provided" do
        it "sets default name to 'My Collection'" do
          user = create(:user)
          collection = user.ingredient_collections.create

          expect(collection.name).to eq("My Collection")
        end
      end

      context "when name is provided" do
        it "does not override the name" do
          user = create(:user)
          collection = user.ingredient_collections.create(name: "Custom Name")

          expect(collection.name).to eq("Custom Name")
        end
      end
    end

    describe "after_create" do
      context "when it's the first collection for user" do
        it "sets is_default to true" do
          user = create(:user)
          collection = user.ingredient_collections.create(name: "First Collection")

          expect(collection.reload.is_default).to be true
        end
      end

      context "when user already has collections" do
        it "does not set is_default to true" do
          user = create(:user)
          create(:ingredient_collection, user: user, is_default: true)
          second_collection = user.ingredient_collections.create(name: "Second Collection")

          expect(second_collection.reload.is_default).to be false
        end
      end
    end
  end

  describe "Scopes" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    describe ".for_user" do
      it "returns collections for specific user" do
        collection1 = create(:ingredient_collection, user: user1)
        collection2 = create(:ingredient_collection, user: user1)
        collection3 = create(:ingredient_collection, user: user2)

        expect(IngredientCollection.for_user(user1.id)).to contain_exactly(collection1, collection2)
        expect(IngredientCollection.for_user(user2.id)).to contain_exactly(collection3)
      end
    end

    describe ".default" do
      it "returns only default collections" do
        default1 = create(:ingredient_collection, user: user1, is_default: true)
        non_default = create(:ingredient_collection, user: user1, is_default: false)
        default2 = create(:ingredient_collection, user: user2, is_default: true)

        expect(IngredientCollection.default).to contain_exactly(default1, default2)
      end
    end
  end

  describe "#doable_recipes" do
    let(:user) { create(:user) }
    let(:collection) { create(:ingredient_collection, user: user) }

    let(:vodka) { create(:ingredient, name: "Vodka") }
    let(:rum) { create(:ingredient, name: "Rum") }
    let(:gin) { create(:ingredient, name: "Gin") }
    let(:tonic) { create(:ingredient, name: "Tonic Water") }
    let(:lime) { create(:ingredient, name: "Lime Juice") }

    context "when collection is empty" do
      it "returns no recipes" do
        create(:recipe, :with_ingredients, ingredients_count: 2)

        expect(collection.doable_recipes).to be_empty
      end
    end

    context "when collection has ingredients" do
      before do
        collection.ingredients << [ vodka, tonic, lime ]
      end

      it "returns recipes that can be made with available ingredients" do
        # Recipe with vodka and tonic (doable)
        vodka_tonic = create(:recipe, title: "Vodka Tonic")
        vodka_tonic.recipe_ingredients.create!(ingredient: vodka, amount: 50.0, unit: Unit.find_or_create_by!(name: "ml") { |u| u.display_name = "ml"; u.plural_name = "ml"; u.category = "volume"; u.ml_ratio = 1.0; u.divisible = true })
        vodka_tonic.recipe_ingredients.create!(ingredient: tonic, amount: 100.0, unit: Unit.find_or_create_by!(name: "ml") { |u| u.display_name = "ml"; u.plural_name = "ml"; u.category = "volume"; u.ml_ratio = 1.0; u.divisible = true })

        # Recipe with vodka only (doable)
        vodka_shot = create(:recipe, title: "Vodka Shot")
        vodka_shot.recipe_ingredients.create!(ingredient: vodka, amount: 40.0, unit: Unit.find_or_create_by!(name: "ml") { |u| u.display_name = "ml"; u.plural_name = "ml"; u.category = "volume"; u.ml_ratio = 1.0; u.divisible = true })

        # Recipe with rum and lime (not doable - missing rum)
        rum_punch = create(:recipe, title: "Rum Punch")
        rum_punch.recipe_ingredients.create!(ingredient: rum, amount: 50.0, unit: Unit.find_or_create_by!(name: "ml") { |u| u.display_name = "ml"; u.plural_name = "ml"; u.category = "volume"; u.ml_ratio = 1.0; u.divisible = true })
        rum_punch.recipe_ingredients.create!(ingredient: lime, amount: 20.0, unit: Unit.find_or_create_by!(name: "ml") { |u| u.display_name = "ml"; u.plural_name = "ml"; u.category = "volume"; u.ml_ratio = 1.0; u.divisible = true })

        doable = collection.doable_recipes

        expect(doable).to include(vodka_tonic, vodka_shot)
        expect(doable).not_to include(rum_punch)
      end

      it "does not return recipes requiring ingredients not in collection" do
        # Recipe requiring gin (not in collection)
        gin_tonic = create(:recipe, title: "Gin & Tonic")
        gin_tonic.recipe_ingredients.create!(ingredient: gin, amount: 50.0, unit: Unit.find_or_create_by!(name: "ml") { |u| u.display_name = "ml"; u.plural_name = "ml"; u.category = "volume"; u.ml_ratio = 1.0; u.divisible = true })
        gin_tonic.recipe_ingredients.create!(ingredient: tonic, amount: 100.0, unit: Unit.find_or_create_by!(name: "ml") { |u| u.display_name = "ml"; u.plural_name = "ml"; u.category = "volume"; u.ml_ratio = 1.0; u.divisible = true })

        expect(collection.doable_recipes).not_to include(gin_tonic)
      end

      it "handles recipes with multiple ingredients correctly" do
        # 3-ingredient recipe that's doable
        complex_drink = create(:recipe, title: "Complex Drink")
        complex_drink.recipe_ingredients.create!(ingredient: vodka, amount: 30.0, unit: Unit.find_or_create_by!(name: "ml") { |u| u.display_name = "ml"; u.plural_name = "ml"; u.category = "volume"; u.ml_ratio = 1.0; u.divisible = true })
        complex_drink.recipe_ingredients.create!(ingredient: tonic, amount: 90.0, unit: Unit.find_or_create_by!(name: "ml") { |u| u.display_name = "ml"; u.plural_name = "ml"; u.category = "volume"; u.ml_ratio = 1.0; u.divisible = true })
        complex_drink.recipe_ingredients.create!(ingredient: lime, amount: 15.0, unit: Unit.find_or_create_by!(name: "ml") { |u| u.display_name = "ml"; u.plural_name = "ml"; u.category = "volume"; u.ml_ratio = 1.0; u.divisible = true })

        expect(collection.doable_recipes).to include(complex_drink)
      end
    end

    context "when multiple collections exist" do
      it "only considers ingredients from the specific collection" do
        other_collection = create(:ingredient_collection, user: user, name: "Other Collection")
        other_collection.ingredients << rum

        collection.ingredients << vodka

        vodka_recipe = create(:recipe, title: "Vodka Recipe")
        vodka_recipe.recipe_ingredients.create!(ingredient: vodka, amount: 50.0, unit: Unit.find_or_create_by!(name: "ml") { |u| u.display_name = "ml"; u.plural_name = "ml"; u.category = "volume"; u.ml_ratio = 1.0; u.divisible = true })

        rum_recipe = create(:recipe, title: "Rum Recipe")
        rum_recipe.recipe_ingredients.create!(ingredient: rum, amount: 50.0, unit: Unit.find_or_create_by!(name: "ml") { |u| u.display_name = "ml"; u.plural_name = "ml"; u.category = "volume"; u.ml_ratio = 1.0; u.divisible = true })

        expect(collection.doable_recipes).to include(vodka_recipe)
        expect(collection.doable_recipes).not_to include(rum_recipe)
        expect(other_collection.doable_recipes).to include(rum_recipe)
        expect(other_collection.doable_recipes).not_to include(vodka_recipe)
      end
    end
  end

  describe "Notes field" do
    it "can store notes" do
      collection = create(:ingredient_collection, :with_notes)
      expect(collection.notes).to eq("Shopping list: rum, vodka, gin")
    end

    it "allows nil notes" do
      collection = create(:ingredient_collection, notes: nil)
      expect(collection.notes).to be_nil
    end
  end

  describe "Cascade deletion" do
    it "deletes collection_ingredients when collection is deleted" do
      collection = create(:ingredient_collection, :with_ingredients, ingredients_count: 3)
      collection_ingredient_ids = collection.collection_ingredients.pluck(:id)

      collection.destroy

      collection_ingredient_ids.each do |id|
        expect(CollectionIngredient.find_by(id: id)).to be_nil
      end
    end

    it "does not delete ingredients when collection is deleted" do
      collection = create(:ingredient_collection, :with_ingredients, ingredients_count: 3)
      ingredient_ids = collection.ingredients.pluck(:id)

      collection.destroy

      ingredient_ids.each do |id|
        expect(Ingredient.find_by(id: id)).not_to be_nil
      end
    end
  end
end
