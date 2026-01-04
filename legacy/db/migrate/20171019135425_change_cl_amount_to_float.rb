class ChangeClAmountToFloat < ActiveRecord::Migration
  def change
    change_column(:recipe_ingredients, :cl_amount, :float)
  end
end
