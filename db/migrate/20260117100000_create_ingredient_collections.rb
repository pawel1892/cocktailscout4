class CreateIngredientCollections < ActiveRecord::Migration[8.0]
  def change
    create_table :ingredient_collections do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :notes
      t.boolean :is_default, default: false, null: false

      t.timestamps

      # Ensure user can't have duplicate collection names
      t.index [ :user_id, :name ], unique: true, name: 'index_ingredient_collections_on_user_and_name'
    end
  end
end
