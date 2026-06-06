namespace :wiki do
  desc "Erstellt Wiki-Leitfaden-Artikel aus dem Barneuling-Thread und verlinkten Beiträgen (idempotent)"
  task seed_guides: :environment do
    authors = {}
    %w[rrr SchuettelStefan zoidberg].each do |username|
      authors[username] = User.find_by(username: username)
      warn "Warnung: Benutzer '#{username}' nicht gefunden." unless authors[username]
    end

    # Strategy: create if new, update if existing article has a shorter body (guide > lexikon stub)
    entries = [

      # ─── Barutensilien ────────────────────────────────────────────────────────
      {
        title: "Barutensilien",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/qVqyJIcq",
        body: <<~MD
          Dieser Leitfaden stellt die wichtigsten Werkzeuge vor, die für die Cocktailzubereitung zu Hause benötigt werden.

          ## Eis

          Eiswürfel sollten mindestens 3 cm Kantenlänge haben, damit sie langsamer schmelzen und den Drink nicht zu schnell verwässern. Beim Kauf von Silikonformen unbedingt auf Lebensmittelqualität achten.

          ## Shaker

          Es gibt zwei Haupttypen:

          **3-teiliger Shaker (Cobbler Shaker):** Besteht aus Becher, integriertem Sieb und Deckel. Für den Heimbereich gut geeignet; günstigere Modelle können sich nach dem Schütteln schwer öffnen lassen.

          **2-teiliger Shaker:** Bietet mehr Flexibilität. Der bekannteste Typ ist der **Boston Shaker** in der Variante Metall + Mischglas oder Metall + Metall. Niemals Modelle mit Gummidichtungen kaufen.

          ## Barsieb

          Beim 2-teiligen Shaker zwingend erforderlich. Zwei bewährte Typen:
          - **[[wiki:hawthorne-strainer|Hawthorne Strainer]]:** Häufigster Typ, mit Federspirale.
          - **[[wiki:julep-strainer|Julep Strainer]]:** Löffelförmig, für das Rührglas.

          ## Jigger

          Für genaues Messen der Zutaten unerlässlich. Der Standard-Jigger ist beidseitig mit 4 cl und 2 cl. Siehe auch [[wiki:barmasse|Barmaße]].

          ## Mixer/Blender

          Für Frozen Drinks und die Verarbeitung von Früchten notwendig.
        MD
      },

      # ─── Gläser ──────────────────────────────────────────────────────────────
      {
        title: "Gläser",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/Td3hzyZf",
        body: <<~MD
          Die Wahl des richtigen Glases beeinflusst Geschmack und Trinkgenuss eines Cocktails erheblich. Eine Übersicht der gängigsten Typen:

          | Glastyp | Inhalt | Verwendung |
          |---|---|---|
          | Longdrink-Glas | 200–450 ml | Drinks mit Eis, Säfte, Tonic |
          | Collins-Glas | 200–350 ml | Schlank und hoch, für Collins-Drinks |
          | Highball / DOF | variabel | Stabil, für einfache Drinks und Muddling |
          | Fancy / Hurricane | 200–450 ml | Exotische Drinks mit Fruchtsäften |
          | Tumbler / Old-Fashioned | 140–300 ml | Kurz, breit, dickwandig |
          | Martini-Glas | 150–220 ml | Klassisches Cocktailglas für Shortdrinks |
          | Margarita-Glas | 200–350 ml | Spezialisiert; kann durch Sekt- oder Martiniglas ersetzt werden |
          | Nosing-Glas | ab 170 ml | Konisch zulaufend, konzentriert Aromen |
          | Tiki Mug | 300–600 ml | Rum- und Tiki-Drinks |
          | Shot-Glas | 40–60 ml | Für Kurzdrinks wie B-52 |

          ## Unverzichtbare Grundausstattung

          Wer kompakt starten möchte, kommt mit diesen vier Typen weit:
          - Longdrink-Glas
          - Martini-Glas
          - Tumbler
          - Nosing-Glas
        MD
      },

      # ─── Alkoholfreie Zutaten ─────────────────────────────────────────────────
      {
        title: "Alkoholfreie Zutaten",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/D3esYm5r",
        body: <<~MD
          ## Säfte

          Die Qualitätshierarchie bei Säften ist entscheidend für das Ergebnis im Glas:

          1. **Frisch gepresst** – Höchste Qualität, besonders bei Zitrusfrüchten unverzichtbar.
          2. **100 % Direktsaft** – Nicht aus Konzentrat, gute Alternative wenn frisches Pressen nicht möglich ist.
          3. **100 % Konzentrat** – Voller Fruchtgehalt, aber durch Eindampfung und Haltbarmachung spürbar schlechter.
          4. **Nektar (mind. 25 % Fruchtanteil)** – Nur akzeptabel, wenn kein Saft erhältlich ist. Relevant bei: Passionsfrucht, Mango, Pfirsich, Aprikose, Kirsche, Erdbeere.
          5. **Fruchtsaftgetränke (unter 25 %)** – Nicht empfehlenswert; fehlt an Qualität und Aroma.

          Für den Kauf gilt: Den Saft wählen, der pur am besten schmeckt und im eigenen Handel gut erhältlich ist.
        MD
      },

      # ─── Sirup ───────────────────────────────────────────────────────────────
      {
        title: "Sirup",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/3DVpC7Zb",
        body: <<~MD
          Die Eigenherstellung von Sirup ist gerade für Gelegenheitsmixer oft unpraktisch: Der Aufwand ist hoch und die Haltbarkeit frischer Fruchtsirupe begrenzt.

          **Bar-Sirupe** bieten in der Regel bessere Lösungen: längere Haltbarkeit, homogene Konsistenz und Optimierung für den Einsatz als Mixer.

          In Deutschland weit verbreitete und empfehlenswerte Marken sind **Riemerschmid** und **Monin**.

          Für selbst hergestellte Grundsirupe ohne Frucht empfehlen sich [[wiki:simple-syrup|Simple Syrup]] (1:1) und [[wiki:rich-syrup|Rich Syrup]] (2:1).
        MD
      },

      # ─── Spirituosen Allgemein ────────────────────────────────────────────────
      {
        title: "Spirituosen – Allgemeine Tipps",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/LI0Gaf1h",
        body: <<~MD
          ## Qualität beim Kauf

          Es empfiehlt sich, Spirituosen unter 5 € aus dem Supermarkt zu meiden. Die Qualität variiert je nach Spirituosenart und Verwendungszweck erheblich.

          ## Kein Allzweckdestillat

          Es gibt keinen Rum oder Whiskey, der für alle Cocktails optimal geeignet ist. Für spezifische Rezepte eignen sich bestimmte Spirituosen deutlich besser als andere.

          ## Reifung

          Destillation und Fassreifung beeinflussen Geschmack und Textur erheblich. Gelagerte Spirituosen entwickeln durch die Wechselwirkung mit dem Holz Weichheit und Charakter. Längere Reifung rechtfertigt allerdings nicht automatisch höhere Preise, besonders nicht bei der Verwendung im Cocktail.
        MD
      },

      # ─── Vodka ───────────────────────────────────────────────────────────────
      {
        title: "Vodka",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/ecp1xQsx",
        body: <<~MD
          Vodka ist eine Spirituose, die aus beliebigen kohlenhydrathaltigen Rohstoffen mit mindestens 37,5 % Alkohol destilliert wird. Hochwertige Wodkas werden vorwiegend aus Roggen (Russland, Polen) oder Weizen (westliche Produzenten) hergestellt, gelegentlich aus Kartoffeln.

          Durch mehrfache Destillation und Filtration ist Vodka theoretisch geschmacksneutral – gute Wodkas besitzen jedoch subtile charakteristische Eigenschaften. Östliche Varianten tendieren zu milden, leicht süßlichen Profilen, westliche Produkte bieten alternative Ausprägungen.

          ## Empfehlungen (unter 15 €/0,7 l)

          **Östliche Produzenten:**
          - Russian Standard
          - Parliament
          - Wyborowa

          **Westliche Produzenten:**
          - Absolut
          - Smirnoff
          - Danzka
          - Finlandia

          ## Bekannte Cocktails
          [[wiki:bloody-mary|Bloody Mary]], Caipirovka, [[wiki:cosmopolitan|Cosmopolitan]], [[wiki:moscow-mule|Moscow Mule]], Sex On The Beach, Vodka [[wiki:martini|Martini]]
        MD
      },

      # ─── Gin ─────────────────────────────────────────────────────────────────
      {
        title: "Gin",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/SSCU7FTL",
        featured: true, featured_position: 3,
        body: <<~MD
          Gin ist ein Getreidedestillat, das während der Destillation mit verschiedenen Gewürzaromen angereichert wird. Allen Gins gemeinsam ist der Wacholder (*Juniperus communis*). Es empfiehlt sich, Varianten mit über 40 % Alkohol zu kaufen – höherprozentige Abfüllungen bieten spürbar vollere, rundere Geschmacksprofile als 40-%-Varianten.

          ## Kategorien

          | Kategorie | Charakter |
          |---|---|
          | Dry / London Dry | Trocken |
          | Old Tom | Leicht süßlich |
          | Plymouth | Süßlich und würzig |

          Die Wacholder-Intensität variiert erheblich zwischen den Kategorien.

          ## Empfehlungen London Dry (unter 15 €/0,7 l)
          - Finsbury Platinum – 47 %
          - Finsbury – 60 %
          - Beefeater – 47 %
          - Tanqueray – 47,3 %
          - Bombay Sapphire – 47 %

          ## Premium (ab 20 €/0,7 l)
          - Beefeater 24 – 45 %
          - The Duke – 45 %
          - Tanqueray No. Ten – 47,3 %
          - Lebensstern – 43 %
          - Both's Old Tom – 47 %
          - Plymouth Gin – 41,2 %

          ## Bekannte Cocktails
          [[wiki:aviation|Aviation]], [[wiki:gimlet|Gimlet]], Gin Basil Smash, [[wiki:gin-fizz|Gin Fizz]], [[wiki:gin-tonic|Gin Tonic]], Martinez, [[wiki:martini|Martini]], Singapore Sling, White Lady
        MD
      },

      # ─── Whisky ──────────────────────────────────────────────────────────────
      {
        title: "Whisky und Whiskey",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/LSbjcA1e",
        featured: true, featured_position: 2,
        body: <<~MD
          Die Schreibweise gibt Hinweis auf die Herkunft: **Whisky** (Schottland, Kanada) – **Whiskey** (Irland, USA).

          ## Destillatkategorien

          **Malt Whisky** wird aus gemälzter Gerste von einer einzigen Brennerei hergestellt und genießt die höchste Wertschätzung unter Trinkern. Siehe [[wiki:single-malt|Single Malt]].

          **Grain Whisky** (Weizen, Roggen, ungemälzte Gerste, Hafer, Mais) wird selten pur abgefüllt und dient hauptsächlich zum Verschneiden mit Malts. **Blended Whisky** bietet gleichbleibende Aromen – von Vorteil für konsistente Cocktails.

          ## Schottischer Whisky
          Regionsabhängige Aromenprofile von mild bis rauchig ([[wiki:peated|Peated]]). Sechs anerkannte Regionen.

          ## Irischer Whiskey
          Milder als schottische Pendants, da Gerste nicht über Torf gedarrt wird und dreifach destilliert wird.

          ## Amerikanische Whiskys

          | Typ | Besonderheit |
          |---|---|
          | [[wiki:bourbon|Bourbon]] | Mind. 51 % Mais, süßlich-mild |
          | [[wiki:rye-whiskey|Rye Whiskey]] | Mind. 51 % Roggen, würzig |
          | Tennessee | Sonderfilterung (Lincoln County Process), weich und mild |
          | Corn Whiskey | Nahezu neutral, hauptsächlich zum Blenden |

          ## Empfehlungen Einstieg (ca. 20 €/0,7 l)
          - Glenfiddich 12 Jahre
          - Clontarf Irish Malt
          - Jim Beam Black
          - Jim Beam Rye
          - Jack Daniel's No. 7
          - Black Velvet Reserve
          - Glenlivet 12 Jahre
          - Jameson Irish Whiskey
          - Tyrconnell Single Malt

          ## Premium
          - Ardmore Fully Peated
          - Connemara Irish Malt
          - Elijah Craig
          - Lot No. 40
          - Deanston Virgin Oak
          - Wild Turkey 101
          - Glenmorangie The Original
          - Talisker 10 Jahre

          ## Bekannte Cocktails
          Blood and Sand, [[wiki:manhattan|Manhattan]], [[wiki:old-fashioned|Old Fashioned]], [[wiki:whiskey-sour|Whiskey Sour]], Hot Toddy, Irish Coffee, [[wiki:mint-julep|Mint Julep]], Rob Roy, Rusty Nail
        MD
      },

      # ─── Weißer Rum ──────────────────────────────────────────────────────────
      {
        title: "Weißer Rum",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/AEiAj1OF",
        body: <<~MD
          Zuckerrohr stammt ursprünglich aus Papua-Neuguinea und gelangte über Spanien in die Karibik, wo das Klima optimale Anbaubedingungen bot. Als Nebenprodukt der Zuckerproduktion entstand [[wiki:melasse|Melasse]] – ein vergärbarer Rückstand mit verbleibenden Zuckeranteilen. Die Melasse wird mit Hefe und Wasser vergärt und anschließend destilliert.

          Aus ca. 15 Litern Maische entsteht 1 Liter Rum.

          ## Destillationsverfahren

          **[[wiki:pot-still|Pot Still]]** (diskontinuierlich): Arbeitsintensiv, erzeugt Destillat mit hohem Ester- und Aldehydgehalt („schwere" Rums).

          **Column Still** (kontinuierlich, [[wiki:coffey-still|Coffey Still]]): Reineres Destillat mit reduziertem Ester-/Aldehydgehalt („leichte" Rums).

          ## Rhum Agricole

          [[wiki:agricole|Rhum Agricole]] wird direkt aus frisch gepresstem Zuckerrohrsaft hergestellt – nicht aus Melasse. Hauptsächlich in den ehemaligen französischen Kolonien produziert. Deutlich anderes Geschmacksprofil als Melasse-Rums.

          ## Bezeichnungen nach Herkunft
          - **Ron** – spanischsprachige Länder
          - **Rhum** – französischsprachig (technisch: Rhum Agricole)
          - **Rum** – englischsprachig

          ## Empfehlungen (bis 20 €/0,7 l)
          - Havana Club Añejo Blanco 37,5 %
          - Saint James Imperial Blanc Agricole 40 %
          - El Dorado White 37,5 %
          - La Mauny Rhum Blanc Agricole 50 %
          - Appleton White 40 %
          - Barbancourt White 40 %
          - Cartavio Silver 40 %

          ## Premium
          - Clément Rhum Agricole Blanc 50 %
          - J.M. Rhum White 50 %

          ## Bekannte Cocktails
          [[wiki:daiquiri|Daiquiri]], Frozen Daiquiri, [[wiki:pina-colada|Piña Colada]], [[wiki:mojito|Mojito]], Cuba Libre, El Presidente, Ti Punch
        MD
      },

      # ─── Dunkler Rum ─────────────────────────────────────────────────────────
      {
        title: "Dunkler Rum",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/6B70hcZ6",
        body: <<~MD
          Klares Destillat erhält seine dunkle Farbe durch Fasslagerung von über 3 Jahren. Auch als Gold Rum bezeichnet.

          ## Fassreifung

          Holzfässer interagieren mit dem Rum: Das Holz absorbiert Öle und Alkohol, während es gleichzeitig Tannine und Aromastoffe abgibt, was den Rum weicher und dunkler werden lässt. Die Stärke beim Einlagern beeinflusst Absorption und [[wiki:angel-s-share|Angel's Share]].

          Heute werden häufig Gebrauchtfässer aus der [[wiki:whisky|Whisky]]-, [[wiki:cognac|Cognac]]-, [[wiki:sherry|Sherry]]-, Porto- und Weinproduktion verwendet. Ausgekohlte Fässer intensivieren Eichenaromen und produzieren dunklere Farben.

          ## Reifungsmethoden

          - **Single Cask:** Nur ein einziges Fass wird abgefüllt.
          - **First/Second/Third Fill:** Das Destillat wechselt nacheinander in verschiedene Fässer.
          - **[[wiki:solera|Solera]]:** Mehrere Fassreihen übereinander; ältestes Destillat in der untersten Reihe wird entnommen und durch jüngeres aus oben aufgefüllt.

          ## Hinweis zu Farbstoffen

          Manche Produzenten fügen Zuckerkulör (Karamellfarbe) hinzu, um längere Reifung vorzutäuschen. Dies ist weit verbreitet, aber kein Qualitätsmerkmal.

          ## Empfehlungen (bis 20 €/0,7 l)
          - Appleton Estate V/X 40 %
          - Barbancourt Three Stars 40 %
          - Flor de Caña Black Label 5 Años 40 %
          - Malecon Gran Reserva 8 Años 40 %
          - Old Pascas Jamaica 40 %
          - Hampden Estate Jamaica Gold 40 %
          - Saint James Rhum Agricole Royal Ambré 45 %

          ## Premium
          - Clément Rhum Vieux VSOP 40 %
          - Doorly's Fine Old 5 Años 40 %
          - J. Bally Rhum Ambré 45 %
          - Pampero Aniversario 40 %
          - Appleton Estate Extra 12 Años 43 %
          - Lemon Hart 151 Overproof Demerara 75,5 %

          ## Bekannte Cocktails
          [[wiki:mai-tai|Mai Tai]], Last Rites, Rum Sour, Painkiller, Dark 'n' Stormy, Añejo Highball, Zombie
        MD
      },

      # ─── Cachaça ─────────────────────────────────────────────────────────────
      {
        title: "Cachaça",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/7rup7eFi",
        body: <<~MD
          Brasilianisches Destillat aus kalt gepresstem Zuckerrohrsaft mit 38–48 % Alkohol. Verwandt mit [[wiki:agricole|Rhum Agricole]], aber kein direktes Äquivalent – eigene Produktionsregeln und Charakter.

          ## Varianten

          - **Prata (Silber):** Ungereift oder kurz gelagert.
          - **Gereift:** Fasslagerung verleiht Weichheit und Holzaromen. Eine zu lange Reifung überdeckt jedoch die frischen Zuckerrohrnoten.

          Die Bezeichnung **Artesanal** steht für traditionelle handwerkliche Produktion.

          ## Empfehlungen
          - Velho Barreiro Silver / Gold
          - Delicana Silver / Gold / Premium
          - Nega Fulo
          - CanaRio

          ## Premium
          - Ypioca Special Reserve 150
          - Leblon
          - Armazem Vieira Safira

          ## Bekannte Cocktails
          [[wiki:caipirinha|Caipirinha]], Batida de Ananás, Tradicional Caipirinha
        MD
      },

      # ─── Tequila ─────────────────────────────────────────────────────────────
      {
        title: "Tequila",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/1X6UGsPe",
        featured: true, featured_position: 1,
        body: <<~MD
          ###Agavendestillate

          **Tequila**

          Tequila ist wohl die am häufigsten falsch eingestufte Spirituose, die es gibt. Auch finden sich immer wieder Vorurteile, die dieser tollen Spirituose einfach nicht gerecht werden.

          Nein, Tequila ist kein Kaktusschnaps und nein, er wird auch nicht mit einem Wurm in der Flasche verkauft. Letzteres kommt bei seinen Mezcalgeschwistern zwar durchaus vor (allerdings auch nur bei den nicht so hochwertigen), dient aber entgegen anderslautender Aussagen nicht der Würze, sondern ist dort nur ein reiner Marketinggag. Außerdem ist es auch kein Wurm, sondern die Larve eines Falters, die in den Agaven lebt. In einem Tequila werdet Ihr jedoch nie eine solche Larve vorfinden. Auch ist er alkoholisch nicht stärker, als jede andere Spirituosenart auch und ebenso hat er auch keine anderen alkoholischen Wirkungen, als die anderen. Die Trinkstärke liegt in der Regel bei 40%.

          Tequila ist technisch gesehen ein Mezcal, allerdings mit einigen Besonderheiten. Mezcal ist ein Destillat, welches aus Agaven ausschließlich in Mexiko hergestellt wird. Agaven gehören nicht zu den Kakteen, wie immer noch viele glauben, sondern zu den Sukkulenten. Wir wollen jetzt jedoch nicht zu weit ins Reich der Botanik abschweifen. Was unterscheidet nun Tequila von den anderen Mezcals?

          Nun, in allererster Linie sind es erst mal die Agaven selbst. Tequila darf nur aus einer bestimmten Agavensorte hergestellt werden und zwar aus der "Agave Tequilana Weber, var. blau", oder kurz "agave azul". Soviel erst mal zur Kaktussaftlegende. Im Weiteren hebt sich auch der Verarbeitungsprozess maßgeblich von dem der Mezcals ab. So wird die Tequilaagave unter Dampfdruck gegart, während die Mezcalagave geröstet wird. Auch hier verzichten wir mal auf weitere Details.

          Feld mit blauer Agave

          Außerdem entscheidet der Herkunftsort der Agaven darüber, ob aus ihnen Tequila hergestellt werden kann. Ähnlich wie beim Cognac sind der Tequilaagavenanbau und die Tequilaherstellung regional eng abgegrenzt. Ganze 5 Provinzen, alle in der südlichen Mitte Mexikos liegend, dürfen Tequila herstellen. Das Zentrum sind die Städte Tequila und Guadelajara in der Provinz Jalisco. Tequila darf nur maximal 49% Fremdzucker enthalten und muss somit zu mindestens 51% aus Agave Azul hergestellt sein.

          Tequilas dieser Zusammensetzung bezeichnet man als Mixtos. Diese wurden erfunden um den Massenmarkt mit möglichst kostengünstiger Ware zu bedienen. Den Tequila mit dem roten Sombrero kennen sicher einige von Euch. Auch er gehört zu dieser Tequilakategorie. Diese Tequilas dürfen auch außerhalb Mexicos abgefüllt werden. Die Qualität der meisten Mixtos läßt oft zu wünschen übrig. Wirklich gute Tequilas erhält man nur mit Destillaten, die zu 100% aus Agavezuckern hergestellt wurden.

          Diese Qualität wird auf der Flasche in Formulierungen wie 100% de Agave, 100% Puro de Agave, 100% Agave Azul oder auch einfach nur 100% Agave angegeben. Fehlt dieser Hinweis, handelt es sich um einen Mixto. 100% Agave Tequila darf ausschließlich nur in Mexico abgefüllt werden. Außerdem findet Ihr weitere Kontrollsymbole in Form eines NOM-Etiketts (kennzeichnet die Destillerie in welcher der Tequila hergestellt wurde) und eine CRT-Etikett (garantiert, dass der Tequila während der gesamten Produktion behördlich kontrolliert wurde).

          Fehlt eine dieser Markierungen oder wird Euch gar angeblicher 100% Agave Tequila in einer abgefüllten Apothekerflasche angeboten, dann Hände weg davon. Im günstigsten Fall ist es ein Mixto, im schlechtesten Fall irgendwas Gepanschtes. In keinem Fall jedoch ein 100% Agave Tequila.

          Tequilas werden jedoch nicht nur über ihren Agavengehalt klassifiziert, sondern auch über ihr Alter, was direkten Einfluß auf ihren Charakter hat. Die reinste Form des Agavengeschmacks findet sich bei Blanco-, Plata- oder Silvertequila. Wobei im Prinzip alle 3 Bezeichnungen das gleiche bedeuten. Diese Tequilas sind entweder direkt nach der Destillation abgefüllt oder nur sehr kurz gelagert (maximal 60 Tage). Dadurch sind es die authentischsten, für manchen Gaumen aber eben auch die schärfsten Tequilas.

          Tequilas, welche länger als 60 Tage, jedoch weniger als 1 Jahr gelagert werden, bezeichnet man als Reposado. Sie sind durch die Lagerung in ihrem Auftritt deutlich weicher als ihre weißen Geschwister, bieten aber immer noch einen guten Agavegeschmack. Auch agavefremde Aromen aus den Fasshölzern finden sich im Geschmacksbild dieser Tequilas.

          Die dritte Form sind die gealterten Tequilas, genannt Anejo. Diese Tequilas werden bis zu 3 Jahren in Eichenfässern gelagert. Dabei nehmen die Destillate natürlich wesentlich mehr Holzaromen auf als bei der relativ kurzen Lagerzeit der Reposados. Bei einigen Anejo Tequilas ist die Balance leider aus dem Ruder gelaufen. Die Holznoten überwiegen und drängen den Agavegeschmack in den Hintergrund. Nur sehr gute Anejos meistern die Gratwanderung und bieten eine gute Balance zwischen Weichheit, Holz- und Agavearomen. Wer Tequila wirklich kennenlernen will, sollte nicht mit einem Anejo einsteigen.

          Für gewöhnlich dienen Anejos eher dem Purgenuss. Es ist allerdings durchaus möglich, eine ansprechende Margarita auch mit einem Anejo Tequila zuzubereiten. Einige Hersteller versuchten und versuchen sich an zusätzlichen Reifezyklen oder anderen Fasssorten und bedenken ihre so gealterten Destillate mit Bezeichnungen wie "Muy Anejo", "Extra Anejo", "Barrique", "Selection Suprema" und so weiter, um sie von den Anejos sprachlich abzuheben. Diese Bezeichnungen sind jedoch nicht durch die CRT standardisiert und werden praktisch wahlfrei eingesetzt. Es handelt sich bei diesen Destillaten also weiterhin um Tequila Anejo.

          Man sollte dabei auch folgendes bedenken. Tequilas profitieren im Gegensatz zu anderen gelagerten Destillaten, wie Cognac, Whisky und Rum, nicht von immer längeren Lagerzeiten. Insofern sollte man gut prüfen, ob man bereit ist die teils exorbitanten Preise dieser Super-Premium-Tequilas zu bezahlen.

          Eine Kategorie fand bisher jedoch noch gar keine Erwähnung, die der sogenannten Joven oder Gold Tequilas. Das hat auch einen guten Grund. Mit dieser Bezeichnung werden nur Mixtos versehen, die keiner Lagerung, aber dafür einer Manipulation mit Zuckercouleur und/oder Holzspänen unterzogen wurden. Damit will man künstlich eine Weichheit generieren, ohne den Aufwand der Lagerung betrieben zu haben und somit dem Kunden quasi Reposadoqualität suggerieren. Für den wahren Tequilafreund stellen diese Tequilas jedoch keine wirkliche Option dar.

          Zum Schluss noch eine Anmerkung. Es hat sich in der Vergangenheit immer wieder gezeigt, dass Tester Tequilarezepte als schlecht eingestuft haben, weil sie einfach zum falschen Tequila gegriffen haben. Wenn man erst mal den falschen hatte, fällt es schwer, noch einmal Geld für eine Spirituosengattung auszugeben, die scheinbar nicht lecker ist. Bitte tut Euch selbst einen Gefallen und versucht möglichst mit dem Herradura Plata die Welt der Tequilas zu betreten. Ich weiß, er kommt nicht mit dem Preis daher, den sich ein Einsteiger für eine Mixspirituose vorstellt oder erhofft. Aber erst wenn Ihr diesen Tequila probiert habt und Euch der Geschmack nicht überzeugt, bin ich bereit anzunehmen, daß Tequila nicht "Eure" Spirituose ist. Wenn Ihr aber Gefallen an ihm findet, dann werdet auch Ihr bald mit dem Tequilavirus infiziert sein und von da an werden sicher noch viele andere Tequilas den Weg in Euer Glas finden. Sicher auch noch preisintensivere als der Herradura. Empfehlungen dazu könnt Ihr jederzeit im Forum erhalten.

          Einsteigertequilas bis 20€ / 0,7Liter:
          - Sauza Hornitos Blanco / Reposado
          - el Jimador Blanco / Reposado

          bis 30€ / 0,7Liter:
          - Herradura Plata / Reposado
          - Milagro Silver / Reposado

          Mit den Sauza Hornitos Tequilas lassen sich sehr gut Cocktails mit starker Fruchtausprägung (besonders Zitrusfrüchte), aber trotzdem noch hohem Tequilagehalt zubereiten. Als Beispiel sei hier der [[recipe:tequila-sunrise]] genannt, in dem der Sauza Hornitos Reposado einen sehr guten Job macht, oder auch der [[recipe:guavia-civil]].

          Die el Jimador Tequilas eignen sich sehr gut für Rezepte mit etwas weniger starker Fruchtausprägung, aber sattem Agaveauftrag wie zum Beispiel die [[recipe:margarita]], auch deren zahllose Frucht- und Frozenversionen wie [[recipe:apfel-ingwer-margarita]]. Aber auch Drinks, in denen Tequila nur eine Gastrolle zu spielen scheint, gelingen damit recht gut und der Tequila geht nicht unter. So zum Beispiel der [[recipe:el-manito]] oder auch der [[recipe:prince]].

          In der etwas gehobeneren Preisklasse, sind die Herradura- und Milagro-Tequila echte Allrounder. Besonders universell jeweils der Herradura Plata und der Milagro Reposado. Mit ihnen gelingen die meisten Tequilarezepte.
        MD
      },

      # ─── Brandy, Cognac und Armagnac ─────────────────────────────────────────
      {
        title: "Brandy, Cognac und Armagnac",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/fra5XQS2",
        body: <<~MD
          Traubendestillate: [[wiki:weinbrand|Weinbrand]] (dt.), Brandy (engl.). Entstehen aus Wein oder Traubenmaische, nicht aus Trester (→ [[wiki:grappa|Grappa]], [[wiki:tresterbrand|Tresterbrand]]).

          ## Brandy de Jerez

          Geschützte Herkunftsbezeichnung aus Andalusien (Dreieck Jerez de la Frontera, El Puerto de Santa María, Sanlúcar de Barrameda). Charakteristisch: Schokoladenaromen, [[wiki:solera|Solera]]-Reifung in Sherryfässern – verschiedene Jahrgänge werden kontinuierlich verschnitten, daher keine Jahrgangskennzeichnung.

          | Klasse | Mindestlagerung |
          |---|---|
          | Solera | 6 Monate |
          | Solera Reserva | 1 Jahr |
          | Solera Gran Reserva | 3 Jahre |

          ## Cognac

          Frankreichs bekanntester Weinbrand mit geschützter Herkunftsbezeichnung. Produktion auf sechs Regionen rund um die Stadt Cognac begrenzt: Grande Champagne, Petite Champagne, Borderies, Fins Bois, Bons Bois, Bois Ordinaires.

          *Fine Champagne* erfordert mind. 50 % Trauben aus der Grande Champagne, Rest Petite Champagne.

          | Klassifizierung | Mindestreife |
          |---|---|
          | V.S. (Very Special) | 2 Jahre |
          | V.S.O.P. | 4 Jahre |
          | X.O. (Extra Old) | 6 Jahre |

          Für Cocktails sind V.S.O.P.-Abfüllungen völlig ausreichend.

          ## Armagnac

          Historisch älterer Weinbrand aus der Gascogne (Gers, Landes, Lot-et-Garonne). Einmalig destilliert, charakteristisch rustikaler als Cognac.

          Zusätzlich zur Cognac-Klassifikation: **Hors d'âge** (mind. 10 Jahre).

          ## Empfehlungen Brandy (bis 20 €/0,7 l)
          - Carlos III
          - Osborne Veterano
          - Osborne 103
          - Torres 10

          ## Empfehlungen Cognac (ca. 30 €/0,7 l)
          - Courvoisier V.S.O.P.
          - Otard V.S.O.P.
          - Rémy Martin V.S.O.P.

          ## Bekannte Cocktails
          B&B, Between the Sheets, Brandy Alexander, [[wiki:brandy-crusta|Brandy Crusta]], [[wiki:sidecar|Sidecar]], Stinger
        MD
      },

      # ─── Pisco ───────────────────────────────────────────────────────────────
      {
        title: "Pisco",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/fra5XQS2",
        body: <<~MD
          Südamerikanischer Weinbrand aus Peru oder Chile – die Frage der Herkunft ist zwischen beiden Ländern seit Jahrhunderten umstritten. Wird aus Traubensaft (nicht Trester) destilliert. Peru lässt nur einfache Destillation auf 40 % zu.

          ## Klassifizierungen (Peru)

          | Typ | Beschreibung |
          |---|---|
          | Pisco Puro | Aus einer einzigen Traubensorte |
          | Pisco Acholado | Aus zwei oder mehr Sorten |
          | Pisco Mosto Verde | Fermentation wird vorzeitig unterbrochen – süßer, weicher |

          ## Bekannte Cocktails
          [[wiki:pisco-sour|Pisco Sour]], Pisco Punch, Judgment Day
        MD
      },

      # ─── Obstbrände ──────────────────────────────────────────────────────────
      {
        title: "Obstbrände",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/WckvbYIT",
        body: <<~MD
          Alpine Tradition mit Anfängen im 15. Jahrhundert, professionalisiert im 19. Jahrhundert. Destillation aus Einzel- oder Mischobst ([[wiki:obstler|Obstler]]). Mindestalkohol: 37,5 %.

          ## Kategorien

          **Wässer** (Kernobst-Destillate): Hoher natürlicher Zuckergehalt; typisch für Apfel, Birne, Kirsche. Entstehen direkt aus vergorenem Obst.

          **Geister** (Beerenobst-Destillate): Erfordern Zugabe von Neutralalkohol wegen des geringen natürlichen Zuckergehalts; z. B. Himbeergeist, Brombeergeist.

          [[wiki:kirschwasser|Kirschwasser]] ist ein wichtiger Cocktailzutat, z. B. im Singapore Sling.

          ## Empfehlungen
          - Pascall
          - Weingut Markus Görgen
          - Schladerer

          ---

          ## Calvados

          Apfelbrand mit geschützter Herkunftsbezeichnung aus der Normandie. Die Region **Pays d'Auge** gilt als Spitze der Qualitätspyramide.

          **Historisches:** Erste regulatorische Erwähnung 1553; der Name „Calvados" entstand erst später. Nach der Französischen Revolution (1789) begünstigte Steuererleichterungen die Hausbrennerei, bevor erst nach dem Zweiten Weltkrieg das Premiumimage etabliert wurde.

          **Produktion:** 48 autorisierte Apfelsorten werden zu Cidre vergoren, 1–2 Jahre Holzlagerung, anschließend zweifache Destillation, erneute Fassreifung.

          | Klassifizierung | Reifezeit |
          |---|---|
          | V.O. / V.S. | mind. 2 Jahre |
          | V.S.O.P. | mind. 4 Jahre |
          | X.O. / Hors d'âge | mind. 6 Jahre |

          ## Empfehlungen Calvados (ca. 15 €/0,7 l)
          - Papidoux V.S.O.P.
          - Père Magloire Fine

          ## Premium
          - Papidoux X.O.
          - Père Magloire V.S.O.P.

          ## Bekannte Cocktails
          After All, Jack Rose, Tulip
        MD
      },

      # ─── Liköre ──────────────────────────────────────────────────────────────
      {
        title: "Liköre",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/ABPOc8gf",
        body: <<~MD
          Alkoholische Getränke mit mindestens 100 g Zucker pro Liter und 15–40 % Alkohol. Ursprünge im Mittelalter, als Klöster Liköre als Medizin herstellten (Bénédictine, Chartreuse werden heute noch in Klöstern produziert).

          ## Kategorien

          ### Fruchtliköre / Curaçaos
          Auf Basis von Bitterorangen. Trockene Varianten (**[[wiki:triple-sec|Triple Sec]]**, z. B. Cointreau, Grand Marnier) erreichen über 40 % Alkohol – unverzichtbar für [[wiki:cosmopolitan|Cosmopolitan]], [[wiki:margarita|Margarita]], [[wiki:sidecar|Sidecar]]. [[wiki:blue-curacao|Blue Curaçao]] ist die künstlich blau gefärbte Variante (20–25 %).

          ### Crème de Fruits
          Fruchtliköre mit mind. 250 g Zucker pro Liter (Himbeere, Brombeere, Erdbeere, schwarze Johannisbeere), 15–20 % Alkohol.

          ### Kakaoliköre
          [[wiki:creme-de-cacao|Crème de Cacao]] (weiß und braun), außerhalb der Crème-de-Fruits-Kategorie.

          ### Kräuterliköre
          Ab 40 % Alkohol, Chartreuse Verte kann 55 %+ erreichen. Vanille-Kräuter-Varianten: Likör 43, Galliano Vanilla. Gewürzliköre: [[wiki:falernum|Falernum]] (Rum, Nelken, Ingwer, Piment) – unverzichtbar für Tiki-Cocktails.

          ## Kaufstrategie

          Liköre gezielt nach benötigten Rezepten kaufen, nicht nach Vollständigkeit einer Kategorie.

          ## Qualitätsproduzenten
          - Giffard, Marie Brizard (ca. 15 €/0,7 l)
          - Cartron, Boudier (ca. 20 €/0,7 l)

          ## Einzelempfehlungen
          - Amaretto: Disaronno
          - Anise: Pernod
          - Falernum: The Bitter Truth
          - Kaffee: Kahlúa
          - Kirsche: Cherry Heering
          - Kokos: Batida de Coco, Malibu
          - Kräuter: Bénédictine D.O.M.
          - Maraschino: Luxardo
          - Triple Sec: Cointreau, Grand Marnier Triple Sec
          - Vanille: Galliano Vanilla, Likör 43
        MD
      },

      # ─── Absinth ─────────────────────────────────────────────────────────────
      {
        title: "Absinth",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/qKdcnPi7",
        body: <<~MD
          Kräuterdestillat aus Anis, Fenchel und Wermut sowie weiteren Botanicals, 45–80 % Alkohol. Wird in Cocktails tropfenweise eingesetzt – viele Rezepte geben genaue Tropfenmengen vor.

          ## Geschichte und Thujon-Mythos

          Die Popularität im 19. und frühen 20. Jahrhundert führte zu fälschlichen Annahmen über gesundheitliche Schäden durch [[wiki:thujon|Thujon]] (Wermutkomponente). In Wirklichkeit verursachten Überkonsum und schlechte Qualität den schlechten Ruf, nicht das Thujon. Die EU begrenzt Thujon auf 35 mg/kg – weit unterhalb schädlicher Konzentrationen. Nicht das Thujon, sondern der hohe Alkoholgehalt erklärt negative Wirkungen bei Überkonsum.

          Legalisierung: Deutschland 1991, USA 2007.

          ## Geschmacksprofile

          - **Anisbetonter Absinth:** Ähnelt Pernod/Pastis, traditionell mit Zuckerwürfel und Wasser serviert.
          - **Wermutzentrierter Absinth:** Für Personen mit Abneigung gegen Anis.

          ## Cocktailverwendung

          Absinth harmoniert hervorragend mit [[wiki:gin|Gin]], [[wiki:whisky|Whisky]], [[wiki:cognac|Cognac]] und [[wiki:vermouth|Vermouth]]. Manche Rezepte verwenden ihn nur zum Ausspülen des Glases (*Rinse*), z. B. [[wiki:sazerac|Sazerac]] und Corpse Reviver No. 2.

          ## Kauftipps

          Qualitätsabsinthe sind selten unter 30 € erhältlich und oft in größeren Flaschen abgefüllt. Pernod ist eine günstigere Alternative für Rezepte, die anisbetonten Ersatz zulassen.

          ## Empfehlung (unter 20 €/0,7 l)
          - Abysse Premium Absinthe 60 %
        MD
      },

      # ─── Bitters ─────────────────────────────────────────────────────────────
      {
        title: "Bitters",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/wUtwrdOn",
        body: <<~MD
          Bitters werden in Cocktails wie Kochgewürze eingesetzt – tropfenweise, in „[[wiki:dash|Dash]]es" dosiert. Sie sind nicht ausschließlich bitter; die Kompositionen können komplex sein und Piment, Nelken, Zitrus oder Schokolade hervorheben.

          ## Geschichte

          Der älteste und bekannteste Bitter ist [[wiki:angostura|Angostura]], 1824 vom deutschen Arzt Johann Gottlieb Benjamin Siegert in Venezuela entwickelt – ursprünglich als Tropenmedizin.

          ## Einsatz

          Hervorragende Kombinationen mit [[wiki:whisky|Whisky]], [[wiki:gin|Gin]], [[wiki:cognac|Cognac]] und [[wiki:vermouth|Vermouth]]. Unverzichtbar in Whisk(e)y-Vermouth-Cocktails ([[wiki:manhattan|Manhattan]], [[wiki:martini|Martini]]) sowie in ausgewählten Tiki-Drinks ([[wiki:mai-tai|Mai Tai]], Zombie).

          **Kauftipp:** Für den Einstieg empfehlen sich aromatische und Orangenbitters. Trotz hohem Literpreis halten 0,2-l-Flaschen bei tropfenweisem Einsatz sehr lange.

          ## Empfehlungen (unter 15 €/0,2 l)
          - Angostura Aromatic Bitters
          - Angostura Orange Bitters
          - The Bitter Truth Aromatic Bitters
          - The Bitter Truth Orange Bitters
          - The Bitter Truth Lemon Bitters
          - Peychaud's
        MD
      },

      # ─── Wein ────────────────────────────────────────────────────────────────
      {
        title: "Wein",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/LCsqyzy7",
        body: <<~MD
          Wein gilt als das älteste dokumentierte alkoholische Getränk (Produktion seit ca. 6000 v. Chr.) und wird in Rot-, Weiß- und Roséwein unterteilt.

          ## Produktion

          Trauben werden gepresst, der Most vergärt. Rotwein gärt mit Schalen (Farbpigmente); Rosé nutzt kurzen Schalenkontakt; Weißwein gärt ohne Schalen. Hefe wandelt Zucker in Alkohol um. Nicht vollständig vergärter Zucker bleibt als Restsüße.

          Mindestalkohol: 7,5 % (Spezialitäten wie Madeira oder Marsala bis 17,5 %).

          ## Wichtige weiße Rebsorten
          Chardonnay, Gewürztraminer, Grüner Veltliner, Riesling, Sauvignon Blanc, Weißburgunder u. a.

          ## Wichtige rote Rebsorten
          Cabernet Sauvignon, Merlot, Pinot Noir (Spätburgunder), Sangiovese, Syrah u. a.

          ## Verwendung in Cocktails

          Wein spielt im Cocktailbereich eine begrenzte, aber wichtige Rolle: als [[wiki:aperitif|Aperitif]], in Bowlen, [[wiki:gluhwein|Glühwein]] und als Basis für [[wiki:vermouth|Vermouth]].
        MD
      },

      # ─── Vermouth und Aperitifweine ──────────────────────────────────────────
      {
        title: "Vermouth und Aperitifweine",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/LCsqyzy7",
        body: <<~MD
          Wein-basierte Getränke, die als Vorspeisen-Drinks geeignet sind.

          ## Quinquina

          Weinbasis mit Chinarindenzusatz (Quinin) für bittere Note, 15–18 % Alkohol. Historisch als Malariamedizin in Kolonialgebieten verteilt. James Bonds Vesper Martini nutzte den eingestellten Kina Lillet; der Nachfolger **Lillet Blanc** ist weniger bitter und fruchtiger.

          **Cocktails:** Corpse Reviver No. 2, Twentieth Century, Vesper

          ## Vermouth

          [[wiki:vermouth|Wermut]]-Wein aromatisiert mit Wermut (*Artemisia absinthium*) und Fruchtlikören, 15–18 % Alkohol. Französische Produktion dominiert trockene Varianten (Noilly Prat). Italienische Produzenten betonen süße Ausdrucksformen.

          | Typ | Charakter | Einsatz |
          |---|---|---|
          | Bianco | Weiß, süßlich | Selten in Cocktails |
          | Rosso | Rot, bitter-süß | Manhattan, Negroni |
          | Extra Dry | Sehr trocken | Martini |

          ### Empfehlungen (unter 15 €/0,7 l)
          - Dolin Blanc
          - Dolin Rouge
          - Carpano Bianco
          - Carpano Classico Rosso
          - Noilly Prat Extra Dry

          ### Premium
          - Carpano Antica Formula
          - Noilly Prat Ambré
          - Noilly Prat Rouge

          **Cocktails:** [[wiki:manhattan|Manhattan]], Martinez, Dry [[wiki:martini|Martini]], [[wiki:negroni|Negroni]]
        MD
      },

      # ─── Sherry ──────────────────────────────────────────────────────────────
      {
        title: "Sherry",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/LCsqyzy7",
        body: <<~MD
          Spanischer Likörwein (Aperitifwein) aus der [[wiki:jerez|Jerez]]-Region. Alle Sherrys basieren auf trockenem Weißwein, der mit Branntwein aufgespritzt wird. Süße Varianten erhalten nach dem Aufspriten Fruchtmengen-Zusätze.

          ## Klassifizierungen nach Zuckergehalt

          | Typ | Charakter | Verwendung |
          |---|---|---|
          | Fino | Blass, trocken, feine Mandelnoten | Klassischer Aperitif, gut gekühlt |
          | Amontillado | Bernsteinfarben, halbtrocken, vollmundig | |
          | Oloroso | Dunkelgold, leicht trocken bis süß, Nussaromen | |
          | Cream | Dunkelrubin, mild, süß | Digestif |
          | Pedro Ximénez | Braunschwarz, intensiv süß | Als Dessertwein oder Topping |

          ## Empfehlungen
          - Dry Sack
          - Lustau
          - Tío Pepe

          ## Bekannte Cocktails
          Adonis, Sherry Mistmas
        MD
      },

      # ─── Schaumwein ──────────────────────────────────────────────────────────
      {
        title: "Schaumwein",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/LCsqyzy7",
        body: <<~MD
          Wein-basiertes Getränk mit CO₂-Sättigung bei mindestens 3 bar Überdruck. Perlwein liegt bei 1–2,5 bar. Mindestalkohol: 10 %.

          ## Herstellungsmethoden

          | Methode | Beschreibung |
          |---|---|
          | Asti-Methode | Gärung wird vor dem Ende gestoppt, um Restsüße zu erhalten |
          | Charmat / Tank-Methode | Sekundärgärung in Drucktanks |
          | Méthode Champenoise | Flaschengärung; Basis für [[wiki:champagner|Champagner]], [[wiki:cava|Cava]], [[wiki:cremant|Crémant]], Sekt |
          | Direkte Karbonisierung | CO₂-Einleitung unter Druck |

          ## Geschützte Bezeichnungen

          - **[[wiki:champagner|Champagner]]** – Geschützte Herkunftsbezeichnung, Region Champagne (Frankreich)
          - **[[wiki:cava|Cava]]** – Geschützt, Spanien
          - **[[wiki:cremant|Crémant]]** – Frankreich ohne Champagne-Schutz
          - **Winzersekt / Hauersekt** – Ohne regionalen Schutz

          Für Cocktails sind preisgünstigere Winzersektion qualitativ oft vergleichbar mit Premium-Marken.

          ## Bekannte Cocktails
          Bellini, French 68, [[wiki:french-75|French 75]], [[wiki:kir-royal|Kir Royal]], Mimosa
        MD
      },

      # ─── Bier ────────────────────────────────────────────────────────────────
      {
        title: "Bier",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/RUIy8WjI",
        body: <<~MD
          Getreide-basiertes Gärgetränk aus Hopfen, gemälztem Getreide (meist Gerste), Hefe und Wasser. Typisch 4,5–6 % Alkohol, spezialisierte Varianten 0–16 %+.

          ## Gärarten

          **Obergärig (Ale):** Gärtemperatur 15–22 °C, Hefe steigt nach oben. Beispiele: Ale, Altbier, Berliner Weiße, Kölsch, Porter, Stout, Weizenbier.

          **Untergärig (Lager):** Unter 10 °C, Hefe setzt sich ab. Beispiele: Export, Lager, Märzen, Pilsner, Schwarzbier.

          **Spontangärung:** Vergärung durch Wildhefen aus der Luft; historisch der Ursprung aller Bierproduktion.

          ## Verwendung in Cocktails
          Bier erlebt wachsende Beliebtheit als Cocktailzutat.

          **Bekannte Cocktails:** Colours of the World, Black Refresher, Michelada
        MD
      },

      # ─── Bezeichnung der Getränke ─────────────────────────────────────────────
      {
        title: "Bezeichnung der Getränke",
        author: "rrr",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/RUIy8WjI",
        featured: true, featured_position: 4,
        body: <<~MD
          Das Wort „Cocktail" wurde erstmals 1806 dokumentiert und bezeichnete ursprünglich ein belebendes Getränk aus Spirituosen, Zucker, Wasser und [[wiki:bitters|Bitters]]. Heute gilt als Cocktail jede Mischung aus mindestens zwei Zutaten.

          **Shortdrink:** ca. 7–14 cl, meist ohne Eis oder mit wenig Eis, in Cocktailgläsern serviert.
          **Longdrink:** Größere Menge, meist mit Eis und einem Mixer, in Longdrinkgläsern.

          Überschneidungen zwischen den Kategorien sind normal und beabsichtigt – die Einteilung dient der Orientierung, nicht der strikten Abgrenzung.

          ## Kategorien (Auswahl)

          | Kategorie | Beschreibung |
          |---|---|
          | [[wiki:aperitif|Aperitif]] | Trocken, appetitanregend, vor dem Essen |
          | [[wiki:collins|Collins]] | Longdrink: Spirituose, Zitronensaft, Zucker, Soda |
          | [[wiki:cobbler|Cobbler]] | Spirituose oder Wein, Fruchtstücke, Zucker über Crushed Ice |
          | [[wiki:cooler|Cooler]] | Spirituose, Fruchtsaft, Ginger Ale oder Soda |
          | [[wiki:daiquiri|Daiquiri]] | Rum, Limettensaft, Zucker – geschüttelt |
          | [[wiki:digestif|Digestif]] | Nach dem Essen, meist schwerer und süßer |
          | [[wiki:eggnog|Eggnog]] | Ei, Sahne, Spirituose, Gewürze |
          | [[wiki:fizz|Fizz]] | Geschüttelter Sour + Sprudel |
          | [[wiki:flip|Flip]] | Spirituose oder Wein, Ei, Zucker |
          | [[wiki:frappe|Frappé]] | Likör oder Spirituose über Crushed Ice |
          | [[wiki:frozen|Frozen]] | Im Mixer mit Crushed Ice homogen gemixt |
          | [[wiki:highball|Highball]] | Spirituose + Mixer (Longdrink, wenige Zutaten) |
          | [[wiki:julep|Julep]] | Spirituose, Minze, Zucker, Crushed Ice |
          | [[wiki:margarita|Margarita]] | Tequila, Triple Sec, Limette, Salzrand |
          | [[wiki:mule|Mule]] | Spirituose, Ginger Beer, Limette |
          | [[wiki:nogs|Nogs]] | Spirituose, Ei, Sahne auf Eis |
          | [[wiki:posset|Posset]] | Milk/Cream, Wein oder Bier, Gewürze, warm |
          | [[wiki:pousse-cafe|Pousse Café]] | Geschichtete Zutaten nach Dichte |
          | [[wiki:punch|Punch]] | Ursprünglich 5 Zutaten: Spirituose, Zitrone, Tee, Zucker, Gewürze |
          | [[wiki:rickey|Rickey]] | Spirituose, halbe Limette, Soda auf Eis |
          | [[wiki:sangaree|Sangaree]] | Wein oder Port, Spirituose, Zucker |
          | [[wiki:scaffa|Scaffa]] | Spirituose, Likör, Bitters – Zimmertemperatur |
          | [[wiki:shooter|Shooter]] | Kleiner Cocktail (2–4 cl), auf Ex |
          | [[wiki:shrub|Shrub]] | Mazeration von Früchten, Spirituose, Zucker, optional Essig |
          | [[wiki:sling|Sling]] | Spirituose, Wasser, Zucker, Bitters |
          | [[wiki:smash|Smash]] | Wie Julep, aber mit Zitronensaft |
          | [[wiki:sour|Sour]] | Spirituose, Zitronensaft, Süßungsmittel |
          | [[wiki:swizzle|Swizzle]] | Spirituose, Limette, Zucker, Crushed Ice, mit Swizzle-Stab aufgewirbelt |
          | [[wiki:toddy|Toddy]] | Warm: Spirituose, Wasser, Zucker, Gewürze |
        MD
      },

      # ─── Kräuter und Botanicals ──────────────────────────────────────────────
      {
        title: "Kräuter und Botanicals",
        author: "SchuettelStefan",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/7AL2C0PB",
        body: <<~MD
          Frische Kräuter, Blüten, Stängel und Wurzeln eröffnen im Cocktail ein breites Aromaspektrum. Bezug über Wochenmärkte, Biosupermärkte oder Eigenanbau empfohlen.

          ## Kräuter

          | Kraut | Aromaprofil | Hinweis |
          |---|---|---|
          | Basilikum | Pfeffrig, leicht süßlich, würzig | Vielseitig in Gin- und Rum-Drinks |
          | Minze | Frisch, kühlend | Verschiedene Sorten; Hain-Minze ideal für [[wiki:mojito|Mojito]] |
          | Rosmarin | Ausgeprägt, eucalyptisch, leicht bitter | Sparsam einsetzen |
          | Thymian | Würzig, aromatisch | Auch Zitronenthymian verfügbar |
          | Salbei | Unverwechselbares, intensives Aroma | |
          | Petersilie | Frisch-grün | Glattblättrige Sorte für Cocktails bevorzugen |
          | Estragon | Leichter Anisduft, krautig | |

          ## Essbare Blüten

          Hibiskus, Gänseblümchen, Veilchen, Borretsch – je nach Saison verfügbar. Intensives Aroma und dekorativer Effekt.

          ## Wurzeln und Rhizome

          | Zutat | Charakter |
          |---|---|
          | Ingwer | Scharf, würzig, frisch |
          | Galgant | Milder als Ingwer, leicht campherartig |
          | Kurkuma | Erdig, leicht bitter, intensive Farbe |

          ## Weitere Botanicals

          - **Zitronengras:** Zitrusnote mit leichter Schärfe
          - **Zitronenmelisse:** Sanft, zitronig
          - **Zitronenverbene:** Intensiver als Melisse
          - **Lavendel:** Florals-würzig, sparsam einsetzen
          - **Wermut (*Artemisia absinthium*):** Intensiv bitter; Basis für [[wiki:absinth|Absinth]] und [[wiki:vermouth|Vermouth]]
          - **Ysop:** Minzig-bitter

          ## Anklatschen

          Kräuter vor dem Einsatz in der hohlen Hand zusammenklatschen ([[wiki:anklatschen|Anklatschen]]), um die Aromen freizusetzen.
        MD
      },

      # ─── Barmaße ─────────────────────────────────────────────────────────────
      {
        title: "Barmaße",
        author: "rrr",
        source_url: "https://www.cocktailscout.de/cocktailforum/beitrag/6gwRnHPv",
        body: <<~MD
          Übersicht der gebräuchlichsten Maße in der Bar. Absolute Volumenangaben (ml, cl) sind verlässlicher als traditionelle Gerätemaße, da diese erheblich variieren können.

          ## Jigger

          Das Standard-Messgerät der Bar. Beidseitig mit **4 cl** (großer Jigger) und **2 cl** (kleiner Jigger). Entspricht randvoll gefüllt den US-Unzen-Angaben in amerikanischen Rezepten.

          | Maß | Menge |
          |---|---|
          | 1 oz (Ounce) | ca. 3 cl |
          | 1,5 oz (Jigger) | ca. 4,5 cl |
          | 1 Pony | ca. 3 cl |

          ## Barspoon

          Konvention: **1 Barspoon = 0,5 cl (5 ml)**. In der Praxis variieren die tatsächlichen Löffel erheblich (0,25–0,5 cl). Wer auf Genauigkeit angewiesen ist, sollte die eigenen Werkzeuge vorab ausmessen.

          ## Dash

          Kleine Einheit für [[wiki:bitters|Bitters]] und andere Aromatika. Je nach Viskosität der Flüssigkeit ca. 0,5–1 ml.

          ## Splash / Spritzer

          Ungefähre Menge, entspricht einem kurzen Ausguss aus der Flasche, ca. 1–2 cl.
        MD
      },

      # ─── Hausbar anlegen ─────────────────────────────────────────────────────
      {
        title: "Hausbar anlegen",
        author: "zoidberg",
        source_url: "https://www.cocktailscout.de/cocktailforum/thema/tipps-fuer-den-barneuling",
        body: <<~MD
          Dieser Leitfaden gibt Einsteigern eine strukturierte Übersicht, welche Spirituosen, Liköre und alkoholfreien Zutaten für eine gut aufgestellte Heimbar empfehlenswert sind.

          ## Basisspirituosen

          Für eine vielseitige Hausbar empfehlen sich Einstiegsprodukte aus diesen Kategorien:

          - **Weißer Rum** – Basis für Daiquiri, Mojito, Cuba Libre
          - **Dunkler Rum** – Für Tiki-Drinks und Grogs
          - **Cachaça** – Für Caipirinha
          - **Gin** – London Dry, über 40 %
          - **Vodka** – Neutral, für breite Verwendung
          - **Tequila / Mezcal** – 100 % Agave bevorzugen
          - **Bourbon oder Rye Whiskey** – Für Manhattan, Old Fashioned
          - **Brandy / Cognac V.S.O.P.**

          ## Liköre

          - Blue Curaçao / Triple Sec
          - Maraschino
          - Amaretto
          - Kaffeelikör

          ## Mixer und alkoholfreie Zutaten

          - Frisch gepresste Zitronensäfte (Limette, Zitrone)
          - Zuckersaft (1:1 und 2:1)
          - Sodawasser, Tonic Water
          - Cola
          - Fruchtsäfte (100 % Direktsaft)

          ## Hinweis zu Preisen

          Die ursprüngliche Richtlinie von 20 € pro Flasche spiegelt aktuelle Marktpreise nicht mehr vollständig wider. Vergleichbare Qualität ist heute oft erst ab einem höheren Preisniveau erhältlich.

          Für detaillierte Empfehlungen zu einzelnen Spirituosen-Kategorien siehe die jeweiligen Leitfaden-Artikel.
        MD
      }

    ] # end entries

    created = updated = skipped = 0

    entries.each do |entry|
      author = authors[entry[:author]]
      unless author
        puts "Überspringe '#{entry[:title]}': Autor '#{entry[:author]}' nicht gefunden."
        skipped += 1
        next
      end

      source_footer = "\n\n---\n\n*Quelle: [Forum: Tipps für den Barneuling](#{entry[:source_url]})*"
      full_body = entry[:body] + source_footer

      article = WikiArticle.find_or_initialize_by(title: entry[:title])
      if article.new_record?
        article.body = full_body
        article.user = author
        article.published = true
        article.save!
        created += 1
        puts "Erstellt:     #{entry[:title]}"
      elsif full_body.length > article.body.to_s.length
        article.update!(body: full_body)
        updated += 1
        puts "Aktualisiert: #{entry[:title]}"
      else
        skipped += 1
        puts "Übersprungen: #{entry[:title]}"
      end

      if entry[:featured]
        article.update_columns(featured: true, featured_position: entry[:featured_position])
      end
    end

    puts "\nLeitfaden-Seeder: #{created} erstellt, #{updated} aktualisiert, #{skipped} übersprungen."
  end
end
