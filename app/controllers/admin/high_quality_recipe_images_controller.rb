module Admin
  class HighQualityRecipeImagesController < BaseController
    before_action :require_high_quality_permission!

    def create
      recipe_image = RecipeImage.find(params[:recipe_image_id])
      recipe_image.update!(high_quality: true)
      redirect_to admin_recipe_image_path(recipe_image), notice: "Bild als hochwertig markiert."
    end

    def destroy
      recipe_image = RecipeImage.find(params[:id])
      recipe_image.update!(high_quality: false)
      redirect_to admin_recipe_image_path(recipe_image), notice: "Hochwertig-Markierung entfernt."
    end

    private

    def require_high_quality_permission!
      unless Current.user&.can_mark_high_quality?
        redirect_to root_path, alert: "Zugriff verweigert."
      end
    end
  end
end
