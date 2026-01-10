namespace :import do
  desc "Migrate legacy recipe images to Active Storage (Approved only)"
  task migrate_images_to_active_storage: :environment do
    require "fileutils"

    # Filter for approved images only
    scope = RecipeImage.approved.where.not(old_id: nil)

    total = scope.count
    processed = 0
    missing = 0
    success = 0

    puts "Starting migration of #{total} APPROVED images..."

    scope.find_each do |recipe_image|
      # Skip if already attached
      next if recipe_image.image.attached?

      legacy_image = Legacy::RecipeImage.find_by(id: recipe_image.old_id)
      next unless legacy_image

      # Construct path to the original legacy image
      # Structure: public/system/recipe_images/:folder_identifier/original/:filename
      legacy_path = Rails.root.join(
        "public",
        "system",
        "recipe_images",
        recipe_image.old_id.to_s,
        "original",
        legacy_image.image_file_name
      )

      if File.exist?(legacy_path)
        begin
          File.open(legacy_path) do |file|
            recipe_image.image.attach(
              io: file,
              filename: legacy_image.image_file_name,
              content_type: legacy_image.image_content_type
            )
          end
          success += 1
          print "."
          STDOUT.flush if processed % 10 == 0
        rescue => e
          puts "\nFailed to attach image for ID #{recipe_image.id}: #{e.message}"
        end
      else
        missing += 1
        # Uncomment for debugging missing files
        # puts "\nMissing file for ID #{recipe_image.id}: #{legacy_path}"
      end

      processed += 1
    end

    puts "\nMigration complete!"
    puts "Processed: #{processed}"
    puts "Successfully attached: #{success}"
    puts "Missing files: #{missing}"
  end
end
