namespace :recipe_images do
  desc "Process thumb and medium variants for all approved images that haven't been processed yet"
  task process_variants: :environment do
    images = RecipeImage.approved.includes(image_attachment: :blob)
    total = images.count
    puts "Processing variants for #{total} approved images..."

    processed = 0
    failed = 0

    images.find_each do |ri|
      next unless ri.image.attached?

      begin
        ri.image.variant(:thumb).processed
        ri.image.variant(:medium).processed
        processed += 1
        print "." if processed % 10 == 0
      rescue => e
        failed += 1
        puts "\nFailed for RecipeImage ##{ri.id}: #{e.message}"
      end
    end

    puts "\nDone. #{processed} processed, #{failed} failed."
  end
end
