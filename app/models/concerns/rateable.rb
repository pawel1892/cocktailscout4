module Rateable
  extend ActiveSupport::Concern

  included do
    has_many :ratings, as: :rateable, dependent: :destroy
  end

  def update_rating_cache!
    current_avg = ratings.average(:score).to_f
    current_count = ratings.count

    update_columns(
      average_rating: current_avg,
      ratings_count: current_count
    )
  end
end
