namespace :ratings do
  desc "Recalculate rating cache for all recipes (sets average_rating to 0 for recipes below the minimum ratings threshold)"
  task recalculate_cache: :environment do
    threshold = Rateable::MIN_RATINGS_FOR_DISPLAY
    scope = Recipe.unscoped.where("ratings_count > 0 AND ratings_count < ?", threshold)
    count = scope.count

    puts "Recalculating rating cache..."
    puts "Recipes with ratings below threshold (< #{threshold}): #{count}"

    scope.find_each do |recipe|
      recipe.update_rating_cache!
      print "."
    end

    puts ""
    puts "Done."
  end
end
