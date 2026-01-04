class AddColumnsToComment < ActiveRecord::Migration
  def change
    add_column :recipe_comments, :guest_name, :string
    add_column :recipe_comments, :guest_email, :string
    add_column :recipe_comments, :last_editor_id, :integer
  end
end
