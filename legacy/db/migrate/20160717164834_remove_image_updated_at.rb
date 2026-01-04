class RemoveImageUpdatedAt < ActiveRecord::Migration
  def change
    remove_column :recipe_images, :image_updated_at, :datetime
  end
end
