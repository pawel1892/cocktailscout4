class AddParentAndNetVotesToRecipeComments < ActiveRecord::Migration[8.0]
  def change
    add_reference :recipe_comments, :parent, foreign_key: { to_table: :recipe_comments }, null: true
    add_column :recipe_comments, :net_votes, :integer, default: 0, null: false
  end
end
