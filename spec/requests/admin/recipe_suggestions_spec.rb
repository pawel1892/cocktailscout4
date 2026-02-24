require 'rails_helper'

RSpec.describe "Admin::RecipeSuggestions", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:recipe_moderator) { create(:user, :recipe_moderator) }
  let(:super_moderator) { create(:user, :super_moderator) }
  let(:regular_user) { create(:user) }
  let(:submitter) { create(:user) }

  let(:ingredient1) { create(:ingredient, name: "Rum") }
  let(:ingredient2) { create(:ingredient, name: "Lime Juice") }
  let(:unit) { Unit.find_or_create_by!(name: "cl") { |u| u.display_name = "cl"; u.plural_name = "cl"; u.category = "volume"; u.ml_ratio = 10.0; u.divisible = true } }

  let!(:pending_suggestion) do
    sug = RecipeSuggestion.create!(
      user: submitter,
      title: "Pending Mojito",
      description: "Classic Cuban cocktail with mint and lime",
      tag_list: "rum, minze, klassiker",
      status: "pending"
    )
    sug.recipe_suggestion_ingredients.create!(
      ingredient: ingredient1,
      unit: unit,
      amount: 5,
      position: 1
    )
    sug.recipe_suggestion_ingredients.create!(
      ingredient: ingredient2,
      unit: unit,
      amount: 2,
      position: 2
    )
    sug
  end

  let!(:approved_suggestion) do
    RecipeSuggestion.create!(
      user: submitter,
      title: "Approved Cocktail",
      description: "Already approved",
      status: "approved",
      reviewed_by: admin,
      reviewed_at: 1.day.ago
    )
  end

  let!(:rejected_suggestion) do
    RecipeSuggestion.create!(
      user: submitter,
      title: "Rejected Cocktail",
      description: "Was rejected",
      status: "rejected",
      reviewed_by: admin,
      reviewed_at: 1.day.ago,
      feedback: "Not good enough"
    )
  end

  describe "GET /admin/recipe_suggestions" do
    context "as admin" do
      before { sign_in(admin) }

      it "returns http success" do
        get admin_recipe_suggestions_path
        expect(response).to have_http_status(:success)
      end

      it "shows all suggestions by default" do
        get admin_recipe_suggestions_path
        expect(response.body).to include("Pending Mojito")
        expect(response.body).to include("Approved Cocktail")
        expect(response.body).to include("Rejected Cocktail")
      end

      it "filters by pending status" do
        get admin_recipe_suggestions_path, params: { status: "pending" }
        expect(response.body).to include("Pending Mojito")
        expect(response.body).not_to include("Approved Cocktail")
        expect(response.body).not_to include("Rejected Cocktail")
      end

      it "filters by approved status" do
        get admin_recipe_suggestions_path, params: { status: "approved" }
        expect(response.body).to include("Approved Cocktail")
        expect(response.body).not_to include("Pending Mojito")
        expect(response.body).not_to include("Rejected Cocktail")
      end

      it "filters by rejected status" do
        get admin_recipe_suggestions_path, params: { status: "rejected" }
        expect(response.body).to include("Rejected Cocktail")
        expect(response.body).not_to include("Pending Mojito")
        expect(response.body).not_to include("Approved Cocktail")
      end
    end

    context "as recipe moderator" do
      before { sign_in(recipe_moderator) }

      it "returns http success" do
        get admin_recipe_suggestions_path
        expect(response).to have_http_status(:success)
      end
    end

    context "as super moderator" do
      before { sign_in(super_moderator) }

      it "returns http success" do
        get admin_recipe_suggestions_path
        expect(response).to have_http_status(:success)
      end
    end

    context "as regular user" do
      before { sign_in(regular_user) }

      it "redirects to root with error" do
        get admin_recipe_suggestions_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        get admin_recipe_suggestions_path
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /admin/recipe_suggestions/:id" do
    context "as recipe moderator" do
      before { sign_in(recipe_moderator) }

      it "returns http success" do
        get admin_recipe_suggestion_path(pending_suggestion)
        expect(response).to have_http_status(:success)
      end

      it "shows suggestion details" do
        get admin_recipe_suggestion_path(pending_suggestion)
        expect(response.body).to include("Pending Mojito")
        expect(response.body).to include("Classic Cuban cocktail")
        expect(response.body).to include(submitter.username)
      end

      it "shows ingredients" do
        get admin_recipe_suggestion_path(pending_suggestion)
        expect(response.body).to include("Rum")
        expect(response.body).to include("Lime Juice")
      end

      it "shows approve/reject buttons for pending" do
        get admin_recipe_suggestion_path(pending_suggestion)
        expect(response.body).to include("Vorschlag genehmigen")
        expect(response.body).to include("Vorschlag ablehnen")
      end

      it "shows feedback for rejected suggestions" do
        get admin_recipe_suggestion_path(rejected_suggestion)
        expect(response.body).to include("Not good enough")
      end
    end

    context "as regular user" do
      before { sign_in(regular_user) }

      it "redirects to root with error" do
        get admin_recipe_suggestion_path(pending_suggestion)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end
    end
  end

  describe "POST /admin/recipe_suggestions/:id/approve" do
    context "as recipe moderator" do
      before { sign_in(recipe_moderator) }

      it "approves the suggestion and creates a recipe" do
        expect {
          post approve_admin_recipe_suggestion_path(pending_suggestion)
        }.to change { Recipe.count }.by(1)

        pending_suggestion.reload
        expect(pending_suggestion.status).to eq("approved")
        expect(pending_suggestion.reviewed_by).to eq(recipe_moderator)
        expect(pending_suggestion.reviewed_at).to be_present
        expect(pending_suggestion.published_recipe).to be_present
      end

      it "creates recipe with correct attributes" do
        post approve_admin_recipe_suggestion_path(pending_suggestion)

        recipe = Recipe.last
        expect(recipe.title).to eq("Pending Mojito")
        expect(recipe.description).to eq("Classic Cuban cocktail with mint and lime")
        expect(recipe.user).to eq(submitter)  # Original author preserved
        expect(recipe.is_public).to be true
        expect(recipe.tag_list).to include("rum", "minze", "klassiker")
      end

      it "creates recipe with correct ingredients" do
        expect {
          post approve_admin_recipe_suggestion_path(pending_suggestion)
        }.to change { RecipeIngredient.count }.by(2)

        recipe = Recipe.last
        expect(recipe.recipe_ingredients.count).to eq(2)

        first_ingredient = recipe.recipe_ingredients.first
        expect(first_ingredient.ingredient).to eq(ingredient1)
        expect(first_ingredient.unit).to eq(unit)
        expect(first_ingredient.amount).to eq(5.0)
      end

      it "links the created recipe to the suggestion" do
        post approve_admin_recipe_suggestion_path(pending_suggestion)

        pending_suggestion.reload
        expect(pending_suggestion.published_recipe).to eq(Recipe.last)
      end

      it "redirects with success notice" do
        post approve_admin_recipe_suggestion_path(pending_suggestion)
        expect(response).to redirect_to(admin_recipe_suggestions_path)
        expect(flash[:notice]).to include("genehmigt")
      end
    end

    context "as admin" do
      before { sign_in(admin) }

      it "can approve suggestions" do
        expect {
          post approve_admin_recipe_suggestion_path(pending_suggestion)
        }.to change { Recipe.count }.by(1)

        pending_suggestion.reload
        expect(pending_suggestion.reviewed_by).to eq(admin)
      end
    end

    context "as super moderator" do
      before { sign_in(super_moderator) }

      it "can approve suggestions" do
        expect {
          post approve_admin_recipe_suggestion_path(pending_suggestion)
        }.to change { Recipe.count }.by(1)

        pending_suggestion.reload
        expect(pending_suggestion.reviewed_by).to eq(super_moderator)
      end
    end

    context "as regular user" do
      before { sign_in(regular_user) }

      it "redirects to root with error" do
        post approve_admin_recipe_suggestion_path(pending_suggestion)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end

      it "does not create a recipe" do
        expect {
          post approve_admin_recipe_suggestion_path(pending_suggestion)
        }.not_to change { Recipe.count }
      end
    end
  end

  describe "POST /admin/recipe_suggestions/:id/reject" do
    context "as recipe moderator" do
      before { sign_in(recipe_moderator) }

      it "rejects the suggestion with feedback" do
        post reject_admin_recipe_suggestion_path(pending_suggestion),
             params: { feedback: "Needs more details about preparation" }

        pending_suggestion.reload
        expect(pending_suggestion.status).to eq("rejected")
        expect(pending_suggestion.reviewed_by).to eq(recipe_moderator)
        expect(pending_suggestion.reviewed_at).to be_present
        expect(pending_suggestion.feedback).to eq("Needs more details about preparation")
      end

      it "does not create a recipe" do
        expect {
          post reject_admin_recipe_suggestion_path(pending_suggestion),
               params: { feedback: "Not good enough" }
        }.not_to change { Recipe.count }
      end

      it "redirects with success notice" do
        post reject_admin_recipe_suggestion_path(pending_suggestion),
             params: { feedback: "Not good enough" }

        expect(response).to redirect_to(admin_recipe_suggestions_path)
        expect(flash[:notice]).to include("abgelehnt")
      end
    end

    context "as admin" do
      before { sign_in(admin) }

      it "can reject suggestions" do
        post reject_admin_recipe_suggestion_path(pending_suggestion),
             params: { feedback: "Admin rejection" }

        pending_suggestion.reload
        expect(pending_suggestion.status).to eq("rejected")
        expect(pending_suggestion.reviewed_by).to eq(admin)
        expect(pending_suggestion.feedback).to eq("Admin rejection")
      end
    end

    context "as super moderator" do
      before { sign_in(super_moderator) }

      it "can reject suggestions" do
        post reject_admin_recipe_suggestion_path(pending_suggestion),
             params: { feedback: "Super mod rejection" }

        pending_suggestion.reload
        expect(pending_suggestion.status).to eq("rejected")
        expect(pending_suggestion.reviewed_by).to eq(super_moderator)
      end
    end

    context "as regular user" do
      before { sign_in(regular_user) }

      it "redirects to root with error" do
        post reject_admin_recipe_suggestion_path(pending_suggestion),
             params: { feedback: "Should not work" }

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end

      it "does not reject the suggestion" do
        post reject_admin_recipe_suggestion_path(pending_suggestion),
             params: { feedback: "Should not work" }

        pending_suggestion.reload
        expect(pending_suggestion.status).to eq("pending")
      end
    end
  end

  describe "GET /admin/recipe_suggestions/count" do
    context "as recipe moderator" do
      before { sign_in(recipe_moderator) }

      it "returns pending suggestion count as JSON" do
        get count_admin_recipe_suggestions_path
        expect(response).to have_http_status(:success)

        json = JSON.parse(response.body)
        expect(json["count"]).to eq(1)  # Only pending_suggestion
      end

      it "returns correct count with multiple pending suggestions" do
        RecipeSuggestion.create!(
          user: submitter,
          title: "Another Pending",
          description: "Description",
          status: "pending"
        )

        get count_admin_recipe_suggestions_path
        json = JSON.parse(response.body)
        expect(json["count"]).to eq(2)
      end

      it "does not count approved or rejected suggestions" do
        get count_admin_recipe_suggestions_path
        json = JSON.parse(response.body)

        # We have 1 pending, 1 approved, 1 rejected
        expect(json["count"]).to eq(1)
      end
    end

    context "as admin" do
      before { sign_in(admin) }

      it "returns pending suggestion count" do
        get count_admin_recipe_suggestions_path
        json = JSON.parse(response.body)
        expect(json["count"]).to eq(1)
      end
    end

    context "as super moderator" do
      before { sign_in(super_moderator) }

      it "returns pending suggestion count" do
        get count_admin_recipe_suggestions_path
        json = JSON.parse(response.body)
        expect(json["count"]).to eq(1)
      end
    end

    context "as regular user" do
      before { sign_in(regular_user) }

      it "redirects to root with error" do
        get count_admin_recipe_suggestions_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq("Zugriff verweigert.")
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        get count_admin_recipe_suggestions_path
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "approval workflow integration" do
    before { sign_in(recipe_moderator) }

    it "complete workflow: pending -> approved -> recipe created" do
      # Start with pending
      expect(pending_suggestion.status).to eq("pending")
      expect(pending_suggestion.published_recipe).to be_nil

      # Approve
      post approve_admin_recipe_suggestion_path(pending_suggestion)

      # Check suggestion updated
      pending_suggestion.reload
      expect(pending_suggestion.status).to eq("approved")
      expect(pending_suggestion.reviewed_by).to eq(recipe_moderator)
      expect(pending_suggestion.published_recipe).to be_present

      # Check recipe created
      recipe = pending_suggestion.published_recipe
      expect(recipe.title).to eq(pending_suggestion.title)
      expect(recipe.user).to eq(submitter)
      expect(recipe.is_public).to be true
    end

    it "complete workflow: pending -> rejected -> resubmitted -> approved" do
      # Reject first
      post reject_admin_recipe_suggestion_path(pending_suggestion),
           params: { feedback: "Needs improvement" }

      pending_suggestion.reload
      expect(pending_suggestion.status).to eq("rejected")

      # User edits and resubmits (simulated by updating status)
      pending_suggestion.update!(status: "pending")

      # Now approve
      post approve_admin_recipe_suggestion_path(pending_suggestion)

      pending_suggestion.reload
      expect(pending_suggestion.status).to eq("approved")
      expect(pending_suggestion.published_recipe).to be_present
    end
  end
end
