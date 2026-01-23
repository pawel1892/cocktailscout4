class AddLastEditorIdToRecipeComments < ActiveRecord::Migration[8.1]
  def change
    add_reference :recipe_comments, :last_editor, null: true, foreign_key: { to_table: :users }, after: :user_id
  end
end
