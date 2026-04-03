class UpdateForumImagesForOrphanTracking < ActiveRecord::Migration[8.1]
  def change
    change_column_null :forum_images, :user_id, true
    add_column :forum_images, :orphaned_at, :datetime, null: true
    add_index :forum_images, :orphaned_at
  end
end
