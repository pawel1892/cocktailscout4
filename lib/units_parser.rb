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

    # Pattern: [number] [unit] [ingredient] [(optional)]
    # Examples: "3cl Rum", "2 TL Zucker", "ein Spritzer", "1 Scheibe Zitrone"
    pattern = /^(\d+\.?\d*|ein|eine)\s*(cl|ml|l|TL|EL|Teelöffel|Esslöffel|Spritzer|Dash|Splash|Barlöffel|Stück|Scheiben?|Blätter?|Zweige?)/i

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
      # No structured data - check if it's garnish description
      is_garnish = GARNISH_KEYWORDS.any? { |kw| description.downcase.include?(kw) }

      { amount: nil, unit: nil, additional_info: description, is_garnish: is_garnish }
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
