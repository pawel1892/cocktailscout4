class FixColumnName < ActiveRecord::Migration
  def up
    rename_column :recipes, :description_html, :description
  end

  def down
    rename_column :recipes, :description, :description_html
  end
end
