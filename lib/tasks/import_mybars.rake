namespace :import do
  desc "Import user mybars from legacy database as 'Meine Hausbar' collections"
  task mybars: :environment do
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
    puts "Created: #{created}"
    puts "Skipped: #{skipped}"
    puts "Total users processed: #{mybar_data.keys.size}"
  end
end
