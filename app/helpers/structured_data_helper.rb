# frozen_string_literal: true

module StructuredDataHelper
  # Generate Recipe schema JSON-LD for structured data
  def recipe_structured_data(recipe)
    sanitizer = Rails::Html::FullSanitizer.new

    schema = {
      "@context": "https://schema.org",
      "@type": "Recipe",
      "name": recipe.title,
      "description": sanitizer.sanitize(recipe.description || recipe.title),
      "image": recipe_images(recipe),
      "author": {
        "@type": "Person",
        "name": recipe.user.username,
        "url": user_profile_url(recipe.user)
      },
      "datePublished": recipe.created_at.iso8601,
      "dateModified": recipe.updated_at.iso8601,
      "recipeIngredient": recipe_ingredients_list(recipe),
      "recipeInstructions": {
        "@type": "HowToSection",
        "text": sanitizer.sanitize(recipe.description || "")
      }
    }

    # Add aggregate rating if ratings exist
    if recipe.ratings_count > 0
      schema["aggregateRating"] = {
        "@type": "AggregateRating",
        "ratingValue": recipe.average_rating.to_f,
        "ratingCount": recipe.ratings_count,
        "bestRating": 10,
        "worstRating": 1
      }
    end

    # Add keywords from tags
    if recipe.tags.any?
      schema["keywords"] = recipe.tags.map(&:name).join(", ")
    end

    # Add alcohol content if present
    if recipe.alcohol_content.present?
      schema["alcoholContent"] = "#{recipe.alcohol_content}% ABV"
    end

    tag.script(schema.to_json.html_safe, type: "application/ld+json")
  end

  private

  # Get array of image URLs for recipe
  def recipe_images(recipe)
    if recipe.approved_recipe_images.any?
      recipe.approved_recipe_images.map do |recipe_image|
        url_for(recipe_image.image.variant(resize_to_limit: [ 800, 600 ]))
      end
    else
      [ asset_url("icon.png") ]
    end
  end

  # Format recipe ingredients as array of strings
  def recipe_ingredients_list(recipe)
    recipe.recipe_ingredients.includes(:ingredient, :unit).map do |ri|
      parts = []
      parts << ri.formatted_amount if ri.formatted_amount.present?
      parts << ri.formatted_ingredient_name
      parts << "(#{ri.additional_info})" if ri.additional_info.present?
      parts.join(" ")
    end
  end
end
