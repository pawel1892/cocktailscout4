module NavigationHelper
  def main_navigation_items
    [
      {
        label: "Rezepte",
        path: recipes_path,
        controllers: [ "recipes", "recipe_images", "recipe_categories", "top_lists" ],
        dropdown: [
          { label: "Alle Rezepte", path: recipes_path, controllers: [ "recipes" ] },
          { label: "Cocktailgalerie", path: recipe_images_path, controllers: [ "recipe_images" ] },
          { label: "Toplisten", path: top_lists_path, controllers: [ "top_lists" ] },
          { label: "Rezept-Kategorien", path: recipe_categories_path, controllers: [ "recipe_categories" ] }
        ]
      },
      {
        label: "Community",
        path: forum_topics_path,
        controllers: [ "users", "forum_topics", "forum_threads", "forum_posts", "forum_search" ],
        dropdown: [
          { label: "Forum", path: forum_topics_path, controllers: [ "forum_topics", "forum_threads", "forum_posts", "forum_search" ] },
          { label: "Benutzer", path: users_path, controllers: [ "users" ] }
        ]
      },
      {
        label: "Meine Bar",
        path: my_bar_path,
        controllers: [ "my_bar" ],
        dropdown: nil
      }
    ]
  end

  def current_nav_item
    main_navigation_items.find do |item|
      item[:controllers]&.include?(controller_name) ||
      controller_path.start_with?(*Array(item[:controllers] || []))
    end
  end

  def show_subnav?
    current_nav_item&.dig(:dropdown).present?
  end

  def subnav_items
    current_nav_item&.dig(:dropdown) || []
  end

  def subnav_item_active?(item)
    item[:controllers]&.include?(controller_name) ||
    controller_path.start_with?(*Array(item[:controllers] || []))
  end
end
