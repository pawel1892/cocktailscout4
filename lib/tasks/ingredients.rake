namespace :ingredients do
  desc "Populate ml_per_unit for common ingredients"
  task populate_volumes: :environment do
    puts "Populating ml_per_unit for common ingredients..."

    volumes = {
      # Citrus fruits (durchschnittliche Saftausbeute)
      "Limette" => 30.0,    # ~30ml Saft pro Limette
      "Zitrone" => 45.0,    # ~45ml Saft pro Zitrone
      "Orange" => 80.0,     # ~80ml Saft pro Orange

      # Other ingredients
      "Eigelb" => 20.0,     # ~20ml pro Eigelb
      "Eiweiß" => 30.0,     # ~30ml pro Eiweiß

      # Garnishes - explicitly set to 0
      "Minze" => 0.0,           # Garnitur
      "Cocktailkirsche" => 0.0  # Dekoration
    }

    updated_count = 0
    not_found = []

    volumes.each do |name, ml|
      ingredient = Ingredient.find_by(name: name)
      if ingredient
        ingredient.update(ml_per_unit: ml)
        puts "  ✓ #{name}: #{ml} ml"
        updated_count += 1
      else
        not_found << name
        puts "  ✗ #{name}: not found in database"
      end
    end

    puts "\n✓ Updated #{updated_count} ingredients"
    if not_found.any?
      puts "⚠ Not found: #{not_found.join(', ')}"
    end
  end
end
