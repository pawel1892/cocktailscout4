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
    let!(:comment) { create(:recipe_comment, recipe: recipe, body: "Yummy!", user: recipe.user) }

    it "returns http success and shows details" do
      get recipe_path(recipe)
      expect(response).to have_http_status(:success)
      expect(response.body).to include(recipe.title)
      expect(response.body).to include("Gin")
      expect(response.body).to include("4.0 cl")
      expect(response.body).to include("Yummy!")
    end

    it "tracks an anonymous visit" do
      expect {
        get recipe_path(recipe)
      }.to change { Visit.count }.by(1)

      visit = Visit.last
      expect(visit.user).to be_nil
      expect(visit.visitable).to eq(recipe)
    end

    it "tracks an authenticated user visit" do
      user = create(:user)
      sign_in(user)

      expect {
        get recipe_path(recipe)
      }.to change { Visit.count }.by(1)

      visit = Visit.last
      expect(visit.user).to eq(user)
      expect(visit.visitable).to eq(recipe)
    end

    it "returns 404 for non-existent slug" do
      get "/rezepte/non-existent"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "Sorting" do
    let!(:recipe1) { create(:recipe, title: "A", visits_count: 10, average_rating: 3.0) }
    let!(:recipe2) { create(:recipe, title: "B", visits_count: 50, average_rating: 5.0) }
    let!(:recipe3) { create(:recipe, title: "C", visits_count: 30, average_rating: 1.0) }

    it "sorts by visits_count desc by default" do
      get recipes_path
      expect(response.body).to match(/#{recipe2.title}.*#{recipe3.title}.*#{recipe1.title}/m)
    end

    it "sorts by title asc" do
      get recipes_path(sort: "title", direction: "asc")
      expect(response.body).to match(/#{recipe1.title}.*#{recipe2.title}.*#{recipe3.title}/m)
    end

    it "sorts by average_rating desc" do
      get recipes_path(sort: "average_rating", direction: "desc")
      expect(response.body).to match(/#{recipe2.title}.*#{recipe1.title}.*#{recipe3.title}/m)
    end
  end

  describe "Pagination" do
    before do
      # Create 51 recipes total (1 existing 'recipe' + 50 new ones)
      # We rely on Pagy default limit of 50
      create_list(:recipe, 50)
    end

    it "paginates results" do
      get recipes_path
      expect(response).to have_http_status(:success)
      # Should show 50 recipes (limit)
      expect(response.body.scan(/class="card-body/).count).to eq(50)
      # Should have link to next page
      expect(response.body).to include('rel="next"')
    end

    it "shows second page" do
      get recipes_path(page: 2)
      expect(response).to have_http_status(:success)
      # Should show remaining recipes (1 + 50 = 51 total, so 1 on page 2)
      # Wait, let!(:recipe) at top creates 1. create_list creates 50. Total 51.
      # Page 1 has 50. Page 2 has 1.
      expect(response.body.scan(/class="card-body/).count).to eq(1)
    end
  end
end
