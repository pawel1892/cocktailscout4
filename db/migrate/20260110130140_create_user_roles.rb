class CreateUserRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.integer :old_id

      t.timestamps
    end
    add_index :user_roles, :old_id
  end
end
