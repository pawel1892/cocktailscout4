class RenameBlogTable < ActiveRecord::Migration
  def change
    rename_table :blogs, :blog_entries
  end
end
