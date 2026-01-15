class RecipeImagesController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]

  def index
    add_breadcrumb "Rezepte", recipes_path
    add_breadcrumb "Cocktailgalerie"
    @pagy, @recipe_images = pagy(RecipeImage.approved.includes(:recipe, :user).order(created_at: :desc), limit: 60)
  end
end
