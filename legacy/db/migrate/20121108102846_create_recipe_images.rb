class CreateRecipeImages < ActiveRecord::Migration
  def change
    create_table :recipe_images do |t|
      t.integer :recipe_id
      t.boolean :is_approved
      t.integer :approved_by

      t.timestamps
    end
  end
end
