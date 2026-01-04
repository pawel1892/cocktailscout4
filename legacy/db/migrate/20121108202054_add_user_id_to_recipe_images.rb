class AddUserIdToRecipeImages < ActiveRecord::Migration
  def change
    add_column :recipe_images, :user_id, :integer
  end
end
