class HomeController < ApplicationController
  allow_unauthenticated_access only: %i[ index ]
  def index
    set_meta_tags(
      title: "Home",
      description: "Willkommen bei CocktailScout.de - Deine Plattform für die besten Cocktail-Rezepte. Entdecke, erstelle und teile einzigartige Drinks."
    )
  end
end
