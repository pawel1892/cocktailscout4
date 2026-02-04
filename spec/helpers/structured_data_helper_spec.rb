require 'rails_helper'

RSpec.describe StructuredDataHelper, type: :helper do
  describe "#recipe_structured_data" do
    let(:user) { create(:user, username: "Mixologist") }
    let(:recipe) { create(:recipe, title: "Daiquiri", description: "Classic rum cocktail", user: user, alcohol_content: 15) }
    let(:ingredient) { create(:ingredient, name: "Rum") }

    before do
      create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 6, unit: "cl")
      recipe.tag_list.add("Sour")
      recipe.save
    end

    it "generates valid JSON-LD for a recipe" do
      output = helper.recipe_structured_data(recipe)

      # Extract the JSON content from the script tag
      json_string = output.match(/<script type="application\/ld\+json">(.*?)<\/script>/m)[1]
      data = JSON.parse(json_string)

      expect(data["@context"]).to eq("https://schema.org")
      expect(data["@type"]).to eq("Recipe")
      expect(data["name"]).to eq("Daiquiri")
      expect(data["description"]).to eq("Classic rum cocktail")
      expect(data["author"]["name"]).to eq("Mixologist")
      expect(data["alcoholContent"]).to eq("15.0% ABV")
      expect(data["keywords"]).to eq("Sour")
      expect(data["recipeIngredient"]).to include("6.0 cl Rum")
    end

    it "includes aggregate rating if ratings exist" do
      create(:rating, rateable: recipe, score: 5)
      recipe.reload # reload to update counter cache or calculation

      output = helper.recipe_structured_data(recipe)
      json_string = output.match(/<script type="application\/ld\+json">(.*?)<\/script>/m)[1]
      data = JSON.parse(json_string)

      expect(data["aggregateRating"]).to be_present
      expect(data["aggregateRating"]["ratingValue"]).to eq(5.0)
    end

    it "handles missing alcohol content" do
      recipe.alcohol_content = nil

      output = helper.recipe_structured_data(recipe)
      json_string = output.match(/<script type="application\/ld\+json">(.*?)<\/script>/m)[1]
      data = JSON.parse(json_string)

      expect(data).not_to have_key("alcoholContent")
    end
  end
end
