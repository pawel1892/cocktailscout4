class CreateBars < ActiveRecord::Migration
  def change
    create_table :bars do |t|
      t.string :name
      t.text :description_html
      t.string :street
      t.string :zip
      t.string :city
      t.string :phone
      t.string :email
      t.string :homepage

      t.timestamps
    end
  end
end
