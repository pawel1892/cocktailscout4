class AddPublicIdToForumPostsAndThreads < ActiveRecord::Migration[8.1]
  def change
    # Add public_id to forum_posts (after foreign keys, before data columns)
    # Note: forum_threads already use slugs as stable identifiers
    # Start as nullable to allow backfilling existing records
    unless column_exists?(:forum_posts, :public_id)
      add_column :forum_posts, :public_id, :string, limit: 8, after: :forum_thread_id
    end

    unless index_exists?(:forum_posts, :public_id, unique: true)
      add_index :forum_posts, :public_id, unique: true
    end

    # Backfill existing records
    reversible do |dir|
      dir.up do
        backfill_public_ids
      end
    end

    # Make public_id NOT NULL after backfilling (only if currently nullable)
    if column_exists?(:forum_posts, :public_id) &&
       connection.columns(:forum_posts).find { |c| c.name == "public_id" }&.null
      change_column_null :forum_posts, :public_id, false
    end
  end

  private

  def backfill_public_ids
    # Backfill forum_posts that don't already have a public_id
    ForumPost.unscoped.where(public_id: nil).find_each do |post|
      post.update_column(:public_id, generate_public_id)
    end
  end

  def generate_public_id
    loop do
      id = SecureRandom.alphanumeric(8)
      break id unless ForumPost.unscoped.exists?(public_id: id)
    end
  end
end
