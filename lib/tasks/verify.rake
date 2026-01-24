# lib/tasks/verify.rake

module VerifyImport
  SAMPLE_SIZE = 50

  def self.assert_equal(label, val1, val2, errors)
    v1 = val1.presence
    v2 = val2.presence

    # Time comparison (1s tolerance)
    if v1.is_a?(Time) && v2.is_a?(Time)
      unless (v1 - v2).abs < 1.0
        errors << "#{label} mismatch: #{v1} vs #{v2}"
      end
      return
    end

    # Float comparison
    if v1.is_a?(Float) || v2.is_a?(Float) || v1.is_a?(BigDecimal) || v2.is_a?(BigDecimal)
      unless (v1.to_f - v2.to_f).abs < 0.01
        errors << "#{label} mismatch: #{v1} vs #{v2}"
      end
      return
    end

    unless v1 == v2
      errors << "#{label} mismatch: '#{v1}' vs '#{v2}'"
    end
  end

  def self.verify_model(name, legacy_scope, new_scope, &block)
    puts "\n" + "="*60
    puts "🔍 Verifying #{name}"
    puts "="*60

    # 1. Count Check
    puts "Checking counts..."
    l_count = legacy_scope.count
    n_count = new_scope.where.not(old_id: nil).count

    if l_count == n_count
      puts "✅ Count matches: #{n_count}"
    else
      diff = n_count - l_count
      puts "⚠️  Count mismatch! Legacy: #{l_count}, New: #{n_count} (Diff: #{diff})"
    end

    # 2. Random Sample Check
    puts "Verifying random sample of #{SAMPLE_SIZE} records..."

    errors = []
    # Use Arel.sql to avoid UnknownAttributeReference for raw SQL
    legacy_scope.order(Arel.sql("RAND()")).limit(SAMPLE_SIZE).each do |legacy|
      new_record = new_scope.find_by(old_id: legacy.id)

      unless new_record
        errors << "Missing record for Legacy ID #{legacy.id}"
        next
      end

      # Run custom comparison block
      model_errors = []
      block.call(legacy, new_record, model_errors)

      if model_errors.any?
        errors << "ID #{legacy.id}: #{model_errors.join(', ')}"
      end
    end

    if errors.empty?
      puts "✅ Sample verification PASSED!"
    else
      puts "❌ #{errors.size} errors found in sample:"
      errors.first(10).each { |e| puts "   - #{e}" }
      puts "   (...and #{errors.size - 10} more)" if errors.size > 10
    end
  end
end

namespace :verify do
  desc "Run all verifications"
  task all: [ :ingredients, :users, :recipes, :comments, :forum, :messages, :ratings, :tags, :visits, :favorites, :images, :roles, :mybars ]

  desc "Verify Ratings"
  task ratings: :environment do
    # Filter orphans: valid user and valid recipe
    valid_user_ids = User.where.not(old_id: nil).pluck(:old_id)
    valid_recipe_ids = Legacy::Recipe.pluck(:id)

    legacy_scope = Legacy::Rate.where(rateable_type: "Recipe")
                               .where(rater_id: valid_user_ids)
                               .where(rateable_id: valid_recipe_ids)

    VerifyImport.verify_model("Ratings", legacy_scope, Rating) do |l, n, errs|
      # Score conversion 1-5 -> 1-10
      expected_score = (l.stars * 2).round
      expected_score = 10 if expected_score > 10
      expected_score = 1 if expected_score < 1

      VerifyImport.assert_equal("Score", expected_score, n.score, errs)

      if n.rateable.old_id != l.rateable_id
        errs << "Recipe mismatch"
      end
      if n.user.old_id != l.rater_id
        errs << "User mismatch"
      end
    end
  end

  desc "Verify Tags"
  task tags: :environment do
    puts "\n" + "="*60
    puts "🔍 Verifying Tags (Sampling Recipes)"
    puts "="*60

    # We check if recipes have the correct tags attached
    # Legacy structure: Tagging -> Tag

    errors = []
    # Sample 50 recipes that HAVE tags in legacy to make checking useful
    tagged_recipe_ids = Legacy::Tagging.where(taggable_type: "Recipe", context: "tags").distinct.pluck(:taggable_id)
    # Filter for existing recipes
    valid_ids = Recipe.where(old_id: tagged_recipe_ids).pluck(:old_id)

    Legacy::Recipe.where(id: valid_ids).order(Arel.sql("RAND()")).limit(50).each do |l_recipe|
      n_recipe = Recipe.find_by(old_id: l_recipe.id)
      next unless n_recipe

      l_tags = Legacy::Tagging.where(taggable_id: l_recipe.id, taggable_type: "Recipe", context: "tags")
                              .map { |t| Legacy::Tag.find(t.tag_id).name }.sort
      n_tags = n_recipe.tag_list.sort

      unless l_tags == n_tags
        errors << "Recipe #{l_recipe.id}: Tags mismatch. Legacy: #{l_tags}, New: #{n_tags}"
      end
    end

    if errors.empty?
      puts "✅ Tag verification PASSED (Sampled 50 tagged recipes)"
    else
      puts "❌ Tag errors found:"
      errors.first(10).each { |e| puts "   - #{e}" }
    end
  end

  desc "Verify Visits"
  task visits: :environment do
    puts "\n" + "="*60
    puts "🔍 Verifying Visits"
    puts "="*60

    # Check total visits count sum for Recipes
    # This is faster than row-by-row for this table
    l_sum = LegacyRecord.connection.select_value("SELECT SUM(total_visits) FROM visits WHERE visitable_type = 'Recipe'").to_i
    n_sum = Visit.where(visitable_type: "Recipe").sum(:count)

    # We skipped visits for deleted recipes/users, so N should be slightly less
    puts "Legacy Visit Sum (Recipes): #{l_sum}"
    puts "New Visit Sum (Recipes):    #{n_sum}"

    if n_sum > 0 && n_sum <= l_sum
       puts "✅ Visit sum looks reasonable (New <= Legacy)"
    else
       puts "⚠️  Visit sum mismatch or zero!"
    end
  end

  desc "Verify Favorites"
  task favorites: :environment do
    valid_user_ids = User.where.not(old_id: nil).pluck(:old_id)
    valid_recipe_ids = Legacy::Recipe.pluck(:id)

    legacy_scope = Legacy::UserRecipe.where(user_id: valid_user_ids, recipe_id: valid_recipe_ids)

    VerifyImport.verify_model("Favorites", legacy_scope, Favorite) do |l, n, errs|
      if n.favoritable_type == "Recipe" && n.favoritable.old_id != l.recipe_id
        errs << "Recipe mismatch"
      end
      if n.user.old_id != l.user_id
        errs << "User mismatch"
      end
    end
  end

  desc "Verify Recipe Images"
  task images: :environment do
    # Only imported approved images
    # And skipped missing users/recipes
    valid_user_ids = User.where.not(old_id: nil).pluck(:old_id)
    valid_recipe_ids = Legacy::Recipe.pluck(:id)

    legacy_scope = Legacy::RecipeImage.where(user_id: valid_user_ids, recipe_id: valid_recipe_ids) # Approved check? Import imported all, but migrate_images only approved.
    # Verify model checks DB records. Migration sets db records for all.

    VerifyImport.verify_model("Recipe Images (DB)", legacy_scope, RecipeImage) do |l, n, errs|
      VerifyImport.assert_equal("Approved At", l.is_approved ? l.updated_at : nil, n.approved_at, errs)

      # Check attachment if approved
      if l.is_approved
        unless n.image.attached?
           # This might fail if the file was missing on disk during import
           errs << "Image attachment missing (ActiveStorage)"
        end
      end
    end
  end

  desc "Verify Roles"
  task roles: :environment do
    puts "\n" + "="*60
    puts "🔍 Verifying Roles"
    l_roles = Legacy::Role.where.not(name: "member").count
    n_roles = Role.count
    if l_roles == n_roles
       puts "✅ Role count matches: #{n_roles}"
    else
       puts "⚠️  Role count mismatch: Legacy #{l_roles} vs New #{n_roles}"
    end
  end

  desc "Verify MyBars"
  task mybars: :environment do
    puts "\n" + "="*60
    puts "🔍 Verifying MyBars"
    l_users = Legacy::UserIngredient.where(dimension: "mybar").distinct.count(:user_id)
    n_users = IngredientCollection.where(name: "Meine Hausbar").count
    # Roughly check
    puts "Legacy Users with MyBar: #{l_users}"
    puts "New 'Meine Hausbar' Collections: #{n_users}"
    if n_users <= l_users && n_users > l_users - 500 # Tolerance for deleted users
       puts "✅ MyBar count reasonable"
    else
       puts "⚠️  MyBar count mismatch"
    end
  end

  desc "Verify Private Messages"
  task messages: :environment do
    # Filter messages where both sender and receiver exist in the new system
    # mirroring the next unless sender_id && receiver_id logic in import
    imported_user_ids = User.where.not(old_id: nil).pluck(:old_id)
    puts "DEBUG: Imported Users Count: #{imported_user_ids.count}"

    legacy_messages_scope = Legacy::PrivateMessage.where(sender_id: imported_user_ids, receiver_id: imported_user_ids)
    puts "DEBUG: Legacy Messages Filtered Count: #{legacy_messages_scope.count}"

    VerifyImport.verify_model("Private Messages", legacy_messages_scope, PrivateMessage) do |l, n, errs|
      VerifyImport.assert_equal("Subject", l.subject, n.subject, errs)
      l_body = l.message&.gsub(/<br\s*\/?>/i, "\n")
      VerifyImport.assert_equal("Body", l_body, n.body, errs)
      VerifyImport.assert_equal("Read", !!l.read, n.read, errs)
      VerifyImport.assert_equal("DelByRecv", !!l.deleted_by_receiver, n.deleted_by_receiver, errs)
      VerifyImport.assert_equal("DelBySend", !!l.deleted_by_sender, n.deleted_by_sender, errs)

      if n.sender.old_id != l.sender_id
        errs << "Sender mismatch"
      end
      if n.receiver.old_id != l.receiver_id
        errs << "Receiver mismatch"
      end
    end
  end

  desc "Verify Recipe Comments"
  task comments: :environment do
    # Filter orphans
    valid_recipe_ids = Legacy::Recipe.pluck(:id)
    legacy_comments_scope = Legacy::RecipeComment.where(recipe_id: valid_recipe_ids)

    VerifyImport.verify_model("Comments", legacy_comments_scope, RecipeComment) do |l, n, errs|
      l_body = l.comment&.gsub(/<br\s*\/?>/i, "\n")
      VerifyImport.assert_equal("Body", l_body, n.body, errs)

      # Check Associations
      if n.recipe.old_id != l.recipe_id
        errs << "Recipe mismatch (Old #{l.recipe_id} vs #{n.recipe.old_id})"
      end

      if l.user_id && n.user
        if n.user.old_id != l.user_id
           errs << "User mismatch (Old #{l.user_id} vs #{n.user.old_id})"
        end
      elsif l.user_id && !n.user
        # Check if user was skipped in import
        if User.exists?(old_id: l.user_id)
           errs << "User missing (Old User ID: #{l.user_id} exists but not linked)"
        end
      end
    end
  end

  desc "Verify Users"
  task users: :environment do
    # Filter active and confirmed users matching import logic
    active_user_ids = (
      Legacy::Recipe.pluck(:user_id) +
      Legacy::RecipeComment.pluck(:user_id) +
      Legacy::ForumPost.pluck(:user_id) +
      Legacy::UserRecipe.pluck(:user_id) +
      Legacy::RecipeImage.pluck(:user_id) +
      Legacy::UserIngredient.pluck(:user_id)
    ).uniq.compact

    legacy_users_scope = Legacy::User.where(id: active_user_ids).where.not(confirmed_at: nil)

    VerifyImport.verify_model("Users", legacy_users_scope, User) do |l, n, errs|
      VerifyImport.assert_equal("Username", l.login, n.username, errs)
      VerifyImport.assert_equal("Email", l.email&.strip&.downcase, n.email_address&.downcase, errs)
      VerifyImport.assert_equal("Password Digest", l.encrypted_password, n.password_digest, errs)
      VerifyImport.assert_equal("Sign In Count", l.sign_in_count, n.sign_in_count, errs)

      if l.user_profile
        VerifyImport.assert_equal("Gender", l.user_profile.gender, n.gender, errs)
        VerifyImport.assert_equal("Prename", l.user_profile.prename, n.prename, errs)
        VerifyImport.assert_equal("Public Email", l.user_profile.public_mail, n.public_email, errs)
        VerifyImport.assert_equal("Location", l.user_profile.location, n.location, errs)
      end
    end
  end

  desc "Verify Ingredients"
  task ingredients: :environment do
    VerifyImport.verify_model("Ingredients", Legacy::Ingredient, Ingredient) do |l, n, errs|
      VerifyImport.assert_equal("Name", l.name, n.name, errs)
      VerifyImport.assert_equal("Description", l.description, n.description, errs)
      VerifyImport.assert_equal("Alcohol Content", l.alcoholic_content, n.alcoholic_content, errs)
      VerifyImport.assert_equal("Slug", l.slug, n.slug, errs)
    end
  end

  desc "Verify Recipes and Recipe Ingredients"
  task recipes: :environment do
    VerifyImport.verify_model("Recipes", Legacy::Recipe, Recipe) do |l, n, errs|
      VerifyImport.assert_equal("Title", l.name, n.title, errs)
      VerifyImport.assert_equal("Description", l.description, n.description, errs)
      VerifyImport.assert_equal("Slug", l.slug, n.slug, errs)
      VerifyImport.assert_equal("Total Volume", l.cl_amount, n.total_volume, errs)
      VerifyImport.assert_equal("Alcohol Content", l.alcoholic_content, n.alcohol_content, errs)

      # Check User association
      if l.user_id
        legacy_user_exists = User.exists?(old_id: l.user_id)
        if legacy_user_exists && n.user.nil?
           errs << "User missing (Old User ID: #{l.user_id})"
        elsif legacy_user_exists && n.user.old_id != l.user_id
           errs << "User mismatch"
        end
      end

      # Verify Recipe Ingredients (nested check)
      l_ingredients = l.recipe_ingredients.count
      n_ingredients = n.recipe_ingredients.count
      if l_ingredients != n_ingredients
        errs << "Ingredient count mismatch: Legacy #{l_ingredients} vs New #{n_ingredients}"
      end

      # Check random ingredient mapping within this recipe
      if l_ingredients > 0
        l_ri = l.recipe_ingredients.first
        n_ri = n.recipe_ingredients.find_by(old_id: l_ri.id)
        if n_ri
          VerifyImport.assert_equal("RI Amount", l_ri.cl_amount, n_ri.amount, errs)
          # Check ingredient link
          if n_ri.ingredient.old_id != l_ri.ingredient_id
            errs << "RecipeIngredient #{l_ri.id} points to wrong ingredient"
          end
        else
          errs << "RecipeIngredient #{l_ri.id} missing"
        end
      end
    end
  end

  desc "Verify Forum Threads and Posts"
  task forum: :environment do
    # Threads
    VerifyImport.verify_model("Forum Threads", Legacy::ForumThread.unscoped, ForumThread.unscoped) do |l, n, errs|
      VerifyImport.assert_equal("Title", l.title, n.title, errs)
      VerifyImport.assert_equal("Slug", l.slug, n.slug, errs)
      VerifyImport.assert_equal("Sticky", l.sticky, n.sticky, errs)
      VerifyImport.assert_equal("Locked", l.locked, n.locked, errs)
      VerifyImport.assert_equal("Deleted", !!l.deleted, n.deleted, errs)
    end

    # Posts
    # Filter out orphaned posts (invalid thread_id) to match import logic
    valid_thread_ids = Legacy::ForumThread.unscoped.pluck(:id)
    legacy_posts_scope = Legacy::ForumPost.unscoped.where(forum_thread_id: valid_thread_ids)

    VerifyImport.verify_model("Forum Posts", legacy_posts_scope, ForumPost.unscoped) do |l, n, errs|
      l_body = l.content&.gsub(/<br\s*\/?>/i, "\n")

      # Partial match check (first 50 chars) to handle potential whitespace/cleanup diffs
      if l_body.present?
        snippet = l_body[0..50]
        unless n.body&.include?(snippet)
           errs << "Body mismatch (partial): New body does not contain start of legacy content"
        end
      elsif n.body.present?
        errs << "Body mismatch: Legacy empty, New has content"
      end

      VerifyImport.assert_equal("Deleted", !!l.deleted, n.deleted, errs)

      if n.forum_thread&.old_id != l.forum_thread_id
        # Note: If thread was missing in legacy map, post was skipped.
        # If thread exists in new DB, it should match.
        if ForumThread.unscoped.exists?(old_id: l.forum_thread_id)
           errs << "Thread mismatch (Old Thread ID: #{l.forum_thread_id})"
        end
      end
    end
  end
end
