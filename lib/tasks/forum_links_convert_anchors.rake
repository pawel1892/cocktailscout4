namespace :forum do
  namespace :links do
    desc "Convert relative anchor links [url=#ID] to [post=ID] format"
    task convert_anchors: :environment do
      dry_run = ENV["DRY_RUN"] != "false"

      puts "=" * 80
      puts "Forum Anchor Links Migration"
      puts "=" * 80
      puts "Mode: #{dry_run ? 'DRY RUN (preview only)' : 'LIVE UPDATE'}"
      puts

      # Build ID mapping: old_id => new_id
      puts "Building ID mapping (old_id => new_id)..."
      id_map = {}
      ForumPost.unscoped.where.not(old_id: nil).find_each do |post|
        id_map[post.old_id] = post.id
      end
      puts "Loaded #{id_map.size} ID mappings"
      puts

      # Find posts with anchor-style links
      posts_with_anchors = ForumPost.unscoped.where("body LIKE '%[url=#%'")
      puts "Found #{posts_with_anchors.count} posts with anchor links"
      puts

      stats = {
        posts_updated: 0,
        anchors_converted: 0,
        anchors_not_found: 0,
        errors: []
      }

      posts_with_anchors.find_each do |post|
        begin
          original_body = post.body
          updated_body = convert_anchor_links(original_body, id_map, stats)

          if original_body != updated_body
            stats[:posts_updated] += 1

            if dry_run
              if stats[:posts_updated] <= 3
                puts "-" * 80
                puts "Post ID: #{post.id}"
                puts
                puts "SAMPLE CONVERSIONS:"
                # Show just the changed anchors
                original_anchors = original_body.scan(/\[url=#(\d+)\]/).flatten.uniq.first(5)
                updated_anchors = updated_body.scan(/\[post=(\d+)\]/).flatten.uniq.first(5)
                original_anchors.each_with_index do |old_id, i|
                  new_id = id_map[old_id.to_i]
                  puts "  [url=##{old_id}] -> [post=#{new_id || 'NOT FOUND'}]"
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
      puts "Anchors converted: #{stats[:anchors_converted]}"
      puts "Anchors not found (kept as-is): #{stats[:anchors_not_found]}"

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
        puts "To apply changes, run: rake forum:links:convert_anchors DRY_RUN=false"
      else
        puts
        puts "Anchor conversion completed successfully!"
      end
    end
  end
end

# Helper method to convert anchor links
def convert_anchor_links(body, id_map, stats)
  result = body.dup

  # Convert [url=#POST_ID]text[/url] to [post=POST_ID]text[/post]
  # Important: Match each individual url tag, not across multiple tags
  # Use negative lookahead to stop at the first [/url] that doesn't have another [url= before it
  result.gsub!(/\[url=#(\d+)\]((?:(?!\[url=)(?!\[\/url\]).)*)\[\/url\]/mi) do
    old_post_id = Regexp.last_match(1).to_i
    link_text = Regexp.last_match(2)

    # Look up the new ID
    new_post_id = id_map[old_post_id]

    if new_post_id
      stats[:anchors_converted] += 1
      "[post=#{new_post_id}]#{link_text}[/post]"
    else
      # Keep as-is if we can't find the mapping
      stats[:anchors_not_found] += 1
      "[url=##{old_post_id}]#{link_text}[/url]"
    end
  end

  result
end
