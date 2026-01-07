module RecipeImagesHelper
  def recipe_image_url(recipe_image, style: :medium)
    return nil unless recipe_image.image.attached?

    recipe_image.image.variant(style)
  end
end
