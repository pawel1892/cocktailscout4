class ChangeColumnNameRecipeUser < ActiveRecord::Migration
  def change
    rename_column :user_recipes, :list, :dimension
  end
end
