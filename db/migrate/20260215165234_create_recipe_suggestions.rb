class CreateRecipeSuggestions < ActiveRecord::Migration[8.0]
  def change
    create_table :recipe_suggestions do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :title, null: false
      t.text :description
      t.string :tag_list
      t.string :status, default: 'pending', null: false
      t.text :feedback
      t.references :reviewed_by, foreign_key: { to_table: :users }, index: true
      t.datetime :reviewed_at
      t.references :published_recipe, foreign_key: { to_table: :recipes }, index: true

      t.timestamps
    end

    add_index :recipe_suggestions, :status
    add_index :recipe_suggestions, :created_at

    create_table :recipe_suggestion_ingredients do |t|
      t.references :recipe_suggestion, null: false, foreign_key: true, index: true
      t.references :ingredient, null: false, foreign_key: true, index: true
      t.references :unit, foreign_key: true, index: true
      t.decimal :amount, precision: 10, scale: 2
      t.string :additional_info
      t.string :display_name
      t.boolean :is_optional, default: false, null: false
      t.boolean :is_scalable, default: true, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :recipe_suggestion_ingredients, :position
  end
end
