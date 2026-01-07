class AddLegacyFieldsToRecipeImages < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_images, :image_file_name, :string
    add_column :recipe_images, :image_content_type, :string
    add_column :recipe_images, :image_file_size, :integer
  end
end
