class UserRank < ActiveRecord::Base

  belongs_to :user

  after_create :recalculate_points!

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
    rank = 0
    RANKS.each do |k,v|
      rank = k if self.points.to_i > v
    end
    return rank
  end

  def calculate_points
    # TODO add scopes (only active recipes, images etc)
    points = user.recipes.count * 15
    points += user.recipe_images.count * 20
    points += user.forum_posts.count * 3
    points += user.recipe_comments.count * 2
    points += user.ratings_for_recipes.count
    points += 10 if user.has_mybar?
    # TODO daily logins
    return points.to_i
  end

  def recalculate_points!
    self.points = calculate_points
    save
  end

  def self.repair_all_user
    # create missing user_rank records
    User.all.each do |u|
      unless u.user_rank.is_a? UserRank
        u.build_user_rank
        u.save
      end
    end
    # delete all user_rank records with invalid user_id
    UserRank.all.each do |ur|
      ur.destroy unless ur.user.is_a? User
    end
    # recalculate all points
    UserRank.all.each do |ur|
      ur.recalculate_points!
    end
  end

end
