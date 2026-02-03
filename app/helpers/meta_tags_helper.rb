# frozen_string_literal: true

module MetaTagsHelper
  # Default meta tags for all pages
  def default_meta_tags
    {
      site: "CocktailScout",
      description: "Entdecke und teile die besten Cocktail-Rezepte. Erstelle deine eigenen Drinks, bewerte Rezepte und tausche dich mit der Community aus.",
      keywords: "Cocktails, Rezepte, Drinks, Bar, Mixgetränke, Spirituosen",
      og: {
        site_name: "CocktailScout",
        type: "website",
        locale: "de_DE",
        image: asset_url("icon.png")
      },
      twitter: {
        card: "summary_large_image",
        site: "@cocktailscout"
      },
      reverse: true,
      separator: "|"
    }
  end

  # Set meta tags for recipe pages
  def set_recipe_meta_tags(recipe)
    image_url = recipe_meta_image_url(recipe)
    description = sanitize_and_truncate(recipe.description, 160)

    set_meta_tags(
      title: recipe.title,
      description: description,
      og: {
        title: recipe.title,
        description: description,
        type: "article",
        url: recipe_url(recipe),
        image: image_url,
        article: {
          published_time: recipe.created_at.iso8601,
          modified_time: recipe.updated_at.iso8601,
          author: user_profile_url(recipe.user)
        }
      },
      twitter: {
        card: "summary_large_image",
        title: recipe.title,
        description: description,
        image: image_url
      }
    )
  end

  # Set meta tags for forum thread pages
  def set_forum_thread_meta_tags(thread)
    description = if thread.first_post&.body.present?
      sanitize_and_truncate(thread.first_post.body, 160)
    else
      "#{thread.topic.name} - Diskussion in der CocktailScout Community"
    end

    set_meta_tags(
      title: thread.title,
      description: description,
      og: {
        title: thread.title,
        description: description,
        type: "article",
        url: forum_thread_url(thread),
        article: {
          published_time: thread.created_at.iso8601,
          modified_time: thread.updated_at.iso8601,
          author: user_profile_url(thread.user)
        }
      },
      twitter: {
        card: "summary",
        title: thread.title,
        description: description
      }
    )
  end

  private

  # Sanitize HTML and truncate text for meta descriptions
  def sanitize_and_truncate(text, length)
    return "" if text.blank?

    # Remove HTML tags
    sanitized = Rails::Html::FullSanitizer.new.sanitize(text)

    # Truncate to specified length at word boundary
    if sanitized.length > length
      sanitized[0..length].gsub(/\s\w+\s*$/, "...").strip
    else
      sanitized.strip
    end
  end

  # Get the appropriate meta image URL for a recipe
  def recipe_meta_image_url(recipe)
    if recipe.approved_recipe_images.any?
      # Use the first approved image in medium variant
      url_for(recipe.approved_recipe_images.first.image.variant(resize_to_limit: [ 800, 600 ]))
    else
      # Fall back to default icon
      asset_url("icon.png")
    end
  end
end
