class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      # Essential Data
      t.string :email_address, null: false
      t.string :password_digest, null: false
      t.string :username

      # Profile Data
      t.string :prename
      t.string :title
      t.string :gender
      t.string :location
      t.string :homepage
      t.string :public_email

      # Activity / Meta
      t.integer :sign_in_count
      t.datetime :last_active_at

      # Legacy
      t.integer :old_id

      # Timestamps
      t.timestamps
    end
    add_index :users, :email_address, unique: true
    add_index :users, :username
  end
end
