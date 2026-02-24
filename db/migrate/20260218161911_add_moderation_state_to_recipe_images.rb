class AddModerationStateToRecipeImages < ActiveRecord::Migration[8.1]
  def up
    rename_column :recipe_images, :approved_by_id, :moderated_by_id
    rename_column :recipe_images, :approved_at, :moderated_at

    add_column :recipe_images, :state, :string, null: false, default: "pending",
               after: :moderated_by_id
    add_column :recipe_images, :moderation_reason, :text, after: :moderated_at

    # Data migration: all existing images are approved (legacy DB no longer accessible)
    execute "UPDATE recipe_images SET state = 'approved'"

    add_index :recipe_images, :state
  end

  def down
    remove_index :recipe_images, :state
    remove_column :recipe_images, :moderation_reason
    remove_column :recipe_images, :state
    rename_column :recipe_images, :moderated_at, :approved_at
    rename_column :recipe_images, :moderated_by_id, :approved_by_id
  end
end
