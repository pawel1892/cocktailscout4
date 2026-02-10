class SetForumPostsPublicIdNotNull < ActiveRecord::Migration[8.1]
  def up
    # Only set NOT NULL if column currently allows nulls
    if column_allows_null?(:forum_posts, :public_id)
      # First check if there are any NULL values
      null_count = connection.select_value("SELECT COUNT(*) FROM forum_posts WHERE public_id IS NULL")

      if null_count > 0
        raise StandardError, "Cannot set NOT NULL: #{null_count} forum_posts have NULL public_id. Run 'bin/rails forum:backfill_public_ids' first."
      end

      change_column_null :forum_posts, :public_id, false
      say "Set public_id to NOT NULL"
    else
      say "public_id is already NOT NULL, skipping"
    end
  end

  def down
    # Allow reverting back to nullable if needed
    change_column_null :forum_posts, :public_id, true
  end

  private

  def column_allows_null?(table, column)
    connection.columns(table).find { |c| c.name == column.to_s }&.null
  end
end
