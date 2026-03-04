class HomeController < ApplicationController
  include ActivityStreamEnrichable

  allow_unauthenticated_access only: %i[ index ]

  def index
    set_meta_tags(
      title: "Cocktail-Rezepte, Drinks & Mixgetränke",
      description: "Willkommen bei CocktailScout.de - Deine Plattform für die besten Cocktail-Rezepte. Entdecke, erstelle und teile einzigartige Drinks."
    )
    @activity_stream = ActivityStreamService.new(limit: 10).call
    enrich_image_events!(@activity_stream)
  end
end
