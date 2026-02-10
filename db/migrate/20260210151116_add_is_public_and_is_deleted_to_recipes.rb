class AddIsPublicAndIsDeletedToRecipes < ActiveRecord::Migration[8.1]
  def change
    add_column :recipes, :is_public, :boolean, default: false, null: false
    add_column :recipes, :is_deleted, :boolean, default: false, null: false

    add_index :recipes, :is_public
    add_index :recipes, :is_deleted

    # Migrate existing recipes to published (they were all public before)
    reversible do |dir|
      dir.up do
        Recipe.update_all(is_public: true, is_deleted: false)
      end
    end
  end
end
