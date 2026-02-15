## Ausgangslage

### Tabellen
- Zutaten (ingredients)
- Rezepte (recipes)
- Rezeptzutaten (recipe_ingredients)

#### Relationen
Jede Rezeptzutat muss einem Rezept und einer Zutat zugeordnet sein. Mindestens zwei Rezeptzutaten pro Rezept

#### Felder
In diesem Kontext relevant sind bei Rezeptzutaten die Felder
- Menge in cl (amount)
- Zutat (ingredient_id)
- Beschreibung (description)

#### Rendering
Der Nutzer bekommt nur die Beschreibung zu sehen. Menge und Zutat werden intern verwendet, um Gesamtvolumen, Alkoholgehalt zu berechnen, sowie für meine Bar und andere Suchmöglichkeiten nach Zutaten.

Diese Datenstrukturen waren äußerst flexibel wenn es darum geht, was auf der Rezeptseite zu sehen ist. Bei der Migration zum neuen System fällt uns das auf die Füße.

#### Edge Cases
Der einfachste und zum häufigste Fall ist, dass die Beschreibung mit den internen Daten übereinstimmt. Beispiel:
amount: 2, ingredient: Tequila (weiss), description: 2 cl Tequila (weiss)

In allen anderen Fällen, wo die Beschreibung nicht mit den internen Daten übereinstimmt haben wir zwei Wahrheiten und müssen uns für eine entscheiden. Das ist schwierig zu automatisieren und wird

## Ziel: Einführung von Einheiten
### Tabellen
- Einheiten (units)
- Zutaten (ingredients)
- Rezepte (recipes)
- Rezeptzutaten (recipe_ingredients)

### Tabelle: units
  - `name` varchar(255) NOT NULL: Name der Einheit
  - `display_name` varchar(255) NOT NULL: Angezeigter Name
  - `plural_name` varchar(255) NOT NULL: Angezeigter Name im Plural
  - `category` varchar(255) NOT NULL: volume, special, count
  - `ml_ratio` decimal(10,4) DEFAULT NULL: Umrechnung zu ml
  - `divisible` tinyint(1) NOT NULL DEFAULT 1: Teilbar (z.B. Spritzer nein). Es gibt keinen halben Spritzer
Zusätzlich dazu gibt es natürlich alles Standardfelder: id, timestamps

### Tabelle: recipe_units
#### Neue Felder
- `amount` decimal(10,2) DEFAULT NULL: Menge in der neuen Einheit (unit_id)
-  `unit_id` bigint(20) DEFAULT NULL: Einheit (Relation zu unit)
-  `additional_info` varchar(255) DEFAULT NULL: zusätzliche Information
- `old_amount` decimal(10,2) DEFAULT NULL: Mengenangabe vor der Datenmigration
-  `old_description` varchar(255) DEFAULT NULL: Beschreibung vor der Datenmigration
-  `needs_review` tinyint(1) NOT NULL DEFAULT 0: temporäres Feld um zu markieren, wo keine vollautomatische Migration möglich war (siehe edge cases)
-  `is_scalable` tinyint(1) NOT NULL DEFAULT 1: wird das mit Portionen skaliert?
-  `is_optional` tinyint(1) NOT NULL DEFAULT 0: im wesentlichen für mybar (kann diese Zutat weggelassen werden?)
-  `display_name` varchar(255) DEFAULT NULL: Fall ein anderer Zutatenname angezeigt werden muss als der in Zutaten tabelle. Beispiel: Zutat: Erdbeeren - Display name: gefrostete Erdbeeren
### Tabelle: ingredients
neu: `:plural_name, :string, after: :name`
Das wird benötigt, um beim Skalieren: 1 Limette und 2 Limetten Plural anzuzeigen
#### Neue Relation
Rezeptzutaten (recipe_ingredients) haben eine Einheit (ingredients)

## Durchführung der Migration
### Alte Werte speichern
Um nach der Migration überprüfen zu können, ob die alten und neuen Daten übereinstimmen, müssen wir die vorhandenen Daten in Rezeptzutaten speichern.
 - old_description: description
 - old_amount: amount
### Einheiten anlegen
Bisher wurde alles in cl gemessen. Nach Analyse der Beschreibungen werden diese neuen Einheiten benötigt und müssen angelegt werden:
```
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
```

### Neue Felder in Rezeptzutaten befüllen
Hierfür muss die old_description geparst werden. Es muss versucht werden in diesem String ein Muster zu finden: Menge + Einheit + Zutat oder Menge + Zutat. In Rezeptzutaten ist die Einheit optional, da es Dinge wie Limetten oder Minzweige gibt. Diese haben die implizite Einheit Stück.

Beispiele: 
- "2 cl Wodka" -> Menge: 2, Einheit: cl, Zutat: Wodka
- "ein Spritzer Cola" -> Menge: 1, Einheit: dash, Zutat: Cola
- "1/2 Limette" -> Menge: 0.5, Einheit: null, Zutat: Limette

In allen Fällen, wo es nicht möglich ist eine Menge und Zutat zu identifizieren wird eine manuelle Anpassung nach der Migration durchgeführt. Dafür wird `needs_review`auf 1 gesetzt.

Beispiele hier sind:
- 2-4 Limetten (Mengenangabe als Wertebereich)
- Soda (Keine Mengenangabe)
- 1/3 Apfelsaft (Relative Mengenangabe)
- Minzzweig (keine Mengenangabe)

Um keine Informationen zu verlieren müssen wir nach dem Parsen auch überprüfen ob der Zutatenname in old_description und der Name der Zutaten in der Einheitentabelle (ingredients) übereinstimmen. Es geht nicht darum, ob die der String zu 100% übereinstimmt, sondern ob es inhaltlich übereinstimmt. Das lässt sich natürlich nicht per Skript automatisieren. Es gibt aber ein "Übersetzungsarray":
```
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
```

Wenn die Zutaten nach Überprüfung des Arrays nicht übereinstimmen, dann wird ebenfalls das needs_review Flag gesetzt, um eine manuelle Überprüfung zu triggern. 
Beispiele sind:
- "4 gefrostete Erdbeeren" (Zutat: Erdbeeren)
- "2 Eigelb" (Zutat: Eier)
- "4 cl Wyborowa Wodka" (Zutat: Wodka)
Hier würden die Zusatzinformationen (gefrostet, nur Eigelb, Marke Wyborowa) verloren gehen bei einer automatischen Migration.

Wenn needs_review gesetzt ist, zeigt das System dem User die old_description. Diese Rezepte können nicht nach Portionen skaliert werden, bis sie bereinigt wurden.
