require 'rails_helper'

RSpec.describe "Admin::Recipes", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:recipe_moderator) { create(:user, :recipe_moderator) }
  let(:super_moderator) { create(:user, :super_moderator) }
  let(:regular_user) { create(:user) }
  let!(:published_recipe) { create(:recipe, title: "Published Recipe") }
  let!(:draft_recipe) { create(:recipe, :draft, title: "Draft Recipe") }
  let!(:deleted_recipe) { create(:recipe, :deleted, title: "Deleted Recipe") }

  describe "GET /admin/recipes" do
    context "when logged in as admin" do
      before { sign_in admin }

      it "returns success" do
        get admin_recipes_path
        expect(response).to have_http_status(:success)
      end

      it "includes deleted recipes" do
        get admin_recipes_path
        expect(response.body).to include("Deleted Recipe")
      end

      it "shows all recipes by default" do
        get admin_recipes_path
        expect(response.body).to include("Published Recipe")
        expect(response.body).to include("Draft Recipe")
        expect(response.body).to include("Deleted Recipe")
      end

      it "displays recipe count" do
        get admin_recipes_path
        expect(response.body).to match(/Gesamt:.*3.*Rezepte/)
      end
    end

    context "when logged in as recipe moderator" do
      before { sign_in recipe_moderator }

      it "returns success" do
        get admin_recipes_path
        expect(response).to have_http_status(:success)
      end

      it "can view all recipes" do
        get admin_recipes_path
        expect(response.body).to include("Published Recipe")
        expect(response.body).to include("Draft Recipe")
      end
    end

    context "when logged in as super moderator" do
      before { sign_in super_moderator }

      it "returns success" do
        get admin_recipes_path
        expect(response).to have_http_status(:success)
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "redirects to root" do
        get admin_recipes_path
        expect(response).to redirect_to(root_path)
      end

      it "shows access denied message" do
        get admin_recipes_path
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        get admin_recipes_path
        expect(response).to redirect_to(new_session_path)
      end
    end

    describe "filtering" do
      before { sign_in admin }

      context "by status" do
        it "filters draft recipes" do
          get admin_recipes_path, params: { status: "draft" }
          expect(response.body).to include("Draft Recipe")
          expect(response.body).not_to include("Published Recipe")
          expect(response.body).not_to include("Deleted Recipe")
        end

        it "filters published recipes" do
          get admin_recipes_path, params: { status: "published" }
          expect(response.body).to include("Published Recipe")
          expect(response.body).not_to include("Draft Recipe")
          expect(response.body).not_to include("Deleted Recipe")
        end

        it "filters deleted recipes" do
          get admin_recipes_path, params: { status: "deleted" }
          expect(response.body).to include("Deleted Recipe")
          expect(response.body).not_to include("Published Recipe")
          expect(response.body).not_to include("Draft Recipe")
        end

        it "shows all recipes when status is empty" do
          get admin_recipes_path, params: { status: "" }
          expect(response.body).to include("Published Recipe")
          expect(response.body).to include("Draft Recipe")
          expect(response.body).to include("Deleted Recipe")
        end
      end

      context "by needs attention" do
        let!(:recipe_needs_review) do
          recipe = create(:recipe, title: "Needs Review Recipe")
          ingredient = create(:ingredient)
          unit = Unit.find_or_create_by!(name: "cl") do |u|
            u.display_name = "cl"
            u.plural_name = "cl"
            u.category = "volume"
            u.ml_ratio = 10.0
            u.divisible = true
          end
          create(:recipe_ingredient,
                 recipe: recipe,
                 ingredient: ingredient,
                 unit: unit,
                 amount: 4.0,
                 needs_review: true)
          recipe
        end

        let!(:recipe_no_review) do
          recipe = create(:recipe, title: "No Review Recipe")
          ingredient = create(:ingredient)
          unit = Unit.find_or_create_by!(name: "cl") do |u|
            u.display_name = "cl"
            u.plural_name = "cl"
            u.category = "volume"
            u.ml_ratio = 10.0
            u.divisible = true
          end
          create(:recipe_ingredient,
                 recipe: recipe,
                 ingredient: ingredient,
                 unit: unit,
                 amount: 4.0,
                 needs_review: false)
          recipe
        end

        it "filters recipes with ingredients needing review" do
          get admin_recipes_path, params: { needs_attention: "true" }
          expect(response.body).to include("Needs Review Recipe")
          expect(response.body).not_to include("No Review Recipe")
        end

        it "shows all recipes when needs_attention is not set" do
          get admin_recipes_path
          expect(response.body).to include("Needs Review Recipe")
          expect(response.body).to include("No Review Recipe")
        end

        it "displays warning icon for recipes needing attention" do
          get admin_recipes_path
          # The view should show ⚠️ icon next to recipes that need review
          expect(response.body).to include("⚠️")
        end
      end

      context "by search query" do
        it "searches recipes by title" do
          get admin_recipes_path, params: { q: "Draft" }
          expect(response.body).to include("Draft Recipe")
          expect(response.body).not_to include("Published Recipe")
        end

        it "performs case-insensitive search" do
          get admin_recipes_path, params: { q: "draft" }
          expect(response.body).to include("Draft Recipe")
        end

        it "shows all recipes when query is empty" do
          get admin_recipes_path, params: { q: "" }
          expect(response.body).to include("Published Recipe")
          expect(response.body).to include("Draft Recipe")
        end
      end

      context "with multiple filters" do
        it "combines status and search filters" do
          get admin_recipes_path, params: { status: "draft", q: "Draft" }
          expect(response.body).to include("Draft Recipe")
          expect(response.body).not_to include("Published Recipe")
        end

        it "shows active filter badges" do
          get admin_recipes_path, params: { status: "draft", q: "test" }
          expect(response.body).to include("Aktive Filter:")
          expect(response.body).to include("Status: Entwürfe")
          expect(response.body).to include('Suche: "test"')
        end

        it "provides filter reset link when filters are active" do
          get admin_recipes_path, params: { status: "draft" }
          expect(response.body).to include("Filter zurücksetzen")
        end
      end
    end

    describe "sorting" do
      before { sign_in admin }

      let!(:recipe_a) { create(:recipe, title: "Alpha Recipe", visits_count: 10, average_rating: 4.0) }
      let!(:recipe_z) { create(:recipe, title: "Zulu Recipe", visits_count: 50, average_rating: 5.0) }

      it "sorts by visits_count descending by default" do
        get admin_recipes_path
        expect(response).to have_http_status(:success)
        # Recipe with 50 visits should appear before recipe with 10 visits in the HTML
        body_index_recipe_z = response.body.index("Zulu Recipe")
        body_index_recipe_a = response.body.index("Alpha Recipe")
        expect(body_index_recipe_z).to be < body_index_recipe_a
      end

      it "sorts by title ascending when specified" do
        get admin_recipes_path, params: { sort: "title", direction: "asc" }
        expect(response).to have_http_status(:success)
        body_index_recipe_a = response.body.index("Alpha Recipe")
        body_index_recipe_z = response.body.index("Zulu Recipe")
        expect(body_index_recipe_a).to be < body_index_recipe_z
      end

      it "sorts by title descending when specified" do
        get admin_recipes_path, params: { sort: "title", direction: "desc" }
        expect(response).to have_http_status(:success)
        body_index_recipe_z = response.body.index("Zulu Recipe")
        body_index_recipe_a = response.body.index("Alpha Recipe")
        expect(body_index_recipe_z).to be < body_index_recipe_a
      end

      it "sorts by visits_count ascending when specified" do
        get admin_recipes_path, params: { sort: "visits_count", direction: "asc" }
        expect(response).to have_http_status(:success)
        # Recipe with 10 visits should appear before recipe with 50 visits
        body_index_recipe_a = response.body.index("Alpha Recipe")
        body_index_recipe_z = response.body.index("Zulu Recipe")
        expect(body_index_recipe_a).to be < body_index_recipe_z
      end

      it "sorts by average_rating descending when specified" do
        get admin_recipes_path, params: { sort: "average_rating", direction: "desc" }
        expect(response).to have_http_status(:success)
        # Recipe with 5.0 rating should appear before recipe with 4.0 rating
        body_index_recipe_z = response.body.index("Zulu Recipe")
        body_index_recipe_a = response.body.index("Alpha Recipe")
        expect(body_index_recipe_z).to be < body_index_recipe_a
      end

      it "displays sort indicators in column headers" do
        get admin_recipes_path, params: { sort: "title", direction: "asc" }
        expect(response.body).to include("↑")  # Ascending arrow
      end

      it "allows sorting by alcohol_content" do
        get admin_recipes_path, params: { sort: "alcohol_content", direction: "desc" }
        expect(response).to have_http_status(:success)
      end

      it "allows sorting by created_at" do
        get admin_recipes_path, params: { sort: "created_at", direction: "desc" }
        expect(response).to have_http_status(:success)
      end

      it "allows sorting by updated_at" do
        get admin_recipes_path, params: { sort: "updated_at", direction: "asc" }
        expect(response).to have_http_status(:success)
      end
    end

    describe "pagination" do
      before { sign_in admin }

      it "paginates results" do
        # Create enough recipes to trigger pagination (default limit is 50)
        create_list(:recipe, 55)
        get admin_recipes_path
        expect(response).to have_http_status(:success)
        # Should show pagination controls
        expect(response.body).to include("page=2")
      end
    end

    describe "recipe links and actions" do
      before { sign_in admin }

      it "displays edit link for each recipe" do
        get admin_recipes_path
        expect(response.body).to include("Bearbeiten")
        expect(response.body).to include(edit_admin_recipe_path(published_recipe.id))
      end

      it "displays view link for each recipe" do
        get admin_recipes_path
        expect(response.body).to include("Ansehen")
        expect(response.body).to include(recipe_path(published_recipe.slug))
      end

      it "displays status badges" do
        get admin_recipes_path
        expect(response.body).to include("Veröffentlicht")
        expect(response.body).to include("Entwurf")
        expect(response.body).to include("Gelöscht")
      end

      it "displays recipe metadata" do
        get admin_recipes_path
        expect(response.body).to include(published_recipe.user.username)
        expect(response.body).to include(published_recipe.visits_count.to_s)
      end
    end
  end

  describe "GET /admin/recipes/new" do
    context "when logged in as admin" do
      before { sign_in admin }

      it "returns success" do
        get new_admin_recipe_path
        expect(response).to have_http_status(:success)
      end

      it "displays the recipe form" do
        get new_admin_recipe_path
        expect(response.body).to include("Neues Rezept erstellen")
        expect(response.body).to include("recipe-form")
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "redirects to root" do
        get new_admin_recipe_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /admin/recipes" do
    let!(:rum) { create(:ingredient, name: "Rum") }
    let!(:lime) { create(:ingredient, name: "Lime") }
    let!(:cl_unit) { create(:unit, name: "cl") }
    let!(:piece_unit) { create(:unit, name: "piece") }
    let(:valid_params) do
      {
        recipe: {
          title: "New Test Recipe",
          description: "A delicious cocktail",
          tag_list: "classic, strong",
          is_public: "true",
          ingredients_json: JSON.generate([
            {
              ingredientId: rum.id,
              ingredientName: rum.name,
              unitId: cl_unit.id,
              amount: "4",
              additionalInfo: "",
              displayName: "",
              isOptional: false,
              isScalable: true
            },
            {
              ingredientId: lime.id,
              ingredientName: lime.name,
              unitId: piece_unit.id,
              amount: "1",
              additionalInfo: "",
              displayName: "",
              isOptional: false,
              isScalable: true
            }
          ])
        }
      }
    end

    context "when logged in as admin" do
      before { sign_in admin }

      it "creates a new recipe" do
        expect {
          post admin_recipes_path, params: valid_params
        }.to change(Recipe, :count).by(1)
      end

      it "redirects to admin recipes index" do
        post admin_recipes_path, params: valid_params
        expect(response).to redirect_to(admin_recipes_path)
      end

      it "sets the current user as the recipe owner" do
        post admin_recipes_path, params: valid_params
        expect(Recipe.last.user).to eq(admin)
      end

      it "creates recipe ingredients" do
        post admin_recipes_path, params: valid_params
        expect(Recipe.last.recipe_ingredients.count).to eq(2)
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "redirects to root" do
        post admin_recipes_path, params: valid_params
        expect(response).to redirect_to(root_path)
      end

      it "does not create a recipe" do
        expect {
          post admin_recipes_path, params: valid_params
        }.not_to change(Recipe, :count)
      end
    end

    context "with invalid params" do
      before { sign_in admin }

      it "renders new template with errors" do
        post admin_recipes_path, params: { recipe: { title: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /admin/recipes/:id/edit" do
    context "when logged in as admin" do
      before { sign_in admin }

      it "returns success" do
        get edit_admin_recipe_path(published_recipe.id)
        expect(response).to have_http_status(:success)
      end

      it "displays the recipe form with existing data" do
        get edit_admin_recipe_path(published_recipe.id)
        expect(response.body).to include("Rezept bearbeiten")
        expect(response.body).to include(published_recipe.title)
        expect(response.body).to include("recipe-form")
      end

      it "can edit deleted recipes" do
        get edit_admin_recipe_path(deleted_recipe.id)
        expect(response).to have_http_status(:success)
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "redirects to root" do
        get edit_admin_recipe_path(published_recipe.id)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "PATCH /admin/recipes/:id" do
    let!(:vodka) { create(:ingredient, name: "Vodka") }
    let!(:cranberry) { create(:ingredient, name: "Cranberry Juice") }
    let!(:ml_unit) { create(:unit, name: "ml") }
    let(:update_params) do
      {
        recipe: {
          title: "Updated Recipe Title",
          description: "Updated description",
          tag_list: "updated, tags",
          is_public: "false",
          ingredients_json: JSON.generate([
            {
              ingredientId: vodka.id,
              ingredientName: vodka.name,
              unitId: ml_unit.id,
              amount: "50",
              additionalInfo: "",
              displayName: "",
              isOptional: false,
              isScalable: true
            },
            {
              ingredientId: cranberry.id,
              ingredientName: cranberry.name,
              unitId: ml_unit.id,
              amount: "100",
              additionalInfo: "",
              displayName: "",
              isOptional: false,
              isScalable: true
            }
          ])
        }
      }
    end

    context "when logged in as admin" do
      before { sign_in admin }

      it "updates the recipe" do
        patch admin_recipe_path(published_recipe.id), params: update_params
        published_recipe.reload
        expect(published_recipe.title).to eq("Updated Recipe Title")
        expect(published_recipe.description).to eq("Updated description")
      end

      it "redirects to admin recipes index" do
        patch admin_recipe_path(published_recipe.id), params: update_params
        expect(response).to redirect_to(admin_recipes_path)
      end

      it "can update deleted recipes" do
        patch admin_recipe_path(deleted_recipe.id), params: update_params
        deleted_recipe.reload
        expect(deleted_recipe.title).to eq("Updated Recipe Title")
      end

      it "uses ID in URL, not slug" do
        # This test ensures we're using ID-based routing
        expect {
          patch admin_recipe_path(published_recipe.id), params: update_params
        }.not_to raise_error
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "redirects to root" do
        patch admin_recipe_path(published_recipe.id), params: update_params
        expect(response).to redirect_to(root_path)
      end

      it "does not update the recipe" do
        original_title = published_recipe.title
        patch admin_recipe_path(published_recipe.id), params: update_params
        published_recipe.reload
        expect(published_recipe.title).to eq(original_title)
      end
    end

    context "with invalid params" do
      before { sign_in admin }

      it "renders edit template with errors" do
        patch admin_recipe_path(published_recipe.id), params: { recipe: { title: "" } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "DELETE /admin/recipes/:id" do
    context "when logged in as admin" do
      before { sign_in admin }

      it "soft deletes the recipe" do
        delete admin_recipe_path(published_recipe.id)
        published_recipe.reload
        expect(published_recipe.is_deleted).to be true
      end

      it "redirects to admin recipes index" do
        delete admin_recipe_path(published_recipe.id)
        expect(response).to redirect_to(admin_recipes_path)
      end

      it "uses ID in URL, not slug" do
        # This test ensures we're using ID-based routing
        expect {
          delete admin_recipe_path(published_recipe.id)
        }.not_to raise_error
      end
    end

    context "when logged in as regular user" do
      before { sign_in regular_user }

      it "redirects to root" do
        delete admin_recipe_path(published_recipe.id)
        expect(response).to redirect_to(root_path)
      end

      it "does not delete the recipe" do
        delete admin_recipe_path(published_recipe.id)
        published_recipe.reload
        expect(published_recipe.is_deleted).to be false
      end
    end
  end
end
