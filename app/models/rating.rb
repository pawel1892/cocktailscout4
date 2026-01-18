class Rating < ApplicationRecord
  belongs_to :user
  belongs_to :rateable, polymorphic: true

  validates :score, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }
  validates :user_id, uniqueness: { scope: [ :rateable_type, :rateable_id ], message: "has already rated this item" }

  after_save :update_rateable_cache
  after_destroy :update_rateable_cache
  after_create :update_user_stats
  after_destroy :update_user_stats

  private

  def update_rateable_cache
    rateable.update_rating_cache! if rateable.respond_to?(:update_rating_cache!)
  end

  def update_user_stats
    user&.stat&.recalculate! if rateable_type == "Recipe"
  end
end
