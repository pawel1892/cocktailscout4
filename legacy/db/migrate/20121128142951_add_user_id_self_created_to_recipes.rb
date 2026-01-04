class AddUserIdSelfCreatedToRecipes < ActiveRecord::Migration
  def change
    add_column :recipes, :user_id, :integer
    add_column :recipes, :self_created, :boolean
  end
end
