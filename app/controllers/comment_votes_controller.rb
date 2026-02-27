class CommentVotesController < ApplicationController
  allow_unauthenticated_access only: [ :create, :destroy ]
  before_action :set_comment
  before_action :require_user!

  def create
    value = params[:value].to_i
    unless [ 1, -1 ].include?(value)
      return render json: { error: "Invalid vote value" }, status: :unprocessable_content
    end

    vote = @comment.comment_votes.find_or_initialize_by(user: Current.user)

    if vote.persisted? && vote.value == value
      # Same vote again — remove it (toggle off)
      vote.destroy
    else
      vote.value = value
      vote.save!
    end

    @comment.reload
    current_vote = @comment.comment_votes.find_by(user: Current.user)
    render json: {
      net_votes: @comment.net_votes,
      current_user_vote: current_vote&.value
    }
  end

  def destroy
    vote = @comment.comment_votes.find_by(user: Current.user)
    vote&.destroy
    @comment.reload
    render json: {
      net_votes: @comment.net_votes,
      current_user_vote: nil
    }
  end

  private

  def set_comment
    @comment = RecipeComment.find(params[:id])
  end

  def require_user!
    unless Current.user
      render json: { error: "Du musst angemeldet sein." }, status: :unauthorized
    end
  end
end
