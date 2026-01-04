class CreateUserProfiles < ActiveRecord::Migration
  def change
    create_table :user_profiles do |t|
      t.string :gender
      t.string :prename
      t.string :public_mail
      t.string :homepage
      t.string :location
      t.string :title
      t.string :signature
      t.text :additional_data

      t.timestamps
    end
  end
end
