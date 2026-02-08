class AddPluralNameToIngredients < ActiveRecord::Migration[8.1]
  def change
    add_column :ingredients, :plural_name, :string, after: :name
  end
end
