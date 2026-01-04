module RecipesHelper
  def recipe_rating(recipe)
    render 'recipes/rating', rating: recipe.rating.to_f, rating_count: recipe.rating_count
  end
end
