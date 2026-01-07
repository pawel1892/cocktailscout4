class RemoveLegacyFieldsFromRecipeImages < ActiveRecord::Migration[8.1]
  def change
    remove_column :recipe_images, :folder_identifier, :string
    remove_column :recipe_images, :image_file_name, :string
    remove_column :recipe_images, :image_content_type, :string
    remove_column :recipe_images, :image_file_size, :integer
  end
end
