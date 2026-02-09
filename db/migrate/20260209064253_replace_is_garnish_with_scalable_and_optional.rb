class ReplaceIsGarnishWithScalableAndOptional < ActiveRecord::Migration[8.1]
  def up
    # Add new columns with defaults
    # All ingredients default to scalable (true) and required (false)
    # Non-scalable ingredients will be set manually later
    add_column :recipe_ingredients, :is_scalable, :boolean, default: true, null: false
    add_column :recipe_ingredients, :is_optional, :boolean, default: false, null: false

    # Add indexes for performance
    add_index :recipe_ingredients, :is_scalable
    add_index :recipe_ingredients, :is_optional

    # Remove old column (no data migration - all default to scalable)
    remove_column :recipe_ingredients, :is_garnish
  end

  def down
    # Add back is_garnish (all default to false)
    add_column :recipe_ingredients, :is_garnish, :boolean, default: false, null: false

    # Remove new columns
    remove_index :recipe_ingredients, :is_optional
    remove_index :recipe_ingredients, :is_scalable
    remove_column :recipe_ingredients, :is_optional
    remove_column :recipe_ingredients, :is_scalable
  end
end
