module NavigationHelper
  # TEMP_WIKI_PROD_HIDE: Keep test/beta/dev visible; hide production wiki nav for non-editors.
  def wiki_visible?
    !Rails.env.production? || Current.user&.can_edit_wiki?
  end

  def main_navigation_items
    [
      {
        label: "Rezepte",
        path: recipes_path,
        controllers: [ "recipes", "recipe_images", "recipe_categories", "top_lists" ],
        search: { action: recipes_path, label: "Rezepte suchen", input_id: "desktop-recipe-search", placeholder: "Margarita, Rum..." },
        dropdown: [
          { label: "Alle Rezepte", path: recipes_path, controllers: [ "recipes" ], description: "Tausende Cocktails – suchen, filtern und direkt loslegen.", emphasized: true, icon: "fa-solid fa-martini-glass-citrus" },
          { label: "Cocktailgalerie", path: recipe_images_path, controllers: [ "recipe_images" ], description: "Lass dich von Fotos verführen und entdecke neue Favoriten.", emphasized: true, icon: "fa-solid fa-images" },
          { label: "Toplisten", path: top_lists_path, controllers: [ "top_lists" ], description: "Was die Community liebt: die Klassiker und die Überraschungen." },
          { label: "Rezept-Kategorien", path: recipe_categories_path, controllers: [ "recipe_categories" ], description: "Von Sour bis Tiki – nach Stil, Zutat oder Anlass stöbern." }
        ]
      },
      # TEMP_WIKI_PROD_HIDE: Hide the Wiki nav item in production for non-editors.
      (wiki_visible? ? {
        label: "Wiki",
        path: wiki_dashboard_path,
        controllers: [ "wiki_articles", "wiki/dashboard" ],
        dropdown: nil
      } : nil),
      {
        label: "Community",
        path: community_path,
        controllers: [ "community", "users", "forum_topics", "forum_threads", "forum_posts", "forum_search" ],
        search: { action: forum_search_path, label: "Forumsuche", input_id: "desktop-forum-search", placeholder: "Thema oder Beitrag suchen..." },
        dropdown: [
          { label: "Aktivitätsstream", path: community_path, controllers: [ "community" ], description: "Live aus der Community: Bewertungen, Kommentare, Neuigkeiten." },
          { label: "Forum", path: forum_topics_path, controllers: [ "forum_topics", "forum_threads", "forum_posts", "forum_search" ], description: "Fragen, Tipps und Debatten – dein digitaler Stammtisch.", emphasized: true, icon: "fa-solid fa-comments" },
          { label: "Benutzer", path: users_path, controllers: [ "users" ], description: "Wer shaked was? Entdecke aktive Mitglieder und Profile." }
        ]
      },
      {
        label: "Meine Bar",
        path: my_bar_path,
        controllers: [ "my_bar" ],
        dropdown: nil
      }
      # TEMP_WIKI_PROD_HIDE: Drop the hidden Wiki nav item while the production gate exists.
    ].compact
  end

  def current_nav_item
    main_navigation_items.find do |item|
      item[:controllers]&.include?(controller_name) ||
      controller_path.start_with?(*Array(item[:controllers] || []))
    end
  end

  def main_nav_item_active?(item)
    current_nav_item == item
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
