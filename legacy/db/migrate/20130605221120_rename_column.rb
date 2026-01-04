class RenameColumn < ActiveRecord::Migration
  def change
    rename_column :ingredients, :description_html, :description
  end
end
