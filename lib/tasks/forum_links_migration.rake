namespace :forum do
  namespace :links do
    desc "Migrate forum URL links to BBCode [post] and [thread] tags"
    task migrate: :environment do
      dry_run = ENV["DRY_RUN"] != "false"

      puts "=" * 80
      puts "Forum Links Migration to BBCode"
      puts "=" * 80
      puts "Mode: #{dry_run ? 'DRY RUN (preview only)' : 'LIVE UPDATE'}"
      puts

      # Find all posts with forum URLs
      posts_with_links = ForumPost.unscoped.where("body LIKE ?", "%[url=%cocktailforum%")

      puts "Found #{posts_with_links.count} posts with forum URL links"
      puts

      stats = {
        posts_updated: 0,
        thread_links_converted: 0,
        post_links_converted: 0,
        errors: []
      }

      posts_with_links.find_each do |post|
        begin
          original_body = post.body
          updated_body = migrate_forum_links(original_body, stats)

          if original_body != updated_body
            stats[:posts_updated] += 1

            if dry_run
              puts "-" * 80
              puts "Post ID: #{post.id} (Thread: #{post.forum_thread.title})"
              puts
              puts "ORIGINAL:"
              puts original_body
              puts
              puts "CONVERTED:"
              puts updated_body
              puts
            else
              # Skip callbacks to avoid updating thread timestamps unnecessarily
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
      puts "Thread links converted: #{stats[:thread_links_converted]}"
      puts "Post links converted: #{stats[:post_links_converted]}"

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
        puts "To apply changes, run: rake forum:links:migrate DRY_RUN=false"
      else
        puts
        puts "Migration completed successfully!"
      end
    end

    desc "Show sample forum links that would be migrated"
    task preview: :environment do
      posts_with_links = ForumPost.unscoped
        .where("body LIKE ?", "%[url=%cocktailforum%")
        .limit(10)

      puts "Sample forum links found (first 10 posts):"
      puts "=" * 80

      posts_with_links.each do |post|
        # Extract just the URL tags
        urls = post.body.scan(/\[url=(.*?)\](.*?)\[\/url\]/mi)
        forum_urls = urls.select { |url, _| url.include?("cocktailforum") }

        if forum_urls.any?
          puts
          puts "Post ID: #{post.id}"
          forum_urls.each do |url, text|
            puts "  URL: #{url}"
            puts "  Text: #{text}"
            puts
          end
        end
      end
    end
  end
end

# Helper method to migrate forum links
def migrate_forum_links(body, stats)
  result = body.dup

  # First, fix any malformed tags from previous partial migrations
  # Fix [post=123]...[/url] -> [post=123]...[/post]
  result.gsub!(/\[post=(\d+)\](.*?)\[\/url\]/mi, '[post=\1]\2[/post]')
  # Fix [thread=slug]...[/url] -> [thread=slug]...[/thread]
  result.gsub!(/\[thread=([a-z0-9\-]+)\](.*?)\[\/url\]/mi, '[thread=\1]\2[/thread]')

  # Pattern: [url=FORUM_URL]TEXT[/url]
  # We need to handle:
  # 1. Thread links: /cocktailforum/thema/{slug}
  # 2. Post links: /cocktailforum/beitrag/{id}
  # 3. Thread with anchor: /cocktailforum/thema/{slug}#{post_id}
  # 4. Query parameters and /seite/ paths
  # Note: Use non-greedy match for content to handle nested BBCode

  result.gsub!(/\[url=(https?:\/\/[^\]]*?cocktailforum[^\]]*?)\](.*?)\[\/url\]/mi) do
    url = Regexp.last_match(1)
    link_text = Regexp.last_match(2)

    # Skip if URL is nil or empty
    next "[url=#{url}]#{link_text}[/url]" if url.nil? || url.strip.empty?

    # Strip leading/trailing whitespace from URL
    url = url.strip

    # Decode URL-encoded characters (e.g., %20 -> space)
    decoded_url = CGI.unescape(url)

    # Remove domain if present (handle both http and https)
    path = decoded_url.sub(%r{^https?://[^/]+}, "")

    # Skip if path is nil or empty after domain removal
    next "[url=#{url}]#{link_text}[/url]" if path.nil? || path.strip.empty?

    # Remove query parameters but keep anchor
    # Split on # first to preserve anchor
    path_parts = path.split("#")
    base_path = path_parts[0]
    anchor = path_parts[1]

    # Remove query string and /seite/N from base path
    base_path = base_path.split("?").first
    base_path = base_path.sub(%r{/seite/\d+$}, "")

    # Check for post link with anchor (e.g., #61093)
    if anchor && anchor =~ /^(\d+)$/
      post_id = Regexp.last_match(1)
      stats[:post_links_converted] += 1

      # If link text is empty, let BBCode auto-generate it
      if link_text.strip.empty?
        "[post=#{post_id}][/post]"
      else
        "[post=#{post_id}]#{link_text}[/post]"
      end

    # Check for direct post link (e.g., /cocktailforum/beitrag/123)
    elsif base_path =~ %r{/cocktailforum/beitrag/(\d+)}
      post_id = Regexp.last_match(1)
      stats[:post_links_converted] += 1

      if link_text.strip.empty?
        "[post=#{post_id}][/post]"
      else
        "[post=#{post_id}]#{link_text}[/post]"
      end

    # Check for thread link (e.g., /cocktailforum/thema/slug)
    elsif base_path =~ %r{/cocktailforum/thema/([a-z0-9\-]+)}
      thread_slug = Regexp.last_match(1)
      stats[:thread_links_converted] += 1

      if link_text.strip.empty?
        "[thread=#{thread_slug}][/thread]"
      else
        "[thread=#{thread_slug}]#{link_text}[/thread]"
      end

    else
      # Not a recognized forum link pattern, keep original
      "[url=#{url}]#{link_text}[/url]"
    end
  end

  result
end
