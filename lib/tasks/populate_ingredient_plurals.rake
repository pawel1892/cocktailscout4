namespace :ingredients do
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

    # Ingredients that don't need plurals (abstract/mass nouns)
    # Likör, Vodka, Rum, Gin, Whisky, Sirup, Saft, Wasser, Zucker, Salz, etc.
    # These are not in the plurals hash, so they won't get a plural_name

    count = 0

    # First, fix plural ingredient names
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
end
