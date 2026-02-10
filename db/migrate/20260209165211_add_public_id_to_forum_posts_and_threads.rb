class AddPublicIdToForumPostsAndThreads < ActiveRecord::Migration[8.1]
  def change
    # Add public_id to forum_posts (after foreign keys, before data columns)
    # Note: forum_threads already use slugs as stable identifiers
    # Start as nullable to allow backfilling existing records
    add_column :forum_posts, :public_id, :string, limit: 8, after: :forum_thread_id
    add_index :forum_posts, :public_id, unique: true

    # Backfill existing records
    reversible do |dir|
      dir.up do
        backfill_public_ids
      end
    end

    # Make public_id NOT NULL after backfilling
    change_column_null :forum_posts, :public_id, false
  end

  private

  def backfill_public_ids
    # Backfill forum_posts
    ForumPost.unscoped.find_each do |post|
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
