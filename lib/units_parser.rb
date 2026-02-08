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

    # ========== HARD-CODED SPECIAL CASES (from ingredients_analysis_report.txt) ==========

    # D.O.M. Benedictine - Brand-Spezifikation
    if match = normalized.match(/^(\d+\.?\d*)\s*(cl|ml)\s+(?:D\.O\.M\.\s+)?Benedictine(?:\s+D\.O\.M\.)?/i)
      return { amount: match[1].to_f, unit: match[2].downcase, additional_info: "D.O.M.", is_garnish: false }
    end

    # Erdbeeren in Gramm (frisch oder gefroren)
    if match = normalized.match(/^(\d+)\s*g\s+Erdbeeren\s*\(?\s*(frisch.*?(?:od\.|oder).*?gefroren)/i)
      info = match[2].gsub(/\s*od\.\s*/, " oder ").gsub(/\s+/, " ").strip
      return { amount: match[1].to_f, unit: "x", additional_info: info, is_garnish: false }
    end

    # Eiweiß von einem Ei
    if description.match(/Eiweiß\s+von\s+einem/i)
      return { amount: 1.0, unit: "x", additional_info: "Eiweiß", is_garnish: false }
    end

    # Eingefrorene Himbeere im Eiswürfel
    if description.match(/in\s+klarem\s+Eisw.*?\s+eingefrorene\s+Himbeere/i)
      return { amount: 1.0, unit: "x", additional_info: "in klarem Eiswürfel eingefroren", is_garnish: true }
    end

    # "ein paar Spritzer" / "ein paar Tropfen" Angostura
    if description.match(/ein\s+paar\s+(Spritzer|Tropfen)/i)
      return { amount: 3.0, unit: "spritzer", additional_info: nil, is_garnish: false }
    end

    # Soda oder kohlensäurearmes Wasser
    if match = normalized.match(/^(\d+\.?\d*)\s*(cl|ml)\s+Soda\s+oder\s+kohlensäurearmes\s+Wasser/i)
      return { amount: match[1].to_f, unit: match[2].downcase, additional_info: "oder kohlensäurearmes Wasser", is_garnish: false }
    end

    # London Gin N1 Original blue
    if match = normalized.match(/^(\d+\.?\d*)\s*(cl|ml)\s+London\s+Gin\s+N1\s+Original\s+blue/i)
      return { amount: match[1].to_f, unit: match[2].downcase, additional_info: "London Gin N1 Original blue", is_garnish: false }
    end

    # Brandy oder guter Weinbrand
    if match = normalized.match(/^(\d+\.?\d*)\s*(cl|ml)\s+Brandy\s+oder\s+guter\s+Weinbrand/i)
      return { amount: match[1].to_f, unit: match[2].downcase, additional_info: "oder guter Weinbrand", is_garnish: false }
    end

    # Mineralwasser mit oder ohne Kohlensäure
    if match = normalized.match(/^(\d+\.?\d*)\s*(cl|ml)\s+Mineralwasser\s+mit\s+oder\s+ohne\s+Kohlensäure/i)
      return { amount: match[1].to_f, unit: match[2].downcase, additional_info: "mit oder ohne Kohlensäure", is_garnish: false }
    end

    # Hennessy Fine de Cognac
    if match = normalized.match(/^(\d+\.?\d*)\s*(cl|ml)\s+Hennessy\s+Fine\s+de\s+Cognac/i)
      return { amount: match[1].to_f, unit: match[2].downcase, additional_info: "Hennessy Fine de Cognac", is_garnish: false }
    end

    # Crème de Menthe (grün), alternativ Minzsirup
    if match = normalized.match(/^(\d+\.?\d*)\s*(cl|ml)\s+Cr.*?me\s+de\s+Menthe\s*\(grün\).*?alt.*?Minzsirup/i)
      return { amount: match[1].to_f, unit: match[2].downcase, additional_info: "grün, alternativ Minzsirup", is_garnish: false }
    end

    # Büschel Waldmeister ohne Blüten
    if description.match(/Büschel\s+Waldmeister\s+ohne\s+Blüten/i)
      return { amount: 1.0, unit: "x", additional_info: "Büschel, ohne Blüten", is_garnish: false }
    end

    # Kugel Vanilleeis (ca. 5 cl)
    if description.match(/Kugel\s+Vanilleeis.*?ca.*?5\s*cl/i)
      return { amount: 1.0, unit: "x", additional_info: "Kugel (ca. 5 cl)", is_garnish: false }
    end

    # Rohrzucker braun mit BL (Barlöffel)
    if match = normalized.match(/^(\d+\.?\d*)\s+(?:bis\s+\d+\.?\d*\s+)?BL\s+Rohrzucker\s+braun/i)
      amount = match[1].to_f
      # Bei Range "2 bis 3" nehmen wir Mittelpunkt
      if range = description.match(/(\d+)\s+bis\s+(\d+)/)
        amount = (range[1].to_f + range[2].to_f) / 2.0
      end
      return { amount: amount, unit: "x", additional_info: "braun", is_garnish: false }
    end

    # Bourbon oder Rye Whiskey
    if match = normalized.match(/^(\d+\.?\d*)\s*(cl|ml)\s+Bourbon\s+oder\s+Rye\s+Whiskey/i)
      return { amount: match[1].to_f, unit: match[2].downcase, additional_info: "Bourbon oder Rye", is_garnish: false }
    end

    # Glas Schattenmorellen mit Kirschsaft
    if description.match(/Glas\s+Schattenmorellen.*?Kirschsaft/i)
      return { amount: 1.0, unit: "x", additional_info: "Glas Schattenmorellen mit Kirschsaft", is_garnish: false }
    end

    # Tropfen Pfirsich Bitter (Peach Bitter's TBT)
    if match = normalized.match(/^(\d+)\s+Tropfen\s+Pfirsich\s+Bitter.*?Peach\s+Bitter/i)
      return { amount: match[1].to_f, unit: "spritzer", additional_info: "Peach Bitter's TBT", is_garnish: false }
    end

    # Frisches Püree vom weißen Pfirsich
    if match = normalized.match(/^(\d+\.?\d*)\s*(cl|ml)\s+frisches\s+Püree\s+vom\s+weißen\s+Pfirsich/i)
      return { amount: match[1].to_f, unit: match[2].downcase, additional_info: "frisches Püree vom weißen Pfirsich", is_garnish: false }
    end

    # Lychees/Litschi (ersatzweise aus der Dose)
    if match = normalized.match(/^(\d+)\s+Lychees.*?ersatzweise\s+aus\s+der\s+Dose/i)
      return { amount: match[1].to_f, unit: "x", additional_info: "ersatzweise aus der Dose", is_garnish: false }
    end

    # Stengel Minze / ca. 6 Blatt
    if description.match(/Stengel\s+Minze.*?ca.*?6\s+Blatt/i)
      return { amount: 1.0, unit: "x", additional_info: "Stengel (ca. 6 Blatt)", is_garnish: false }
    end

    # Single Malt Scotch Whisky
    if match = normalized.match(/^(\d+\.?\d*)\s*(cl|ml)\s+Single\s+Malt\s+Scotch\s+Whisky/i)
      return { amount: match[1].to_f, unit: match[2].downcase, additional_info: "Single Malt Scotch", is_garnish: false }
    end

    # Islay Single Malt Scotch Whisky
    if match = normalized.match(/^(\d+\.?\d*)\s*(cl|ml)\s+Islay\s+Single\s+Malt\s+Scotch\s+Whisky/i)
      return { amount: match[1].to_f, unit: match[2].downcase, additional_info: "Islay Single Malt Scotch", is_garnish: false }
    end

    # Frischer Ingwer (gerieben) mit TL
    if match = normalized.match(/^(\d+\.?\d*(?:\/\d+)?)\s+TL\s+Frischer\s+Ingwer.*?gerieben/i)
      amount = eval(match[1].gsub("/", ".0/"))  # Handle fractions like "1/2"
      return { amount: amount, unit: "tl", additional_info: "frisch gerieben", is_garnish: false }
    end

    # Rohzucker (braun, gemahlen) mit BL
    if match = normalized.match(/^(\d+)\s+BL\s+Rohzucker.*?braun.*?gemahlen/i)
      return { amount: match[1].to_f, unit: "x", additional_info: "braun, gemahlen", is_garnish: false }
    end

    # Instant-Kaffee Mocca mit BL
    if match = normalized.match(/^(\d+)\s+BL\s+Instant-Kaffee\s+Mocca/i)
      return { amount: match[1].to_f, unit: "x", additional_info: "Instant-Kaffee", is_garnish: false }
    end

    # Rye, Bourbon oder Scotch Whisk(e)y
    if match = normalized.match(/^(\d+\.?\d*)\s*(cl|ml)\s+Rye.*?Bourbon.*?Scotch/i)
      return { amount: match[1].to_f, unit: match[2].downcase, additional_info: "Rye, Bourbon oder Scotch", is_garnish: false }
    end

    # Gereifter Rum, vorzugsweise aus Barbados
    if match = normalized.match(/^(\d+\.?\d*)\s*(cl|ml)\s+gereifter\s+Rum.*?vorzugsweise\s+aus\s+Barbados/i)
      return { amount: match[1].to_f, unit: match[2].downcase, additional_info: "gereift, vorzugsweise aus Barbados", is_garnish: false }
    end

    # ========== END HARD-CODED CASES ==========

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
