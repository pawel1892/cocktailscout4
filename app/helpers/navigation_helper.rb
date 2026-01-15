module NavigationHelper
  def main_navigation_items
    [
      {
        label: "Rezepte",
        path: "#",
        dropdown: [
          { label: "Alle Rezepte", path: recipes_path },
          { label: "Cocktailgalerie", path: recipe_images_path }
        ]
      },
      {
        label: "Forum",
        path: forum_topics_path,
        dropdown: nil
      }
    ]
  end
end
