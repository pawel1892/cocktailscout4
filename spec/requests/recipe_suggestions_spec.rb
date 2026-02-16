require 'rails_helper'

RSpec.describe "RecipeSuggestions", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:ingredient1) { create(:ingredient, name: "Rum") }
  let(:ingredient2) { create(:ingredient, name: "Lime Juice") }
  let(:unit) { Unit.find_or_create_by!(name: "cl") { |u| u.display_name = "cl"; u.plural_name = "cl"; u.category = "volume"; u.ml_ratio = 10.0; u.divisible = true } }

  let(:valid_ingredients_json) do
    [
      {
        ingredientId: ingredient1.id,
        ingredientName: ingredient1.name,
        unitId: unit.id,
        amount: "4",
        additionalInfo: nil,
        displayName: nil,
        isOptional: false,
        isScalable: true
      },
      {
        ingredientId: ingredient2.id,
        ingredientName: ingredient2.name,
        unitId: unit.id,
        amount: "2",
        additionalInfo: nil,
        displayName: nil,
        isOptional: false,
        isScalable: true
      }
    ].to_json
  end

  describe "GET /rezeptvorschlaege" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns http success" do
        get recipe_suggestions_path
        expect(response).to have_http_status(:success)
      end

      it "shows user's own suggestions" do
        suggestion = RecipeSuggestion.create!(
          user: user,
          title: "My Cocktail",
          description: "Description",
          status: "pending"
        )

        get recipe_suggestions_path
        expect(response.body).to include("My Cocktail")
      end

      it "does not show other users' suggestions" do
        other_suggestion = RecipeSuggestion.create!(
          user: other_user,
          title: "Other User Cocktail",
          description: "Description",
          status: "pending"
        )

        get recipe_suggestions_path
        expect(response.body).not_to include("Other User Cocktail")
      end

      it "shows suggestions with all statuses" do
        reviewer = create(:user)

        pending = RecipeSuggestion.create!(
          user: user,
          title: "Pending",
          description: "Description",
          status: "pending"
        )

        approved = RecipeSuggestion.create!(
          user: user,
          title: "Approved",
          description: "Description",
          status: "approved",
          reviewed_by: reviewer,
          reviewed_at: Time.current
        )

        rejected = RecipeSuggestion.create!(
          user: user,
          title: "Rejected",
          description: "Description",
          status: "rejected",
          reviewed_by: reviewer,
          reviewed_at: Time.current,
          feedback: "Needs work"
        )

        get recipe_suggestions_path
        expect(response.body).to include("Pending")
        expect(response.body).to include("Approved")
        expect(response.body).to include("Rejected")
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        get recipe_suggestions_path
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /rezeptvorschlaege/new" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns http success" do
        get new_recipe_suggestion_path
        expect(response).to have_http_status(:success)
      end

      it "shows the suggestion form" do
        get new_recipe_suggestion_path
        expect(response.body).to include("Rezept vorschlagen")
        expect(response.body).to include("recipe-form")
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        get new_recipe_suggestion_path
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "POST /rezeptvorschlaege" do
    context "when authenticated" do
      before { sign_in(user) }

      it "creates a new suggestion with valid data" do
        expect {
          post recipe_suggestions_path, params: {
            recipe_suggestion: {
              title: "New Mojito",
              description: "Classic Cuban cocktail",
              tag_list: "rum, minze",
              ingredients_json: valid_ingredients_json
            }
          }
        }.to change { RecipeSuggestion.count }.by(1)

        suggestion = RecipeSuggestion.last
        expect(suggestion.title).to eq("New Mojito")
        expect(suggestion.description).to eq("Classic Cuban cocktail")
        expect(suggestion.user).to eq(user)
        expect(suggestion.status).to eq("pending")
        expect(response).to redirect_to(recipe_suggestions_path)
        expect(flash[:notice]).to include("eingereicht")
      end

      it "creates suggestion ingredients" do
        expect {
          post recipe_suggestions_path, params: {
            recipe_suggestion: {
              title: "New Mojito",
              description: "Classic Cuban cocktail",
              ingredients_json: valid_ingredients_json
            }
          }
        }.to change { RecipeSuggestionIngredient.count }.by(2)
      end

      it "fails with invalid data" do
        expect {
          post recipe_suggestions_path, params: {
            recipe_suggestion: {
              title: "",  # Missing title
              description: "Description",
              ingredients_json: valid_ingredients_json
            }
          }
        }.not_to change { RecipeSuggestion.count }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "fails with insufficient ingredients" do
        expect {
          post recipe_suggestions_path, params: {
            recipe_suggestion: {
              title: "Test",
              description: "Description",
              ingredients_json: [
                { ingredientId: ingredient1.id, amount: "4" }
              ].to_json
            }
          }
        }.not_to change { RecipeSuggestion.count }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        post recipe_suggestions_path, params: {
          recipe_suggestion: {
            title: "Test",
            description: "Test",
            ingredients_json: valid_ingredients_json
          }
        }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /rezeptvorschlaege/:id" do
    let(:suggestion) do
      RecipeSuggestion.create!(
        user: user,
        title: "Test Cocktail",
        description: "Test Description",
        status: "pending"
      )
    end

    context "when authenticated as owner" do
      before { sign_in(user) }

      it "returns http success" do
        get recipe_suggestion_path(suggestion)
        expect(response).to have_http_status(:success)
      end

      it "shows suggestion details" do
        get recipe_suggestion_path(suggestion)
        expect(response.body).to include("Test Cocktail")
        expect(response.body).to include("Test Description")
      end
    end

    context "when authenticated as different user" do
      before { sign_in(other_user) }

      it "cannot access other user's suggestion" do
        get recipe_suggestion_path(suggestion)
        expect(response).to redirect_to(recipe_suggestions_path)
        expect(flash[:alert]).to include("nicht gefunden")
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        get recipe_suggestion_path(suggestion)
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /rezeptvorschlaege/:id/edit" do
    context "when suggestion is pending" do
      let(:suggestion) do
        RecipeSuggestion.create!(
          user: user,
          title: "Test",
          description: "Test",
          status: "pending"
        )
      end

      before { sign_in(user) }

      it "returns http success" do
        get edit_recipe_suggestion_path(suggestion)
        expect(response).to have_http_status(:success)
      end

      it "shows edit form" do
        get edit_recipe_suggestion_path(suggestion)
        expect(response.body).to include("Vorschlag bearbeiten")
        expect(response.body).to include("recipe-form")
      end
    end

    context "when suggestion is rejected" do
      let(:reviewer) { create(:user) }
      let(:suggestion) do
        RecipeSuggestion.create!(
          user: user,
          title: "Test",
          description: "Test",
          status: "rejected",
          reviewed_by: reviewer,
          reviewed_at: Time.current,
          feedback: "Needs improvement"
        )
      end

      before { sign_in(user) }

      it "returns http success" do
        get edit_recipe_suggestion_path(suggestion)
        expect(response).to have_http_status(:success)
      end

      it "shows rejection feedback" do
        get edit_recipe_suggestion_path(suggestion)
        expect(response.body).to include("Needs improvement")
      end
    end

    context "when suggestion is approved" do
      let(:reviewer) { create(:user) }
      let(:suggestion) do
        RecipeSuggestion.create!(
          user: user,
          title: "Test",
          description: "Test",
          status: "approved",
          reviewed_by: reviewer,
          reviewed_at: Time.current
        )
      end

      before { sign_in(user) }

      it "redirects with error message" do
        get edit_recipe_suggestion_path(suggestion)
        expect(response).to redirect_to(recipe_suggestions_path)
        expect(flash[:alert]).to include("kann nicht mehr bearbeitet werden")
      end
    end

    context "when not the owner" do
      let(:suggestion) do
        RecipeSuggestion.create!(
          user: other_user,
          title: "Test",
          description: "Test",
          status: "pending"
        )
      end

      before { sign_in(user) }

      it "redirects with error" do
        get edit_recipe_suggestion_path(suggestion)
        expect(response).to redirect_to(recipe_suggestions_path)
        expect(flash[:alert]).to include("nicht gefunden")
      end
    end
  end

  describe "PATCH /rezeptvorschlaege/:id" do
    let(:suggestion) do
      sug = RecipeSuggestion.create!(
        user: user,
        title: "Original Title",
        description: "Original Description",
        status: "pending"
      )
      sug.recipe_suggestion_ingredients.create!(
        ingredient: ingredient1,
        amount: 5,
        position: 1
      )
      sug
    end

    context "when authenticated as owner" do
      before { sign_in(user) }

      context "with valid data" do
        it "updates the suggestion" do
          patch recipe_suggestion_path(suggestion), params: {
            recipe_suggestion: {
              title: "Updated Title",
              description: "Updated Description",
              tag_list: "new, tags",
              ingredients_json: valid_ingredients_json
            }
          }

          suggestion.reload
          expect(suggestion.title).to eq("Updated Title")
          expect(suggestion.description).to eq("Updated Description")
          expect(response).to redirect_to(recipe_suggestions_path)
          expect(flash[:notice]).to include("aktualisiert")
        end

        it "resets status to pending" do
          reviewer = create(:user)
          suggestion.update!(
            status: "rejected",
            reviewed_by: reviewer,
            reviewed_at: Time.current,
            feedback: "Bad"
          )

          patch recipe_suggestion_path(suggestion), params: {
            recipe_suggestion: {
              title: "Updated Title",
              description: "Updated Description",
              ingredients_json: valid_ingredients_json
            }
          }

          suggestion.reload
          expect(suggestion.status).to eq("pending")
        end

        it "replaces ingredients" do
          expect(suggestion.recipe_suggestion_ingredients.count).to eq(1)

          patch recipe_suggestion_path(suggestion), params: {
            recipe_suggestion: {
              title: "Updated Title",
              description: "Updated Description",
              ingredients_json: valid_ingredients_json
            }
          }

          suggestion.reload
          expect(suggestion.recipe_suggestion_ingredients.count).to eq(2)
        end
      end

      context "with invalid data" do
        it "fails to update" do
          patch recipe_suggestion_path(suggestion), params: {
            recipe_suggestion: {
              title: "",  # Invalid
              description: "Description",
              ingredients_json: valid_ingredients_json
            }
          }

          suggestion.reload
          expect(suggestion.title).to eq("Original Title")
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context "when suggestion is approved" do
      before do
        sign_in(user)
        reviewer = create(:user)
        suggestion.update!(
          status: "approved",
          reviewed_by: reviewer,
          reviewed_at: Time.current
        )
      end

      it "cannot update" do
        patch recipe_suggestion_path(suggestion), params: {
          recipe_suggestion: {
            title: "Updated Title",
            description: "Updated Description",
            ingredients_json: valid_ingredients_json
          }
        }

        expect(response).to redirect_to(recipe_suggestions_path)
        expect(flash[:alert]).to include("kann nicht mehr bearbeitet werden")
      end
    end

    context "when not authenticated" do
      it "redirects to login page" do
        patch recipe_suggestion_path(suggestion), params: {
          recipe_suggestion: {
            title: "Updated",
            description: "Updated",
            ingredients_json: valid_ingredients_json
          }
        }
        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
