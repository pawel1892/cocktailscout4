require 'rails_helper'

RSpec.describe "Recipes", type: :request do
  let!(:recipe) { create(:recipe) }

  # Helper method to authenticate requests
  def sign_in(user)
    @session = Session.create!(user: user, ip_address: "127.0.0.1", user_agent: "Test")
    # Stub the authentication check to set Current.session for each request
    allow_any_instance_of(ApplicationController).to receive(:resume_session).and_wrap_original do |original_method, *args|
      Current.session = @session
      @session
    end
  end

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
end
