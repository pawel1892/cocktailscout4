class AddHighQualityToRecipeImages < ActiveRecord::Migration[8.0]
  def change
    add_column :recipe_images, :high_quality, :boolean, default: false, null: false
    add_index  :recipe_images, :high_quality
  end
end
