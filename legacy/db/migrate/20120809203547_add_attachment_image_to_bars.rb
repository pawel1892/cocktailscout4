class AddAttachmentImageToBars < ActiveRecord::Migration
  def self.up
    change_table :bars do |t|
      t.has_attached_file :image
    end
  end

  def self.down
    drop_attached_file :bars, :image
  end
end
