class FavoritesController < ApplicationController
  allow_unauthenticated_access only: [] # Must be logged in

  def create
    favoritable = find_favoritable
    favorite = Favorite.find_or_initialize_by(user: Current.user, favoritable: favoritable)

    if favorite.save
      render json: { success: true, favorited: true }
    else
      render json: { success: false, errors: favorite.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    favoritable = find_favoritable
    favorite = Favorite.find_by(user: Current.user, favoritable: favoritable)

    if favorite&.destroy
      render json: { success: true, favorited: false }
    else
      render json: { success: false, error: "Favorite not found" }, status: :not_found
    end
  end

  private

  def find_favoritable
    # Securely finding favoritable.
    # Whitelist allowed classes.
    allowed_types = { "Recipe" => Recipe }
    klass = allowed_types[params[:favoritable_type]]

    raise ActiveRecord::RecordNotFound, "Invalid favoritable type" unless klass
    klass.find(params[:favoritable_id])
  end
end
