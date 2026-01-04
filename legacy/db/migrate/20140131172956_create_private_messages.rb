class CreatePrivateMessages < ActiveRecord::Migration
  def change
    create_table :private_messages do |t|
      t.integer :sender_id
      t.integer :receiver_id
      t.string :subject
      t.text :message
      t.boolean :read, default: 0
      t.boolean :deleted_by_receiver, default: 0
      t.boolean :deleted_by_sender, default: 0

      t.timestamps
    end
  end
end
