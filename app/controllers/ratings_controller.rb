class RatingsController < ApplicationController
  # API only, no views
  allow_unauthenticated_access only: [] # Must be logged in

  def create
    rateable = find_rateable
    rating = Rating.find_or_initialize_by(user: Current.user, rateable: rateable)
    rating.score = params[:score]

    if rating.save
      render json: { success: true, rating: rating, average: rateable.reload.average_rating, count: rateable.ratings_count }
    else
      render json: { success: false, errors: rating.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    rateable = find_rateable
    rating = Rating.find_by(user: Current.user, rateable: rateable)

    if rating&.destroy
      render json: { success: true, average: rateable.reload.average_rating, count: rateable.ratings_count }
    else
      render json: { success: false, error: "Rating not found" }, status: :not_found
    end
  end

  private

  def find_rateable
    # Securely finding rateable.
    # Whitelist allowed classes.
    allowed_types = { "Recipe" => Recipe }
    klass = allowed_types[params[:rateable_type]]

    raise NameError, "Invalid rateable type" unless klass
    klass.find(params[:rateable_id])
  end
end
