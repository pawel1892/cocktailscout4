class CreateForumImages < ActiveRecord::Migration[8.1]
  def change
    create_table :forum_images do |t|
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
  end
end
