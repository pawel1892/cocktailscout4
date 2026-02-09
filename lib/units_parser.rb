module UnitsParser
  # List of ingredient names that are typically garnishes
  GARNISH_KEYWORDS = %w[
    garnierung garnitur deko dekoration
    scheibe scheiben zweig zweige blatt blätter
    zeste spiral schale
  ]

  def self.parse(description)
    return nil if description.blank?

    # Normalize: handle German number format (comma → period)
    normalized = description.gsub(",", ".")

    # Special case: "halbe" (half) → 0.5
    normalized = normalized.sub(/^halbe\s+/i, "0.5 ")

    # Pattern: [number] [optional space] [unit] [ingredient] [(optional)]
    # Examples: "4 cl Rum", "4cl Rum", "2 TL Zucker", "ein Spritzer", "1 Scheibe Zitrone", "ein Schuss Blue Curaçao"
    # The l(?!\w) lookahead prevents matching "l" in "Limette"
    # \s* allows optional space between number and unit (handles "1,5cl" and "1,5 cl")
    pattern = /^(\d+\.?\d*|ein|eine)\s*(cl|ml|l(?!\w)|TL|EL|Teelöffel|Esslöffel|Spritzer|Dash|Splash|Schuss|Barlöffel|Stück|Scheiben?|Blätter?|Zweige?)\b/i

    if match = normalized.match(pattern)
      amount_str = match[1]
      unit_str = match[2]
      remainder = normalized.sub(match[0], "").strip

      # Convert "ein"/"eine" to 1
      amount = amount_str.match?(/^ein/i) ? 1.0 : amount_str.to_f

      # Extract additional info from parentheses
      additional_info = extract_additional_info(remainder)

      # Detect if this is a garnish
      is_garnish = detect_garnish(unit_str, remainder)

      {
        amount: amount,
        unit: normalize_unit_name(unit_str),
        additional_info: additional_info,
        is_garnish: is_garnish,
        is_certain: true  # Main pattern matched - this is certain
      }
    else
      # Pattern for fractions without explicit unit: "1/2 Limette", "1 1/2 Orangen"
      # This matches: whole number + optional fraction, then ingredient name
      fraction_pattern = /^(\d+\s+)?((\d+)\/(\d+))\s+(.+)/

      if fraction_match = normalized.match(fraction_pattern)
        whole = fraction_match[1] ? fraction_match[1].to_i : 0
        numerator = fraction_match[3].to_f
        denominator = fraction_match[4].to_f
        ingredient_name = fraction_match[5].strip

        amount = whole + (numerator / denominator)

        {
          amount: amount,
          unit: "x",  # Blank unit
          additional_info: nil,
          is_garnish: false,
          is_certain: false  # Fraction without explicit unit - uncertain
        }
      else
        # Try simple count pattern: "1 Limette", "2 Orangen"
        simple_count = normalized.match(/^(\d+\.?\d*|ein|eine)\s+(.+)/)
        if simple_count
          amount_str = simple_count[1]
          remainder = simple_count[2]
          amount = amount_str.match?(/^ein/i) ? 1.0 : amount_str.to_f

          # Try to extract adjectives (e.g., "gefrostete Erdbeeren" → additional_info: "gefrostete")
          adjective_match = remainder.match(/^([a-zäöüß]+(?:e|en|er|es|em))\s+(.+)/i)
          additional_info = adjective_match ? adjective_match[1] : nil

          {
            amount: amount,
            unit: "x",  # Blank unit
            additional_info: additional_info,
            is_garnish: false,
            is_certain: false  # Simple count without unit - uncertain
          }
        else
          # No structured data - check if it's garnish description
          is_garnish = GARNISH_KEYWORDS.any? { |kw| description.downcase.include?(kw) }

          {
            amount: nil,
            unit: nil,
            additional_info: description,
            is_garnish: is_garnish,
            is_certain: false  # Unstructured - uncertain
          }
        end
      end
    end
  end

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
      "schuss" => "spritzer",  # Schuss is like Spritzer
      "barlöffel" => "barspoon",
      "stück" => "piece",
      "scheibe" => "slice",
      "blatt" => "leaf",
      "zweig" => "sprig"
    }[normalized] || normalized
  end

  def self.detect_garnish(unit_str, remainder)
    # Count units (Scheibe, Zweig, etc.) with food items are usually garnish
    unit_lower = unit_str.downcase

    # If unit is Scheibe, Zweig, Blatt - likely garnish
    return true if unit_lower.match?(/scheiben?|zweige?|blätter?/)

    # Check ingredient name for garnish keywords
    GARNISH_KEYWORDS.any? { |kw| remainder.downcase.include?(kw) }
  end

  def self.extract_additional_info(text)
    # Extract parentheses content: "Rum (braun)" → "braun"
    if match = text.match(/\(([^)]+)\)/)
      return match[1]
    end

    nil
  end
end
