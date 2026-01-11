class UserStat < ApplicationRecord
  belongs_to :user

  # Thresholds for ranks 0-10
  RANKS = {
     0 =>     0,
     1 =>    10,
     2 =>    50,
     3 =>   100,
     4 =>   250,
     5 =>   500,
     6 =>  1000,
     7 =>  2500,
     8 =>  5000,
     9 => 10000,
    10 => 25000
  }

  def rank
    current_rank = 0
    RANKS.each do |level, threshold|
      current_rank = level if points >= threshold
    end
    current_rank
  end

  def recalculate!
    update(points: calculate_points)
  end

  private

  def calculate_points
    score = 0
    score += user.recipes.count * 15
    score += user.recipe_images.approved.count * 20
    score += user.recipe_comments.count * 2
    score += user.ratings.where(rateable_type: "Recipe").count * 1
    score += user.forum_posts.count * 3

    # TODO: Add MyBar (10 pts)

    score
  end
end
