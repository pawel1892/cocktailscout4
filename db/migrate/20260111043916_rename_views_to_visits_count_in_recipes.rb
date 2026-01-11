class RenameViewsToVisitsCountInRecipes < ActiveRecord::Migration[8.1]
  def change
    rename_column :recipes, :views, :visits_count
  end
end
