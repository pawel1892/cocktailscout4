class CreateCommentVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :comment_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.references :recipe_comment, null: false, foreign_key: true
      t.integer :value, null: false
      t.timestamps
    end
    add_index :comment_votes, [ :user_id, :recipe_comment_id ], unique: true
  end
end
