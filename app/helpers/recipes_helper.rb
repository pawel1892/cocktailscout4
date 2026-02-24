module RecipesHelper
  def recipe_thumbnail(recipe, size_class: "w-20 h-20")
    attached_images = recipe.approved_recipe_images.select { |ri| ri.image.attached? }
    if attached_images.any?
      image_tag(attached_images.sample.image.variant(:thumb), class: "#{size_class} object-cover rounded-md")
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
    if params[:q].present?
      filters << { label: "Suche: #{params[:q]}", param: :q }
    end
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
    if params[:collection_id].present?
      collection = IngredientCollection.find_by(id: params[:collection_id])
      filters << { label: "Liste: #{collection.name}", param: :collection_id } if collection
    end
    if params[:filter] == "favorites"
      filters << { label: "Nur Favoriten", param: :filter }
    end
    filters
  end

  def tag_cloud_class(count)
    # Cache tag stats for this request to avoid repeated queries
    @tag_cloud_stats ||= begin
      all_tags = @tags || Recipe.tag_counts
      if all_tags.empty?
        { min: 0, max: 0 }
      else
        counts = all_tags.map(&:taggings_count)
        { min: counts.min, max: counts.max }
      end
    end

    return "tag-level-1" if @tag_cloud_stats[:min] == 0 && @tag_cloud_stats[:max] == 0

    # Avoid division by zero
    return "tag-level-5" if @tag_cloud_stats[:min] == @tag_cloud_stats[:max]

    # Use logarithmic scale for better distribution with power-law data
    # (many tags with few recipes, few tags with many recipes)
    min_count = @tag_cloud_stats[:min]
    max_count = @tag_cloud_stats[:max]

    # Add 1 to avoid log(0) and ensure positive values
    log_count = Math.log(count + 1)
    log_min = Math.log(min_count + 1)
    log_max = Math.log(max_count + 1)

    # Calculate level (1-10) based on logarithmic distribution
    log_spread = log_max - log_min
    level = ((log_count - log_min) / log_spread * 9).ceil + 1
    level = [ [ level, 1 ].max, 10 ].min # Clamp between 1 and 10

    "tag-level-#{level}"
  end

  # Authorization helpers
  def can_view_recipe?(recipe)
    return true if recipe.is_public  # Published recipes visible to all
    return false unless Current.user
    return true if recipe.user == Current.user  # Owner can see own drafts
    Current.user.can_moderate_recipe?  # Moderators can see all drafts
  end

  def can_edit_recipe?(recipe)
    return false unless Current.user
    return true if recipe.user == Current.user
    can_delete_recipe?(recipe)
  end

  def can_delete_recipe?(recipe)
    return false unless Current.user
    Current.user.can_moderate_recipe?
  end
end
