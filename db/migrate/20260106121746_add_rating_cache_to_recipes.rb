class AddRatingCacheToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :average_rating, :decimal, precision: 3, scale: 1, default: 0.0
    add_column :recipes, :ratings_count, :integer, default: 0
  end
end
