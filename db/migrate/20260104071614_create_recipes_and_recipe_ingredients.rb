class CreateRecipesAndRecipeIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :recipes do |t|
      # 1. Foreign Keys
      t.references :user, null: false, foreign_key: true
      t.references :updated_by, foreign_key: { to_table: :users }
      
      # 2. Essential Data
      t.string :title, null: false
      t.string :slug
      t.text :description
      
      # 3. Other Data
      
      # 4. Caches / Calculations
      t.decimal :total_volume, precision: 10, scale: 2
      t.decimal :alcohol_content, precision: 5, scale: 2
      t.integer :views, default: 0
      
      # 5. Legacy
      t.integer :old_id, index: true

      # 6. Timestamps
      t.timestamps
    end
    add_index :recipes, :slug, unique: true

    create_table :recipe_ingredients do |t|
      # 1. Foreign Keys
      t.references :recipe, null: false, foreign_key: true
      t.references :ingredient, null: false, foreign_key: true
      
      # 2. Data
      t.decimal :amount, precision: 10, scale: 2
      t.string :unit, default: 'cl'
      t.string :description # Was 'note' / 'description' in legacy
      
      # 3. Meta / Legacy
      t.integer :position # Was 'sequence' in legacy
      t.integer :old_id, index: true

      # 4. Timestamps
      t.timestamps
    end
  end
end
