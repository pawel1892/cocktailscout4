namespace :import do
  desc "Import recipes and recipe ingredients from legacy database"
  task recipes: :environment do
    puts "Starting Recipe Import..."

    # Pre-load legacy users and ingredients mapping to minimize lookups
    # Map old_id -> new_id
    user_map = User.where.not(old_id: nil).pluck(:old_id, :id).to_h
    ingredient_map = Ingredient.where.not(old_id: nil).pluck(:old_id, :id).to_h

    Legacy::Recipe.find_each do |legacy_recipe|
      # Skip if user not found (orphaned recipe)
      new_user_id = user_map[legacy_recipe.user_id]
      unless new_user_id
        puts "Skipping recipe #{legacy_recipe.id} (#{legacy_recipe.name}): User #{legacy_recipe.user_id} not found."
        next
      end

      updated_by_id = legacy_recipe.last_edit_user_id ? user_map[legacy_recipe.last_edit_user_id] : nil

      recipe = Recipe.find_or_initialize_by(old_id: legacy_recipe.id)

      recipe.title = legacy_recipe.name
      recipe.slug = legacy_recipe.slug
      recipe.description = legacy_recipe.description
      # No separate instructions in legacy, mapping description to description.
      # recipe.instructions = nil

      recipe.total_volume = legacy_recipe.cl_amount
      recipe.alcohol_content = legacy_recipe.alcoholic_content

      # recipe.views = legacy_recipe.views || 0 # views not in model yet, but in migration.
      # Validating model... I added views to migration, but not explicitly to model. It's fine.
      recipe.views = legacy_recipe.views || 0

      recipe.user_id = new_user_id
      recipe.updated_by_id = updated_by_id

      recipe.created_at = legacy_recipe.created_at
      recipe.updated_at = legacy_recipe.updated_at

      if recipe.save
        # Import Ingredients
        legacy_recipe.recipe_ingredients.each do |legacy_ri|
          new_ingredient_id = ingredient_map[legacy_ri.ingredient_id]

          unless new_ingredient_id
             puts "  - Skipping ingredient row #{legacy_ri.id}: Ingredient #{legacy_ri.ingredient_id} not found."
             next
          end

          ri = recipe.recipe_ingredients.find_or_initialize_by(old_id: legacy_ri.id)
          ri.ingredient_id = new_ingredient_id
          ri.amount = legacy_ri.cl_amount
          ri.unit = "cl" # Default unit
          ri.description = legacy_ri.description
          ri.position = legacy_ri.sequence
          ri.created_at = legacy_ri.created_at
          ri.updated_at = legacy_ri.updated_at

          unless ri.save
            puts "  - Failed to save recipe ingredient #{legacy_ri.id}: #{ri.errors.full_messages.join(", ")}"
          end
        end
        print "."
      else
        puts "\nFailed to import recipe #{legacy_recipe.id}: #{recipe.errors.full_messages.join(", ")}"
      end
    end

    puts "\nRecipe Import Completed!"
  end
end
