require 'rails_helper'

RSpec.describe "Ingredients API", type: :request do
  describe "GET /ingredients" do
    let!(:vodka) { create(:ingredient, name: "Vodka") }
    let!(:gin) { create(:ingredient, name: "Gin") }
    let!(:rum) { create(:ingredient, name: "Rum") }

    let!(:recipe1) { create(:recipe) }
    let!(:recipe2) { create(:recipe) }
    let!(:recipe3) { create(:recipe) }

    before do
      # Vodka is in 3 recipes
      create(:recipe_ingredient, recipe: recipe1, ingredient: vodka)
      create(:recipe_ingredient, recipe: recipe2, ingredient: vodka)
      create(:recipe_ingredient, recipe: recipe3, ingredient: vodka)

      # Gin is in 1 recipe
      create(:recipe_ingredient, recipe: recipe1, ingredient: gin)

      # Rum is in no recipes
    end

    it "returns all ingredients with recipe counts" do
      get ingredients_path, headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)

      expect(json["success"]).to be true
      expect(json["ingredients"].size).to eq(3)
    end

    it "includes recipes_count for each ingredient" do
      get ingredients_path, headers: { 'Accept' => 'application/json' }

      json = JSON.parse(response.body)
      vodka_data = json["ingredients"].find { |i| i["name"] == "Vodka" }
      gin_data = json["ingredients"].find { |i| i["name"] == "Gin" }
      rum_data = json["ingredients"].find { |i| i["name"] == "Rum" }

      expect(vodka_data["recipes_count"]).to eq(3)
      expect(gin_data["recipes_count"]).to eq(1)
      expect(rum_data["recipes_count"]).to eq(0)
    end

    it "returns ingredients sorted alphabetically" do
      get ingredients_path, headers: { 'Accept' => 'application/json' }

      json = JSON.parse(response.body)
      names = json["ingredients"].map { |i| i["name"] }

      expect(names).to eq([ "Gin", "Rum", "Vodka" ])
    end

    context "with search query" do
      it "filters ingredients by name" do
        get ingredients_path, params: { q: "Vod" }, headers: { 'Accept' => 'application/json' }

        json = JSON.parse(response.body)
        expect(json["ingredients"].size).to eq(1)
        expect(json["ingredients"].first["name"]).to eq("Vodka")
      end

      it "returns empty array when no matches" do
        get ingredients_path, params: { q: "xyz" }, headers: { 'Accept' => 'application/json' }

        json = JSON.parse(response.body)
        expect(json["ingredients"].size).to eq(0)
      end

      it "returns all matching ingredients without limit" do
        25.times { |i| create(:ingredient, name: "Test #{i}") }

        get ingredients_path, params: { q: "Test" }, headers: { 'Accept' => 'application/json' }

        json = JSON.parse(response.body)
        expect(json["ingredients"].size).to eq(25)
      end
    end

    it "returns JSON format" do
      get ingredients_path, headers: { 'Accept' => 'application/json' }

      expect(response.content_type).to match(/application\/json/)
    end

    it "includes id and name for each ingredient" do
      get ingredients_path, headers: { 'Accept' => 'application/json' }

      json = JSON.parse(response.body)
      ingredient = json["ingredients"].first

      expect(ingredient).to have_key("id")
      expect(ingredient).to have_key("name")
      expect(ingredient).to have_key("recipes_count")
    end
  end
end
