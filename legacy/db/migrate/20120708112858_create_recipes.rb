class CreateRecipes < ActiveRecord::Migration
  def change
    create_table :recipes do |t|
      t.string :name
      t.text :description_html
      t.string :image_url
      t.integer :views

      t.timestamps
    end
  end
end
