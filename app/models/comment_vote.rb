class CommentVote < ApplicationRecord
  belongs_to :user
  belongs_to :recipe_comment

  validates :value, inclusion: { in: [ 1, -1 ] }
  validates :user_id, uniqueness: { scope: :recipe_comment_id }

  after_create  :update_net_votes
  after_update  :update_net_votes
  after_destroy :update_net_votes

  private

  def update_net_votes
    recipe_comment.update_column(:net_votes, recipe_comment.comment_votes.sum(:value))
  end
end
