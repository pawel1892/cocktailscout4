module RecipesHelper
  def recipe_thumbnail(recipe, size_class: "w-20 h-20")
    if recipe.approved_recipe_images.any?
      image = recipe.approved_recipe_images.sample.image
      if image.attached?
        # Use a variant if available, otherwise the image itself
        # Assuming :thumb variant exists as per RecipeImage model
        image_tag(image.variant(:thumb), class: "#{size_class} object-cover rounded-md")
      else
        placeholder_image(size_class)
      end
    else
      placeholder_image(size_class)
    end
  end

  def placeholder_image(size_class)
    # Simple SVG placeholder
    content_tag(:div, class: "#{size_class} bg-gray-200 rounded-md flex items-center justify-center text-gray-400") do
      content_tag(:i, nil, class: "fas fa-cocktail text-2xl")
    end
  end

  def active_filters
    filters = []
    if params[:min_rating].present?
      filters << { label: "Bewertung: #{params[:min_rating]}+", param: :min_rating }
    end
    if params[:tag].present?
      filters << { label: "Tag: #{params[:tag]}", param: :tag }
    end
    if params[:ingredient_id].present?
      ingredient = Ingredient.find_by(id: params[:ingredient_id])
      filters << { label: "Zutat: #{ingredient.name}", param: :ingredient_id } if ingredient
    end
    filters
  end
end
