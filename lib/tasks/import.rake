namespace :import do
  desc "Ensure we are not in production"
  task :ensure_development do
    if Rails.env.production?
      abort "⚠️  DANGER: This task is destructive and cannot be run in production!"
    end
  end

  desc "Import all data from the legacy database (Resets DB and Storage first)"
  task all: :ensure_development do
    puts "⚠️  WARNING: This will delete all data in the current database and local storage!"
    puts "5 seconds to cancel (Ctrl+C)..."
    sleep 5

    # 1. Clear Storage
    puts "Cleaning storage/ directory..."
    storage_path = Rails.root.join("storage")
    if Dir.exist?(storage_path)
      # Delete all subdirectories in storage, keeping .keep or similar if needed
      # But usually blowing it away is fine.
      FileUtils.rm_rf(Dir.glob("#{storage_path}/*"))
    end
    puts "Storage cleaned."

    # 2. Reset Database
    puts "Resetting database..."
    Rake::Task["db:reset"].invoke
    puts "Database reset complete."

    # 3. Run Imports
    Rake::Task["import:ingredients"].invoke
    Rake::Task["import:users"].invoke
    Rake::Task["import:roles"].invoke
    Rake::Task["import:recipes"].invoke
    Rake::Task["import:recipe_images"].invoke
    Rake::Task["import:comments"].invoke
    Rake::Task["import:ratings"].invoke
    Rake::Task["import:tags"].invoke
    Rake::Task["import:forum"].invoke
    Rake::Task["import:private_messages"].invoke
    Rake::Task["import:visits"].invoke
    Rake::Task["import:favorites"].invoke
    Rake::Task["import:stats"].invoke
    Rake::Task["import:mybars"].invoke
    Rake::Task["import:migrate_images_to_active_storage"].invoke

    puts "\n✅ Full Import Complete!"
  end

  desc "Import visits from the legacy database"
  task visits: [ :environment, :ensure_development ] do
    puts "Loading maps..."
    user_map = User.where.not(old_id: nil).pluck(:old_id, :id).to_h
    recipe_map = Recipe.where.not(old_id: nil).pluck(:old_id, :id).to_h
    thread_map = ForumThread.unscoped.where.not(old_id: nil).pluck(:old_id, :id).to_h
    puts "Maps loaded. Users: #{user_map.size}, Recipes: #{recipe_map.size}, Threads: #{thread_map.size}"

    puts "Importing visits..."
    count = 0
    LegacyRecord.connection.select_all("SELECT * FROM visits").each do |legacy_visit|
      # Note: select_all returns hash with string keys
      visitable_type = legacy_visit["visitable_type"]
      visitable_id = legacy_visit["visitable_id"]

      new_visitable_id = case visitable_type
      when "Recipe" then recipe_map[visitable_id.to_i]
      when "ForumThread" then thread_map[visitable_id.to_i]
      end

      next unless new_visitable_id

      user_id = legacy_visit["user_id"] ? user_map[legacy_visit["user_id"].to_i] : nil

      # We skip if it was a user visit but we don't have that user in our system
      # (unless it was anonymous where user_id is nil)
      next if legacy_visit["user_id"] && !user_id

      visit = Visit.find_or_initialize_by(
        visitable_type: visitable_type,
        visitable_id: new_visitable_id,
        user_id: user_id
      )

      visit.assign_attributes(
        count: legacy_visit["total_visits"].to_i,
        last_visited_at: legacy_visit["last_visit_time"],
        old_id: legacy_visit["id"],
        created_at: legacy_visit["created_at"],
        updated_at: legacy_visit["updated_at"]
      )

      visit.save!(validate: false)
      count += 1
      print "." if (count % 1000).zero?
    end
    puts "\nVisits imported: #{count}"

    puts "Syncing visits_count cache for Recipes..."
    Recipe.find_each do |recipe|
      actual_count = recipe.visits.sum(:count)
      recipe.update_columns(visits_count: actual_count)
    end
    puts "Recipe cache sync complete."

    puts "Syncing visits_count cache for ForumThreads..."
    ForumThread.unscoped.find_each do |thread|
      actual_count = thread.visits.sum(:count)
      thread.update_columns(visits_count: actual_count)
    end
    puts "ForumThread cache sync complete."
  end

  desc "Import forum topics, threads and posts"
  task forum: [ :environment, :ensure_development ] do
    puts "Importing forum topics..."
    Legacy::ForumTopic.find_each do |legacy_topic|
      topic = ForumTopic.find_or_initialize_by(old_id: legacy_topic.id)
      topic.assign_attributes(
        name: legacy_topic.name,
        description: legacy_topic.description,
        slug: legacy_topic.slug,
        position: legacy_topic.sorting,
        created_at: legacy_topic.created_at,
        updated_at: legacy_topic.updated_at
      )
      topic.save!(validate: false)
    end
    puts "Forum topics imported."

    puts "Loading maps..."
    user_map = User.where.not(old_id: nil).pluck(:old_id, :id).to_h
    topic_map = ForumTopic.where.not(old_id: nil).pluck(:old_id, :id).to_h
    puts "Maps loaded. Users: #{user_map.size}, Topics: #{topic_map.size}"

    puts "Importing forum threads..."
    count = 0
    Legacy::ForumThread.unscoped.find_each do |legacy_thread|
      topic_id = topic_map[legacy_thread.forum_topic_id]
      next unless topic_id

      thread = ForumThread.unscoped.find_or_initialize_by(old_id: legacy_thread.id)
      thread.assign_attributes(
        forum_topic_id: topic_id,
        user_id: user_map[legacy_thread.user_id],
        title: legacy_thread.title,
        slug: legacy_thread.slug,
        sticky: legacy_thread.sticky || false,
        locked: legacy_thread.locked || false,
        deleted: legacy_thread.deleted || false,
        created_at: legacy_thread.created_at,
        updated_at: legacy_thread.updated_at
      )
      thread.save!(validate: false)
      count += 1
      print "." if (count % 100).zero?
    end
    puts "\nForum threads imported: #{count}"

    puts "Loading thread map..."
    thread_map = ForumThread.unscoped.where.not(old_id: nil).pluck(:old_id, :id).to_h
    puts "Thread map loaded: #{thread_map.size}"

    puts "Importing forum posts..."
    count = 0
    Legacy::ForumPost.unscoped.find_each do |legacy_post|
      thread_id = thread_map[legacy_post.forum_thread_id]
      next unless thread_id

      # Convert <br /> to newlines for cleaner storage
      clean_body = legacy_post.content&.gsub(/<br\s*\/?>/i, "\n")

      post = ForumPost.unscoped.find_or_initialize_by(old_id: legacy_post.id)
      post.assign_attributes(
        forum_thread_id: thread_id,
        user_id: user_map[legacy_post.user_id],
        last_editor_id: user_map[legacy_post.last_editor_id],
        body: clean_body,
        deleted: legacy_post.deleted || false,
        created_at: legacy_post.created_at,
        updated_at: legacy_post.updated_at
      )
      post.save!(validate: false)
      count += 1
      print "." if (count % 500).zero?
    end
    puts "\nForum posts imported: #{count}"
  end

  desc "Import private messages"
  task private_messages: [ :environment, :ensure_development ] do
    puts "Loading maps..."
    user_map = User.where.not(old_id: nil).pluck(:old_id, :id).to_h
    puts "Maps loaded. Users: #{user_map.size}"

    puts "Importing private messages..."
    count = 0
    Legacy::PrivateMessage.find_each do |legacy_message|
      sender_id = user_map[legacy_message.sender_id]
      receiver_id = user_map[legacy_message.receiver_id]

      # Skip if sender or receiver not found
      next unless sender_id && receiver_id

      # Convert <br /> to newlines for cleaner storage
      clean_body = legacy_message.message&.gsub(/<br\s*\/?>/i, "\n")

      message = PrivateMessage.find_or_initialize_by(old_id: legacy_message.id)
      message.assign_attributes(
        sender_id: sender_id,
        receiver_id: receiver_id,
        subject: legacy_message.subject,
        body: clean_body,
        read: legacy_message.read || false,
        deleted_by_receiver: legacy_message.deleted_by_receiver || false,
        deleted_by_sender: legacy_message.deleted_by_sender || false,
        created_at: legacy_message.created_at,
        updated_at: legacy_message.updated_at
      )
      message.save!(validate: false)
      count += 1
      print "." if (count % 100).zero?
    end
    puts "\nPrivate messages imported: #{count}"
  end

  desc "Import roles and user roles"
  task roles: [ :environment, :ensure_development ] do
    puts "Importing roles..."

    legacy_roles_map = {}

    Legacy::Role.find_each do |legacy_role|
      next if legacy_role.name == "member"

      role = Role.find_or_initialize_by(old_id: legacy_role.id)
      role.name = legacy_role.name
      role.save!

      legacy_roles_map[legacy_role.id] = role.id
    end
    puts "Roles imported."

    puts "Importing user roles..."
    user_map = User.where.not(old_id: nil).pluck(:old_id, :id).to_h

    count = 0
    Legacy::UserRole.find_each do |legacy_ur|
      new_user_id = user_map[legacy_ur.user_id]
      new_role_id = legacy_roles_map[legacy_ur.role_id]

      next unless new_user_id && new_role_id

      UserRole.find_or_create_by!(
        user_id: new_user_id,
        role_id: new_role_id
      ) do |ur|
        ur.old_id = legacy_ur.id
      end
      count += 1
    end
    puts "User roles imported: #{count}"
  end

  desc "Import tags from the legacy database"
  task tags: [ :environment, :ensure_development ] do
    puts "Loading maps..."
    recipe_map = Recipe.where.not(old_id: nil).pluck(:old_id, :id).to_h
    puts "Maps loaded. Recipes: #{recipe_map.size}"

    puts "Loading legacy tags..."
    legacy_tags = Legacy::Tag.pluck(:id, :name).to_h
    puts "Loaded #{legacy_tags.size} legacy tags."

    puts "Grouping tags by recipe..."
    recipe_tags = Hash.new { |h, k| h[k] = [] }
    Legacy::Tagging.where(taggable_type: "Recipe", context: "tags").find_each do |legacy_tagging|
      tag_name = legacy_tags[legacy_tagging.tag_id]
      recipe_tags[legacy_tagging.taggable_id] << tag_name if tag_name
    end
    puts "Found tags for #{recipe_tags.size} recipes."

    puts "Importing tags..."
    count = 0
    recipe_tags.each do |legacy_recipe_id, tags|
      new_id = recipe_map[legacy_recipe_id]
      next unless new_id

      recipe = Recipe.find(new_id)
      recipe.tag_list.add(tags)
      recipe.save!(validate: false)

      count += 1
      print "." if (count % 100).zero?
    end
    puts "\nTags imported for #{count} recipes."
  end

  desc "Import ratings from the legacy database"
  task ratings: [ :environment, :ensure_development ] do
    puts "Loading maps..."
    user_map = User.where.not(old_id: nil).pluck(:old_id, :id).to_h
    recipe_map = Recipe.where.not(old_id: nil).pluck(:old_id, :id).to_h
    puts "Maps loaded. Users: #{user_map.size}, Recipes: #{recipe_map.size}"

    puts "Importing ratings..."
    count = 0
    Legacy::Rate.where(rateable_type: "Recipe").find_each do |legacy_rate|
      new_recipe_id = recipe_map[legacy_rate.rateable_id]
      new_user_id = user_map[legacy_rate.rater_id]

      next unless new_recipe_id && new_user_id

      # Convert stars (1-5) to score (1-10)
      # Assuming legacy stars are float 1.0-5.0
      new_score = (legacy_rate.stars * 2).round
      new_score = 10 if new_score > 10
      new_score = 1 if new_score < 1

      rating = Rating.find_or_initialize_by(
        user_id: new_user_id,
        rateable_type: "Recipe",
        rateable_id: new_recipe_id
      )

      rating.score = new_score
      rating.old_id = legacy_rate.id
      rating.created_at = legacy_rate.created_at
      rating.updated_at = legacy_rate.updated_at

      rating.save!(validate: false)
      count += 1
      print "." if (count % 100).zero?
    end
    puts "\nRatings imported: #{count}"

    puts "Updating recipe cache..."
    Recipe.find_each(&:update_rating_cache!)
    puts "Cache updated."
  end

  desc "Import recipe images"
  task recipe_images: [ :environment, :ensure_development ] do
    puts "Importing recipe images..."
    Legacy::RecipeImage.find_each do |legacy_image|
      recipe = Recipe.find_by(old_id: legacy_image.recipe_id)
      user = User.find_by(old_id: legacy_image.user_id)

      next unless recipe && user

      image = RecipeImage.find_or_initialize_by(old_id: legacy_image.id)

      approved_at = legacy_image.is_approved ? legacy_image.updated_at : nil
      approved_by_user = nil
      if legacy_image.approved_by.present?
         approved_by_user = User.find_by(old_id: legacy_image.approved_by)
      end

      image.assign_attributes(
        recipe: recipe,
        user: user,
        approved_at: approved_at,
        approved_by: approved_by_user,
        created_at: legacy_image.created_at,
        updated_at: legacy_image.updated_at
      )
      image.save!(validate: false)
    end
    puts "Imported #{RecipeImage.count} recipe images (metadata only)."
  end

  desc "Import recipes from the legacy database"
  task recipes: [ :environment, :ensure_development ] do
    puts "Loading maps..."
    user_map = User.where.not(old_id: nil).pluck(:old_id, :id).to_h
    ingredient_map = Ingredient.where.not(old_id: nil).pluck(:old_id, :id).to_h
    puts "Maps loaded. Users: #{user_map.size}, Ingredients: #{ingredient_map.size}"

    puts "Importing recipes..."
    count = 0
    Legacy::Recipe.includes(:recipe_ingredients).find_each do |legacy_recipe|
      user_id = user_map[legacy_recipe.user_id]
      next unless user_id # Skip if user not found

      updated_by_id = legacy_recipe.last_edit_user_id ? user_map[legacy_recipe.last_edit_user_id] : nil

      recipe = Recipe.find_or_initialize_by(old_id: legacy_recipe.id)
      recipe.assign_attributes(
        user_id: user_id,
        updated_by_id: updated_by_id,
        title: legacy_recipe.name,
        description: legacy_recipe.description,
        slug: legacy_recipe.slug,
        total_volume: legacy_recipe.cl_amount || 0,
        alcohol_content: legacy_recipe.alcoholic_content || 0,
        created_at: legacy_recipe.created_at,
        updated_at: legacy_recipe.updated_at
      )
      recipe.save!(validate: false)

      # Import ingredients
      legacy_recipe.recipe_ingredients.each do |legacy_ri|
        new_ingredient_id = ingredient_map[legacy_ri.ingredient_id]
        next unless new_ingredient_id

        ri = recipe.recipe_ingredients.find_or_initialize_by(old_id: legacy_ri.id)
        ri.assign_attributes(
          ingredient_id: new_ingredient_id,
          amount: legacy_ri.cl_amount,
          unit: "cl", # Legacy seems to use cl_amount float, implies cl
          description: legacy_ri.description,
          position: legacy_ri.sequence,
          created_at: legacy_ri.created_at,
          updated_at: legacy_ri.updated_at
        )
        ri.save!(validate: false)
      end

      count += 1
      print "." if (count % 100).zero?
    end
    puts "\nRecipes imported: #{count}"
  end

  desc "Import comments from the legacy database"
  task comments: [ :environment, :ensure_development ] do
    puts "Loading maps..."
    user_map = User.where.not(old_id: nil).pluck(:old_id, :id).to_h
    recipe_map = Recipe.where.not(old_id: nil).pluck(:old_id, :id).to_h
    puts "Maps loaded. Users: #{user_map.size}, Recipes: #{recipe_map.size}"

    puts "Importing comments..."
    count = 0
    Legacy::RecipeComment.find_each do |legacy_comment|
      new_recipe_id = recipe_map[legacy_comment.recipe_id]
      next unless new_recipe_id # Skip if recipe doesn't exist

      # Convert <br /> to newlines for cleaner storage
      clean_body = legacy_comment.comment&.gsub(/<br\s*\/?>/i, "\n")

      comment = RecipeComment.find_or_initialize_by(old_id: legacy_comment.id)
      comment.assign_attributes(
        recipe_id: new_recipe_id,
        user_id: user_map[legacy_comment.user_id], # Nil if user not found
        last_editor_id: user_map[legacy_comment.last_editor_id],
        body: clean_body,
        created_at: legacy_comment.created_at,
        updated_at: legacy_comment.updated_at
      )
      comment.save!(validate: false)
      count += 1
      print "." if (count % 100).zero?
    end
    puts "\nComments imported: #{count}"
  end

  desc "Import ingredients from the legacy database"
  task ingredients: [ :environment, :ensure_development ] do
    puts "Importing ingredients..."
    Legacy::Ingredient.find_each do |legacy_ingredient|
      ingredient = Ingredient.find_or_initialize_by(old_id: legacy_ingredient.id)
      ingredient.update!(
        name: legacy_ingredient.name,
        description: legacy_ingredient.description,
        alcoholic_content: legacy_ingredient.alcoholic_content,
        slug: legacy_ingredient.slug,
        created_at: legacy_ingredient.created_at,
        updated_at: legacy_ingredient.updated_at
      )
    end
    puts "Ingredients imported!"
  end

  desc "Import users from the legacy database"
  task users: [ :environment, :ensure_development ] do
    puts "Identify active users..."
    active_user_ids = (
      Legacy::Recipe.pluck(:user_id) +
      Legacy::RecipeComment.pluck(:user_id) +
      Legacy::ForumPost.pluck(:user_id) +
      Legacy::UserRecipe.pluck(:user_id) +
      Legacy::RecipeImage.pluck(:user_id) +
      Legacy::UserIngredient.pluck(:user_id)
    ).uniq.compact
    puts "Found #{active_user_ids.count} active users."

    puts "Importing users..."
    Legacy::User.where(id: active_user_ids).where.not(confirmed_at: nil).includes(:user_profile).find_each do |legacy_user|
      user = User.find_or_initialize_by(old_id: legacy_user.id)

      # Base user attributes
      user.assign_attributes(
        email_address: legacy_user.email,
        password_digest: legacy_user.encrypted_password,
        username: legacy_user.login,
        sign_in_count: legacy_user.sign_in_count,
        last_active_at: legacy_user.last_active_at,
        confirmed_at: legacy_user.confirmed_at,
        created_at: legacy_user.created_at,
        updated_at: legacy_user.updated_at
      )

      # Profile attributes
      if legacy_user.user_profile
        user.assign_attributes(
          gender: legacy_user.user_profile.gender,
          prename: legacy_user.user_profile.prename,
          public_email: legacy_user.user_profile.public_mail,
          homepage: legacy_user.user_profile.homepage,
          location: legacy_user.user_profile.location,
          title: legacy_user.user_profile.title
        )
      end

      user.save!(validate: false)
    end
    puts "Users imported!"
  end

  desc "Recalculate user stats"
  task stats: [ :environment, :ensure_development ] do
    puts "Recalculating user stats..."
    User.find_each do |user|
      user.stat.recalculate!
    end
    puts "Stats updated for #{User.count} users."
  end

  desc "Import favorites (user_recipes) from the legacy database"
  task favorites: [ :environment, :ensure_development ] do
    puts "Loading maps..."
    user_map = User.where.not(old_id: nil).pluck(:old_id, :id).to_h
    recipe_map = Recipe.where.not(old_id: nil).pluck(:old_id, :id).to_h
    puts "Maps loaded. Users: #{user_map.size}, Recipes: #{recipe_map.size}"

    puts "Importing favorites..."
    count = 0
    Legacy::UserRecipe.find_each do |legacy_favorite|
      new_user_id = user_map[legacy_favorite.user_id]
      new_recipe_id = recipe_map[legacy_favorite.recipe_id]

      next unless new_user_id && new_recipe_id

      favorite = Favorite.find_or_initialize_by(
        user_id: new_user_id,
        favoritable_type: "Recipe",
        favoritable_id: new_recipe_id
      )

      favorite.assign_attributes(
        old_id: legacy_favorite.id,
        created_at: legacy_favorite.created_at,
        updated_at: legacy_favorite.updated_at
      )

      favorite.save!(validate: false)
      count += 1
      print "." if (count % 100).zero?
    end
    puts "\nFavorites imported: #{count}"
  end

  desc "Import user mybars from legacy database as 'Meine Hausbar' collections"
  task mybars: [ :environment, :ensure_development ] do
    puts "Starting MyBar Import..."

    # Pre-load user and ingredient mappings
    user_map = User.where.not(old_id: nil).pluck(:old_id, :id).to_h
    ingredient_map = Ingredient.where.not(old_id: nil).pluck(:old_id, :id).to_h

    # Group mybar ingredients by user
    mybar_data = {}
    Legacy::UserIngredient.where(dimension: "mybar").find_each do |legacy_ui|
      new_user_id = user_map[legacy_ui.user_id]
      new_ingredient_id = ingredient_map[legacy_ui.ingredient_id]

      # Skip if user or ingredient not found
      unless new_user_id && new_ingredient_id
        puts "Skipping user_ingredient #{legacy_ui.id}: User or ingredient not found."
        next
      end

      mybar_data[new_user_id] ||= []
      mybar_data[new_user_id] << new_ingredient_id
    end

    puts "Found #{mybar_data.keys.size} users with mybar data."

    # Create collections for users
    created = 0
    skipped = 0

    mybar_data.each do |user_id, ingredient_ids|
      user = User.find(user_id)

      # Check if user already has a "Meine Hausbar" collection
      collection = user.ingredient_collections.find_by(name: "Meine Hausbar")

      if collection
        puts "User #{user.username} (#{user_id}) already has 'Meine Hausbar' collection. Skipping."
        skipped += 1
        next
      end

      # Create the collection
      collection = user.ingredient_collections.create!(
        name: "Meine Hausbar",
        notes: "Importiert aus dem alten System",
        is_default: user.ingredient_collections.count == 0
      )

      # Add ingredients
      ingredients = Ingredient.where(id: ingredient_ids)
      collection.ingredients << ingredients

      puts "Created 'Meine Hausbar' for #{user.username} (#{user_id}) with #{ingredients.count} ingredients."
      created += 1
    end

    puts "\nMyBar Import Complete!"
  end

  desc "Migrate legacy recipe images to Active Storage (Approved only)"
  task migrate_images_to_active_storage: [ :environment, :ensure_development ] do
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
