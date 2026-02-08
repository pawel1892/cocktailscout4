namespace :units_migration do
  desc "Run complete migration workflow (all tasks in correct order)"
  task full_migration: :environment do
    puts "\n" + "=" * 80
    puts "UNITS MIGRATION - FULL WORKFLOW"
    puts "=" * 80 + "\n"

    begin
      # Step 1: Migrate units data
      puts "\n[1/4] Running units migration..."
      Rake::Task["units_migration:migrate"].invoke
      puts "✓ Units migration complete\n"

      # Step 2: Populate ingredient plurals and clean up names
      puts "\n[2/4] Populating ingredient plurals and cleaning names..."
      Rake::Task["ingredients:populate_plurals"].invoke
      puts "✓ Ingredient plurals and cleanup complete\n"

      # Step 3: Validate migration
      puts "\n[3/4] Validating migration results..."
      Rake::Task["units_migration:validate"].invoke
      puts "✓ Validation complete\n"

      # Step 4: Check for issues
      puts "\n[4/4] Checking for parsing issues..."
      Rake::Task["units_migration:check_issues"].invoke
      puts "✓ Issue check complete\n"

      puts "\n" + "=" * 80
      puts "✓ FULL MIGRATION COMPLETE!"
      puts "=" * 80
      puts "\nNext steps:"
      puts "  - Review any reported issues above"
      puts "  - Test recipes in browser to verify display"
      puts "  - Run comparison script if needed: ruby scripts/compare_ingredients.rb"
      puts "  - When satisfied, finalize with: rake units_migration:finalize CONFIRM=yes"
      puts ""

    rescue => e
      puts "\n" + "=" * 80
      puts "✗ MIGRATION FAILED"
      puts "=" * 80
      puts "\nError: #{e.message}"
      puts e.backtrace.first(5)
      puts "\nPlease fix the error and run again."
      exit 1
    end
  end

  desc "Populate units table with German units"
  task populate_units: :environment do
    puts "Populating units table with German units..."

    units_data = [
      # Volume units (metric)
      { name: "cl", display_name: "cl", plural_name: "cl", category: "volume", ml_ratio: 10.0, divisible: true },
      { name: "ml", display_name: "ml", plural_name: "ml", category: "volume", ml_ratio: 1.0, divisible: true },
      { name: "l", display_name: "l", plural_name: "l", category: "volume", ml_ratio: 1000.0, divisible: true },

      # German measurement units
      { name: "tl", display_name: "TL", plural_name: "TL", category: "volume", ml_ratio: 5.0, divisible: true },
      { name: "el", display_name: "EL", plural_name: "EL", category: "volume", ml_ratio: 15.0, divisible: true },

      # Bartending special units
      { name: "spritzer", display_name: "Spritzer", plural_name: "Spritzer", category: "special", ml_ratio: 0.9, divisible: false },
      { name: "splash", display_name: "Splash", plural_name: "Splash", category: "special", ml_ratio: 5.0, divisible: false },
      { name: "barspoon", display_name: "Barlöffel", plural_name: "Barlöffel", category: "special", ml_ratio: 5.0, divisible: true },

      # Count units (typically for garnishes)
      { name: "piece", display_name: "Stück", plural_name: "Stück", category: "count", ml_ratio: nil, divisible: false },
      { name: "slice", display_name: "Scheibe", plural_name: "Scheiben", category: "count", ml_ratio: nil, divisible: false },
      { name: "leaf", display_name: "Blatt", plural_name: "Blätter", category: "count", ml_ratio: nil, divisible: false },
      { name: "sprig", display_name: "Zweig", plural_name: "Zweige", category: "count", ml_ratio: nil, divisible: false },

      # Blank unit (for ingredient counts like "1/2 Limette" - displays ingredient name only)
      { name: "x", display_name: "", plural_name: "", category: "count", ml_ratio: nil, divisible: true }
    ]

    units_data.each do |unit_attrs|
      unit = Unit.find_or_initialize_by(name: unit_attrs[:name])
      unit.assign_attributes(unit_attrs)
      unit.save!
      puts "  ✓ #{unit.name} → #{unit.display_name} (#{unit.plural_name})"
    end

    puts "\n✓ Populated #{Unit.count} German units"
  end

  desc "Backup current data to old_* columns"
  task backup_data: :environment do
    puts "Backing up current data to old_* columns..."

    RecipeIngredient.find_each do |ri|
      ri.update_columns(
        old_amount: ri.amount,
        old_unit: ri.unit,
        old_description: ri.description
      )
    end

    puts "✓ Backed up #{RecipeIngredient.count} records"
  end

  desc "Migrate data from descriptions to structured fields"
  task migrate: :environment do
    Rake::Task["units_migration:populate_units"].invoke

    # Only backup if old_description is nil (first time running)
    if RecipeIngredient.where.not(old_description: nil).exists?
      puts "Skipping backup - using existing old_description data"
    else
      Rake::Task["units_migration:backup_data"].invoke
    end

    require_relative "../units_parser"

    stats = { total: 0, migrated: 0, errors: [] }

    RecipeIngredient.find_each do |ri|
      stats[:total] += 1

      # Parse the description (the only source of truth)
      parsed = UnitsParser.parse(ri.old_description)

      if parsed[:amount] && parsed[:unit]
        unit = Unit.find_by(name: parsed[:unit])
        unless unit
          stats[:errors] << "Recipe #{ri.recipe_id}, Ingredient #{ri.ingredient_id}: Unknown unit '#{parsed[:unit]}' from description '#{ri.old_description}'"
          next
        end

        # Don't store additional_info if it's already part of the ingredient name
        additional_info = parsed[:additional_info]
        if additional_info.present? && ri.ingredient.name.include?("(#{additional_info})")
          additional_info = nil
        end

        ri.update_columns(
          amount: parsed[:amount],
          unit_id: unit.id,
          additional_info: additional_info,
          is_garnish: parsed[:is_garnish],
          description: nil  # Clear old description
        )
      else
        # Garnish or unstructured (e.g., "Minzzweig")
        ri.update_columns(
          amount: nil,
          unit_id: nil,
          additional_info: parsed[:additional_info],
          is_garnish: parsed[:is_garnish],
          description: nil
        )
      end

      stats[:migrated] += 1
      print "." if (stats[:total] % 100).zero?
    end

    puts "\n✓ Migrated #{stats[:migrated]}/#{stats[:total]}"
    if stats[:errors].any?
      puts "\n⚠ Errors: #{stats[:errors].count}"
      stats[:errors].each { |err| puts "  - #{err}" }
    end
  end

  desc "Check for potential parsing issues by comparing current state with re-parsing"
  task check_issues: :environment do
    require_relative "../units_parser"

    puts "\n=== Checking for Potential Unit Parsing Issues ===\n"

    issues = []

    # Check for records where old_description doesn't match current parsing
    RecipeIngredient.where.not(old_description: nil).find_each do |ri|
      parsed = UnitsParser.parse(ri.old_description)

      current_unit = ri.unit&.name
      expected_unit = parsed[:unit]

      if current_unit != expected_unit || ri.amount&.to_f != parsed[:amount]&.to_f
        issues << {
          id: ri.id,
          recipe: ri.recipe.title,
          old_description: ri.old_description,
          current_unit: current_unit,
          current_amount: ri.amount,
          expected_unit: expected_unit,
          expected_amount: parsed[:amount]
        }
      end
    end

    if issues.empty?
      puts "✓ No parsing mismatches found! All records match expected parsing."
    else
      puts "Found #{issues.count} records with unit/amount mismatches:\n"
      issues.first(25).each do |issue|
        puts "  [#{issue[:id]}] #{issue[:recipe]}: '#{issue[:old_description]}'"
        puts "    Current:  #{issue[:current_amount]} #{issue[:current_unit]}"
        puts "    Expected: #{issue[:expected_amount]} #{issue[:expected_unit]}"
        puts ""
      end

      if issues.count > 25
        puts "  ... and #{issues.count - 25} more"
      end

      puts "\n⚠ Run 'rake units_migration:migrate' to fix these issues"
    end
  end

  desc "Validate migration results"
  task validate: :environment do
    puts "Validating migration results...\n"

    # Check for missing units
    missing_units = RecipeIngredient.where.not(amount: nil).where(unit_id: nil).count
    puts "Records with amount but no unit_id: #{missing_units}"
    puts "  #{missing_units == 0 ? '✓' : '⚠'}"

    # Check for missing data
    missing_data = RecipeIngredient.where(amount: nil, additional_info: nil).count
    puts "\nRecords with no amount AND no additional_info: #{missing_data}"
    puts "  #{missing_data == 0 ? '✓' : '⚠'}"

    # Unit distribution
    puts "\nUnit distribution:"
    RecipeIngredient.joins(:unit).group("units.display_name").count.each do |unit_name, count|
      puts "  #{unit_name}: #{count}"
    end

    # Garnishes without unit
    garnish_count = RecipeIngredient.where(is_garnish: true, unit_id: nil).count
    puts "\nGarnishes without unit_id: #{garnish_count}"

    # Sample comparison
    puts "\n\nSample comparison (first 20 records):"
    puts "%-40s | %-20s | %-s" % [ "Old Description", "New Amount + Unit", "Additional Info" ]
    puts "-" * 100
    RecipeIngredient.limit(20).each do |ri|
      new_display = ri.unit ? "#{ri.amount} #{ri.unit.display_name}" : "(no unit)"
      puts "%-40s | %-20s | %-s" % [
        ri.old_description&.truncate(40) || "(empty)",
        new_display,
        ri.additional_info || "(empty)"
      ]
    end

    puts "\n✓ Validation complete"
  end

  desc "Finalize migration by removing temporary columns (requires CONFIRM=yes)"
  task finalize: :environment do
    unless ENV["CONFIRM"] == "yes"
      puts "⚠ This will permanently remove old_amount, old_unit, and old_description columns."
      puts "Run with CONFIRM=yes to proceed: rake units_migration:finalize CONFIRM=yes"
      exit
    end

    puts "Removing temporary columns..."

    ActiveRecord::Migration.remove_column :recipe_ingredients, :old_amount
    ActiveRecord::Migration.remove_column :recipe_ingredients, :old_unit
    ActiveRecord::Migration.remove_column :recipe_ingredients, :old_description

    puts "✓ Finalized migration"
  end
end
