class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.string :name, null: false              # 'cl', 'ml', 'tl', 'dash', 'piece'
      t.string :display_name, null: false      # 'cl', 'ml', 'TL', 'Spritzer', 'Stück'
      t.string :plural_name, null: false       # 'cl', 'ml', 'TL', 'Spritzer', 'Stück'
      t.string :category, null: false          # 'volume', 'count', 'special'
      t.decimal :ml_ratio, precision: 10, scale: 4  # Conversion to ml (null for count)
      t.boolean :divisible, default: true, null: false # Can use decimals? (false for 'piece')
      t.timestamps
    end

    add_index :units, :name, unique: true
  end
end
