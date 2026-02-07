require 'rails_helper'

RSpec.describe "RecipeComments", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:recipe) { create(:recipe) }
  let!(:comment) { create(:recipe_comment, recipe: recipe, user: user) }

  describe "GET /recipe_comments/:id/edit" do
    context "as author" do
      before { sign_in user }
      it "returns http success" do
        get edit_recipe_comment_path(comment)
        expect(response).to have_http_status(:success)
      end

      it "updates the comment and sets last_editor" do
        patch recipe_comment_path(comment), params: { recipe_comment: { body: "Updated body" } }
        expect(response).to redirect_to(recipe_path(recipe, anchor: "comment-#{comment.id}"))
        comment.reload
        expect(comment.body).to eq("Updated body")
        expect(comment.last_editor).to eq(user)
      end
    end

    context "as other user" do
      before { sign_in other_user }
      it "redirects to recipe path" do
        get edit_recipe_comment_path(comment)
        expect(response).to redirect_to(recipe_path(recipe))
        expect(flash[:alert]).to eq("Keine Berechtigung.")
      end
    end

    context "as recipe moderator" do
      let(:moderator) { create(:user, :recipe_moderator) }
      before { sign_in moderator }
      it "returns http success" do
        get edit_recipe_comment_path(comment)
        expect(response).to have_http_status(:success)
      end
    end

    context "as forum moderator" do
      let(:moderator) { create(:user, :forum_moderator) }
      before { sign_in moderator }
      it "redirects to recipe path" do
        get edit_recipe_comment_path(comment)
        expect(response).to redirect_to(recipe_path(recipe))
        expect(flash[:alert]).to eq("Keine Berechtigung.")
      end
    end

    context "as super moderator" do
      let(:super_mod) { create(:user, :super_moderator) }
      before { sign_in super_mod }
      it "returns http success" do
        get edit_recipe_comment_path(comment)
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "DELETE /recipe_comments/:id" do
    context "as author" do
      before { sign_in user }
      it "does not delete the comment" do
        expect {
          delete recipe_comment_path(comment)
        }.not_to change(RecipeComment, :count)
        expect(response).to redirect_to(recipe_path(recipe))
        expect(flash[:alert]).to eq("Keine Berechtigung.")
      end
    end

    context "as recipe moderator" do
      let(:moderator) { create(:user, :recipe_moderator) }
      before { sign_in moderator }
      it "deletes the comment" do
        expect {
          delete recipe_comment_path(comment)
        }.to change(RecipeComment, :count).by(-1)
      end
    end

    context "as forum moderator" do
      let(:moderator) { create(:user, :forum_moderator) }
      before { sign_in moderator }
      it "does not delete the comment" do
        expect {
          delete recipe_comment_path(comment)
        }.not_to change(RecipeComment, :count)
        expect(response).to redirect_to(recipe_path(recipe))
        expect(flash[:alert]).to eq("Keine Berechtigung.")
      end
    end

    context "as super moderator" do
      let(:super_mod) { create(:user, :super_moderator) }
      before { sign_in super_mod }
      it "deletes the comment" do
        expect {
          delete recipe_comment_path(comment)
        }.to change(RecipeComment, :count).by(-1)
      end
    end

    context "as other user" do
      before { sign_in other_user }
      it "does not delete the comment" do
        expect {
          delete recipe_comment_path(comment)
        }.not_to change(RecipeComment, :count)
        expect(response).to redirect_to(recipe_path(recipe))
      end
    end
  end
end
