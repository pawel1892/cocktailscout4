class AddLastEditUserToRecipes < ActiveRecord::Migration
  def change
    add_column :recipes, :last_edit_user_id, :integer
  end
end
