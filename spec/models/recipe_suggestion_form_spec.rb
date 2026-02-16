require 'rails_helper'

RSpec.describe RecipeSuggestionForm, type: :model do
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
      form = RecipeSuggestionForm.new(
        user: user,
        description: "Test description",
        ingredients_data: valid_ingredients_data
      )

      expect(form.valid?).to be false
      expect(form.errors[:title]).to include("muss ausgefüllt werden")
    end

    it "validates presence of description" do
      form = RecipeSuggestionForm.new(
        user: user,
        title: "Test Suggestion",
        ingredients_data: valid_ingredients_data
      )

      expect(form.valid?).to be false
      expect(form.errors[:description]).to include("muss ausgefüllt werden")
    end

    it "validates presence of user" do
      form = RecipeSuggestionForm.new(
        title: "Test Suggestion",
        description: "Test description",
        ingredients_data: valid_ingredients_data
      )

      expect(form.valid?).to be false
      expect(form.errors[:user]).to include("muss ausgefüllt werden")
    end

    it "validates minimum 2 ingredients" do
      form = RecipeSuggestionForm.new(
        user: user,
        title: "Test Suggestion",
        description: "Test description",
        ingredients_data: [ { ingredient_id: ingredient1.id, amount: 4.0 } ]
      )

      expect(form.valid?).to be false
      expect(form.errors[:ingredients]).to include("Es müssen mindestens 2 Zutaten angegeben werden")
    end

    it "validates empty ingredients list" do
      form = RecipeSuggestionForm.new(
        user: user,
        title: "Test Suggestion",
        description: "Test description",
        ingredients_data: []
      )

      expect(form.valid?).to be false
      expect(form.errors[:ingredients]).to include("Es müssen mindestens 2 Zutaten angegeben werden")
    end

    it "validates ingredient has name or id" do
      form = RecipeSuggestionForm.new(
        user: user,
        title: "Test Suggestion",
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
      form = RecipeSuggestionForm.new(
        user: user,
        title: "Test Suggestion",
        description: "Test description",
        ingredients_data: [
          { ingredient_id: ingredient1.id, amount: 4.0 },
          { ingredient_id: ingredient2.id, amount: -2.0 }  # Negative amount
        ]
      )

      expect(form.valid?).to be false
      expect(form.errors[:ingredients]).to include("Zutat 2: Menge muss >= 0 sein")
    end
  end

  describe "#save" do
    it "creates a new recipe suggestion" do
      form = RecipeSuggestionForm.new(
        user: user,
        title: "Mojito Suggestion",
        description: "Classic Cuban cocktail",
        tag_list: "rum, minze",
        ingredients_data: valid_ingredients_data
      )

      expect { form.save }.to change { RecipeSuggestion.count }.by(1)

      suggestion = RecipeSuggestion.last
      expect(suggestion.title).to eq("Mojito Suggestion")
      expect(suggestion.description).to eq("Classic Cuban cocktail")
      expect(suggestion.tag_list).to eq("rum, minze")
      expect(suggestion.user).to eq(user)
      expect(suggestion.status).to eq("pending")
    end

    it "creates recipe suggestion ingredients" do
      form = RecipeSuggestionForm.new(
        user: user,
        title: "Mojito Suggestion",
        description: "Classic Cuban cocktail",
        ingredients_data: valid_ingredients_data
      )

      expect { form.save }.to change { RecipeSuggestionIngredient.count }.by(2)

      suggestion = RecipeSuggestion.last
      expect(suggestion.recipe_suggestion_ingredients.count).to eq(2)

      first_ingredient = suggestion.recipe_suggestion_ingredients.first
      expect(first_ingredient.ingredient).to eq(ingredient1)
      expect(first_ingredient.unit).to eq(unit)
      expect(first_ingredient.amount).to eq(4.0)
      expect(first_ingredient.position).to eq(1)
    end

    it "finds or creates ingredient by name" do
      form = RecipeSuggestionForm.new(
        user: user,
        title: "New Cocktail",
        description: "Description",
        ingredients_data: [
          { ingredient_name: "New Ingredient", amount: 2.0 },
          { ingredient_id: ingredient1.id, amount: 4.0 }
        ]
      )

      expect { form.save }.to change { Ingredient.count }.by(1)

      new_ingredient = Ingredient.find_by(name: "New Ingredient")
      expect(new_ingredient).to be_present
      expect(new_ingredient.alcoholic_content).to eq(0.0)
    end

    it "updates existing recipe suggestion" do
      suggestion = RecipeSuggestion.create!(
        user: user,
        title: "Original Title",
        description: "Original Description",
        status: "pending"
      )

      form = RecipeSuggestionForm.new(
        recipe_suggestion: suggestion,
        user: user,
        title: "Updated Title",
        description: "Updated Description",
        tag_list: "new, tags",
        ingredients_data: valid_ingredients_data
      )

      expect { form.save }.not_to change { RecipeSuggestion.count }

      suggestion.reload
      expect(suggestion.title).to eq("Updated Title")
      expect(suggestion.description).to eq("Updated Description")
      expect(suggestion.tag_list).to eq("new, tags")
    end

    it "resets status to pending on save" do
      reviewer = create(:user)
      suggestion = RecipeSuggestion.create!(
        user: user,
        title: "Original Title",
        description: "Original Description",
        status: "rejected",
        reviewed_by: reviewer,
        reviewed_at: Time.current,
        feedback: "Needs improvement"
      )

      form = RecipeSuggestionForm.new(
        recipe_suggestion: suggestion,
        user: user,
        title: "Updated Title",
        description: "Updated Description",
        ingredients_data: valid_ingredients_data
      )

      form.save

      suggestion.reload
      expect(suggestion.status).to eq("pending")
    end

    it "replaces ingredients when updating" do
      suggestion = RecipeSuggestion.create!(
        user: user,
        title: "Original Title",
        description: "Original Description",
        status: "pending"
      )

      suggestion.recipe_suggestion_ingredients.create!(
        ingredient: ingredient1,
        amount: 5.0,
        position: 1
      )

      form = RecipeSuggestionForm.new(
        recipe_suggestion: suggestion,
        user: user,
        title: "Updated Title",
        description: "Updated Description",
        ingredients_data: valid_ingredients_data
      )

      expect { form.save }.to change { suggestion.recipe_suggestion_ingredients.count }.from(1).to(2)
    end

    it "handles ingredient options (is_optional, is_scalable, etc.)" do
      form = RecipeSuggestionForm.new(
        user: user,
        title: "Test",
        description: "Test",
        ingredients_data: [
          {
            ingredient_id: ingredient1.id,
            unit_id: unit.id,
            amount: 4.0,
            additional_info: "weiß",
            display_name: "Weißer Rum",
            is_optional: true,
            is_scalable: false
          },
          {
            ingredient_id: ingredient2.id,
            amount: 2.0
          }
        ]
      )

      form.save

      suggestion = RecipeSuggestion.last
      first_ingredient = suggestion.recipe_suggestion_ingredients.first

      expect(first_ingredient.additional_info).to eq("weiß")
      expect(first_ingredient.display_name).to eq("Weißer Rum")
      expect(first_ingredient.is_optional).to be true
      expect(first_ingredient.is_scalable).to be false

      second_ingredient = suggestion.recipe_suggestion_ingredients.second
      expect(second_ingredient.is_optional).to be false
      expect(second_ingredient.is_scalable).to be true
    end

    it "returns false if validation fails" do
      form = RecipeSuggestionForm.new(
        user: user,
        # Missing title
        description: "Test description",
        ingredients_data: valid_ingredients_data
      )

      expect(form.save).to be false
    end

    it "doesn't create records if validation fails" do
      form = RecipeSuggestionForm.new(
        user: user,
        # Missing title
        description: "Test description",
        ingredients_data: valid_ingredients_data
      )

      expect { form.save }.not_to change { RecipeSuggestion.count }
    end
  end

  describe "#persisted?" do
    it "returns false for new suggestion" do
      form = RecipeSuggestionForm.new(
        user: user,
        title: "Test",
        description: "Test",
        ingredients_data: valid_ingredients_data
      )

      expect(form.persisted?).to be false
    end

    it "returns true after saving" do
      form = RecipeSuggestionForm.new(
        user: user,
        title: "Test",
        description: "Test",
        ingredients_data: valid_ingredients_data
      )

      form.save

      expect(form.persisted?).to be true
    end
  end

  describe "initialization" do
    it "initializes with empty values for new suggestion" do
      form = RecipeSuggestionForm.new

      expect(form.recipe_suggestion).to be_a(RecipeSuggestion)
      expect(form.recipe_suggestion).to be_new_record
      expect(form.title).to be_nil
      expect(form.description).to be_nil
      expect(form.tag_list).to be_nil
      expect(form.ingredients_data).to eq([])
    end

    it "initializes with existing suggestion data" do
      suggestion = RecipeSuggestion.create!(
        user: user,
        title: "Existing Title",
        description: "Existing Description",
        tag_list: "tag1, tag2"
      )

      form = RecipeSuggestionForm.new(recipe_suggestion: suggestion)

      expect(form.recipe_suggestion).to eq(suggestion)
      expect(form.title).to eq("Existing Title")
      expect(form.description).to eq("Existing Description")
      expect(form.tag_list).to eq("tag1, tag2")
    end
  end
end
