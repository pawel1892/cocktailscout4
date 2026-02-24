class AddUnitsMigrationFields < ActiveRecord::Migration[8.1]
  def change
    # Track ingredients that need manual review
    unless column_exists?(:recipe_ingredients, :needs_review)
      add_column :recipe_ingredients, :needs_review, :boolean, default: false, null: false
    end

    unless index_exists?(:recipe_ingredients, :needs_review)
      add_index :recipe_ingredients, :needs_review
    end

    # Note: divisible column already exists on units table
  end
end
