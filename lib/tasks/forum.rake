require "cgi"

namespace :forum do
  desc "Backfill public_id for existing forum posts"
  task backfill_public_ids: :environment do
    puts "Starting public_id backfill..."

    # Count posts without public_id
    total = ForumPost.unscoped.where(public_id: nil).count
    puts "Found #{total} posts without public_id"

    if total.zero?
      puts "No posts to backfill!"
      return
    end

    # Process in batches
    batch_size = 1000
    processed = 0

    ForumPost.unscoped.where(public_id: nil).find_in_batches(batch_size: batch_size) do |batch|
      batch.each do |post|
        # Generate unique public_id
        public_id = loop do
          id = SecureRandom.alphanumeric(8)
          break id unless ForumPost.unscoped.exists?(public_id: id)
        end

        post.update_column(:public_id, public_id)
        processed += 1

        # Progress update every 100 posts
        if processed % 100 == 0
          puts "Processed #{processed}/#{total} posts (#{(processed.to_f / total * 100).round(1)}%)"
        end
      end
    end

    puts "Backfill complete! Processed #{processed} posts."
  end

  desc "Fix double-encoded HTML entities in forum post bodies (e.g. &amp; → &). Use DRY_RUN=true to preview."
  task fix_html_entities: :environment do
    dry_run = ENV["DRY_RUN"] == "true"
    puts dry_run ? "DRY RUN - keine Änderungen werden gespeichert" : "Starte Fix für HTML-Entities in Forum-Posts..."

    total = ForumPost.unscoped.count
    puts "Gesamt: #{total} Posts"

    affected = 0
    checked = 0

    ForumPost.unscoped.find_in_batches(batch_size: 500) do |batch|
      batch.each do |post|
        checked += 1
        decoded = CGI.unescapeHTML(post.body)
        next if decoded == post.body

        affected += 1
        if dry_run
          puts "Post ##{post.public_id}: #{post.body.truncate(80).inspect} → #{decoded.truncate(80).inspect}"
        else
          post.update_column(:body, decoded)
        end
      end
      print "\r#{checked}/#{total} geprüft, #{affected} betroffen..."
    end

    puts "\nFertig. #{affected} von #{total} Posts #{dry_run ? "würden" : "wurden"} korrigiert."
  end
end
