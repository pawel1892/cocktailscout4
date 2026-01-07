class AddFolderIdentifierToRecipeImages < ActiveRecord::Migration[8.1]
  def change
    add_column :recipe_images, :folder_identifier, :string
  end
end
