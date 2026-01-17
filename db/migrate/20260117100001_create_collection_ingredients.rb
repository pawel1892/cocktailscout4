class CreateCollectionIngredients < ActiveRecord::Migration[8.0]
  def change
    create_table :collection_ingredients do |t|
      t.references :ingredient_collection, null: false, foreign_key: true, index: true
      t.references :ingredient, null: false, foreign_key: true

      t.timestamps

      # Composite unique index - an ingredient can only appear once per collection
      t.index [ :ingredient_collection_id, :ingredient_id ],
              unique: true,
              name: 'index_collection_ingredients_on_collection_and_ingredient'

      # Useful for queries like "which collections contain this ingredient?"
      t.index [ :ingredient_id, :ingredient_collection_id ],
              name: 'index_collection_ingredients_on_ingredient_and_collection'
    end
  end
end
