module Rateable
  extend ActiveSupport::Concern

  MIN_RATINGS_FOR_DISPLAY = 4

  included do
    has_many :ratings, as: :rateable, dependent: :destroy
  end

  def show_rating?
    ratings_count >= MIN_RATINGS_FOR_DISPLAY
  end

  def has_ratings?
    ratings_count >= 1
  end

  def update_rating_cache!
    current_count = ratings.count
    current_avg = current_count >= MIN_RATINGS_FOR_DISPLAY ? ratings.average(:score).to_f : 0.0

    update_columns(
      average_rating: current_avg,
      ratings_count: current_count
    )
  end
end
