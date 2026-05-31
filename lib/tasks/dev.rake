namespace :dev do
  desc "Seed sample wiki articles for local development"
  task seed_wiki: :environment do
    raise "Only runs in development or beta" unless Rails.env.development? || Rails.env.beta?

    user = User.first || raise("No users found — create a user account first")

    wiki_editor_role = Role.find_or_create_by(name: "wiki_editor") { |r| r.display_name = "Wiki-Editor" }
    User.find_each do |u|
      u.roles << wiki_editor_role unless u.role?(wiki_editor_role.name)
    end
    puts "Assigned wiki_editor role to all #{User.count} user(s)"

    rum      = Ingredient.find_by(name: "Rum")
    gin      = Ingredient.find_by(name: "Gin")
    lime     = Ingredient.find_by(name: "Limettensaft")

    # Slugs must match title.parameterize — update here if titles change
    slug = {
      rum:           "rum-geschichte-herstellung",
      gin:           "gin-botanicals-destillation",
      saeure:        "saure-im-cocktail-zitrus-richtig-einsetzen",
      sirupe:        "hausgemachte-sirupe-grundrezepte-entwurf",
      whisky:        "whisky-single-malt-bis-blended",
      tequila:       "tequila-mezcal-agave-destillate",
      vodka:         "vodka-neutralitat-als-starke",
      vermouth:      "vermouth-der-unterschatzte-wermut",
      bitters:       "bitters-aromatische-konzentrate",
      eis:           "eis-im-cocktail-arten-einsatz",
      technik:       "shaken-vs-stirred-die-richtige-technik",
      glaeser:       "glaser-form-folgt-funktion",
      daiquiri:      "classic-daiquiri-anatomie-eines-sours",
      negroni:       "negroni-bittersweet-klassiker",
      old_fashioned: "old-fashioned-die-urform-des-cocktails",
      mojito:        "mojito-frische-technik",
      batching:      "batching-cocktails-fur-gruppen",
      fermentation:  "fermentation-sodawasser-in-der-bar",
      alkoholfrei:   "alkoholfreie-cocktails-mocktails-richtig-gemacht",
      werkzeug:      "barwerkzeug-das-einmaleins"
    }

    articles = [
      {
        title: "Rum — Geschichte & Herstellung",
        published: true,
        featured: true,
        featured_position: 1,
        ingredients: [ rum ].compact,
        body: <<~MD
          ## Was ist Rum?

          Rum ist ein **Zuckerrohrschnaps**, der aus vergorenem Zuckerrohrsaft oder Melasse destilliert wird.
          Er gehört zu den meistkonsumierten Spirituosen der Welt und ist die Basis vieler klassischer Cocktails —
          darunter der [[wiki:#{slug[:daiquiri]}|Classic Daiquiri]] und der [[wiki:#{slug[:mojito]}|Mojito]].

          ## Geschichte

          Die ersten dokumentierten Hinweise auf die Rum-Produktion stammen aus dem **17. Jahrhundert** von der Karibik-Insel Barbados.
          Sklaven auf den Zuckerrohrplantagen entdeckten, dass Melasse — ein Nebenprodukt der Zuckerraffinierung — zu Alkohol vergoren werden kann.

          > "Rum ist das Destillat der Tropen, in jeder Flasche steckt ein Stück karibischer Geschichte."

          ### Wichtige Meilensteine

          1. **1620** — Erste urkundliche Erwähnung von Rum in Barbados
          2. **1655** — Die britische Royal Navy führt die tägliche Rum-Ration ein
          3. **1862** — Bacardí gründet seine erste Destillerie in Kuba
          4. **1919–1933** — US-Prohibition macht Kuba zum Rum-Tourismusziel

          ## Herstellung

          Die Produktion läuft grob in vier Schritten ab:

          - **Rohstoff**: Zuckerrohrsaft (für *Rhum Agricole*) oder Melasse (für industriellen Rum)
          - **Vergärung**: Hefe wandelt Zucker in 3–10 Tagen in Alkohol um
          - **Destillation**: Pot Still (vollmundig) oder Column Still (leichter)
          - **Reifung**: Eichenfässer — je länger, desto komplexer

          ## Stile im Überblick

          | Stil | Herkunft | Charakter |
          |---|---|---|
          | Weißer Rum | Kuba, Puerto Rico | Leicht, neutral |
          | Goldener Rum | Barbados, Trinidad | Mild, karamellisiert |
          | Dunkler Rum | Jamaika, Guyana | Vollmundig, rauchig |
          | Rhum Agricole | Martinique | Grasig, komplex |
          | Overproof | Jamaika | Intensiv, >57% |

          ## Rum im Cocktail

          Für [[wiki:#{slug[:batching]}|Batched Drinks]] eignen sich goldene oder dunkle Rums besonders gut —
          ihre Komplexität trägt auch in großen Mengen. Weißer Rum ist die klassische Wahl für Sours.
          Einen guten Überblick über geeignete [[wiki:#{slug[:sirupe]}|Sirupe]] als Gegenpol zur Rumwürze
          findest du im Sirup-Artikel. Wer Rum mit anderen Spirituosen vergleichen möchte: [[wiki:#{slug[:gin]}|Gin]]
          arbeitet mit ganz anderen Aromaprinzipien.

          ## Lagerung & Serviertipps

          Rum sollte **aufrecht** und **lichtgeschützt** gelagert werden. Anders als Wein reift er in der Flasche nicht weiter.
          Für Cocktails greife zu weißem oder goldenem Rum — für Pur-Genuss lohnt sich ein guter aged Rum.
        MD
      },
      {
        title: "Gin — Botanicals & Destillation",
        published: true,
        featured: false,
        ingredients: [ gin ].compact,
        body: <<~MD
          ## Wacholder als Pflichtbestandteil

          Gin ist per Definition ein Wacholdergeist. Ohne ***Juniperus communis*** — den gemeinen Wacholder —
          darf kein Destillat als Gin vermarktet werden. Alles andere ist Freiheit.

          ### Die wichtigsten Botanicals

          Moderne Gins verwenden zwischen **4 und 40** verschiedene Botanicals:

          - Wacholder (Pflicht)
          - Koriandersamen
          - Angelikawurzel
          - Zitrusschalen (Zitrone, Orange, Grapefruit)
          - Kardamom, Ingwer, Pfeffer
          - Gurke, Rosenblüten, Lavendel (New-Western-Stile)

          ## Destillationsmethoden

          ### Pot Still Distillation
          Botanicals werden direkt in die Brennblase gegeben (*maceration*) oder
          über Dampfkorb (*vapour infusion*) aromatisiert. Ergibt vollmundigere Profile.

          ### Column Still
          Schneller und günstiger. Liefert reinere, neutralere Basis-Gins.

          ## Gin-Kategorien

          | Kategorie | Merkmal | Beispiel |
          |---|---|---|
          | London Dry | Keine Zusätze nach der Destillation | Tanqueray, Beefeater |
          | Plymouth | Geographisch geschützt | Plymouth Gin |
          | Old Tom | Leicht gesüßt | Hayman's Old Tom |
          | New Western | Wacholder tritt zurück | Hendrick's, Monkey 47 |
          | Sloe Gin | Schlehenbeeren-Likör | Gordon's Sloe |

          ## Gin mit Begleitern

          Der klassische [[wiki:#{slug[:negroni]}|Negroni]] zeigt, wie Gin mit [[wiki:#{slug[:vermouth]}|Vermouth]]
          und [[wiki:#{slug[:bitters]}|Bitters]] ein vollständiges Geschmacksbild ergibt. Für das richtige
          Mischverhältnis ist die [[wiki:#{slug[:technik]}|Technik beim Rühren vs. Schütteln]] entscheidend —
          ein Negroni wird immer gerührt. Das [[wiki:#{slug[:glaeser]}|passende Glas]] rundet das Erlebnis ab.

          ## Tonic-Pairings

          Ein gutes G&T lebt vom **Verhältnis 1:3** (Gin zu Tonic). Wichtig:

          > Das Tonic sollte den Gin ergänzen, nicht überdecken. Ein blumiger Gin
          > verlangt nach einem milden Tonic; ein würziger nach einem bitteren.

          Immer über großen Eiswürfeln servieren — langsames Schmelzen verdünnt weniger.
        MD
      },
      {
        title: "Säure im Cocktail — Zitrus richtig einsetzen",
        published: true,
        featured: false,
        ingredients: [ lime ].compact,
        body: <<~MD
          ## Die Rolle der Säure

          Säure ist das **Salz der Cocktailwelt** — zu wenig und alles wirkt flach, zu viel und der
          Gaumen schmerzt. Zitrusfrüchte sind die häufigste Quelle, aber nicht die einzige.
          Auch [[wiki:#{slug[:bitters]}|Bitters]] tragen zur Geschmacksbalance bei, arbeiten aber auf
          einer anderen Ebene als direkte Säure.

          ## Zitrus-Vergleich

          | Frucht | pH-Wert | Charakter | Typischer Einsatz |
          |---|---|---|---|
          | Limette | 2,0–2,4 | Scharf, grasig | Daiquiri, Margarita, Mojito |
          | Zitrone | 2,2–2,4 | Runder, blumig | Sour, Collins, Bee's Knees |
          | Grapefruit | 3,0–3,5 | Bitter, komplex | Paloma, Sea Breeze |
          | Yuzu | 2,5–3,0 | Floral, einzigartig | Moderne Sours |

          ## Frisch pressen — immer

          Abgepackter Saft enthält Konservierungsstoffe und hat durch Pasteurisierung
          an **flüchtigen Aromen** verloren. Frisch gepresster Saft enthält außerdem:

          - Ätherische Öle aus der Schale (beim Pressen mitextrahiert)
          - Lebendige Säurestruktur
          - Natürliche Pektine, die die Textur beeinflussen

          > Saft immer am Tag des Gebrauchs pressen. Nach 24 Stunden im Kühlschrank
          > beginnt er zu oxidieren und verliert Frische.

          ## Die goldene Balance

          Ein klassischer Sour folgt der **2:1:¾-Formel**:

          ```
          2 oz Spirituose
          1 oz Zitrusfrüchte (frisch)
          ¾ oz einfacher Sirup
          ```

          Passe den Sirupanteil an die Intensität des Zitrus an — Limette braucht etwas mehr Süße als Zitrone.
          Alle Grundrezepte für [[wiki:#{slug[:sirupe]}|Sirupe]] findest du im Sirup-Artikel.
          Der [[wiki:#{slug[:daiquiri]}|Classic Daiquiri]] ist das Lehrbeispiel dieser Formel in Reinform.

          ## Oleo Saccharum — die Geheimwaffe

          Zucker auf Zitrusschalen ziehen lassen extrahiert die **ätherischen Öle** direkt in den Zucker.
          Das Ergebnis ist ein intensiv duftendes Öl-Sirup-Gemisch für Punches und Batched Cocktails —
          ideal für [[wiki:#{slug[:alkoholfrei]}|alkoholfreie Varianten]], die auf komplexe Aromen angewiesen sind.

          1. Schalen von 4 Zitronen dünn abziehen (ohne das weiße Mark)
          2. Mit 100 g Zucker vermischen
          3. 30–60 Minuten ziehen lassen
          4. Auspressen — fertig
        MD
      },
      {
        title: "Hausgemachte Sirupe — Grundrezepte (Entwurf)",
        published: false,
        featured: false,
        body: <<~MD
          ## Einfacher Zuckersirup (1:1)

          Der **Standard-Sirup** für die meisten Cocktails — unverzichtbar für [[wiki:#{slug[:rum]}|Rum]]-basierte
          Sours und klassische Rezepte wie den [[wiki:#{slug[:old_fashioned]}|Old Fashioned]].

          - 200 g Zucker
          - 200 ml Wasser

          Wasser erhitzen, Zucker einrühren bis er sich auflöst. Nicht kochen. Abkühlen lassen.
          Haltbarkeit im Kühlschrank: **2–4 Wochen**.

          ## Rich Syrup (2:1)

          Doppelte Süße, kleinere Menge im Cocktail nötig. Besser für Batched Drinks.

          ## Honigsirup

          Honig 1:1 mit heißem Wasser verdünnen — macht ihn flüssig und bartauglich.
          Passt hervorragend zu [[wiki:#{slug[:saeure]}|Zitrus-Säure]] in einem Bee's Knees.

          ## Infused Sirupe

          Wer tiefer einsteigen möchte: Kräuter, Gewürze oder Früchte lassen sich direkt in den
          Zuckersirup ziehen. Techniken dazu — inklusive [[wiki:#{slug[:fermentation]}|fermentierter Ansätze]] —
          sind im Fermentations-Artikel beschrieben.

          > Dieser Artikel ist noch in Arbeit.
        MD
      },
      {
        title: "Whisky — Single Malt bis Blended",
        published: true,
        featured: true,
        featured_position: 2,
        body: <<~MD
          ## Die Welt des Whiskys

          Whisky (oder *Whiskey* in Irland und den USA) ist ein Destillat aus Getreide —
          Gerste, Mais, Roggen oder Weizen — das in Holzfässern reift. Kein anderes Destillat
          profitiert so sehr von der **Fassreifung** wie Whisky.

          ## Regionen & Stile

          | Region | Rohstoff | Charakter |
          |---|---|---|
          | Schottisches Hochland | Gerste | Torfig, würzig, komplex |
          | Speyside | Gerste | Fruchtig, elegant, mild |
          | Islay | Gerste | Stark torfig, rauchig, jodhaltig |
          | Bourbon (Kentucky) | Mais (min. 51%) | Süß, Vanille, Karamell |
          | Rye (USA/Kanada) | Roggen | Würzig, trocken, pfeffrig |
          | Irish | Gerste (ungemälzt) | Leicht, dreifach destilliert |

          ## Single Malt vs. Blended

          - **Single Malt**: Nur eine Destillerie, nur Gerstenmalz. Oft komplex und charakterstark.
          - **Blended Malt**: Mehrere Destillerien, nur Malzwhisky.
          - **Blended Scotch**: Malzwhisky + Grain-Whisky. Zugänglicher, konsistenter.
          - **Single Grain**: Einer Destillerie, aber nicht nur Gerste — selten, interessant.

          ## Whisky im Cocktail

          Der [[wiki:#{slug[:old_fashioned]}|Old Fashioned]] ist das Ur-Rezept des Whisky-Cocktails.
          [[wiki:#{slug[:bitters]}|Bitters]] spielen dabei eine zentrale Rolle — ohne sie fehlt die Tiefe.
          Die Wahl des [[wiki:#{slug[:eis]}|Eises]] beeinflusst, wie schnell ein Whisky-Cocktail verdünnt:
          ein großer Würfel schmilzt langsamer als gestoßenes Eis.

          ## Nosing & Tasting

          > Whisky zuerst ohne Eis verkosten. Erst ein paar Tropfen Wasser zugeben —
          > das öffnet die Aromen. Dann entscheiden, ob Eis passt.

          Das richtige [[wiki:#{slug[:glaeser]}|Glas]] ist entscheidend: ein Tulpenglas konzentriert
          die Aromen zur Nase; ein Tumbler ist für Cocktails oder On-the-Rocks gemacht.
        MD
      },
      {
        title: "Tequila & Mezcal — Agave-Destillate",
        published: true,
        featured: false,
        body: <<~MD
          ## Die Agave als Rohstoff

          Tequila und Mezcal werden aus **Agaven** destilliert — sukkullente Pflanzen, die
          7–25 Jahre bis zur Ernte brauchen. Das macht diese Destillate einzigartig und langsam.

          ## Tequila

          Tequila darf nur in bestimmten Regionen Mexikos (hauptsächlich Jalisco) hergestellt werden
          und muss aus mindestens **51% Blaue Weber-Agave** bestehen. 100%-Agave-Produkte sind hochwertiger.

          | Kategorie | Reifung | Charakter |
          |---|---|---|
          | Blanco / Silver | Ungelagert | Frisch, agavebetont |
          | Reposado | 2–12 Monate im Fass | Mild, Holznoten |
          | Añejo | 1–3 Jahre | Komplex, Vanille |
          | Extra Añejo | >3 Jahre | Reich, whiskyähnlich |

          ## Mezcal

          Mezcal kann aus **über 30 Agave-Arten** hergestellt werden. Die traditionelle Produktion
          röster die Agavenherzen (*Piñas*) in Erdöfen — das ergibt den charakteristischen Rauchgeschmack.

          > "Para todo mal, mezcal. Para todo bien, también."
          > ("Für alles Schlechte, Mezcal. Für alles Gute, auch.")

          ## Im Cocktail

          Die Margarita lebt von der Spannung zwischen Agavengeist und [[wiki:#{slug[:saeure]}|Limettensäure]].
          Das richtige Verhältnis — und warum frischer Saft unersetzlich ist — erklärt der Zitrus-Artikel.
          [[wiki:#{slug[:sirupe]}|Agavensirup]] als Süßungsmittel ist die authentische Wahl.
          Für Parties eignet sich die Margarita hervorragend als [[wiki:#{slug[:batching]}|Batched Cocktail]].
          Die Wahl des [[wiki:#{slug[:eis]}|Eises]] entscheidet über Textur und Verdünnung.
        MD
      },
      {
        title: "Vodka — Neutralität als Stärke",
        published: true,
        featured: false,
        body: <<~MD
          ## Das neutralste Destillat

          Vodka ist per Definition so neutral wie möglich — wenig Eigengeschmack, wenig Eigengeruch.
          Das macht ihn zum **universellsten Mixer** der Bar, aber auch zum am meisten unterschätzten.

          ## Rohstoffe & Herkunft

          | Rohstoff | Herkunft | Charakter |
          |---|---|---|
          | Getreide (Weizen, Roggen) | Russland, Polen | Seidig, leicht |
          | Kartoffel | Polen | Cremig, vollmundig |
          | Traube | Frankreich | Fruchtig, elegant |
          | Melasse | Diverse | Neutral, industriell |

          ## Qualitätsmerkmale

          Die Destillation läuft oft 3–5 mal durch Column Stills. Entscheidend ist die **Filtration**:
          Aktivkohle, Quarz, Silber oder sogar Diamanten werden eingesetzt.
          Premium-Vodkas werden ungefiltert gelassen — zu viel Filtration nimmt Charakter.

          ## Vodka im Cocktail

          Weil Vodka die anderen Zutaten nicht überdeckt, eignet er sich für [[wiki:#{slug[:alkoholfrei]}|nicht-alkoholische Konzepte]],
          bei denen der Alkohol später als Variante hinzugefügt werden kann. [[wiki:#{slug[:bitters]}|Bitters]]
          geben Vodka-Cocktails die fehlende Tiefe. Die [[wiki:#{slug[:technik]}|Schüttel- vs. Rührtechnik]]
          beeinflusst bei Vodka stärker als bei aromatischeren Spirituosen: ein Vodka Martini wird
          typischerweise gerührt für Transparenz und Textur. Großes [[wiki:#{slug[:eis]}|Eis]] ist Pflicht.
        MD
      },
      {
        title: "Vermouth — Der unterschätzte Wermut",
        published: true,
        featured: false,
        body: <<~MD
          ## Was ist Vermouth?

          Vermouth ist ein **aromatisierter Wein** — Basiswein, der mit Alkohol aufgespritet
          und mit Kräutern, Gewürzen und Rinde infundiert wird. Wermut (*Artemisia absinthium*)
          ist der Namensgeber und oft, aber nicht immer, enthalten.

          ## Stile

          | Stil | Herkunft | Restzucker | Charakter |
          |---|---|---|---|
          | Extra Dry | Frankreich | <4 g/l | Trocken, herb |
          | Dry (French) | Frankreich | <50 g/l | Trocken, leicht bitter |
          | Bianco / Blanc | Frankreich, Italien | 100–150 g/l | Süß, blumig |
          | Rosso / Sweet | Italien | 130–150 g/l | Süß, würzig |
          | Rosé | Diverse | Variabel | Fruchtig |

          ## Vermouth richtig lagern

          > Vermouth ist Wein — er oxidiert. Geöffnete Flaschen gehören in den Kühlschrank
          > und sollten innerhalb von 4–6 Wochen verbraucht werden.

          ## Im Cocktail

          Der [[wiki:#{slug[:negroni]}|Negroni]] verwendet Rosso-Vermouth als süß-bitteren Ausgleich zu
          [[wiki:#{slug[:gin]}|Gin]] und Campari. Im Martini ergänzt Dry-Vermouth die botanischen Noten.
          [[wiki:#{slug[:bitters]}|Bitters]] und Vermouth arbeiten oft als Duo: Beide bringen Tiefe,
          die eine Spirituose allein nicht leisten kann. Der [[wiki:#{slug[:old_fashioned]}|Old Fashioned]]
          kommt ohne Vermouth aus — zeigt, wie Bitters allein genügen können.
        MD
      },
      {
        title: "Bitters — Aromatische Konzentrate",
        published: true,
        featured: false,
        body: <<~MD
          ## Was sind Bitters?

          Bitters sind hochkonzentrierte Kräuter-Alkohol-Extrakte — ein paar **Spritzer**
          reichen aus, um einen Cocktail zu transformieren. Historisch als Medizin eingesetzt,
          sind sie heute das wichtigste Würzmittel der Bar.

          ## Klassische Bitters

          | Marke | Hauptaromen | Einsatz |
          |---|---|---|
          | Angostura | Gewürze, Zimt, Nelken | Old Fashioned, Manhattan |
          | Peychaud's | Anis, Kirsche | Sazerac |
          | Orange Bitters | Orangenschale, Gewürze | Martini, Negroni |
          | Mole Bitters | Schokolade, Chili | Tequila-Drinks |
          | Celery Bitters | Sellerie, Kräuter | Bloody Mary |

          ## Hausgemachte Bitters

          Bitters selbst herzustellen dauert 2–4 Wochen, ist aber überraschend einfach:
          Kräuter und Gewürze in hochprozentigem Alkohol ansetzen, filtern, mit Wasser verdünnen.

          ## Im Cocktail

          Der [[wiki:#{slug[:old_fashioned]}|Old Fashioned]] ist das Bitters-Lehrbeispiel:
          ohne Angostura fehlt die Komplexität, die Whisky und Zucker allein nicht erzeugen.
          Im [[wiki:#{slug[:negroni]}|Negroni]] übernimmt Campari die Bitter-Funktion — klassische
          Bitters bleiben optional. [[wiki:#{slug[:vermouth]}|Vermouth]] und Bitters ergänzen sich:
          beide bringen Botanicals, auf unterschiedlichen Wegen. Auch [[wiki:#{slug[:gin]}|Gin]]
          profitiert von einem Spritzer Bitters im Martini — er hebt die Botanicals hervor.
        MD
      },
      {
        title: "Eis im Cocktail — Arten & Einsatz",
        published: true,
        featured: false,
        body: <<~MD
          ## Eis ist eine Zutat

          Die meisten Barkeeper unterschätzen Eis. Es beeinflusst **Temperatur, Verdünnung und Textur**
          eines Cocktails — und damit den Gesamteindruck genauso stark wie die Spirituose.

          ## Eisarten im Überblick

          | Art | Oberfläche | Schmelzrate | Einsatz |
          |---|---|---|---|
          | Großer Würfel (5×5 cm) | Klein | Langsam | On the Rocks, Old Fashioned |
          | Standard-Würfel | Mittel | Mittel | Shaker, Highballs |
          | Gestoßenes Eis | Groß | Schnell | Mule, Julep, Swizzle |
          | Crushed Ice | Sehr groß | Sehr schnell | Tiki, Frozen |
          | Klares Eis | Klein | Langsam | Premium-Präsentation |

          ## Klares Eis selbst herstellen

          Trübes Eis entsteht durch eingeschlossene Luft und Mineralien.
          Klares Eis gelingt mit der **Gerichtungsgefrierung**:

          1. Styroporbox mit Wasser füllen (oben offen lassen)
          2. Im Gefrierschrank von oben nach unten gefrieren lassen
          3. Untere trübe Schicht abschneiden — oberer Teil ist klar

          ## Verdünnungsmanagement

          > Zu wenig Verdünnung: Cocktail zu stark und „hot". Zu viel: flach und wässrig.
          > Der optimale Bereich liegt bei 20–25% Verdünnung durch Schmelzwasser.

          Die richtige [[wiki:#{slug[:technik]}|Schütteltechnik]] entscheidet über Verdünnung beim Shaken.
          Das [[wiki:#{slug[:werkzeug]}|passende Barwerkzeug]] — insbesondere gute Eiswürfelformen — macht den Unterschied.
          Welches [[wiki:#{slug[:glaeser]}|Glas]] du verwendest, beeinflusst, wie schnell das Eis schmilzt.
          Im [[wiki:#{slug[:daiquiri]}|Daiquiri]] spielt Eis eine entscheidende Rolle für Textur und Temperatur.
        MD
      },
      {
        title: "Shaken vs. Stirred — Die richtige Technik",
        published: true,
        featured: false,
        body: <<~MD
          ## Die Grundregel

          > Shaken, wenn Zitrus, Sahne oder Ei im Spiel ist.
          > Gerührt, wenn alle Zutaten klar und spirituosenbasiert sind.

          Diese Faustregel hat einen physikalischen Grund: Schütteln emulgiert —
          es vermischt Zutaten, die sich sonst trennen würden, und erzeugt dabei
          kleine Luftblasen, die den Drink trüben.

          ## Shaken

          **Wann**: Daiquiri, Margarita, Sours, Cocktails mit Limettensaft, Sirup, Ei
          **Wie**: 10–15 Sekunden kräftig schütteln. Das Eis kühlt und verdünnt gleichzeitig.
          **Ergebnis**: Kalt, leicht trüb, schaumig (bei Ei), emulgiert

          ### Dry Shake vs. Wet Shake
          - **Dry Shake** (ohne Eis, zuerst): Emulgiert Ei besser → mehr Schaum
          - **Wet Shake** (mit Eis, danach): Kühlt und verdünnt

          ## Stirred / Gerührt

          **Wann**: Martini, Manhattan, Negroni, Old Fashioned, alle reinen Spirituosen-Cocktails
          **Wie**: 30–45 Sekunden mit langem Barlöffel im Mixing Glass rühren
          **Ergebnis**: Klar, seidig, kontrolliert verdünnt

          ## Werkzeug & Glaswahl

          Für das Rühren brauchst du ein Mixing Glass — alles andere erklärt der Artikel
          über [[wiki:#{slug[:werkzeug]}|Barwerkzeug]]. Das [[wiki:#{slug[:eis]}|Eis]] bestimmt
          die Verdünnungsrate erheblich: gestoßenes Eis verdünnt beim Shaken deutlich schneller.
          Welches [[wiki:#{slug[:glaeser]}|Glas]] du verwendest, ist die letzte Variable
          in der Präsentationskette — und wird oft unterschätzt. Der [[wiki:#{slug[:daiquiri]}|Daiquiri]]
          ist der ideale Übungscocktail für Shaking-Technik.
        MD
      },
      {
        title: "Gläser — Form folgt Funktion",
        published: true,
        featured: false,
        body: <<~MD
          ## Warum das Glas wichtig ist

          Die Form eines Glases beeinflusst, **wie wir trinken** — die Neigung des Kopfes,
          wohin die Flüssigkeit zuerst auf die Zunge trifft, wie sich Aromen zur Nase stauen.
          Kein Zufall, dass jeder Cocktailstil sein eigenes Glasformat entwickelt hat.

          ## Die wichtigsten Glasformen

          | Glas | Fassungsvermögen | Typischer Cocktail |
          |---|---|---|
          | Coupe | 90–150 ml | Daiquiri, Sidecar, Aviation |
          | Martini-Glas (V-Form) | 120–180 ml | Martini, Cosmopolitan |
          | Rocks / Tumbler | 200–350 ml | Old Fashioned, Whisky On the Rocks |
          | Highball | 250–350 ml | G&T, Mojito, Collins |
          | Collins | 300–400 ml | Tom Collins, Long Island |
          | Nick & Nora | 80–120 ml | Martini, Manhattan (Nosing) |
          | Weinglas (groß) | 400–600 ml | Spritzes, Aperol, Tiki |
          | Mule-Becher (Kupfer) | 300–400 ml | Moscow Mule |

          ## Temperatur & Kühlung

          Gläser vor dem Servieren kühlen: entweder im Tiefkühler oder mit Eiswasser befüllen.
          Ein warmes Glas verdünnt den Cocktail schneller und macht ihn wässriger.

          ## Passung zum Stil

          Der [[wiki:#{slug[:negroni]}|Negroni]] kommt im Rocks-Glas — der große Eiswürfel
          passt zum langsamen Trinktempo. Der [[wiki:#{slug[:gin]}|G&T]] im hohen Highball
          hat Platz für viel Eis und Tonic. Der Old Fashioned wird im [[wiki:#{slug[:old_fashioned]}|gleichnamigen Klassiker]]-Stil
          im Rocks-Glas gereicht. Das [[wiki:#{slug[:werkzeug]}|Mixing Glass]] selbst ist auch ein Glas — es gehört zur Barausstattung.
        MD
      },
      {
        title: "Classic Daiquiri — Anatomie eines Sours",
        published: true,
        featured: true,
        featured_position: 3,
        ingredients: [ rum, lime ].compact,
        body: <<~MD
          ## Der einfachste große Cocktail

          Der Daiquiri besteht aus drei Zutaten — und ist trotzdem einer der komplexesten
          Cocktails, wenn man ihn richtig macht. Er ist die **reinste Form eines Sours**:
          Spirituose, Säure, Süße.

          ## Das Rezept

          ```
          60 ml weißer Rum (kubisch, leicht — z.B. Havana Club 3)
          25 ml frischer Limettensaft
          20 ml einfacher Zuckersirup (1:1)
          ```

          Alle Zutaten mit Eis **kräftig schütteln** (12 Sekunden), doppelt abseihen,
          in eine gekühlte Coupette geben. Ohne Garnitur.

          ## Warum dieser Cocktail so lehrreich ist

          1. **Rum**: Zeigt, wie die Basis alles beeinflusst — probiere den Daiquiri mit
             verschiedenen [[wiki:#{slug[:rum]}|Rum-Stilen]]
          2. **Zitrus**: Der [[wiki:#{slug[:saeure]}|Limettensaft]] muss frisch sein — hier
             gibt es keine Kompromisse
          3. **Süße**: Die [[wiki:#{slug[:sirupe]}|Sirupmenge]] entscheidet über Balance —
             kleine Anpassungen, große Wirkung
          4. **Technik**: Die [[wiki:#{slug[:technik]}|Schütteltechnik]] bestimmt Kälte und Verdünnung

          ## Variationen

          - **Hemingway Daiquiri**: Grapefruitsaft + Maraschino, weniger Sirup
          - **Banana Daiquiri**: Bananenlikör als Teil der Süße
          - **Frozen Daiquiri**: Mit Crushed Ice im Mixer — Hawaii-Bar-Stil

          > Der Daiquiri ist der Lackmustest für einen Barkeeper. Wer ihn perfekt macht,
          > macht fast alles andere auch gut.
        MD
      },
      {
        title: "Negroni — Bittersweet-Klassiker",
        published: true,
        featured: true,
        featured_position: 4,
        ingredients: [ gin ].compact,
        body: <<~MD
          ## Drei gleiche Teile

          Der Negroni ist das mathematisch schönste Rezept der Cocktailwelt: **1:1:1**.
          Gin, Campari, süßer Vermouth — kein Teil dominiert, alles ergänzt sich.

          ## Das Rezept

          ```
          30 ml Gin (London Dry — z.B. Tanqueray, Beefeater)
          30 ml Campari
          30 ml süßer Vermouth (Rosso — z.B. Carpano Antica, Punt e Mes)
          ```

          Alle Zutaten mit Eis **rühren** (30 Sekunden), in ein Rocks-Glas über einen
          großen Eiswürfel abseihen. Mit einer Orangenzeste garnieren.

          ## Geschichte

          Graf Camillo Negroni bat 1919 in der Bar Casoni in Florenz, seinen Americano
          zu verstärken — der Barkeeper ersetzte Sodawasser durch Gin. Der Rest ist Geschichte.

          ## Variationen

          | Name | Änderung |
          |---|---|
          | Americano | Campari + Vermouth + Soda (kein Gin) |
          | Sbagliato | Prosecco statt Gin |
          | White Negroni | Suze + Lillet Blanc statt Campari + Vermouth |
          | Mezcal Negroni | Mezcal statt Gin |
          | Boulevardier | Bourbon statt Gin |

          ## Baukasten verstehen

          [[wiki:#{slug[:gin]}|Gin]] bringt botanische Komplexität.
          [[wiki:#{slug[:vermouth]}|Vermouth]] süßt und bringt Kräuterwürze.
          [[wiki:#{slug[:bitters]}|Bitters]] — hier durch Campari vertreten — verbinden beide.
          Das [[wiki:#{slug[:glaeser]}|Rocks-Glas]] mit großem Würfel ist kein Zufall:
          der Negroni soll langsam getrunken werden.
        MD
      },
      {
        title: "Old Fashioned — Die Urform des Cocktails",
        published: true,
        featured: false,
        body: <<~MD
          ## Das erste Cocktail-Rezept

          1806 definierte das Magazin *The Balance and Columbian Repository* einen Cocktail als:
          "Spirituose, Wasser, Zucker, Bitters." Der Old Fashioned ist diese Definition —
          destilliert auf vier Zutaten.

          ## Das Rezept

          ```
          60 ml [[wiki:#{slug[:whisky]}|Bourbon oder Rye Whisky]]
          1 Teelöffel Zucker (oder 10 ml Rich Syrup)
          2 Dashes Angostura Bitters
          Spritzer Wasser (optional)
          ```

          Zucker und [[wiki:#{slug[:bitters]}|Bitters]] im Glas verrühren, Whisky zugeben,
          mit einem großen Eiswürfel rühren bis kalt. Mit einer Orangenzeste garnieren.

          ## Zucker vs. Sirup

          Traditionell wird ein Zuckerwürfel verwendet. Praktischer ist [[wiki:#{slug[:sirupe]}|Rich Syrup (2:1)]]:
          er löst sich gleichmäßiger auf und gibt mehr Kontrolle über die Süße.

          ## Eis-Philosophie

          Ein klassischer Old Fashioned wird über einem **großen Eiswürfel** serviert —
          er schmilzt langsam und verdünnt das Getränk kontrolliert über 20–30 Minuten.
          Mehr über [[wiki:#{slug[:eis]}|Eisarten und ihre Wirkung]] im Eis-Artikel.

          ## Bourbon vs. Rye

          - **Bourbon**: Süßer, Vanille, Karamell — zugänglicher
          - **Rye**: Würziger, trockener, komplexer — traditioneller
          - **Scotch**: Rauchig, torfig — der "Smoky Old Fashioned"

          > Der Old Fashioned ist kein vereinfachter Cocktail. Er ist ein reduzierter —
          > und das ist etwas ganz anderes.
        MD
      },
      {
        title: "Mojito — Frische & Technik",
        published: true,
        featured: false,
        ingredients: [ rum, lime ].compact,
        body: <<~MD
          ## Kuba in einem Glas

          Der Mojito ist der bekannteste kubanische Cocktail — und einer der am häufigsten
          falsch gemachten. Matschige Minze, zu viel Zucker oder abgepackter Limettensaft
          zerstören, was ein einfaches Rezept eigentlich leicht macht.

          ## Das Rezept

          ```
          50 ml weißer kubanischer Rum
          25 ml frischer Limettensaft
          20 ml einfacher Zuckersirup (1:1)
          8–10 frische Minzblätter
          Soda Water zum Auffüllen
          ```

          Minze und Sirup **sanft** muddlen (nicht zerstampfen — nur aufbrechen).
          Limettensaft und Rum zugeben. Mit gestoßenem [[wiki:#{slug[:eis]}|Eis]] auffüllen,
          vorsichtig schwenken, Soda drauf.

          ## Die Minze-Frage

          Minze nicht zerstampfen — das zersetzt die Zellwände und erzeugt Bitterstoffe.
          Ziel: die ätherischen Öle freisetzen, die Struktur erhalten.

          > Frische Minze am Ende als Garnitur gibt mehr Duft als die Minze im Drink selbst.

          ## Rum-Wahl

          Der [[wiki:#{slug[:rum]}|Rum]] im Mojito soll sich nicht aufdrängen — weißer,
          leichter Rum ist die klassische Wahl. Dunkler Rum ergibt einen "Dark Mojito" mit
          mehr Körper. Wer die [[wiki:#{slug[:saeure]}|Säurebalance]] versteht, kann Limettenmenge
          und Sirup perfekt aufeinander abstimmen.

          ## Die [[wiki:#{slug[:technik]}|Schütteltechnik]] beim Mojito

          Der Mojito wird **nicht geschüttelt** — er wird im Glas gebaut und geschwenkt
          (*swizzled*). Schütteln würde die Minze zu fein verteilen und das Soda verlieren.
        MD
      },
      {
        title: "Batching — Cocktails für Gruppen",
        published: true,
        featured: false,
        body: <<~MD
          ## Warum Batching?

          Für Partys und Events ist das Einzelmixen ineffizient — und stressig.
          **Batching** bedeutet, Cocktails vorab in großen Mengen vorzubereiten.
          Wenn es richtig gemacht wird, ist die Qualität nicht schlechter als Single-Serve.

          ## Was lässt sich batchen?

          Gut geeignet:
          - Stirred drinks ohne Zitrus (Negroni, Manhattan, Old Fashioned)
          - Sours ohne Ei (Daiquiri, Margarita) — Zitrus direkt vor dem Servieren hinzufügen
          - Punches aller Art

          Schlecht geeignet:
          - Cocktails mit Ei (Schaum geht verloren)
          - Drinks mit Soda (Kohlensäure entweicht)
          - Alles mit Minze (oxidiert)

          ## Verdünnung beim Batchen

          Beim Einzelmixen wird im Shaker verdünnt. Im Batch passiert das nicht automatisch —
          deshalb **muss Wasser manuell hinzugefügt werden**.

          Faustregel: **20–25%** des Spirituosen-Volumens als Wasser zugeben.

          ```
          Beispiel Negroni-Batch für 10:
          300 ml Gin
          300 ml Campari
          300 ml Vermouth
          + 200 ml gefiltertes Wasser
          ```

          Das Batch kühl stellen, zum Servieren über Eis gießen oder direkt aus der Karaffe.

          ## Hochskalierung von [[wiki:#{slug[:sirupe]}|Sirupen]]

          [[wiki:#{slug[:rum]}|Rum]]-basierte Batches — etwa Daiquiri-Batches — brauchen
          vorab abgemessenen [[wiki:#{slug[:sirupe]}|Sirup]] und Zitrus.
          Zitrus erst am Tag des Events hinzufügen. [[wiki:#{slug[:fermentation]}|Fermentierte Elemente]]
          wie Wasserkefir oder Kombucha eignen sich gut als Topping beim Servieren.
          Für [[wiki:#{slug[:alkoholfrei]}|alkoholfreie Varianten]] denselben Batch ohne Spirituose zubereiten.
        MD
      },
      {
        title: "Fermentation & Sodawasser in der Bar",
        published: true,
        featured: false,
        body: <<~MD
          ## Fermentation als Barzutat

          Fermentation ist in der modernen Bar weit mehr als Bier und Wein.
          **Kombucha, Wasserkefir, Ginger Beer und fermentierte Sirupe** eröffnen
          Aromenräume, die synthetische Zutaten nicht erreichen.

          ## Wasserkefir

          Wasserkefir ist ein probiotisches, sprudeliges Getränk — leicht säuerlich,
          mit natürlicher Kohlensäure. Als Cocktailbase oder Mixer:

          1. 30 g Wasserkefirkristalle + 30 g Zucker + 500 ml Wasser — 24–48 h fermentieren
          2. Absieben, Zweitfermentation mit Fruchtsaft 12–24 h für mehr Kohlensäure
          3. Kühl lagern, innerhalb von 5 Tagen verbrauchen

          ## Kombucha in Cocktails

          Kombucha bringt **Säure, Tannine und natürliche Kohlensäure** — es ist ein
          Ersatz für Tonic oder Soda mit deutlich mehr Charakter.
          Besonders gut mit Tequila und Mezcal, aber auch mit dunklem [[wiki:#{slug[:sirupe]}|sirupergänztem]] Rum.

          ## Ginger Beer selbst gemacht

          Hausgemachtes Ginger Beer schmeckt intensiver als Fertigprodukt:

          - 50 g frischer Ingwer (gerieben) + 100 g Zucker + 1 l Wasser
          - 1 EL Zitronensaft + 1/8 TL Hefe
          - 24–48 h bei Raumtemperatur gären lassen
          - Filtern, kühl stellen

          ## Verwendung im Batching

          Fermentierte Komponenten eignen sich gut als Topping in [[wiki:#{slug[:batching]}|Batched Cocktails]] —
          erst beim Servieren hinzufügen, um Kohlensäure zu erhalten.
          Für [[wiki:#{slug[:alkoholfrei]}|alkoholfreie Cocktails]] sind sie unverzichtbar:
          sie liefern Komplexität, die Saft allein nicht bringt.
          Fermentierte [[wiki:#{slug[:bitters]}|Shrubs und Bitters]] sind die nächste Stufe.
        MD
      },
      {
        title: "Alkoholfreie Cocktails — Mocktails richtig gemacht",
        published: true,
        featured: false,
        body: <<~MD
          ## Mehr als Fruchtsaft

          Gute alkoholfreie Cocktails kopieren keine alkoholischen Originale — sie bauen
          eigenständige Geschmacksprofile. Das Ziel ist **Komplexität, Balance und Erlebnis**,
          nicht die Imitation von Alkohol.

          ## Die vier Säulen

          1. **Körper**: Alkohol gibt Textur. Ersatz: Tee-Reduktionen, Kombucha, Shrubs, Sahne
          2. **Säure**: Unverändert — [[wiki:#{slug[:saeure]}|Zitrus]] funktioniert ohne Alkohol genauso
          3. **Süße**: [[wiki:#{slug[:sirupe]}|Sirupe]] — infused, fermentiert, komplex
          4. **Bitterkeit**: Alkoholfreie [[wiki:#{slug[:bitters]}|Bitters]] existieren (Bittermens, Seedlip Spice)

          ## Techniken

          ### Verjuice (Verjus)
          Saft unreifer Trauben — herb, komplex, säuerlich ohne Zitrusgeschmack.
          Ideal als Weinersatz in Rezepten.

          ### Shrubs (Drinking Vinegars)
          Frucht + Zucker + Essig = konzentrierter, haltbarer Sirup-Mix.
          Ergibt einen sofort komplexen Drink mit wenig Aufwand.

          ### Seedlip & Co.
          Destillierte alkoholfreie Spirits — teuer, aber überzeugend. Nicht aromatisiertes
          Wasser, sondern echter Kräuterextrakt ohne Alkohol.

          ## [[wiki:#{slug[:fermentation]}|Fermentierte Komponenten]]

          Wasserkefir, Kombucha und Ginger Beer sind die besten Verbündeten für
          alkoholfreie Cocktails — natürliche Kohlensäure, Säure und Tiefe in einem.

          > Der beste alkoholfreie Cocktail ist kein Kompromiss — er ist ein eigenständiges Getränk.
        MD
      },
      {
        title: "Barwerkzeug — Das Einmaleins",
        published: true,
        featured: false,
        body: <<~MD
          ## Was braucht man wirklich?

          Gute Cocktails entstehen nicht durch viel Ausrüstung — sondern durch
          **das richtige Werkzeug, richtig eingesetzt**. Hier ist die Minimalliste,
          die wirklich jeden Cocktailstil abdeckt.

          ## Die Essentials

          | Werkzeug | Zweck | Worauf achten |
          |---|---|---|
          | Boston Shaker | Schütteln | Zwei Teile (Glas + Metall) — dichter als Cobbler |
          | Mixing Glass | Rühren | Dickwandig, schwer, mit Ausguss |
          | Barlöffel | Rühren, Schichten | Langer Stiel, spiralförmig |
          | Jigger (Doppelmessbecher) | Abmessen | 25/50 ml oder 30/60 ml — kein Schätzen |
          | Hawthorne Strainer | Abseihen | Passt auf Boston Shaker |
          | Feinsieb | Doppelt Abseihen | Hält kleine Eispartikel und Fruchtfleisch zurück |
          | Muddler | Zerstoßen | Nicht zu aggressiv — Zerstampfen ≠ Zerquetschen |
          | Zester / Y-Peeler | Zesten schneiden | Scharfe Klinge pflegen |

          ## Was man nicht braucht

          - Elektrischer Shaker (Verlust der Kontrolle über Verdünnung)
          - Vorgefertigte Sour-Mischungen (echten Zitrus verwenden)
          - Messlöffel aus der Küche (zu ungenau für Bararbeit)

          ## Pflege & Qualität

          Gutes [[wiki:#{slug[:eis]}|Eis]] und scharfes Werkzeug sind untrennbar.
          Ein stumpfer Y-Peeler zerreißt Zitrusschalen statt sie sauber abzuziehen.

          Die [[wiki:#{slug[:technik]}|Technik]] entscheidet über Ergebnis — das Werkzeug
          ermöglicht sie nur. Mit dem richtigen [[wiki:#{slug[:glaeser]}|Glas]] und dem
          richtigen Equipment lässt sich ein [[wiki:#{slug[:daiquiri]}|Daiquiri]] in unter
          2 Minuten auf Restaurantniveau zubereiten.
        MD
      }
    ]

    articles.each do |attrs|
      ingredients = attrs.delete(:ingredients) || []
      article = WikiArticle.find_or_initialize_by(title: attrs[:title])
      article.assign_attributes(attrs.merge(user: user))
      if article.new_record?
        article.save!
        ingredients.each { |i| i.update!(wiki_article: article) } if ingredients.any?
        puts "Created: #{article.title}"
      else
        puts "Skipped (exists): #{article.title}"
      end
    end

    puts "\nDone. #{WikiArticle.count} wiki articles total. Visit /wiki"
  end
end
