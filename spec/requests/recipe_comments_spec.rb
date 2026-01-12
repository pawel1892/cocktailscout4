require 'rails_helper'

RSpec.describe "RecipeComments", type: :request do
  let(:recipe) { create(:recipe) }
  let(:user) { create(:user) }

  describe "POST /rezepte/:recipe_id/kommentare" do
    context "when user is authenticated" do
      before { sign_in(user) }

      context "with valid parameters" do
        let(:valid_params) do
          { recipe_comment: { body: "This is a great recipe!" } }
        end

        it "creates a new comment" do
          expect {
            post recipe_recipe_comments_path(recipe), params: valid_params
          }.to change { RecipeComment.count }.by(1)
        end

        it "associates the comment with the current user" do
          post recipe_recipe_comments_path(recipe), params: valid_params
          comment = RecipeComment.last
          expect(comment.user).to eq(user)
        end

        it "associates the comment with the recipe" do
          post recipe_recipe_comments_path(recipe), params: valid_params
          comment = RecipeComment.last
          expect(comment.recipe).to eq(recipe)
        end

        it "redirects to the recipe with anchor to the new comment" do
          post recipe_recipe_comments_path(recipe), params: valid_params
          comment = RecipeComment.last
          expect(response).to redirect_to(recipe_path(recipe, anchor: "comment-#{comment.id}"))
        end

        it "displays a success flash message" do
          post recipe_recipe_comments_path(recipe), params: valid_params
          expect(flash[:notice]).to eq("Kommentar erfolgreich hinzugefügt.")
        end
      end

      context "with invalid parameters" do
        context "when body is empty" do
          let(:invalid_params) do
            { recipe_comment: { body: "" } }
          end

          it "does not create a new comment" do
            expect {
              post recipe_recipe_comments_path(recipe), params: invalid_params
            }.not_to change { RecipeComment.count }
          end

          it "re-renders the recipe page with unprocessable content status" do
            post recipe_recipe_comments_path(recipe), params: invalid_params
            expect(response).to have_http_status(:unprocessable_content)
            expect(response.body).to include(recipe.title)
          end

          it "displays validation errors in the form" do
            post recipe_recipe_comments_path(recipe), params: invalid_params
            expect(response.body).to include("label-error")
            expect(response.body).to include("form-error-message")
          end

          it "displays error flash message" do
            post recipe_recipe_comments_path(recipe), params: invalid_params
            expect(flash[:alert]).to eq("Kommentar konnte nicht gespeichert werden. Bitte korrigiere die Fehler.")
          end
        end

        context "when body exceeds maximum length" do
          let(:invalid_params) do
            { recipe_comment: { body: "a" * 3001 } }
          end

          it "does not create a new comment" do
            expect {
              post recipe_recipe_comments_path(recipe), params: invalid_params
            }.not_to change { RecipeComment.count }
          end

          it "re-renders the recipe page with unprocessable content status" do
            post recipe_recipe_comments_path(recipe), params: invalid_params
            expect(response).to have_http_status(:unprocessable_content)
            expect(response.body).to include(recipe.title)
          end

          it "displays validation errors in the form" do
            post recipe_recipe_comments_path(recipe), params: invalid_params
            expect(response.body).to include("label-error")
            expect(response.body).to include("form-error-message")
          end

          it "displays error flash message" do
            post recipe_recipe_comments_path(recipe), params: invalid_params
            expect(flash[:alert]).to eq("Kommentar konnte nicht gespeichert werden. Bitte korrigiere die Fehler.")
          end
        end
      end

      context "when recipe does not exist" do
        it "returns 404 not found" do
          post recipe_recipe_comments_path("non-existent"), params: { recipe_comment: { body: "Test" } }
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context "when user is not authenticated" do
      let(:valid_params) do
        { recipe_comment: { body: "This is a great recipe!" } }
      end

      it "does not create a new comment" do
        expect {
          post recipe_recipe_comments_path(recipe), params: valid_params
        }.not_to change { RecipeComment.count }
      end

      it "redirects to the login page" do
        post recipe_recipe_comments_path(recipe), params: valid_params
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
