class AddMlPerUnitToIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :ingredients, :ml_per_unit, :decimal, precision: 10, scale: 2, default: nil
  end
end
