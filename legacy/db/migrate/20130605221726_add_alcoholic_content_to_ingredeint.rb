class AddAlcoholicContentToIngredeint < ActiveRecord::Migration
  def change
    add_column :ingredients, :alcoholic_content, :integer
  end
end
