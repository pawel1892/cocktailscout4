class AddTeaserToBlogs < ActiveRecord::Migration
  def change
    add_column :blogs, :teaser, :text
  end
end
