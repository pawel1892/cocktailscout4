# lib/tasks/import.rake
namespace :import do
  desc "Import all data from the legacy database"
  task all: [:ingredients, :users, :recipes, :comments]

  desc "Import comments from the legacy database"
  task comments: :environment do
    puts "Loading maps..."
    user_map = User.where.not(old_id: nil).pluck(:old_id, :id).to_h
    recipe_map = Recipe.where.not(old_id: nil).pluck(:old_id, :id).to_h
    puts "Maps loaded. Users: #{user_map.size}, Recipes: #{recipe_map.size}"

    puts "Importing comments..."
    count = 0
    Legacy::RecipeComment.find_each do |legacy_comment|
      new_recipe_id = recipe_map[legacy_comment.recipe_id]
      next unless new_recipe_id # Skip if recipe doesn't exist

      comment = RecipeComment.find_or_initialize_by(old_id: legacy_comment.id)
      comment.assign_attributes(
        recipe_id: new_recipe_id,
        user_id: user_map[legacy_comment.user_id], # Nil if user not found
        body: legacy_comment.comment,
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
  task ingredients: :environment do
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
  task users: :environment do
    puts "Identify active users..."
    active_user_ids = (
      Legacy::Recipe.pluck(:user_id) +
      Legacy::RecipeComment.pluck(:user_id) +
      Legacy::ForumPost.pluck(:user_id) +
      Legacy::UserRecipe.pluck(:user_id) +
      Legacy::RecipeImage.pluck(:user_id)
    ).uniq.compact
    puts "Found #{active_user_ids.count} active users."

    puts "Importing users..."
    Legacy::User.where(id: active_user_ids).includes(:user_profile).find_each do |legacy_user|
      user = User.find_or_initialize_by(old_id: legacy_user.id)
      
      # Base user attributes
      user.assign_attributes(
        email_address: legacy_user.email,
        password_digest: legacy_user.encrypted_password,
        username: legacy_user.login,
        sign_in_count: legacy_user.sign_in_count,
        last_active_at: legacy_user.last_active_at,
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
end
