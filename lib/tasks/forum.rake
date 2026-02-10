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
end
