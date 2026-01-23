require 'rails_helper'

RSpec.describe "Home Page", type: :request do
  describe "GET /" do
    it "renders the landing page with key features" do
      get root_path
      expect(response).to have_http_status(:success)

      # Welcome Section
      expect(response.body).to include("Willkommen bei CocktailScout")
      expect(response.body).to include("Entdecke die Welt der Cocktails")

      # Meine Bar Feature
      expect(response.body).to include("Meine Bar")
      expect(response.body).to include("Sag uns, welche Zutaten du zu Hause hast")
      expect(response.body).to include(my_bar_path)

      # Other Features
      expect(response.body).to include("Community")
      expect(response.body).to include(forum_topics_path)

      expect(response.body).to include("Rezepte")
      expect(response.body).to include(recipes_path)

      expect(response.body).to include("Galerie")
      expect(response.body).to include(recipe_images_path)
    end
  end
end
