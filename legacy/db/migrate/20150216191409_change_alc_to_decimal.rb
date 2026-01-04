class ChangeAlcToDecimal < ActiveRecord::Migration
  def change
    change_column :ingredients, :alcoholic_content, :decimal, precision: 3, scale: 1
  end
end
