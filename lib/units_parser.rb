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

    # Handle range patterns: "1-2 Limetten", "2-3cl Rum", "0.5-1 l"
    # Convert to midpoint: "1-2" → "1.5", "2-3" → "2.5"
    if range_match = normalized.match(/^(\d+\.?\d*)\s*-\s*(\d+\.?\d*)/)
      min_val = range_match[1].to_f
      max_val = range_match[2].to_f
      midpoint = (min_val + max_val) / 2.0
      # Replace the range with the midpoint and continue parsing
      normalized = normalized.sub(range_match[0], midpoint.to_s)
    end

    # Hard-coded special case: "3 dünne Scheiben grüne Gurke" → unit: slice, additional_info: "dünn"
    # This handles adjectives between number and unit (Scheiben/Scheibe)
    if scheiben_match = normalized.match(/^(\d+\.?\d*)\s+dünne?\s+(Scheiben?)\s+(.+)/i)
      amount = scheiben_match[1].to_f
      ingredient_rest = scheiben_match[3]

      # Remove "grüne" or other adjectives before ingredient name
      ingredient_rest = ingredient_rest.sub(/^(grüne?|große?|kleine?)\s+/i, "")

      return {
        amount: amount,
        unit: "slice",
        additional_info: "dünn",
        is_garnish: false  # Allow scaling
      }
    end

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
        is_garnish: false
      }
    else
      # Pattern: [number] [unit] [ingredient] [(optional)]
      # Examples: "3cl Rum", "2 TL Zucker", "ein Spritzer", "1 Scheibe Zitrone"
      # The l(?!\w) lookahead prevents matching "l" in "Limette"
      pattern = /^(\d+\.?\d*|ein|eine)\s*(cl|ml|l(?!\w)|TL|EL|Teelöffel|Esslöffel|Spritzer|Dash|Splash|Barlöffel|Stück|Scheiben?|Blätter?|Zweige?)\b/i

      if match = normalized.match(pattern)
        amount_str = match[1]
        unit_str = match[2]
        remainder = normalized.sub(match[0], "").strip

        # Convert "ein"/"eine" to 1
        amount = amount_str.match?(/^ein/i) ? 1.0 : amount_str.to_f

        # Extract additional info from parentheses or ranges
        additional_info = extract_additional_info(remainder)

        # Detect if this is a garnish
        is_garnish = detect_garnish(unit_str, remainder)

        {
          amount: amount,
          unit: normalize_unit_name(unit_str),
          additional_info: additional_info,
          is_garnish: is_garnish
        }
      else
        # Try simple count pattern: "1 Limette", "2 Orangen", "4 gefrostete Erdbeeren"
        # Extract adjectives like "gefrostete", "große", "frische" as additional_info
        simple_count = normalized.match(/^(\d+\.?\d*|ein|eine)\s+(.+)/)
        if simple_count
          amount_str = simple_count[1]
          remainder = simple_count[2]
          amount = amount_str.match?(/^ein/i) ? 1.0 : amount_str.to_f

          # Try to extract adjectives (e.g., "gefrostete Erdbeeren" → additional_info: "gefrostete")
          # Common adjective endings in German: -e, -en, -er, -es, -em
          adjective_match = remainder.match(/^([a-zäöüß]+(?:e|en|er|es|em))\s+(.+)/i)
          additional_info = adjective_match ? adjective_match[1] : nil

          {
            amount: amount,
            unit: "x",  # Blank unit
            additional_info: additional_info,
            is_garnish: false
          }
        else
          # No structured data - check if it's garnish description
          is_garnish = GARNISH_KEYWORDS.any? { |kw| description.downcase.include?(kw) }

          { amount: nil, unit: nil, additional_info: description, is_garnish: is_garnish }
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

    # Handle ranges: "2 bis 3 dashes" → "2-3"
    if text.match(/(\d+)\s*bis\s*(\d+)/i)
      return "#{$1}-#{$2}"
    end

    nil
  end
end
