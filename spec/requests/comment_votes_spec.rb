require 'rails_helper'

RSpec.describe "CommentVotes", type: :request do
  let(:user)       { create(:user) }
  let(:other_user) { create(:user) }
  let(:recipe)     { create(:recipe) }
  let(:comment)    { create(:recipe_comment, recipe: recipe, user: other_user) }

  def vote_path(comment)
    vote_recipe_comment_path(comment)
  end

  # ---------------------------------------------------------------------------
  # POST /recipe_comments/:id/vote
  # ---------------------------------------------------------------------------
  describe "POST /recipe_comments/:id/vote" do
    context "when logged in" do
      before { sign_in user }

      it "creates an upvote and returns updated net_votes" do
        expect {
          post vote_path(comment), params: { value: 1 }, as: :json
        }.to change(CommentVote, :count).by(1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["net_votes"]).to eq(1)
        expect(json["current_user_vote"]).to eq(1)
      end

      it "creates a downvote" do
        expect {
          post vote_path(comment), params: { value: -1 }, as: :json
        }.to change(CommentVote, :count).by(1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["net_votes"]).to eq(-1)
        expect(json["current_user_vote"]).to eq(-1)
      end

      it "toggles off an existing vote when the same value is sent" do
        create(:comment_vote, user: user, recipe_comment: comment, value: 1)
        comment.update_column(:net_votes, 1)

        expect {
          post vote_path(comment), params: { value: 1 }, as: :json
        }.to change(CommentVote, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["net_votes"]).to eq(0)
        expect(json["current_user_vote"]).to be_nil
      end

      it "switches from upvote to downvote" do
        create(:comment_vote, user: user, recipe_comment: comment, value: 1)
        comment.update_column(:net_votes, 1)

        post vote_path(comment), params: { value: -1 }, as: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["net_votes"]).to eq(-1)
        expect(json["current_user_vote"]).to eq(-1)
        expect(CommentVote.count).to eq(1)
      end

      it "rejects invalid vote values" do
        post vote_path(comment), params: { value: 5 }, as: :json

        expect(response).to have_http_status(:unprocessable_content)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end

      it "updates the net_votes cache on the comment" do
        post vote_path(comment), params: { value: 1 }, as: :json

        expect(comment.reload.net_votes).to eq(1)
      end
    end

    context "when not logged in" do
      it "returns 401 unauthorized" do
        post vote_path(comment), params: { value: 1 }, as: :json

        expect(response).to have_http_status(:unauthorized)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end

      it "does not create a vote" do
        expect {
          post vote_path(comment), params: { value: 1 }, as: :json
        }.not_to change(CommentVote, :count)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /recipe_comments/:id/vote
  # ---------------------------------------------------------------------------
  describe "DELETE /recipe_comments/:id/vote" do
    context "when logged in" do
      before { sign_in user }

      it "removes the vote and returns updated net_votes" do
        create(:comment_vote, user: user, recipe_comment: comment, value: 1)
        comment.update_column(:net_votes, 1)

        expect {
          delete vote_path(comment), as: :json
        }.to change(CommentVote, :count).by(-1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["net_votes"]).to eq(0)
        expect(json["current_user_vote"]).to be_nil
      end

      it "is a no-op when no vote exists (idempotent)" do
        expect {
          delete vote_path(comment), as: :json
        }.not_to change(CommentVote, :count)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["net_votes"]).to eq(0)
      end

      it "only removes the current user's vote" do
        create(:comment_vote, user: user, recipe_comment: comment, value: 1)
        other_vote = create(:comment_vote, user: other_user, recipe_comment: comment, value: 1)
        comment.update_column(:net_votes, 2)

        delete vote_path(comment), as: :json

        expect(CommentVote.exists?(other_vote.id)).to be true
        json = JSON.parse(response.body)
        expect(json["net_votes"]).to eq(1)
      end
    end

    context "when not logged in" do
      it "returns 401 unauthorized" do
        delete vote_path(comment), as: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # net_votes cache integrity
  # ---------------------------------------------------------------------------
  describe "net_votes cache" do
    before { sign_in user }

    it "reflects multiple votes from different users" do
      user2 = create(:user)
      user3 = create(:user)

      create(:comment_vote, user: user2, recipe_comment: comment, value: 1)
      create(:comment_vote, user: user3, recipe_comment: comment, value: -1)
      comment.update_column(:net_votes, 0)

      post vote_path(comment), params: { value: 1 }, as: :json

      expect(comment.reload.net_votes).to eq(1)
    end
  end
end
