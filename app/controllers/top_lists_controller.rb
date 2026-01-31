class TopListsController < ApplicationController
  allow_unauthenticated_access

  def index
    add_breadcrumb "Rezepte", recipes_path
    add_breadcrumb "Toplisten"

    categories = [
      { tag: "wodka", name: "Wodka-Drinks" },
      { tag: "gin", name: "Gin-Drinks" },
      { tag: "tequila", name: "Tequila-Drinks" },
      { tag: "whiskey", name: "Whiskey-Drinks" },
      { tag: "campari", name: "Campari-Drinks" },
      { tag: "sekt", name: "Sekt-Drinks" },
      { tag: "rum", name: "Rum-Drinks" },
      { tag: "erfrischend", name: "Erfrischend" },
      { tag: "fruchtig", name: "Fruchtig" },
      { tag: "herb", name: "Herb" },
      { tag: "sauer", name: "Sauer" },
      { tag: "süß", name: "Süß" },
      { tag: "tropisch", name: "Tropisch" },
      { tag: "Shooter", name: "Shooter" },
      { tag: "alkoholfrei", name: "Alkoholfrei" }
    ]

    @lists = categories.map do |category|
      {
        name: category[:name],
        recipes: Recipe.tagged_with(category[:tag])
                      .order(average_rating: :desc, ratings_count: :desc)
                      .limit(10)
      }
    end
  end
end
