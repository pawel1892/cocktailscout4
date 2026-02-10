namespace :forum do
  namespace :links do
    desc "Migrate BBCode tags from numeric IDs to public_ids"
    task migrate_to_public_ids: :environment do
      dry_run = ENV["DRY_RUN"] != "false"

      puts "=" * 80
      puts "Forum Links Migration: Numeric IDs → public_ids"
      puts "=" * 80
      puts "Mode: #{dry_run ? 'DRY RUN (preview only)' : 'LIVE UPDATE'}"
      puts

      # Build lookup: id => public_id
      puts "Building ID mapping (id => public_id)..."
      id_to_public_id = {}
      ForumPost.unscoped.find_each do |post|
        id_to_public_id[post.id] = post.public_id
      end
      puts "Loaded #{id_to_public_id.size} post ID mappings"
      puts

      # Find posts with [post=] tags
      posts_with_tags = ForumPost.unscoped.where("body LIKE '%[post=%'")
      puts "Found #{posts_with_tags.count} posts with [post=] tags"
      puts

      stats = {
        posts_updated: 0,
        ids_converted: 0,
        ids_not_found: 0,
        errors: []
      }

      posts_with_tags.find_each do |post|
        begin
          original_body = post.body
          updated_body = convert_to_public_ids(original_body, id_to_public_id, stats)

          if original_body != updated_body
            stats[:posts_updated] += 1

            if dry_run
              if stats[:posts_updated] <= 3
                puts "-" * 80
                puts "Post ID: #{post.id} (public_id: #{post.public_id})"
                puts
                # Show sample conversions
                original_ids = original_body.scan(/\[post=(\d+)\]/).flatten.uniq.first(3)
                puts "Sample conversions:"
                original_ids.each do |old_id|
                  new_public_id = id_to_public_id[old_id.to_i]
                  puts "  [post=#{old_id}] → [post=#{new_public_id || 'NOT FOUND'}]"
                end
                puts
              end
            else
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
      puts "IDs converted: #{stats[:ids_converted]}"
      puts "IDs not found (kept as-is): #{stats[:ids_not_found]}"

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
        puts "To apply changes, run: rake forum:links:migrate_to_public_ids DRY_RUN=false"
      else
        puts
        puts "Migration to public_ids completed successfully!"
      end
    end
  end
end

# Helper method to convert numeric IDs to public_ids
def convert_to_public_ids(body, id_to_public_id, stats)
  result = body.dup

  # Convert [post=NUMERIC_ID] to [post=PUBLIC_ID]
  result.gsub!(/\[post=(\d+)\]/) do
    numeric_id = Regexp.last_match(1).to_i
    public_id = id_to_public_id[numeric_id]

    if public_id
      stats[:ids_converted] += 1
      "[post=#{public_id}]"
    else
      # ID not found - might be deleted or invalid
      stats[:ids_not_found] += 1
      "[post=#{numeric_id}]"  # Keep as-is
    end
  end

  result
end
