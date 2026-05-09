module Admin
  class HighQualityRecipeImagesController < BaseController
    before_action :require_image_moderator!

    def create
      recipe_image = RecipeImage.find(params[:recipe_image_id])
      recipe_image.update!(high_quality: true)
      respond_to do |format|
        format.json { render json: { high_quality: true } }
        format.html { redirect_to admin_recipe_image_path(recipe_image), notice: "Bild als hochwertig markiert." }
      end
    end

    def destroy
      recipe_image = RecipeImage.find(params[:id])
      recipe_image.update!(high_quality: false)
      respond_to do |format|
        format.json { render json: { high_quality: false } }
        format.html { redirect_to admin_recipe_image_path(recipe_image), notice: "Hochwertig-Markierung entfernt." }
      end
    end

    private

    def require_image_moderator!
      unless Current.user&.can_moderate_image?
        redirect_to root_path, alert: "Zugriff verweigert."
      end
    end
  end
end
