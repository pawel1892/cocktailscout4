class AddFeaturedAtToRecipeImages < ActiveRecord::Migration[8.0]
  def change
    add_column :recipe_images, :featured_at, :datetime, after: :state
  end
end
