namespace :favorites do
  desc "Backfill favorites_count cache on recipes"
  task backfill: :environment do
    Recipe.find_each do |recipe|
      count = recipe.favorites.count
      recipe.update_columns(favorites_count: count)
    end
    puts "Done."
  end
end
