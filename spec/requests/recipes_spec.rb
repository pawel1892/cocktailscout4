require 'rails_helper'

RSpec.describe "Recipes", type: :request do
  let!(:recipe) { create(:recipe) }

  describe "GET /rezepte" do
    it "returns http success" do
      get recipes_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include(recipe.title)

      # Meta Tags
      expect(response.body).to include('<title>Cocktail-Rezepte | CocktailScout</title>')
      expect(response.body).to include('name="description" content="Entdecke die besten Cocktail-Rezepte')
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

      # Meta Tags
      expect(response.body).to include("<title>#{recipe.title} | CocktailScout</title>")

      # Structured Data
      expect(response.body).to include('<script type="application/ld+json">')
      expect(response.body).to include('"@type":"Recipe"')
      expect(response.body).to include("\"name\":\"#{recipe.title}\"")
    end

    context "ingredient display" do
      it "shows only the description when present" do
        ingredient_with_desc = create(:ingredient, name: "Tequila")
        create(:recipe_ingredient,
          recipe: recipe,
          ingredient: ingredient_with_desc,
          amount: 1.0,
          unit: "cl",
          description: "1,5cl Tequila (weiss)"
        )

        get recipe_path(recipe)

        expect(response).to have_http_status(:success)
        # Should show the description
        expect(response.body).to include("1,5cl Tequila (weiss)")
        # Should NOT show the calculated amount + ingredient name
        expect(response.body).not_to match(/<strong>1\.0 cl<\/strong>\s+Tequila/)
      end

      it "shows amount + unit + ingredient name when description is missing" do
        get recipe_path(recipe)

        expect(response).to have_http_status(:success)
        # Should show the calculated values (from the let! recipe_ingredient without description)
        expect(response.body).to include("4.0 cl")
        expect(response.body).to include("Gin")
        # Should show them in the correct format with <strong> tag
        expect(response.body).to match(/<strong>4\.0 cl<\/strong>\s+Gin/)
      end

      it "handles mix of ingredients with and without descriptions" do
        # Ingredient with description
        vodka = create(:ingredient, name: "Vodka")
        create(:recipe_ingredient,
          recipe: recipe,
          ingredient: vodka,
          amount: 2.0,
          unit: "cl",
          description: "2cl Vodka (premium)"
        )

        # Ingredient without description (Gin already created in let!)

        get recipe_path(recipe)

        expect(response).to have_http_status(:success)
        # Should show description for Vodka
        expect(response.body).to include("2cl Vodka (premium)")
        expect(response.body).not_to match(/<strong>2\.0 cl<\/strong>\s+Vodka/)

        # Should show calculated values for Gin
        expect(response.body).to match(/<strong>4\.0 cl<\/strong>\s+Gin/)
      end
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

    context "with many comments" do
      before do
        # Create 35 comments to trigger pagination (30 per page)
        create_list(:recipe_comment, 35, recipe: recipe, user: recipe.user)
      end

      it "paginates comments when there are more than 30" do
        get recipe_path(recipe)
        expect(response).to have_http_status(:success)

        # Should show 30 comments on first page (plus 1 from let! above = 36 total, 30 displayed)
        # Count comment containers by their id attribute (more specific than class)
        expect(response.body.scan(/id="comment-\d+"/).count).to eq(30)

        # Should have pagination controls with pagy_id parameter
        expect(response.body).to include('comments=2')
      end

      it "shows remaining comments on second page" do
        get recipe_path(recipe), params: { comments: 2 }
        expect(response).to have_http_status(:success)

        # Should show remaining 6 comments (36 total - 30 on page 1)
        expect(response.body.scan(/id="comment-\d+"/).count).to eq(6)
      end
    end

    context "with images" do
      it "displays approved recipe images in gallery" do
        approved_image = create(:recipe_image, :with_image, :approved, recipe: recipe, user: recipe.user)

        get recipe_path(recipe)

        expect(response).to have_http_status(:success)
        # Check for the Vue component
        expect(response.body).to include('<recipe-image-gallery>')
        # Check for the JavaScript data with the image ID
        expect(response.body).to include('window.recipeImages')
        expect(response.body).to include("\"id\":#{approved_image.id}")
      end

      it "does not display non-approved recipe images" do
        pending_image = create(:recipe_image, :with_image, :pending, recipe: recipe, user: recipe.user)

        get recipe_path(recipe)

        expect(response).to have_http_status(:success)
        # Should not show the gallery component
        expect(response.body).not_to include('<recipe-image-gallery>')
        # Should not include the JavaScript data
        expect(response.body).not_to include('window.recipeImages')
        # Should not include the pending image ID
        expect(response.body).not_to include("\"id\":#{pending_image.id}")
      end

      it "shows only approved images when both approved and pending exist" do
        approved_image = create(:recipe_image, :with_image, :approved, recipe: recipe, user: recipe.user)
        pending_image = create(:recipe_image, :with_image, :pending, recipe: recipe, user: recipe.user)

        get recipe_path(recipe)

        expect(response).to have_http_status(:success)
        # Should show the gallery component
        expect(response.body).to include('<recipe-image-gallery>')
        # Should include the approved image ID
        expect(response.body).to include("\"id\":#{approved_image.id}")
        # Should NOT include the pending image ID
        expect(response.body).not_to include("\"id\":#{pending_image.id}")
      end

      it "displays multiple approved images in gallery" do
        approved_image1 = create(:recipe_image, :with_image, :approved, recipe: recipe, user: recipe.user)
        approved_image2 = create(:recipe_image, :with_image, :approved, recipe: recipe, user: recipe.user)

        get recipe_path(recipe)

        expect(response).to have_http_status(:success)
        # Should include both approved image IDs in the JavaScript data
        expect(response.body).to include("\"id\":#{approved_image1.id}")
        expect(response.body).to include("\"id\":#{approved_image2.id}")
      end
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

  describe "Filtering" do
    let!(:recipe1) { create(:recipe, title: "Strong Drink", average_rating: 9.5) }
    let!(:recipe2) { create(:recipe, title: "Weak Drink", average_rating: 4.5) }
    let!(:recipe3) { create(:recipe, title: "Fruity Drink", average_rating: 8.0) }
    let!(:ingredient) { create(:ingredient, name: "Lemon") }
    let!(:other_ingredient) { create(:ingredient, name: "Vodka") }

    before do
      recipe1.tag_list.add("Strong")
      recipe1.save
      recipe3.tag_list.add("Fruity")
      recipe3.save
      create(:recipe_ingredient, recipe: recipe3, ingredient: ingredient)
      create(:recipe_ingredient, recipe: recipe2, ingredient: other_ingredient)
    end

    it "filters by min_rating" do
      get recipes_path(min_rating: 8)
      expect(response.body).to include(recipe1.title)
      expect(response.body).to include(recipe3.title)
      expect(response.body).not_to include(recipe2.title)
    end

    it "filters by tag" do
      get recipes_path(tag: "Strong")
      expect(response.body).to include(recipe1.title)
      expect(response.body).not_to include(recipe2.title)
      expect(response.body).not_to include(recipe3.title)
    end

    it "filters by ingredient" do
      get recipes_path(ingredient_id: ingredient.id)
      expect(response.body).to include(recipe3.title)
      expect(response.body).not_to include(recipe1.title)
      expect(response.body).not_to include(recipe2.title)
    end

    it "combines filters" do
      # Recipe 3 is Fruity (Tag) and has Lemon (Ingredient) and Rating 8.0
      # Recipe 1 is Strong (Tag) and Rating 9.5, but no Lemon
      get recipes_path(min_rating: 8, ingredient_id: ingredient.id)
      expect(response.body).to include(recipe3.title)
      expect(response.body).not_to include(recipe1.title)
      expect(response.body).not_to include(recipe2.title)
    end

    it "shows no recipes found message" do
      get recipes_path(tag: "NonExistentTag")
      expect(response.body).to include("Keine Rezepte gefunden")
      expect(response.body).to include("Alle Filter zurücksetzen")
    end

        it "searches by title" do
      get recipes_path(q: "Strong")
      expect(response.body).to include(recipe1.title)
      expect(response.body).not_to include(recipe2.title)
    end

    describe "Favorites filter" do
      let(:user) { create(:user) }
      let!(:fav_recipe) { create(:recipe, title: "My Fav") }
      let!(:other_recipe) { create(:recipe, title: "Not Fav") }

      before do
        Favorite.create!(user: user, favoritable: fav_recipe)
      end

      it "shows only favorited recipes when authenticated and filter is active" do
        sign_in(user)
        get recipes_path(filter: "favorites")
        expect(response.body).to include("My Fav")
        expect(response.body).not_to include("Not Fav")
      end

      it "ignores favorites filter when not authenticated" do
        get recipes_path(filter: "favorites")
        # Should show all (default sort logic applies, usually visits/desc)
        expect(response.body).to include("My Fav")
        expect(response.body).to include("Not Fav")
      end

      it "shows all recipes when filter is not active" do
        sign_in(user)
        get recipes_path
        expect(response.body).to include("My Fav")
        expect(response.body).to include("Not Fav")
      end
    end
  end
end
