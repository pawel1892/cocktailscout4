require 'rails_helper'

RSpec.describe "RecipeComments", type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }
  let(:moderator)  { create(:user, :recipe_moderator) }
  let(:recipe)     { create(:recipe) }
  let!(:comment)   { create(:recipe_comment, recipe: recipe, user: user) }

  # ---------------------------------------------------------------------------
  # GET /rezepte/:slug/comments  (JSON index)
  # ---------------------------------------------------------------------------
  describe "GET /rezepte/:slug/comments" do
    let!(:reply) { create(:recipe_comment, recipe: recipe, user: other_user, parent: comment) }

    it "returns top-level comments as JSON" do
      get comments_recipe_path(recipe), as: :json

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.length).to eq(1)

      top = json.first
      expect(top["id"]).to eq(comment.id)
      expect(top["body"]).to eq(comment.body)
      expect(top["net_votes"]).to eq(0)
      expect(top["current_user_vote"]).to be_nil
      expect(top["tags"]).to eq([])
    end

    it "nests replies under their parent" do
      get comments_recipe_path(recipe), as: :json

      json    = JSON.parse(response.body)
      replies = json.first["replies"]
      expect(replies.length).to eq(1)
      expect(replies.first["id"]).to eq(reply.id)
    end

    it "includes user info in each comment" do
      get comments_recipe_path(recipe), as: :json

      json = JSON.parse(response.body)
      expect(json.first["user"]["username"]).to eq(user.username)
    end

    it "sorts top-level comments by net_votes desc then created_at desc" do
      upvoted = create(:recipe_comment, recipe: recipe, user: other_user, net_votes: 5)

      get comments_recipe_path(recipe), as: :json

      json = JSON.parse(response.body)
      expect(json.first["id"]).to eq(upvoted.id)
    end

    it "returns can_edit / can_delete false when not logged in" do
      get comments_recipe_path(recipe), as: :json

      json = JSON.parse(response.body)
      expect(json.first["can_edit"]).to be false
      expect(json.first["can_delete"]).to be false
      expect(json.first["can_tag"]).to be false
    end

    it "returns can_edit true for the comment author" do
      sign_in user

      get comments_recipe_path(recipe), as: :json

      json = JSON.parse(response.body)
      expect(json.first["can_edit"]).to be true
    end

    it "returns can_delete true for a moderator" do
      sign_in moderator

      get comments_recipe_path(recipe), as: :json

      json = JSON.parse(response.body)
      expect(json.first["can_delete"]).to be true
      expect(json.first["can_tag"]).to be true
    end

    it "returns current_user_vote when the user has voted" do
      sign_in user
      create(:comment_vote, user: user, recipe_comment: comment, value: 1)

      get comments_recipe_path(recipe), as: :json

      json = JSON.parse(response.body)
      expect(json.first["current_user_vote"]).to eq(1)
    end
  end

  # ---------------------------------------------------------------------------
  # POST /rezepte/:slug/comment  (JSON create — top-level)
  # ---------------------------------------------------------------------------
  describe "POST /rezepte/:slug/comment (JSON)" do
    context "when logged in" do
      before { sign_in user }

      it "creates a top-level comment and returns JSON" do
        expect {
          post comment_recipe_path(recipe),
               params: { recipe_comment: { body: "Delicious!" } },
               as: :json
        }.to change(RecipeComment, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["body"]).to eq("Delicious!")
        expect(json["user"]["username"]).to eq(user.username)
        expect(json["parent_id"]).to be_nil
        expect(json["replies"]).to eq([])
      end

      it "creates a reply when parent_id is provided" do
        expect {
          post comment_recipe_path(recipe),
               params: { recipe_comment: { body: "Great tip!", parent_id: comment.id } },
               as: :json
        }.to change(RecipeComment, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)
        expect(json["body"]).to eq("Great tip!")
        expect(RecipeComment.last.parent_id).to eq(comment.id)
      end

      it "rejects a reply to a reply (max 1 level)" do
        reply = create(:recipe_comment, recipe: recipe, user: other_user, parent: comment)

        expect {
          post comment_recipe_path(recipe),
               params: { recipe_comment: { body: "Nested", parent_id: reply.id } },
               as: :json
        }.not_to change(RecipeComment, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end

      it "returns errors for blank body" do
        expect {
          post comment_recipe_path(recipe),
               params: { recipe_comment: { body: "" } },
               as: :json
        }.not_to change(RecipeComment, :count)

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end

    context "when not logged in" do
      it "returns 401 unauthorized for JSON requests" do
        post comment_recipe_path(recipe),
             params: { recipe_comment: { body: "Trying" } },
             as: :json

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end
    end
  end

  # ---------------------------------------------------------------------------
  # POST /rezepte/:slug/comment  (HTML create — kept for completeness)
  # ---------------------------------------------------------------------------
  describe "POST /rezepte/:slug/comment (HTML)" do
    context "when logged in" do
      before { sign_in user }

      it "creates a comment and redirects" do
        expect {
          post comment_recipe_path(recipe), params: { recipe_comment: { body: "Nice!" } }
        }.to change(RecipeComment, :count).by(1)

        expect(response).to redirect_to(recipe_path(recipe, anchor: "comment-#{RecipeComment.last.id}"))
      end

      it "does not create with empty body" do
        expect {
          post comment_recipe_path(recipe), params: { recipe_comment: { body: "" } }
        }.not_to change(RecipeComment, :count)

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when not logged in" do
      it "redirects to login" do
        post comment_recipe_path(recipe), params: { recipe_comment: { body: "Hi" } }

        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /recipe_comments/:id  (JSON update)
  # ---------------------------------------------------------------------------
  describe "PATCH /recipe_comments/:id (JSON)" do
    context "as comment author" do
      before { sign_in user }

      it "updates the body and returns JSON" do
        patch recipe_comment_path(comment),
              params: { recipe_comment: { body: "Updated!" } },
              as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["body"]).to eq("Updated!")
        expect(json["last_editor_username"]).to eq(user.username)
        expect(comment.reload.body).to eq("Updated!")
      end

      it "returns errors for blank body" do
        patch recipe_comment_path(comment),
              params: { recipe_comment: { body: "" } },
              as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end

    context "as other user" do
      before { sign_in other_user }

      it "returns 403 forbidden" do
        patch recipe_comment_path(comment),
              params: { recipe_comment: { body: "Hacked!" } },
              as: :json

        expect(response).to have_http_status(:forbidden)
        expect(comment.reload.body).not_to eq("Hacked!")
      end
    end

    context "as moderator" do
      before { sign_in moderator }

      it "can update any comment" do
        patch recipe_comment_path(comment),
              params: { recipe_comment: { body: "Moderated." } },
              as: :json

        expect(response).to have_http_status(:ok)
        expect(comment.reload.body).to eq("Moderated.")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /recipe_comments/:id  (JSON destroy)
  # ---------------------------------------------------------------------------
  describe "DELETE /recipe_comments/:id (JSON)" do
    context "as moderator" do
      before { sign_in moderator }

      it "deletes the comment and returns success JSON" do
        expect {
          delete recipe_comment_path(comment), as: :json
        }.to change(RecipeComment, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
      end
    end

    context "as comment author" do
      before { sign_in user }

      it "returns 403 forbidden" do
        expect {
          delete recipe_comment_path(comment), as: :json
        }.not_to change(RecipeComment, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "as other user" do
      before { sign_in other_user }

      it "returns 403 forbidden" do
        expect {
          delete recipe_comment_path(comment), as: :json
        }.not_to change(RecipeComment, :count)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /recipe_comments/:id/edit  (HTML edit — unchanged)
  # ---------------------------------------------------------------------------
  describe "GET /recipe_comments/:id/edit" do
    context "as author" do
      before { sign_in user }

      it "returns http success" do
        get edit_recipe_comment_path(comment)
        expect(response).to have_http_status(:success)
      end
    end

    context "as other user" do
      before { sign_in other_user }

      it "redirects with no permission" do
        get edit_recipe_comment_path(comment)
        expect(response).to redirect_to(recipe_path(recipe))
      end
    end
  end
end
