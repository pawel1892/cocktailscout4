class UserRatingsController < ApplicationController
  allow_unauthenticated_access only: [ :index ]

  def index
    @user = User.find(params[:id])

    all_ratings = @user.ratings
                       .where(rateable_type: "Recipe")
                       .includes(:rateable)
                       .order(created_at: :desc)

    total = all_ratings.count

    # Section 1: ratings active in the last year, max 20
    cutoff = 1.year.ago
    recent = all_ratings
               .reorder(updated_at: :desc)
               .select { |r| r.updated_at >= cutoff }
               .first(20)
               .map do |r|
                 recipe = r.rateable
                 {
                   score: r.score,
                   updated_at: r.updated_at.strftime("%d.%m.%Y"),
                   recipe_title: recipe&.title,
                   recipe_slug: recipe&.slug
                 }
               end

    # Section 2: distribution grouped by score
    distribution = 10.downto(1).map do |score|
      score_ratings = all_ratings.select { |r| r.score == score }
      {
        score: score,
        count: score_ratings.count,
        percentage: total > 0 ? (score_ratings.count.to_f / total * 100).round(1) : 0,
        recipes: score_ratings.map { |r|
          recipe = r.rateable
          {
            title: recipe&.title,
            slug: recipe&.slug,
            average_rating: recipe&.average_rating
          }
        }
      }
    end

    # Section 3: unrated visible recipes
    rated_ids = all_ratings.map(&:rateable_id)
    unrated = Recipe.visible
                    .where.not(id: rated_ids)
                    .order(title: :asc)
                    .select(:id, :title, :slug, :average_rating, :ratings_count)
                    .map { |r|
                      {
                        title: r.title,
                        slug: r.slug,
                        average_rating: r.average_rating,
                        ratings_count: r.ratings_count
                      }
                    }

    @user_ratings_json = {
      username: @user.username,
      user_id: @user.id,
      total: total,
      recent: recent,
      distribution: distribution,
      unrated: unrated
    }.to_json
  end
end
