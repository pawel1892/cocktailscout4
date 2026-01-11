class FixRecipesColumnOrdering < ActiveRecord::Migration[8.1]
  def change
    # Current order ends with: ..., visits_count, old_id, created_at, updated_at, average_rating, ratings_count
    # Target order: ..., visits_count, average_rating, ratings_count, old_id, created_at, updated_at

    change_column :recipes, :average_rating, :decimal, precision: 3, scale: 1, default: "0.0", after: :visits_count
    change_column :recipes, :ratings_count, :integer, default: 0, after: :average_rating
    change_column :recipes, :old_id, :integer, after: :ratings_count
  end
end
