class RecipeRatingsController < ApplicationController
  allow_unauthenticated_access only: [ :index ]

  def index
    @recipe = Recipe.find_by!(slug: params[:slug])
    ratings = @recipe.ratings.includes(user: :user_stat).order(score: :desc, created_at: :desc)

    total = ratings.count
    distribution = 10.downto(1).map do |score|
      score_ratings = ratings.select { |r| r.score == score }
      {
        score: score,
        count: score_ratings.count,
        percentage: total > 0 ? (score_ratings.count.to_f / total * 100).round(1) : 0,
        users: score_ratings.map { |r|
          u = r.user
          { id: u&.id, username: u&.username, rank: u&.stat&.rank || 0, online: u&.online? || false }
        }
      }
    end

    recent = ratings
               .reorder(updated_at: :desc)
               .select { |r| r.updated_at >= 1.year.ago }
               .first(20)
               .map { |r|
                 u = r.user
                 { score: r.score, updated_at: r.updated_at.strftime("%d.%m.%Y"),
                   user_id: u&.id, username: u&.username, rank: u&.stat&.rank || 0, online: u&.online? || false }
               }

    @ratings_json = { total: total, average: @recipe.average_rating, distribution: distribution, recent: recent }.to_json
  end
end
