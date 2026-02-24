require 'rails_helper'

RSpec.describe "Admin::Ingredients", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:recipe_moderator) { create(:user, :recipe_moderator) }
  let(:super_moderator) { create(:user, :super_moderator) }
  let(:regular_user) { create(:user) }

  describe "GET /admin/ingredients" do
    let!(:rum) { create(:ingredient, name: "Rum", alcoholic_content: 40.0) }
    let!(:vodka) { create(:ingredient, name: "Vodka", alcoholic_content: 40.0) }
    let!(:lime) { create(:ingredient, name: "Limette", alcoholic_content: 0) }
    let!(:recipe) { create(:recipe) }

    before do
      # Make rum used in a recipe
      create(:recipe_ingredient, ingredient: rum, recipe: recipe)
    end

    context "when logged in as admin" do
      before { sign_in admin }

      it "returns success" do
        get admin_ingredients_path
        expect(response).to have_http_status(:success)
      end

      it "lists all ingredients" do
        get admin_ingredients_path
        expect(response.body).to include("Rum")
        expect(response.body).to include("Vodka")
        expect(response.body).to include("Limette")
      end

      it "displays ingredient count" do
        get admin_ingredients_path
        expect(response.body).to match(/Gesamt:.*3.*Zutaten/)
      end

      it "shows recipe count for each ingredient" do
        get admin_ingredients_path
        expect(response.body).to match(/Rum.*1/m)  # Rum used in 1 recipe
      end

      it "displays alcoholic content badge" do
        get admin_ingredients_path
        expect(response.body).to include("40%")  # Rounded to integer in display
      end

      it "shows new ingredient button" do
        get admin_ingredients_path
        expect(response.body).to include("Neue Zutat erstellen")
      end
    end

    context "when logged in as recipe moderator" do
      before { sign_in recipe_moderator }

      it "returns success" do
        get admin_ingredients_path
        expect(response).to have_http_status(:success)
      end

      it "can view all ingredients" do
        get admin_ingredients_path
        expect(response.body).to include("Rum")
        expect(response.body).to include("Vodka")
      end
    end

    context "when logged in as super moderator" do
      before { sign_in super_moderator }

      it "returns success" do
        get admin_ingredients_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "redirects to root" do
        get admin_ingredients_path
        expect(response).to redirect_to(root_path)
      end

      it "shows access denied message" do
        get admin_ingredients_path
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get admin_ingredients_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    describe "filtering" do
      before { sign_in admin }

      context "by usage" do
        it "filters used ingredients" do
          get admin_ingredients_path, params: { usage: "used" }
          expect(response.body).to include("Rum")
          expect(response.body).not_to include("Vodka")
          expect(response.body).not_to include("Limette")
        end

        it "filters unused ingredients" do
          get admin_ingredients_path, params: { usage: "unused" }
          expect(response.body).to include("Vodka")
          expect(response.body).to include("Limette")
          expect(response.body).not_to include("Rum")
        end

        it "shows all ingredients when usage is empty" do
          get admin_ingredients_path, params: { usage: "" }
          expect(response.body).to include("Rum")
          expect(response.body).to include("Vodka")
          expect(response.body).to include("Limette")
        end
      end

      context "by alcohol" do
        it "filters alcoholic ingredients" do
          get admin_ingredients_path, params: { alcohol: "alcoholic" }
          expect(response.body).to include("Rum")
          expect(response.body).to include("Vodka")
          expect(response.body).not_to include("Limette")
        end

        it "filters non-alcoholic ingredients" do
          get admin_ingredients_path, params: { alcohol: "non_alcoholic" }
          expect(response.body).to include("Limette")
          expect(response.body).not_to include("Rum")
          expect(response.body).not_to include("Vodka")
        end

        it "shows all ingredients when alcohol is empty" do
          get admin_ingredients_path, params: { alcohol: "" }
          expect(response.body).to include("Rum")
          expect(response.body).to include("Vodka")
          expect(response.body).to include("Limette")
        end
      end

      context "by search query" do
        it "searches ingredients by name" do
          get admin_ingredients_path, params: { q: "Rum" }
          expect(response.body).to include("Rum")
          expect(response.body).not_to include("Vodka")
        end

        it "performs case-insensitive search" do
          get admin_ingredients_path, params: { q: "rum" }
          expect(response.body).to include("Rum")
        end

        it "shows all ingredients when query is empty" do
          get admin_ingredients_path, params: { q: "" }
          expect(response.body).to include("Rum")
          expect(response.body).to include("Vodka")
        end
      end

      context "with multiple filters" do
        it "combines usage and alcohol filters" do
          get admin_ingredients_path, params: { usage: "unused", alcohol: "alcoholic" }
          expect(response.body).to include("Vodka")
          expect(response.body).not_to include("Rum")
          expect(response.body).not_to include("Limette")
        end

        it "shows active filter badges" do
          get admin_ingredients_path, params: { usage: "used", alcohol: "alcoholic" }
          expect(response.body).to include("Aktive Filter:")
          expect(response.body).to include("Verwendung: In Rezepten verwendet")
          expect(response.body).to include("Alkohol: Alkoholisch")
        end

        it "provides filter reset link when filters are active" do
          get admin_ingredients_path, params: { usage: "used" }
          expect(response.body).to include("Filter zurücksetzen")
        end
      end
    end

    describe "sorting" do
      before { sign_in admin }

      let!(:ingredient_a) { create(:ingredient, name: "Apple", alcoholic_content: 0) }
      let!(:ingredient_z) { create(:ingredient, name: "Zucchini", alcoholic_content: 50) }
      let!(:recipe2) { create(:recipe) }

      before do
        create(:recipe_ingredient, ingredient: ingredient_a, recipe: recipe)
        create(:recipe_ingredient, ingredient: ingredient_a, recipe: recipe2)
      end

      it "sorts by name ascending by default" do
        get admin_ingredients_path
        expect(response).to have_http_status(:success)
        body_index_ingredient_a = response.body.index("Apple")
        body_index_ingredient_z = response.body.index("Zucchini")
        expect(body_index_ingredient_a).to be < body_index_ingredient_z
      end

      it "sorts by name descending when specified" do
        get admin_ingredients_path, params: { sort: "name", direction: "desc" }
        expect(response).to have_http_status(:success)
        body_index_ingredient_z = response.body.index("Zucchini")
        body_index_ingredient_a = response.body.index("Apple")
        expect(body_index_ingredient_z).to be < body_index_ingredient_a
      end

      it "sorts by recipes_count ascending when specified" do
        get admin_ingredients_path, params: { sort: "recipes_count", direction: "asc" }
        expect(response).to have_http_status(:success)
        # Ingredient with 0 recipes should appear before ingredient with 2 recipes
        body_index_ingredient_z = response.body.index("Zucchini")
        body_index_ingredient_a = response.body.index("Apple")
        expect(body_index_ingredient_z).to be < body_index_ingredient_a
      end

      it "sorts by alcoholic_content descending when specified" do
        get admin_ingredients_path, params: { sort: "alcoholic_content", direction: "desc" }
        expect(response).to have_http_status(:success)
        body_index_ingredient_z = response.body.index("Zucchini")
        body_index_ingredient_a = response.body.index("Apple")
        expect(body_index_ingredient_z).to be < body_index_ingredient_a
      end

      it "displays sort indicators in column headers" do
        get admin_ingredients_path, params: { sort: "name", direction: "asc" }
        expect(response.body).to include("↑")  # Ascending arrow
      end

      it "allows sorting by created_at" do
        get admin_ingredients_path, params: { sort: "created_at", direction: "desc" }
        expect(response).to have_http_status(:success)
      end
    end

    describe "pagination" do
      before { sign_in admin }

      it "paginates results" do
        # Create enough ingredients to trigger pagination (default limit is 50)
        create_list(:ingredient, 55)
        get admin_ingredients_path
        expect(response).to have_http_status(:success)
        # Should show pagination controls
        expect(response.body).to include("page=2")
      end
    end

    describe "delete button visibility" do
      before { sign_in admin }

      it "shows delete button for unused ingredients" do
        get admin_ingredients_path
        # Vodka and Limette are unused, should have active delete button
        expect(response.body).to match(/Vodka.*Löschen/m)
      end

      it "disables delete button for used ingredients" do
        get admin_ingredients_path
        # Rum is used, should have disabled delete button with title
        expect(response.body).to match(/Rum.*Wird in.*Rezept.*verwendet/m)
      end
    end
  end

  describe "GET /admin/ingredients/new" do
    before { sign_in admin }

    it "returns success" do
      get new_admin_ingredient_path
      expect(response).to have_http_status(:success)
    end

    it "displays the form" do
      get new_admin_ingredient_path
      expect(response.body).to include("Neue Zutat erstellen")
      expect(response.body).to include("Name")
      expect(response.body).to include("Pluralform")
      expect(response.body).to include("Alkoholgehalt")
    end
  end

  describe "POST /admin/ingredients" do
    before { sign_in admin }

    context "with valid params" do
      let(:valid_params) do
        {
          ingredient: {
            name: "Tequila",
            plural_name: "Tequilas",
            description: "A Mexican spirit",
            alcoholic_content: 40.0,
            ml_per_unit: 30.0
          }
        }
      end

      it "creates a new ingredient" do
        expect {
          post admin_ingredients_path, params: valid_params
        }.to change(Ingredient, :count).by(1)
      end

      it "redirects to index" do
        post admin_ingredients_path, params: valid_params
        expect(response).to redirect_to(admin_ingredients_path)
      end

      it "shows success message" do
        post admin_ingredients_path, params: valid_params
        expect(flash[:notice]).to eq("Zutat wurde erfolgreich erstellt.")
      end

      it "sets all attributes correctly" do
        post admin_ingredients_path, params: valid_params
        ingredient = Ingredient.last
        expect(ingredient.name).to eq("Tequila")
        expect(ingredient.plural_name).to eq("Tequilas")
        expect(ingredient.description).to eq("A Mexican spirit")
        expect(ingredient.alcoholic_content).to eq(40.0)
        expect(ingredient.ml_per_unit).to eq(30.0)
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          ingredient: {
            name: "",  # Name is required
            alcoholic_content: 150  # Out of range
          }
        }
      end

      it "does not create ingredient" do
        expect {
          post admin_ingredients_path, params: invalid_params
        }.not_to change(Ingredient, :count)
      end

      it "renders new template" do
        post admin_ingredients_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "shows error messages" do
        post admin_ingredients_path, params: invalid_params
        expect(response.body).to include("Fehler")
      end
    end

    context "with duplicate name" do
      let!(:existing_ingredient) { create(:ingredient, name: "Gin") }
      let(:duplicate_params) do
        {
          ingredient: { name: "Gin" }
        }
      end

      it "does not create ingredient" do
        expect {
          post admin_ingredients_path, params: duplicate_params
        }.not_to change(Ingredient, :count)
      end

      it "shows validation error" do
        post admin_ingredients_path, params: duplicate_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /admin/ingredients/:id/edit" do
    let!(:ingredient) { create(:ingredient, name: "Gin") }

    before { sign_in admin }

    it "returns success" do
      get edit_admin_ingredient_path(ingredient)
      expect(response).to have_http_status(:success)
    end

    it "displays the form with current values" do
      get edit_admin_ingredient_path(ingredient)
      expect(response.body).to include("Zutat bearbeiten")
      expect(response.body).to include("Gin")
    end

    context "when ingredient is used in recipes" do
      let!(:recipe) { create(:recipe) }
      let!(:recipe_ingredient) { create(:recipe_ingredient, ingredient: ingredient, recipe: recipe) }

      it "shows warning about usage" do
        get edit_admin_ingredient_path(ingredient)
        expect(response.body).to include("Achtung")
        expect(response.body).to include("1")
        expect(response.body).to include("Rezept(en) verwendet")
      end

      it "does not show delete button" do
        get edit_admin_ingredient_path(ingredient)
        expect(response.body).not_to include("Gefahrenzone")
      end
    end

    context "when ingredient is not used" do
      it "shows delete button" do
        get edit_admin_ingredient_path(ingredient)
        expect(response.body).to include("Gefahrenzone")
        expect(response.body).to include("Zutat löschen")
      end
    end
  end

  describe "PATCH /admin/ingredients/:id" do
    let!(:ingredient) { create(:ingredient, name: "Gin", alcoholic_content: 40.0) }

    before { sign_in admin }

    context "with valid params" do
      let(:valid_params) do
        {
          ingredient: {
            name: "Updated Gin",
            alcoholic_content: 42.0
          }
        }
      end

      it "updates the ingredient" do
        patch admin_ingredient_path(ingredient), params: valid_params
        ingredient.reload
        expect(ingredient.name).to eq("Updated Gin")
        expect(ingredient.alcoholic_content).to eq(42.0)
      end

      it "redirects to index" do
        patch admin_ingredient_path(ingredient), params: valid_params
        expect(response).to redirect_to(admin_ingredients_path)
      end

      it "shows success message" do
        patch admin_ingredient_path(ingredient), params: valid_params
        expect(flash[:notice]).to eq("Zutat wurde erfolgreich aktualisiert.")
      end
    end

    context "with invalid params" do
      let(:invalid_params) do
        {
          ingredient: {
            name: "",  # Name is required
            alcoholic_content: 150  # Out of range
          }
        }
      end

      it "does not update ingredient" do
        patch admin_ingredient_path(ingredient), params: invalid_params
        ingredient.reload
        expect(ingredient.name).to eq("Gin")
        expect(ingredient.alcoholic_content).to eq(40.0)
      end

      it "renders edit template" do
        patch admin_ingredient_path(ingredient), params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "shows error messages" do
        patch admin_ingredient_path(ingredient), params: invalid_params
        expect(response.body).to include("Fehler")
      end
    end
  end

  describe "DELETE /admin/ingredients/:id" do
    before { sign_in admin }

    context "when ingredient is not used in recipes" do
      let!(:ingredient) { create(:ingredient, name: "Unused Ingredient") }

      it "deletes the ingredient" do
        expect {
          delete admin_ingredient_path(ingredient)
        }.to change(Ingredient, :count).by(-1)
      end

      it "redirects to index" do
        delete admin_ingredient_path(ingredient)
        expect(response).to redirect_to(admin_ingredients_path)
      end

      it "shows success message" do
        delete admin_ingredient_path(ingredient)
        expect(flash[:notice]).to eq("Zutat wurde erfolgreich gelöscht.")
      end
    end

    context "when ingredient is used in recipes" do
      let!(:ingredient) { create(:ingredient, name: "Used Ingredient") }
      let!(:recipe) { create(:recipe) }
      let!(:recipe_ingredient) { create(:recipe_ingredient, ingredient: ingredient, recipe: recipe) }

      it "does not delete the ingredient" do
        expect {
          delete admin_ingredient_path(ingredient)
        }.not_to change(Ingredient, :count)
      end

      it "redirects to index" do
        delete admin_ingredient_path(ingredient)
        expect(response).to redirect_to(admin_ingredients_path)
      end

      it "shows error message with recipe count" do
        delete admin_ingredient_path(ingredient)
        expect(flash[:alert]).to match(/kann nicht gelöscht werden/)
        expect(flash[:alert]).to include("1")
        expect(flash[:alert]).to match(/Rezept\(en\)/)
      end

      it "ingredient still exists in database" do
        delete admin_ingredient_path(ingredient)
        expect(Ingredient.exists?(ingredient.id)).to be true
      end
    end

    context "when ingredient is used in multiple recipes" do
      let!(:ingredient) { create(:ingredient, name: "Popular Ingredient") }
      let!(:recipe1) { create(:recipe) }
      let!(:recipe2) { create(:recipe) }
      let!(:recipe_ingredient1) { create(:recipe_ingredient, ingredient: ingredient, recipe: recipe1) }
      let!(:recipe_ingredient2) { create(:recipe_ingredient, ingredient: ingredient, recipe: recipe2) }

      it "shows correct count in error message" do
        delete admin_ingredient_path(ingredient)
        expect(flash[:alert]).to include("2")
      end
    end
  end

  describe "authorization checks across all actions" do
    let(:ingredient) { create(:ingredient) }

    context "when not logged in" do
      it "index redirects to login" do
        get admin_ingredients_path
        expect(response).to redirect_to(new_session_path)
      end

      it "new redirects to login" do
        get new_admin_ingredient_path
        expect(response).to redirect_to(new_session_path)
      end

      it "create redirects to login" do
        post admin_ingredients_path, params: { ingredient: { name: "Test" } }
        expect(response).to redirect_to(new_session_path)
      end

      it "edit redirects to login" do
        get edit_admin_ingredient_path(ingredient)
        expect(response).to redirect_to(new_session_path)
      end

      it "update redirects to login" do
        patch admin_ingredient_path(ingredient), params: { ingredient: { name: "Test" } }
        expect(response).to redirect_to(new_session_path)
      end

      it "destroy redirects to login" do
        delete admin_ingredient_path(ingredient)
        expect(response).to redirect_to(new_session_path)
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "index denies access" do
        get admin_ingredients_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end

      it "new denies access" do
        get new_admin_ingredient_path
        expect(response).to redirect_to(root_path)
      end

      it "create denies access" do
        post admin_ingredients_path, params: { ingredient: { name: "Test" } }
        expect(response).to redirect_to(root_path)
      end

      it "edit denies access" do
        get edit_admin_ingredient_path(ingredient)
        expect(response).to redirect_to(root_path)
      end

      it "update denies access" do
        patch admin_ingredient_path(ingredient), params: { ingredient: { name: "Test" } }
        expect(response).to redirect_to(root_path)
      end

      it "destroy denies access" do
        delete admin_ingredient_path(ingredient)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
