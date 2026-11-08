# Ticket `daten` — F1 Datenaufbereitung

Du bist der Arbeiter für dieses Ticket. Du arbeitest im Projekt-Repo `freizeitkarte-deepseek`
(dein Arbeitsverzeichnis ist ein eigener git-Worktree dieses Repos; prüfe mit
`git rev-parse --show-toplevel`). Rohdaten liegen **nur lesend** unter
`/Users/plotti/code/freizeitkarte-daten/` (36 `.xlsx`-Dateien). Die Aufgabe steht im Repo in
`AUFGABE.md` (Abschnitt „Daten“ und „F1“), die Abnahme in `ABNAHME.md` (Abschnitt „Daten (F1)“).

## Branch / Abgabe

1. Erster Schritt: `git checkout -B wk/daten main` (lokales `main` ist der aktuelle Stand).
2. Arbeite nur an den unten genannten Dateien.
3. Am Ende: alles committen (`git add ... && git commit -m "F1: Datenaufbereitung ..."`), auf
   Branch `wk/daten`. Nicht nach `main` mergen.
4. Melde am Ende: was du gebaut hast, wie du es geprüft hast, Kennzahlen (Zeilen, behalten, pro
   Kategorie), Dateigrößen.

## Deine Dateien (Eigentum)

- `scripts/build-data.mjs` — das Aufbereitungsskript (Node ESM, `xlsx`-Paket).
- `scripts/data/cantons.geojson` — die Kantonsgrenzen (einmalig heruntergeladen, im Repo
  vendored; Quelle unten).
- `tests/data.test.mjs` — automatisierte Tests (Node `node:test`, keine weiteren Pakete nötig).
- `docs/relevance.md` — Erklärung der Relevanzregel (auf Deutsch, kurz).
- `public/data/manifest.json`, `public/data/places.json`, `public/data/stats.json` — **erzeugte**
  Dateien, die mit eingecheckt werden (kompakt!).
- `package.json` NICHT anfassen (gehört `app-core`); `README.md` NICHT anfassen (gehört
  `qualitaet`).

## Rohdaten

36 Excel-Exporte, ~180'000 Zeilen, u. a. Spalten (echte Spaltennamen, per `xlsx` als Objekt lesen):
`query`, `name`, `site`, `subtypes`, `category`, `type`, `phone`, `full_address`, `city`,
`postal_code`, `latitude`, `longitude`, `rating`, `reviews`, `photo`, `working_hours`,
`business_status`, `description`, `location_link`, `place_id`, `country_code`, `country`.
Der Suchbegriff steckt im Dateinamen (z. B. `…_paintball_+1.xlsx`, `go-kart_all.xlsx`).
Nur die erste Sheet der Arbeitsmappe lesen.

**Nur lesen**: Nichts unter `~/code/freizeitkarte-daten/` verändern, keine Kopien ins Repo legen.

## Kategorien (aus Dateinamen, verbindlich)

Bilde aus jedem Dateinamen einen Kategorie-Slug. Entferne führende Nummern/`Outscraper-…`,
Suffixe wie `(1)`/`(3)`/`+1`/`+2`, und mappe auf diese 35 Slugs; zwei Bowling-Dateien gehören zu
`bowling`. Label ist der Anzeigename.

| Datei-Token | Slug | Label |
|---|---|---|
| paintball | paintball | Paintball |
| escape_room_center | escape_room | Escape Room |
| seilrutsche | seilrutsche | Seilrutsche |
| schlitteln | schlitteln | Schlitteln |
| bungeejumping | bungeejumping | Bungeejumping |
| bowling_und_hallensport (2 Dateien) | bowling | Bowling & Hallensport |
| wasserpark | wasserpark | Wasserpark |
| seilpark | seilpark | Seilpark |
| vergnügungspark | vergnuegungspark | Vergnügungspark |
| minigolf | minigolf | Minigolf |
| rodeln | rodeln | Rodeln |
| lasergame | lasergame | Lasergame |
| labyrinth | labyrinth | Labyrinth |
| trottinettplausch | trottinett | Trottinett |
| freizeitzentrum | freizeitzentrum | Freizeitzentrum |
| freifallsimulator | freifallsimulator | Freifallsimulator |
| kino | kino | Kino |
| theater | theater | Theater |
| schlittenhunde | schlittenhunde | Schlittenhunde |
| schlittschuhlaufen | schlittschuhlaufen | Schlittschuhlaufen |
| schneeschuhlaufen | schneeschuhlaufen | Schneeschuhlaufen |
| langlaufen | langlaufen | Langlaufen |
| snowtubing | snowtubing | Snowtubing |
| seebad | seebad | Seebad |
| picknick | picknick | Picknickplatz |
| spielplatz | spielplatz | Spielplatz |
| museum | museum | Museum |
| bibliothek | bibliothek | Bibliothek |
| kunstgalerie | kunstgalerie | Kunstgalerie |
| kulturort | kulturort | Kulturort |
| schloss | schloss | Schloss |
| historische_stätte | historische_staette | Historische Stätte |
| naturereigniss | naturereignis | Naturereignis |
| höhle | hoehle | Höhle |
| go-kart_all | gokart | Go-Kart |

## Ablauf der Aufbereitung

1. Alle 36 Dateien einlesen. Zähle `rowsRead`.
2. Zeilen ohne `place_id` verwerfen (`discardedNoId`).
3. `business_status` muss exakt `OPERATIONAL` sein, sonst verwerfen (`discardedClosed`).
4. Nur Orte in der Schweiz: `country_code` in `{CH, ''}` (bzw. `country` passend) **und**
   Koordinaten im Bounding-Box `lat 45.7–47.9`, `lng 5.8–10.6`. Sonst `discardedOutside`.
   (Liechtenstein hat `country_code` LI und fällt so raus.)
5. Relevanzprüfung pro Ort (siehe unten). Unpassende verwerfen (`discardedIrrelevant`,
   zusätzlich pro Kategorie zählen).
6. Duplikate über `place_id`: jeden Ort genau einmal behalten (`duplicatesRemoved`). Wenn derselbe
   Ort in mehreren Dateien steht, gewinnt die Fundstelle mit der **stärkeren** Relevanz
   (Primär-Match `category`/`type` = 2, Sekundär-Match über `subtypes`/`name` = 1); bei
   Gleichstand die alphabetisch erste Kategorie (deterministisch).
7. Kanton bestimmen (siehe unten).
8. Felder normalisieren, kompakt schreiben, Statistik ausgeben.

## Relevanzregel (verbindlich, nachvollziehbar dokumentieren)

Ziel: Suchtreffer, die offensichtlich nicht zur Kategorie passen, verwerfen. Ein Ort hat
`primary = (category + ' ' + type).toLowerCase()` (Google-Maps-Primärkategorie) und
`support = (subtypes + ' ' + name).toLowerCase()`.

- Für jede Kategorie gibt es `accept`-Muster (deutsch/französisch/italienisch/englisch, z. B.
  `kart`, `karting`, `kartbahn`, `circuit de karting`). Match auf `primary` → Relevanz 2.
- Es gibt eine **generische Reject-Liste** für Primärkategorien, die als Hauptkategorie nie
  passen: `restaurant`, `hotel`, `motel`, `bar`, `café`, `cafe`, `bäckerei`, `metzgerei`,
  `post`, `bank`, `gemeindeverwaltung`, `rathaus`, `bahnhof`, `bushaltestelle`, `parkplatz`,
  `garage`, `autohändler`, `autohaus`, `tankstelle`, `supermarkt`, `apotheke`, `arzt`,
  `immobilien`, `versicherung`, `geschäftsstelle`, `standesamt`, `behörde`. Wenn `primary`
  eines davon trifft und **nicht** gleichzeitig ein Accept-Muster der Kategorie → verwerfen.
  (Ein echtes Museum mit Restaurant-Subtyp behält also, weil `primary` „museum“ ist; ein
  Restaurant mit Museums-Subtyp fliegt raus.)
- Wenn `primary` kein Accept-Match hat, aber `support` einen Accept-Match **und** `primary`
  eine unterstützende Freizeit-/Kultur-/Tourismus-Kategorie ist (`attractions`,
  `sehenswürdigkeit`, `freizeitzentrum`, `recreation center`, `sportanlage`, `sports complex`,
  `veranstaltungsstätte`, `kulturzentrum`, `park`, `tourist attraction`, `amusement park`,
  `campingplatz`, `stiftung`) → Relevanz 1.
- Sonst verwerfen.

Konkret hart prüfen (Abnahme):
- In `gokart` darf kein Ort sein, dessen `primary` Restaurant/Hotel/Garage/Mechaniker/Post/Bank
  ist.
- In `museum` kein Restaurant/Hotel/Café/Bar.
- In `seebad` kein Restaurant/Hotel.
Die Tests müssen das auf den **erzeugten Daten** nachweisen (dafür das Feld `type` mit
Primärtyp behalten).

Die Regel wird in `docs/relevance.md` auf Deutsch erklärt (inkl. Beispiele Go-Kart-Fall: 1403
Treffer → nur echte Bahnen; Museum-Fall: Restaurants raus). README-Pflichttext liefert
`qualitaet`, verweise dort auf `docs/relevance.md`.

## Kanton

- Lade einmalig
  `https://raw.githubusercontent.com/codeforgermany/click_that_hood/main/public/data/switzerland.geojson`
  herunter (FeatureCollection mit genau 26 Kantonen, Eigenschaft `properties.name`) und lege sie
  als `scripts/data/cantons.geojson` ab. Prüfe: 26 Features.
- Ordne jedem Ort per Point-in-Polygon (Ray-Casting, MultiPolygon + Löcher beachten) den Kanton
  zu. Wenn der Punkt in keinem Polygon liegt (vereinfachte Grenzen, Seekanten), nimm den
  nächstgelegenen Kantons-Schwerpunkt (Polygon-Mittelpunkt).
- Mappe die Namen auf die 26 Kürzel:
  `AG Aargau, AI Appenzell Innerrhoden, AR Appenzell Ausserrhoden, BE Bern, BL Basel-Landschaft,
  BS Basel-Stadt, FR Freiburg, GE Genf, GL Glarus, GR Graubünden, JU Jura, LU Luzern,
  NE Neuenburg, NW Nidwalden, OW Obwalden, SG St. Gallen, SH Schaffhausen, SO Solothurn,
  SZ Schwyz, TG Thurgau, TI Tessin, UR Uri, VD Waadt, VS Wallis, ZG Zug, ZH Zürich`.
- **Jeder** ausgegebene Ort muss genau ein Kürzel aus dieser Liste haben (sonst Fehler werfen,
  nicht still null lassen).
- Stichproben-Test: Zürich (47.3769, 8.5417)→ZH, Bern (46.9480, 7.4474)→BE,
  Genf (46.2044, 6.1432)→GE, Lugano (46.0037, 8.9511)→TI, Basel (47.5596, 7.5886)→BS.

## Ausgabedaten (verbindlicher Vertrag)

`public/data/manifest.json`:
```json
{
  "generatedAt": "2026-11-07T…Z",
  "count": 12345,
  "categories": [{"slug":"museum","label":"Museum","count":2345}],
  "cantons": [{"code":"ZH","name":"Zürich","count":1234}],
  "placesFile": "places.json"
}
```
`categories` alle 35 (auch mit count 0), absteigend nach count; `cantons` alle 26 mit count,
alphabetisch nach code.

`public/data/places.json`: **JSON-Array** (kein Wrapper) von Objekten. Felder:
```json
{
  "id": "ChIJ…",                 // place_id, Pflicht, eindeutig
  "name": "…",                   // Pflicht
  "cat": "museum",               // Slug aus Tabelle, Pflicht
  "type": "Museum",              // roher Primärtyp (type), für Relevanz-Nachweis
  "city": "Bern",                // oder null
  "canton": "BE",                // Pflicht, 2 Grossbuchstaben
  "plz": "3000",                 // oder null
  "lat": 46.948,
  "lng": 7.4474,
  "rating": 4.5,                 // Zahl oder null
  "reviews": 123,                // Zahl, 0 wenn unbekannt
  "photo": "https://…",          // oder null
  "site": "https://…",           // oder null
  "phone": "+41 …",              // oder null
  "hours": {"Montag": "09:00-17:00"}, // Objekt oder null (JSON aus working_hours)
  "desc": "…",                   // max. 600 Zeichen, oder null
  "maps": "https://www.google.com/maps/…", // location_link, sonst aus place_id bauen
  "addr": "Strasse 1, 3000 Bern" // full_address oder null
}
```
Alle optionalen Felder dürfen als `null` erscheinen oder weggelassen werden; die App behandelt
beides gleich. Strings trimmen; `"None"`/`""` → `null`. Koordinaten auf 5 Nachkommastellen
runden. `rating`/`reviews` numerisch parsen. Keine unnötigen Rohfelder (kein `about`,
`subtypes`, `working_hours`-Roh-JSON). Kompakt serialisieren (`JSON.stringify(...)`, keine
Einrückung).

`public/data/stats.json`: Objekt mit
`rowsRead, filesRead, duplicatesRemoved, discardedNoId, discardedClosed, discardedOutside,
discardedIrrelevant, kept, perCategory: {slug: n}, discardedIrrelevantPerCategory: {slug: n}`.

## Statistik-Ausgabe (stdout, am Ende)

```
Zeilen gelesen: <n> (36 Dateien)
Duplikate entfernt: <n>
Ohne place_id verworfen: <n>
Geschlossen verworfen: <n>
Ausserhalb CH verworfen: <n>
Unpassend verworfen: <n>
Behalten: <n>
Behalten pro Kategorie:
  <slug>: <n>
  …
```
Die Zahlen müssen zu `stats.json` und `places.json` passen. Ausgabe erscheint bei `npm run data`
(einziger Befehl; `data`-Script = `node scripts/build-data.mjs`, legt `app-core` an).

## Aufruf / Test ohne package.json

`app-core` legt parallel `package.json` an, du hast es in deinem Branch noch nicht. Installiere
`xlsx` für deine eigene Prüfung ausserhalb des Repos:
```
npm install --prefix /tmp/fk-deps xlsx@0.18.5
NODE_PATH=/tmp/fk-deps/node_modules node scripts/build-data.mjs
NODE_PATH=/tmp/fk-deps/node_modules node --test tests/data.test.mjs
```
Das Skript soll ohne Argumente mit Defaults laufen:
`raw = process.env.FREIZEITKARTE_RAW || '/Users/plotti/code/freizeitkarte-daten'`,
`out = <repo>/public/data`, `--raw`/`--out` optional unterstützen.

## Tests (`tests/data.test.mjs`)

Mit `node --test tests/data.test.mjs`, keine Zusatzpakete:
1. `public/data/places.json` existiert, ist ein nichtleeres Array; `manifest.count === places.length`.
2. Alle `id` eindeutig.
3. Alle `canton` in den 26 erlaubten Kürzeln; alle `lat/lng` in der CH-Bounding-Box.
4. Alle `cat` in den 35 Slugs; `manifest.categories` passt zu den Counts in `places.json`.
5. `gokart`: kein Ort mit `type`/`name`-Primär-Match auf restaurant/hotel/garage/mechaniker.
6. `museum`: kein Ort mit `type` restaurant/hotel/café/bar.
7. `seebad`: kein Ort mit `type` restaurant/hotel.
8. Kantons-Stichproben: importiere die Export-Funktion `cantonFor(lat,lng)` aus
   `scripts/build-data.mjs` (Skript soll beim direkten Aufruf bauen, beim Import nichts tun) und
   prüfe die fünf Städte oben.
9. `stats.kept === places.length`, Summen stimmen.

## Definition of Done

- `node scripts/build-data.mjs` läuft fehlerfrei in < 3 Minuten und schreibt die drei Dateien.
- Tests grün.
- `places.json` ist kompakt (Ziel < 15 MB; gib die Dateigröße in der Meldung an).
- Rohdaten unverändert.
- Commit auf `wk/daten` mit aussagekräftiger Nachricht.