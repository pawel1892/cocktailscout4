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
        expect(response.body).to include(edit_recipe_path(published_recipe.slug))
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
end
