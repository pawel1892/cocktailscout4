class AddColumnsToRecipe < ActiveRecord::Migration
  def change
    add_column :recipes, :cl_amount, :float
    add_column :recipes, :alcoholic_content, :integer
  end
end
