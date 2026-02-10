class AddPublicIdToForumPostsAndThreads < ActiveRecord::Migration[8.1]
  def change
    # Add public_id to forum_posts (after foreign keys, before data columns)
    # Note: forum_threads already use slugs as stable identifiers
    # Column is nullable to allow backfilling via rake task
    unless column_exists?(:forum_posts, :public_id)
      add_column :forum_posts, :public_id, :string, limit: 8, after: :forum_thread_id
    end

    unless index_exists?(:forum_posts, :public_id, unique: true)
      add_index :forum_posts, :public_id, unique: true
    end

    # Note: Backfilling is handled by rake task forum:backfill_public_ids
    # to avoid migration timeout with large datasets (120k+ posts)
    # New posts will get public_id via before_create callback in model
  end
end
