require 'rails_helper'

RSpec.describe RecipeForm, type: :model do
  let(:user) { create(:user) }
  let(:ingredient1) { create(:ingredient, name: "Rum") }
  let(:ingredient2) { create(:ingredient, name: "Lime Juice") }
  let(:unit) { Unit.find_or_create_by!(name: "cl") { |u| u.display_name = "cl"; u.plural_name = "cl"; u.category = "volume"; u.ml_ratio = 10.0; u.divisible = true } }

  let(:valid_ingredients_data) do
    [
      {
        ingredient_id: ingredient1.id,
        unit_id: unit.id,
        amount: 4.0
      },
      {
        ingredient_id: ingredient2.id,
        unit_id: unit.id,
        amount: 2.0
      }
    ]
  end

  describe "validations" do
    it "validates presence of title" do
      form = RecipeForm.new(
        user: user,
        description: "Test description",
        ingredients_data: valid_ingredients_data
      )

      expect(form.valid?).to be false
      expect(form.errors[:title]).to include("muss ausgefüllt werden")
    end

    it "validates presence of description" do
      form = RecipeForm.new(
        user: user,
        title: "Test Recipe",
        ingredients_data: valid_ingredients_data
      )

      expect(form.valid?).to be false
      expect(form.errors[:description]).to include("muss ausgefüllt werden")
    end

    it "validates presence of user" do
      form = RecipeForm.new(
        title: "Test Recipe",
        description: "Test description",
        ingredients_data: valid_ingredients_data
      )

      expect(form.valid?).to be false
      expect(form.errors[:user]).to include("muss ausgefüllt werden")
    end

    it "validates minimum 2 ingredients" do
      form = RecipeForm.new(
        user: user,
        title: "Test Recipe",
        description: "Test description",
        ingredients_data: [ { ingredient_id: ingredient1.id, amount: 4.0 } ]
      )

      expect(form.valid?).to be false
      expect(form.errors[:ingredients]).to include("Es müssen mindestens 2 Zutaten angegeben werden")
    end

    it "validates empty ingredients list" do
      form = RecipeForm.new(
        user: user,
        title: "Test Recipe",
        description: "Test description",
        ingredients_data: []
      )

      expect(form.valid?).to be false
      expect(form.errors[:ingredients]).to include("Es müssen mindestens 2 Zutaten angegeben werden")
    end

    it "validates ingredient has name or id" do
      form = RecipeForm.new(
        user: user,
        title: "Test Recipe",
        description: "Test description",
        ingredients_data: [
          { ingredient_id: ingredient1.id, amount: 4.0 },
          { amount: 2.0 }  # Missing ingredient name/id
        ]
      )

      expect(form.valid?).to be false
      expect(form.errors[:ingredients]).to include("Zutat 2: Name fehlt")
    end

    it "validates amount is non-negative" do
      form = RecipeForm.new(
        user: user,
        title: "Test Recipe",
        description: "Test description",
        ingredients_data: [
          { ingredient_id: ingredient1.id, amount: 4.0 },
          { ingredient_id: ingredient2.id, amount: -1.0 }
        ]
      )

      expect(form.valid?).to be false
      expect(form.errors[:ingredients]).to include("Zutat 2: Menge muss >= 0 sein")
    end

    it "allows zero amount" do
      form = RecipeForm.new(
        user: user,
        title: "Test Recipe",
        description: "Test description",
        ingredients_data: [
          { ingredient_id: ingredient1.id, amount: 0.0 },
          { ingredient_id: ingredient2.id, amount: 2.0 }
        ]
      )

      expect(form.valid?).to be true
    end

    it "is valid with all required fields" do
      form = RecipeForm.new(
        user: user,
        title: "Test Recipe",
        description: "Test description",
        ingredients_data: valid_ingredients_data
      )

      expect(form.valid?).to be true
    end
  end

  describe "#save" do
    context "with valid data" do
      it "creates a new recipe" do
        form = RecipeForm.new(
          user: user,
          title: "Mojito",
          description: "A classic Cuban cocktail",
          ingredients_data: valid_ingredients_data
        )

        expect {
          expect(form.save).to be true
        }.to change(Recipe, :count).by(1)

        recipe = Recipe.last
        expect(recipe.title).to eq("Mojito")
        expect(recipe.description).to eq("A classic Cuban cocktail")
        expect(recipe.user).to eq(user)
      end

      it "creates recipe ingredients with correct positions" do
        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          ingredients_data: valid_ingredients_data
        )

        form.save
        recipe = Recipe.last

        expect(recipe.recipe_ingredients.count).to eq(2)
        expect(recipe.recipe_ingredients.order(:position).first.position).to eq(1)
        expect(recipe.recipe_ingredients.order(:position).last.position).to eq(2)
      end

      it "generates a unique slug" do
        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          ingredients_data: valid_ingredients_data
        )

        form.save
        recipe = Recipe.last

        expect(recipe.slug).to eq("test-recipe")
      end

      it "generates unique slug when duplicate exists" do
        existing_recipe = create(:recipe, title: "Test Recipe", slug: "test-recipe")

        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          ingredients_data: valid_ingredients_data
        )

        form.save
        new_recipe = Recipe.last

        expect(new_recipe.slug).to eq("test-recipe-1")
      end

      it "creates ingredient with all optional fields" do
        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          ingredients_data: [
            {
              ingredient_id: ingredient1.id,
              unit_id: unit.id,
              amount: 4.0,
              additional_info: "dark rum",
              display_name: "Dark Rum",
              is_optional: true,
              is_scalable: false
            },
            {
              ingredient_id: ingredient2.id,
              unit_id: unit.id,
              amount: 2.0
            }
          ]
        )

        form.save
        recipe_ingredient = Recipe.last.recipe_ingredients.first

        expect(recipe_ingredient.additional_info).to eq("dark rum")
        expect(recipe_ingredient.display_name).to eq("Dark Rum")
        expect(recipe_ingredient.is_optional).to be true
        expect(recipe_ingredient.is_scalable).to be false
      end

      it "defaults is_scalable to true" do
        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          ingredients_data: valid_ingredients_data
        )

        form.save
        recipe_ingredients = Recipe.last.recipe_ingredients

        expect(recipe_ingredients.all?(&:is_scalable)).to be true
      end

      it "defaults is_optional to false" do
        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          ingredients_data: valid_ingredients_data
        )

        form.save
        recipe_ingredients = Recipe.last.recipe_ingredients

        expect(recipe_ingredients.all? { |ri| !ri.is_optional }).to be true
      end

      it "creates ingredient by name if id not provided" do
        new_ingredient_name = "Unique Ingredient #{SecureRandom.hex(8)}"

        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          ingredients_data: [
            { ingredient_id: ingredient1.id, amount: 4.0 },
            { ingredient_name: new_ingredient_name, amount: 2.0 }
          ]
        )

        expect {
          form.save
        }.to change(Ingredient, :count).by(1)

        new_ingredient = Ingredient.find_by(name: new_ingredient_name)
        expect(new_ingredient).to be_present
        expect(new_ingredient.alcoholic_content).to eq(0.0)

        recipe = Recipe.last
        expect(recipe.recipe_ingredients.pluck(:ingredient_id)).to include(new_ingredient.id)
      end

      it "finds existing ingredient by name if already exists" do
        existing = create(:ingredient, name: "Existing Ingredient")

        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          ingredients_data: [
            { ingredient_id: ingredient1.id, amount: 4.0 },
            { ingredient_name: "Existing Ingredient", amount: 2.0 }
          ]
        )

        expect {
          form.save
        }.not_to change(Ingredient, :count)

        recipe = Recipe.last
        expect(recipe.recipe_ingredients.pluck(:ingredient_id)).to include(existing.id)
      end

      it "sets tags from tag_list" do
        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          tag_list: "rum, classic, tropical",
          ingredients_data: valid_ingredients_data
        )

        form.save
        recipe = Recipe.last.reload  # Reload to get fresh tag data

        expect(recipe.tag_list).to contain_exactly("rum", "classic", "tropical")
      end

      it "calls update_computed_fields!" do
        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          ingredients_data: valid_ingredients_data
        )

        form.save
        recipe = Recipe.last

        # Verify computed fields are set (which means update_computed_fields! was called)
        expect(recipe.total_volume).to be_present
        expect(recipe.alcohol_content).to be_present
      end
    end

    context "with is_public field" do
      it "creates a draft recipe by default" do
        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          ingredients_data: valid_ingredients_data
        )

        form.save
        recipe = Recipe.unscoped.last

        expect(recipe.is_public).to be false
        expect(recipe.draft?).to be true
      end

      it "creates a published recipe when is_public is true" do
        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          is_public: true,
          ingredients_data: valid_ingredients_data
        )

        form.save
        recipe = Recipe.last

        expect(recipe.is_public).to be true
        expect(recipe.draft?).to be false
      end

      it "creates a draft when is_public is explicitly false" do
        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          is_public: false,
          ingredients_data: valid_ingredients_data
        )

        form.save
        recipe = Recipe.unscoped.last

        expect(recipe.is_public).to be false
      end
    end

    context "updating an existing recipe" do
      let(:existing_recipe) { create(:recipe, user: user) }
      let!(:old_ingredient) { create(:recipe_ingredient, recipe: existing_recipe, ingredient: ingredient1, position: 1) }

      it "updates the recipe attributes" do
        form = RecipeForm.new(
          recipe: existing_recipe,
          user: user,
          title: "Updated Title",
          description: "Updated description",
          ingredients_data: valid_ingredients_data
        )

        form.save
        existing_recipe.reload

        expect(existing_recipe.title).to eq("Updated Title")
        expect(existing_recipe.description).to eq("Updated description")
      end

      it "does not generate a new slug" do
        original_slug = existing_recipe.slug

        form = RecipeForm.new(
          recipe: existing_recipe,
          user: user,
          title: "Updated Title",
          description: "Updated description",
          ingredients_data: valid_ingredients_data
        )

        form.save
        existing_recipe.reload

        expect(existing_recipe.slug).to eq(original_slug)
      end

      it "destroys old ingredients and creates new ones" do
        expect(existing_recipe.recipe_ingredients.count).to eq(1)

        form = RecipeForm.new(
          recipe: existing_recipe,
          user: user,
          title: existing_recipe.title,
          description: existing_recipe.description,
          ingredients_data: valid_ingredients_data
        )

        form.save
        existing_recipe.reload

        expect(existing_recipe.recipe_ingredients.count).to eq(2)
        expect(existing_recipe.recipe_ingredients.pluck(:ingredient_id)).to contain_exactly(ingredient1.id, ingredient2.id)
      end

      it "updates is_public status" do
        expect(existing_recipe.is_public).to be true

        form = RecipeForm.new(
          recipe: existing_recipe,
          user: user,
          title: existing_recipe.title,
          description: existing_recipe.description,
          is_public: false,
          ingredients_data: valid_ingredients_data
        )

        expect(form.save).to be true
        existing_recipe.reload

        expect(existing_recipe.is_public).to be false
      end
    end

    context "with invalid data" do
      it "returns false and does not save" do
        form = RecipeForm.new(
          user: user,
          title: "",  # Invalid
          description: "Test description",
          ingredients_data: valid_ingredients_data
        )

        expect(form.save).to be false
        expect(Recipe.count).to eq(0)
      end

      it "does not create any records on validation failure" do
        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          ingredients_data: [ { ingredient_id: ingredient1.id, amount: 4.0 } ]  # Only 1 ingredient
        )

        expect {
          form.save
        }.not_to change(Recipe, :count)
      end

      it "rolls back transaction on save error" do
        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          ingredients_data: valid_ingredients_data
        )

        # Simulate a save error
        allow_any_instance_of(Recipe).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new)

        expect {
          form.save
        }.not_to change(Recipe, :count)
      end

      it "adds error message on save failure" do
        form = RecipeForm.new(
          user: user,
          title: "Test Recipe",
          description: "Test description",
          ingredients_data: valid_ingredients_data
        )

        allow_any_instance_of(Recipe).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(Recipe.new))

        form.save

        expect(form.errors[:base]).to be_present
      end
    end
  end

  describe "#persisted?" do
    it "returns false for new recipe" do
      form = RecipeForm.new(
        user: user,
        title: "Test Recipe",
        description: "Test description",
        ingredients_data: valid_ingredients_data
      )

      expect(form.persisted?).to be false
    end

    it "returns true for existing recipe" do
      existing_recipe = create(:recipe)
      form = RecipeForm.new(recipe: existing_recipe)

      expect(form.persisted?).to be true
    end
  end

  describe "initialization" do
    it "initializes with empty recipe by default" do
      form = RecipeForm.new

      expect(form.recipe).to be_a(Recipe)
      expect(form.recipe.new_record?).to be true
    end

    it "initializes with existing recipe" do
      existing_recipe = create(:recipe, title: "Existing Recipe")
      form = RecipeForm.new(recipe: existing_recipe)

      expect(form.recipe).to eq(existing_recipe)
      expect(form.title).to eq("Existing Recipe")
    end

    it "loads tags from existing recipe" do
      existing_recipe = create(:recipe)
      existing_recipe.tag_list.add("rum", "classic")
      existing_recipe.save

      form = RecipeForm.new(recipe: existing_recipe)

      expect(form.tag_list).to eq("rum, classic")
    end

    it "loads is_public from existing recipe" do
      existing_recipe = create(:recipe, :draft)
      form = RecipeForm.new(recipe: existing_recipe)

      expect(form.is_public).to be false
    end

    it "defaults is_public to false for new recipe" do
      form = RecipeForm.new

      expect(form.is_public).to be false
    end
  end
end
