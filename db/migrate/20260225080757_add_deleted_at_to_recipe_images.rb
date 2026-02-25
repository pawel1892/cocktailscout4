class AddDeletedAtToRecipeImages < ActiveRecord::Migration[8.0]
  def change
    add_column :recipe_images, :deleted_at, :datetime
    add_index  :recipe_images, :deleted_at
  end
end
