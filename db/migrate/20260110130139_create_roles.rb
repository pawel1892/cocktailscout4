class CreateRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :roles do |t|
      t.string :name
      t.integer :old_id

      t.timestamps
    end
    add_index :roles, :old_id
  end
end
