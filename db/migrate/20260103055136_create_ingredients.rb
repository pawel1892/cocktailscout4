class CreateIngredients < ActiveRecord::Migration[8.1]
  def change
    create_table :ingredients do |t|
      # Essential Data
      t.string :name
      t.string :slug
      t.text :description

      # Data
      t.decimal :alcoholic_content

      # Legacy
      t.integer :old_id

      # Timestamps
      t.timestamps
    end
  end
end
