module Admin
  class FeaturedRecipeImagesController < BaseController
    before_action :require_image_moderator!

    def create
      recipe_image = RecipeImage.find(params[:recipe_image_id])
      recipe_image.feature!
      redirect_to admin_recipe_image_path(recipe_image), notice: "Bild wurde als Featured gesetzt."
    rescue => e
      redirect_to admin_recipe_images_path, alert: "Fehler: #{e.message}"
    end

    def destroy
      recipe_image = RecipeImage.find(params[:id])
      recipe_image.unfeature!
      redirect_to admin_recipe_image_path(recipe_image), notice: "Bild wurde als Featured entfernt."
    end

    private

    def require_image_moderator!
      unless Current.user&.can_moderate_image?
        redirect_to root_path, alert: "Zugriff verweigert."
      end
    end
  end
end
