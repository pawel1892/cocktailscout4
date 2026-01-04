require 'rails_helper'

RSpec.describe "Recipes", type: :request do
  let!(:recipe) { create(:recipe) }

  describe "GET /rezepte" do
    it "returns http success" do
      get recipes_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(recipe.title)
    end
  end

  describe "GET /rezepte/:slug" do
    let(:ingredient) { create(:ingredient, name: "Gin") }
    let!(:recipe_ingredient) { create(:recipe_ingredient, recipe: recipe, ingredient: ingredient, amount: 4, unit: "cl") }

    it "returns http success and shows details" do
      get recipe_path(recipe)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(recipe.title)
      expect(response.body).to include("Gin")
      expect(response.body).to include("4.0 cl")
    end

    it "returns 404 for non-existent slug" do
      get "/rezepte/non-existent"
      expect(response).to have_http_status(:not_found)
    end
  end
end
