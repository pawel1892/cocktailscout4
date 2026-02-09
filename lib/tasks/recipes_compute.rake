namespace :recipes do
  desc "Calculate and update total_volume and alcohol_content for all recipes"
  task update_computed_fields: :environment do
    puts "Updating computed fields for all recipes..."
    puts ""

    total_count = Recipe.count
    updated_count = 0
    errors = []

    Recipe.find_each.with_index do |recipe, index|
      begin
        recipe.update_computed_fields!
        updated_count += 1
        print "." if (index + 1) % 50 == 0
      rescue => e
        errors << { recipe_id: recipe.id, recipe_title: recipe.title, error: e.message }
      end
    end

    puts ""
    puts ""
    puts "=" * 80
    puts "✓ Updated #{updated_count}/#{total_count} recipes"
    puts ""

    if errors.any?
      puts "⚠ Errors: #{errors.count}"
      errors.first(10).each do |err|
        puts "  [#{err[:recipe_id]}] #{err[:recipe_title]}: #{err[:error]}"
      end
      if errors.count > 10
        puts "  ... and #{errors.count - 10} more errors"
      end
    else
      puts "✓ No errors"
    end

    puts "=" * 80

    # Show some statistics
    puts ""
    puts "Statistics:"
    puts "  Recipes with alcohol: #{Recipe.where('alcohol_content > 0').count}"
    puts "  Recipes without alcohol: #{Recipe.where('alcohol_content = 0 OR alcohol_content IS NULL').count}"
    puts "  Average alcohol content: #{Recipe.where('alcohol_content > 0').average(:alcohol_content).to_f.round(1)}%"
    puts "  Average total volume: #{Recipe.where('total_volume > 0').average(:total_volume).to_f.round(1)} ml"
    puts ""
  end
end
