namespace :forum do
  namespace :links do
    desc "Update post IDs in BBCode tags from old_id to new id"
    task update_ids: :environment do
      dry_run = ENV["DRY_RUN"] != "false"

      puts "=" * 80
      puts "Forum Links ID Update (old_id -> id)"
      puts "=" * 80
      puts "Mode: #{dry_run ? 'DRY RUN (preview only)' : 'LIVE UPDATE'}"
      puts

      # Build a lookup hash: old_id => new_id
      puts "Building ID mapping (old_id => new_id)..."
      id_map = {}
      ForumPost.unscoped.where.not(old_id: nil).find_each do |post|
        id_map[post.old_id] = post.id
      end
      puts "Loaded #{id_map.size} ID mappings"
      puts

      # Find all posts with [post=] or [thread=] tags
      posts_with_tags = ForumPost.unscoped.where("body LIKE '%[post=%' OR body LIKE '%[thread=%'")
      puts "Found #{posts_with_tags.count} posts with BBCode forum tags"
      puts

      stats = {
        posts_updated: 0,
        post_ids_updated: 0,
        post_ids_not_found: 0,
        errors: []
      }

      posts_with_tags.find_each do |post|
        begin
          original_body = post.body
          updated_body = update_post_ids(original_body, id_map, stats)

          if original_body != updated_body
            stats[:posts_updated] += 1

            if dry_run
              # Show first few examples
              if stats[:posts_updated] <= 5
                puts "-" * 80
                puts "Post ID: #{post.id} (Old ID: #{post.old_id})"
                puts
                # Show just the changed tags
                original_tags = original_body.scan(/\[post=(\d+)\]/).flatten.uniq.first(5)
                updated_tags = updated_body.scan(/\[post=(\d+)\]/).flatten.uniq.first(5)
                puts "Old post IDs referenced: #{original_tags.join(', ')}"
                puts "New post IDs referenced: #{updated_tags.join(', ')}"
                puts
              end
            else
              # Skip callbacks to avoid updating thread timestamps
              post.update_column(:body, updated_body)
            end
          end
        rescue => e
          stats[:errors] << { post_id: post.id, error: e.message }
        end
      end

      puts "=" * 80
      puts "SUMMARY"
      puts "=" * 80
      puts "Posts updated: #{stats[:posts_updated]}"
      puts "Post IDs updated: #{stats[:post_ids_updated]}"
      puts "Post IDs not found (kept as-is): #{stats[:post_ids_not_found]}"

      if stats[:errors].any?
        puts
        puts "ERRORS:"
        stats[:errors].each do |error|
          puts "  Post #{error[:post_id]}: #{error[:error]}"
        end
      end

      if dry_run
        puts
        puts "This was a DRY RUN - no changes were made."
        puts "To apply changes, run: rake forum:links:update_ids DRY_RUN=false"
      else
        puts
        puts "ID update completed successfully!"
      end
    end
  end
end

# Helper method to update post IDs in BBCode tags
def update_post_ids(body, id_map, stats)
  result = body.dup

  # Update [post=OLD_ID] to [post=NEW_ID]
  result.gsub!(/\[post=(\d+)\]/) do
    old_id = Regexp.last_match(1).to_i
    new_id = id_map[old_id]

    if new_id
      stats[:post_ids_updated] += 1
      "[post=#{new_id}]"
    else
      # ID not found in mapping - might be a new post or deleted post
      stats[:post_ids_not_found] += 1
      "[post=#{old_id}]"
    end
  end

  result
end
