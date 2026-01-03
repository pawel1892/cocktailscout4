class CreateIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredients do |t|
      t.string :name
      t.text :description
      t.string :slug
      t.decimal :alcoholic_content
      t.integer :old_id

      t.timestamps
    end
  end
end
