class AddUniqueIndexToFavorites < ActiveRecord::Migration[8.1]
  def change
    add_index :favorites, [ :user_id, :favoritable_type, :favoritable_id ], unique: true, name: 'index_favorites_unique_user_favoritable'
  end
end
