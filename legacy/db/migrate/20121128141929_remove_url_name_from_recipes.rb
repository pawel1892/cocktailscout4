class RemoveUrlNameFromRecipes < ActiveRecord::Migration
  def up
    remove_column :recipes, :url_name
  end

  def down
    add_column :recipes, :url_name, :string
  end
end
