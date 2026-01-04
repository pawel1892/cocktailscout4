module Letsrate
  extend ActiveSupport::Concern

  def rate(stars, user, dimension=nil, dirichlet_method=false)
    dimension = nil if dimension.blank?

    rating = user.ratings_given.where(dimension: dimension, rateable_id: id, rateable_type: self.class.name).first
    rating.destroy if rating.present?

    if can_rate? user, dimension
      rates(dimension).create! do |r|
        r.stars = stars
        r.rater = user
      end
      if dirichlet_method
        update_rate_average_dirichlet(stars, dimension)
      else
        update_rate_average(stars, dimension)
      end
    else
      raise "User has already rated."
    end
  end

end