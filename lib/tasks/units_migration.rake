namespace :units_migration do
  # Convert fraction string to decimal (e.g., "1/2" → 0.5)
  def self.fraction_to_decimal(fraction_str)
    if match = fraction_str.match(/^(\d+)\/(\d+)$/)
      numerator = match[1].to_f
      denominator = match[2].to_f
      return numerator / denominator if denominator != 0
    end
    nil
  end

  # Parse ingredient description - only handles certain cases (amount + unit)
  def self.parse_ingredient_description(description)
    return { is_certain: false } if description.blank?

    # Normalize: handle German number format (comma → period)
    normalized = description.gsub(",", ".")

    # Special case: "halbe" (half) → 0.5
    normalized = normalized.sub(/^halbe\s+/i, "0.5 ")

    # Pattern: [number or fraction] [optional space] [unit] [ingredient] [(optional)]
    # Examples: "4 cl Rum", "4cl Rum", "2 TL Zucker", "ein Spritzer", "1/2 Limette"
    # The l(?!\w) lookahead prevents matching "l" in "Limette"
    # \s* allows optional space between number and unit
    pattern = /^(\d+\/\d+|\d+\.?\d*|ein|eine)\s*(cl|ml|l(?!\w)|TL|EL|Teelöffel|Esslöffel|Spritzer|Dash|Splash|Schuss|Barlöffel|Stück|Scheiben?|Blätter?|Zweige?)\b/i

    match = normalized.match(pattern)

    if match
      # Pattern with explicit unit matched
      amount_str = match[1]
      unit_str = match[2]
      remainder = normalized.sub(match[0], "").strip

      # Convert to decimal
      if amount_str.match?(/^ein/i)
        amount = 1.0
      elsif amount_str.include?("/")
        amount = fraction_to_decimal(amount_str)
        return { is_certain: false } unless amount  # Invalid fraction
      else
        amount = amount_str.to_f
      end

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
    else
      # No explicit unit - check if it's a simple count (including fractions) for whitelisted ingredient
      # This will be validated against ingredient name in the migration task
      simple_count_pattern = /^(\d+\/\d+|\d+\.?\d*|ein|eine)\s+(.+)/i
      simple_match = normalized.match(simple_count_pattern)

      if simple_match
        amount_str = simple_match[1]
        remainder = simple_match[2].strip

        # Convert to decimal
        if amount_str.match?(/^ein/i)
          amount = 1.0
        elsif amount_str.include?("/")
          amount = fraction_to_decimal(amount_str)
          return { is_certain: false } unless amount  # Invalid fraction
        else
          amount = amount_str.to_f
        end

        # Return with no unit (will be NULL in database)
        # Migration task will check if ingredient is in ALLOWED_WITHOUT_UNIT
        {
          amount: amount,
          unit: nil,
          additional_info: nil,
          ingredient_text: remainder,  # For validation in migration
          is_certain: :check_whitelist  # Special flag - needs whitelist check
        }
      else
        # No amount or unit found - mark as uncertain
        { is_certain: false }
      end
    end
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

  # Ingredient name exceptions: descriptions that are acceptable variations of ingredient names
  # Key = ingredient name in database, Value = array of acceptable variations in descriptions
  INGREDIENT_ALIASES = {
    "Rohrzuckersirup" => [ "zuckersirup", "rohrzuckersirup", "sugar syrup" ],
    "Vermouth Dry" => [ "vermouth dry", "trockener wermut", "wermut dry", "dry vermouth" ],
    "Sangrita Picante" => [ "sangrita picante", "sangrita pikant" ],
    "Kirschnektar" => [ "kirschnektar", "kirschsaft", "cherry nectar", "cherry juice" ],
    "Minze" => [ "minze", "minzzweig", "minzblatt", "minzblätter" ],
    "Rum (braun) 73%" => [ "rum (braun) 73%", "rum 73%" ],
    "Rum (weiss)" => [ "rum (weiss)", "rum weiss", "rum(weiss)", "weißer rum", "weisser rum" ],
    "Rum (braun)" => [ "rum (braun)", "rum braun", "rum(braun)", "brauner rum" ],
    "Triple Sec Curaçao" => [ "triple sec curaçao", "triple sec curacao", "triple sec" ],
    "Blue Curaçao" => [ "blue curaçao", "blue curacao" ],
    "Tequila (weiss)" => [ "tequila (weiss)", "tequila weiss", "tequila blanco", "tequila (blanco)" ],
    "Maracujanektar" => [ "maracujanektar", "maracujasaft", "maracuja nektar" ],
    "Grenadine" => [ "grenadine", "grenadinesirup" ]
    # Add more exceptions here as needed
    # "Ingredient Name" => ["variation1", "variation2"]
  }.freeze

  # Ingredients allowed to be parsed without explicit units (e.g., "1 Limette" → amount=1, unit=NULL)
  # Only these ingredients can have simple count patterns marked as certain
  ALLOWED_WITHOUT_UNIT = [
    "Limette", "Limetten",
    "Zitrone", "Zitronen",
    "Orange", "Orangen"
    # Add more countable ingredients as needed
  ].freeze

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
      Rake::Task["units_migration:populate_plurals"].invoke
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
      puts "  - Review uncertain ingredients: rake units_migration:review"
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
      { name: "sprig", display_name: "Zweig", plural_name: "Zweige", category: "count", ml_ratio: nil, divisible: false }
      # Note: Ingredients without explicit units (like "1 Limette") now use NULL unit_id
    ]

    units_data.each do |unit_attrs|
      unit = Unit.find_or_initialize_by(name: unit_attrs[:name])
      unit.assign_attributes(unit_attrs)
      unit.save!
      puts "  ✓ #{unit.name} → #{unit.display_name} (#{unit.plural_name})"
    end

    puts "\n✓ Populated #{Unit.count} German units"
  end

  desc "Populate plural_name for ingredients that need it"
  task populate_plurals: :environment do
    puts "Populating ingredient plural forms..."

    # Define plural rules for German ingredients
    plurals = {
      # Fruits that need plurals
      "Limette" => "Limetten",
      "Zitrone" => "Zitronen",
      "Orange" => "Orangen",
      "Erdbeere" => "Erdbeeren",
      "Himbeere" => "Himbeeren",
      "Brombeere" => "Brombeeren",
      "Kirsche" => "Kirschen",
      "Ananas" => "Ananas",
      "Mango" => "Mangos",
      "Pfirsich" => "Pfirsiche",
      "Apfel" => "Äpfel",
      "Birne" => "Birnen",
      "Banane" => "Bananen",
      "Traube" => "Trauben",
      "Melone" => "Melonen",
      "Pflaume" => "Pflaumen",

      # Vegetables/Herbs that need plurals
      "Gurke" => "Gurken",
      "Tomate" => "Tomaten",
      "Olive" => "Oliven",
      "Zwiebel" => "Zwiebeln",
      "Knoblauchzehe" => "Knoblauchzehen",
      "Minzblatt" => "Minzblätter",
      "Basilikumblatt" => "Basilikumblätter",

      # Other countable items
      "Ei" => "Eier",
      "Eiswürfel" => "Eiswürfel",
      "Cocktailkirsche" => "Cocktailkirschen"
    }

    # Fix ingredients that are stored in plural form - convert to singular and set plural_name
    plural_to_singular = {
      "Limetten" => { singular: "Limette", plural: "Limetten" },
      "Zitronen" => { singular: "Zitrone", plural: "Zitronen" },
      "Orangen" => { singular: "Orange", plural: "Orangen" },
      "Bananen" => { singular: "Banane", plural: "Bananen" }
    }

    # Fix ingredient names with extra information that should be removed
    name_cleanups = {
      "Triple Sec Curaçao z.B. Cointreau" => "Triple Sec Curaçao"
      # Add more cleanup cases here as needed
    }

    # Ingredients that don't need plurals (abstract/mass nouns)
    # Likör, Vodka, Rum, Gin, Whisky, Sirup, Saft, Wasser, Zucker, Salz, etc.
    # These are not in the plurals hash, so they won't get a plural_name

    count = 0

    # First, clean up ingredient names
    name_cleanups.each do |old_name, new_name|
      ingredient = Ingredient.find_by(name: old_name)
      if ingredient
        ingredient.update(name: new_name)
        puts "  ✓ Cleaned: #{old_name} → #{new_name}"
        count += 1
      end
    end

    # Second, fix plural ingredient names
    plural_to_singular.each do |plural_name, forms|
      ingredient = Ingredient.find_by(name: plural_name)
      if ingredient
        ingredient.update(name: forms[:singular], plural_name: forms[:plural])
        puts "  ✓ Fixed: #{plural_name} → #{forms[:singular]} (plural: #{forms[:plural]})"
        count += 1
      end
    end

    # Then, populate singular ingredients with plural forms
    plurals.each do |singular, plural|
      ingredient = Ingredient.find_by(name: singular)
      if ingredient && ingredient.plural_name.blank?
        ingredient.update(plural_name: plural)
        puts "  ✓ #{singular} → #{plural}"
        count += 1
      end
    end

    puts "\n✓ Populated #{count} ingredient plural forms"
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

      # Handle whitelist check for simple counts without units
      if parsed[:is_certain] == :check_whitelist
        # Simple count pattern - check if ingredient is whitelisted
        unless ALLOWED_WITHOUT_UNIT.include?(ri.ingredient.name)
          # Not whitelisted - mark as uncertain
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

        # Whitelisted - convert to certain
        parsed[:is_certain] = true
        parsed[:unit] = nil  # No unit for simple counts
      end

      if parsed[:is_certain]
        # Only update if parsing is unambiguous
        unit = parsed[:unit] ? Unit.find_by(name: parsed[:unit]) : nil
        if parsed[:unit] && !unit
          errors << "Recipe #{ri.recipe_id}, Ingredient #{ri.ingredient_id}: Unknown unit '#{parsed[:unit]}' from description '#{ri.old_description}'"
          next
        end

        # CRITICAL CHECK: Verify ingredient name appears in description
        # This prevents migrating when description is more specific than ingredient name:
        # - "Eier" vs "Eigelb" (different ingredient)
        # - "Minze" vs "Minzzweig" (compound word, more specific)
        # - "Rum" vs "Rum (braun)" (has qualifier, more specific)
        ingredient_name = ri.ingredient.name
        ingredient_name_lower = ingredient_name.downcase
        description_lower = ri.old_description.downcase

        ingredient_matches = false

        # First check: if ingredient has defined aliases, check those
        if INGREDIENT_ALIASES.key?(ingredient_name)
          INGREDIENT_ALIASES[ingredient_name].each do |alias_name|
            if description_lower.include?(alias_name)
              ingredient_matches = true
              break
            end
          end
        end

        # Second check: if no alias match, use word boundary matching
        unless ingredient_matches
          # Check if ingredient name appears as a whole word
          # Use word boundaries to avoid matching "Minze" in "Minzzweig"
          # Only use trailing \b if ingredient name ends with a word character
          escaped_name = Regexp.escape(ingredient_name_lower)
          trailing_boundary = ingredient_name_lower.match?(/\w$/) ? '\b' : ""
          ingredient_pattern = /\b#{escaped_name}#{trailing_boundary}/
          ingredient_matches = description_lower.match?(ingredient_pattern)

          # Also check plural name if available
          if !ingredient_matches && ri.ingredient.plural_name.present?
            plural_name = ri.ingredient.plural_name.downcase
            escaped_plural = Regexp.escape(plural_name)
            plural_boundary = plural_name.match?(/\w$/) ? '\b' : ""
            plural_pattern = /\b#{escaped_plural}#{plural_boundary}/
            ingredient_matches = description_lower.match?(plural_pattern)
          end
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
          unit_id: unit&.id,
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

    # Calculate recipe statistics
    total_recipes = Recipe.count
    recipes_needing_review = Recipe.joins(:recipe_ingredients)
                                   .where(recipe_ingredients: { needs_review: true })
                                   .distinct
                                   .count
    percentage = total_recipes > 0 ? (recipes_needing_review.to_f / total_recipes * 100).round(1) : 0

    puts "\n📊 Recipe Statistics:"
    puts "   Total recipes: #{total_recipes}"
    puts "   Recipes needing review: #{recipes_needing_review} (#{percentage}%)"
    puts "   Recipes fully migrated: #{total_recipes - recipes_needing_review} (#{(100 - percentage).round(1)}%)"

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
      # Skip ingredients from deleted recipes (recipe will be nil due to default_scope)
      next if ri.recipe.nil?

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
      # Skip ingredients from deleted recipes
      next if ri.recipe.nil?
      puts "  [#{ri.id}] #{ri.recipe.title}: #{ri.old_description}"
    end

    if uncertain.count > 20
      puts "\n... and #{uncertain.count - 20} more"
    end

    puts "\nTo fix these, update manually or improve parsing logic and re-run migration."
  end
end
