class CreatePrivateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :private_messages do |t|
      t.references :sender, null: true, foreign_key: { to_table: :users }
      t.references :receiver, null: true, foreign_key: { to_table: :users }
      t.string :subject
      t.text :body
      t.boolean :read, default: false, null: false
      t.boolean :deleted_by_receiver, default: false, null: false
      t.boolean :deleted_by_sender, default: false, null: false
      t.integer :old_id

      t.timestamps
    end
    add_index :private_messages, :old_id
  end
end
