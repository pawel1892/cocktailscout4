require 'rails_helper'

RSpec.describe "Navigation and Breadcrumbs", type: :request do
  describe "GET /" do
    it "renders the home page with correct breadcrumbs" do
      get root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Startseite")
      # "Rezepte" link in the nav
      expect(response.body).to include('Rezepte')
    end
  end

  describe "GET /rezepte" do
    it "renders the recipes index with breadcrumbs" do
      get recipes_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Startseite")
      expect(response.body).to include("/")
      # We check for the visual text in the breadcrumb area
      # Since we are checking raw HTML, we might look for the specific structure or just text proximity if possible,
      # but checking for the presence of the strings is a good start.
      # The breadcrumb for "Rezepte" is just a span, not a link.
      expect(response.body).to include('<span class="text-cs-gold font-medium" aria-current="page">Rezepte</span>')
    end
  end

  describe "GET /cocktailgalerie" do
    it "renders the gallery with breadcrumbs" do
      get recipe_images_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Startseite")
      expect(response.body).to include("Rezepte")
      expect(response.body).to include("Cocktailgalerie")

      # Check specific breadcrumb link for Rezepte
      expect(response.body).to include('href="/rezepte"')
      expect(response.body).to include('<span class="text-cs-gold font-medium" aria-current="page">Cocktailgalerie</span>')
    end
  end

  describe "GET /rezepte/:slug" do
    let!(:user) { create(:user) }
    let!(:recipe) { create(:recipe, title: "Mojito Test", user: user) }

    it "renders the recipe show page with breadcrumbs" do
      get recipe_path(recipe)
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Startseite")
      expect(response.body).to include("Rezepte")
      expect(response.body).to include("Mojito Test")

      # Check structure
      expect(response.body).to include('href="/rezepte"')
      expect(response.body).to include('<span class="text-cs-gold font-medium" aria-current="page">Mojito Test</span>')
    end
  end
end
