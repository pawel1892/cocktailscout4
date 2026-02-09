namespace :units_migration do
  # Parse ingredient description - only handles certain cases (amount + unit)
  def self.parse_ingredient_description(description)
    return { is_certain: false } if description.blank?

    # Normalize: handle German number format (comma → period)
    normalized = description.gsub(",", ".")

    # Special case: "halbe" (half) → 0.5
    normalized = normalized.sub(/^halbe\s+/i, "0.5 ")

    # Pattern: [number] [optional space] [unit] [ingredient] [(optional)]
    # Examples: "4 cl Rum", "4cl Rum", "2 TL Zucker", "ein Spritzer", "1 Scheibe Zitrone"
    # The l(?!\w) lookahead prevents matching "l" in "Limette"
    # \s* allows optional space between number and unit
    pattern = /^(\d+\.?\d*|ein|eine)\s*(cl|ml|l(?!\w)|TL|EL|Teelöffel|Esslöffel|Spritzer|Dash|Splash|Schuss|Barlöffel|Stück|Scheiben?|Blätter?|Zweige?)\b/i

    match = normalized.match(pattern)
    return { is_certain: false } unless match

    amount_str = match[1]
    unit_str = match[2]
    remainder = normalized.sub(match[0], "").strip

    # Convert "ein"/"eine" to 1
    amount = amount_str.match?(/^ein/i) ? 1.0 : amount_str.to_f

    # Extract additional info from parentheses: "Rum (braun)" → "braun"
    additional_info = nil
    if paren_match = remainder.match(/\(([^)]+)\)/)
      additional_info = paren_match[1]
    end

    {
      amount: amount,
      unit: normalize_unit_name(unit_str),
      additional_info: additional_info,
      is_certain: true
    }
  end

  # Normalize unit names to database format
  def self.normalize_unit_name(unit_str)
    # Handle plural forms
    normalized = unit_str.downcase
    normalized = "scheibe" if normalized.match?(/scheiben?/)
    normalized = "blatt" if normalized.match?(/blätter?/)
    normalized = "zweig" if normalized.match?(/zweige?/)

    {
      "cl" => "cl",
      "ml" => "ml",
      "l" => "l",
      "tl" => "tl",
      "teelöffel" => "tl",
      "el" => "el",
      "esslöffel" => "el",
      "spritzer" => "spritzer",
      "dash" => "spritzer",
      "splash" => "splash",
      "schuss" => "spritzer",
      "barlöffel" => "barspoon",
      "stück" => "piece",
      "scheibe" => "slice",
      "blatt" => "leaf",
      "zweig" => "sprig"
    }[normalized] || normalized
  end

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

  desc "Migrate data from descriptions to structured fields (conservative approach)"
  task migrate: :environment do
    Rake::Task["units_migration:populate_units"].invoke

    # Only backup if old_description is nil (first time running)
    if RecipeIngredient.where.not(old_description: nil).exists?
      puts "Skipping backup - using existing old_description data"
    else
      Rake::Task["units_migration:backup_data"].invoke
    end

    puts "\n=== Conservative Units Migration ==="
    puts "Only converting unambiguous patterns...\n"

    certain_count = 0
    uncertain_count = 0
    errors = []

    RecipeIngredient.where.not(old_description: nil).find_each do |ri|
      parsed = parse_ingredient_description(ri.old_description)

      if parsed[:is_certain]
        # Only update if parsing is unambiguous
        unit = Unit.find_by(name: parsed[:unit])
        unless unit
          errors << "Recipe #{ri.recipe_id}, Ingredient #{ri.ingredient_id}: Unknown unit '#{parsed[:unit]}' from description '#{ri.old_description}'"
          next
        end

        # CRITICAL CHECK: Verify ingredient name appears in description
        # This prevents migrating when description is more specific than ingredient name:
        # - "Eier" vs "Eigelb" (different ingredient)
        # - "Minze" vs "Minzzweig" (compound word, more specific)
        # - "Rum" vs "Rum (braun)" (has qualifier, more specific)
        ingredient_name = ri.ingredient.name.downcase
        description_lower = ri.old_description.downcase

        # Check if ingredient name appears as a whole word
        # Use word boundaries to avoid matching "Minze" in "Minzzweig"
        ingredient_pattern = /\b#{Regexp.escape(ingredient_name)}\b/
        ingredient_matches = description_lower.match?(ingredient_pattern)

        # Also check plural name if available
        if !ingredient_matches && ri.ingredient.plural_name.present?
          plural_name = ri.ingredient.plural_name.downcase
          plural_pattern = /\b#{Regexp.escape(plural_name)}\b/
          ingredient_matches = description_lower.match?(plural_pattern)
        end

        # Additional check: if description has parenthetical qualifiers that aren't in ingredient name,
        # mark as uncertain (e.g., ingredient="Rum" but description="Rum (braun)")
        if ingredient_matches && ri.old_description.include?("(")
          # Description has a qualifier like "(braun)"
          # Only proceed if the ingredient name also has that qualifier
          unless ri.ingredient.name.include?("(")
            # Ingredient name doesn't have the qualifier - mark as uncertain
            ri.update_columns(
              amount: nil,
              unit_id: nil,
              additional_info: nil,
              needs_review: true,
              description: nil
            )
            uncertain_count += 1
            next
          end
        end

        unless ingredient_matches
          # Ingredient name doesn't match description - mark as uncertain
          # Example: ingredient="Eier" but description="2 Eigelb"
          ri.update_columns(
            amount: nil,
            unit_id: nil,
            additional_info: nil,
            needs_review: true,
            description: nil
          )
          uncertain_count += 1
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
          needs_review: false,
          description: nil
        )
        certain_count += 1
      else
        # Keep as description, mark for review
        ri.update_columns(
          amount: nil,
          unit_id: nil,
          additional_info: nil,
          needs_review: true,
          description: nil
        )
        uncertain_count += 1
      end

      print "." if ((certain_count + uncertain_count) % 100).zero?
    end

    puts "\n\n✓ Migrated #{certain_count} ingredients with certainty"
    puts "⚠ Marked #{uncertain_count} ingredients for manual review"
    puts "\nUse `bin/rails units_migration:review` to see uncertain cases"

    if errors.any?
      puts "\n⚠ Errors: #{errors.count}"
      errors.each { |err| puts "  - #{err}" }
    end
  end

  desc "Check for potential parsing issues by comparing current state with re-parsing"
  task check_issues: :environment do
    puts "\n=== Checking for Potential Unit Parsing Issues ===\n"

    issues = []

    # Check for records where old_description doesn't match current parsing
    RecipeIngredient.where.not(old_description: nil).find_each do |ri|
      parsed = parse_ingredient_description(ri.old_description)

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

    # Non-scalable ingredients without unit
    non_scalable_count = RecipeIngredient.where(is_scalable: false, unit_id: nil).count
    puts "\nNon-scalable ingredients without unit_id: #{non_scalable_count}"

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

  desc "Show ingredients that need manual review"
  task review: :environment do
    puts "\n=== Ingredients Needing Review ==="

    uncertain = RecipeIngredient.where(needs_review: true).includes(:recipe, :ingredient)

    puts "Total: #{uncertain.count} ingredients"
    puts "\nSample (first 20):"

    uncertain.limit(20).each do |ri|
      puts "  [#{ri.id}] #{ri.recipe.title}: #{ri.old_description}"
    end

    if uncertain.count > 20
      puts "\n... and #{uncertain.count - 20} more"
    end

    puts "\nTo fix these, update manually or improve parsing logic and re-run migration."
  end
end
