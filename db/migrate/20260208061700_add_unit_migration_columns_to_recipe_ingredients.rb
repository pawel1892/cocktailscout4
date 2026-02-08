class AddUnitMigrationColumnsToRecipeIngredients < ActiveRecord::Migration[8.1]
  def change
    # Foreign Keys
    add_reference :recipe_ingredients, :unit, foreign_key: true, null: true

    # Data Columns
    add_column :recipe_ingredients, :additional_info, :string  # For "(braun)", garnish notes, etc.
    add_column :recipe_ingredients, :is_garnish, :boolean, default: false, null: false  # Garnishes don't scale

    # Legacy/Meta columns (temporary for migration validation)
    add_column :recipe_ingredients, :old_amount, :decimal, precision: 10, scale: 2
    add_column :recipe_ingredients, :old_unit, :string
    add_column :recipe_ingredients, :old_description, :string
  end
end
