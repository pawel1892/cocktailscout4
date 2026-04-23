class HomeController < ApplicationController
  include ActivityStreamEnrichable

  allow_unauthenticated_access only: %i[ index ]

  def index
    set_meta_tags(
      title: "Cocktail-Rezepte, Drinks & Mixgetränke",
      description: "Willkommen bei CocktailScout.de - Deine Plattform für die besten Cocktail-Rezepte. Entdecke, erstelle und teile einzigartige Drinks."
    )
    @featured_image = RecipeImage.featured.joins(:recipe).merge(Recipe.visible).includes(:recipe).first
    @top_recipes = Recipe.visible
                         .where("ratings_count >= ?", Rateable::MIN_RATINGS_FOR_DISPLAY)
                         .order(average_rating: :desc, ratings_count: :desc)
                         .limit(3)
                         .includes(:user, :tags, approved_recipe_images: { image_attachment: :blob })
    @activity_stream = ActivityStreamService.new(limit: 5).call
    enrich_image_events!(@activity_stream)
    news_topic = ForumTopic.find_by(slug: ForumTopic::NEWS_FORUM_SLUG)
    @news_threads = news_topic&.forum_threads&.order(created_at: :desc)&.limit(3) || []
  end
end
