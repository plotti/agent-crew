# Ticket `app-core` — Grundgerüst, Routing, Filter F4, URL-Zustand

Du bist der Arbeiter für dieses Ticket. Projekt-Repo `freizeitkarte-deepseek` (dein
Arbeitsverzeichnis ist ein eigener git-Worktree). Aufgabe: `AUFGABE.md` (Rahmen, F4, F6-Rahmen),
Abnahme: `ABNAHME.md` (Filter F4, Qualität F6). Du baust das statische Vite-Grundgerüst, die
Filterleiste, den URL-Zustand und leere Ansichts-Platzhalter. Die eigentlichen Ansichten
(Karte/Liste/Detail) bauen andere Tickets — halte die hier definierten Schnittstellen exakt ein.

## Branch / Abgabe

1. Erster Schritt: `git checkout -B wk/app-core main`.
2. Nur die unten genannten Dateien anfassen.
3. Am Ende committen auf `wk/app-core`, nicht nach `main` mergen.
4. Melde: Dateien, Befehle, wie du Build/URL/Filter geprüft hast.

## Deine Dateien (Eigentum)

- `package.json`, `package-lock.json` (anlegen; `npm install` ausführen)
- `vite.config.js`
- `index.html`
- `src/main.js`, `src/state.js`, `src/router.js`, `src/filters.js`, `src/data.js`, `src/ui.js`
- `src/styles.css`
- `src/views/map.js`, `src/views/list.js`, `src/views/detail.js` (**Platzhalter**, werden von
  anderen Tickets ersetzt)
- `public/` nur für statische Icons/Favicon, **nicht** `public/data/` (kommt von `daten`)
- NICHT: `scripts/`, `tests/`, `README.md`, `docs/`

## Technik

- Node 26, npm 11, Netz vorhanden. Vite + Vanilla-JS (keine React-Pflicht). Rein statisch.
- `package.json` (Beispiel, Versionen dürfen aktuell sein):
  ```json
  {
    "name": "freizeitkarte-schweiz",
    "private": true,
    "type": "module",
    "scripts": {
      "dev": "vite",
      "build": "vite build",
      "preview": "vite preview --port 4173 --strictPort",
      "start": "vite preview --port 4173 --strictPort",
      "data": "node scripts/build-data.mjs",
      "test": "node --test tests/",
      "test:e2e": "playwright test"
    },
    "dependencies": {
      "leaflet": "^1.9.4",
      "leaflet.markercluster": "^1.5.3"
    },
    "devDependencies": {
      "vite": "^8.0.0",
      "xlsx": "0.18.5",
      "@playwright/test": "^1.65.0"
    }
  }
  ```
  `npm run data` verweist schon auf `scripts/build-data.mjs` (Ticket `daten`). `tests/` und
  `test:e2e` werden von `qualitaet` gefüllt; Skripte jetzt schon anlegen.
- `vite.config.js`: `base: './'`, Standard-`publicDir`, `build.outDir: 'dist'`.
  Wichtig: Daten werden zur Laufzeit per `fetch` geladen (nicht importiert), damit
  `public/data/` beim Build mitkopiert wird.

## Datenvertrag (von `daten` erzeugt)

- `public/data/manifest.json`: `{generatedAt, count, categories:[{slug,label,count}], cantons:[{code,name,count}], placesFile:"places.json"}`
- `public/data/places.json`: Array von Orten mit
  `{id,name,cat,type,city,canton,plz,lat,lng,rating,reviews,photo,site,phone,hours,desc,maps,addr}`;
  optionale Felder können `null` oder fehlen.
- Lade-Manifest zuerst, dann `placesFile` relativ zu `data/`:
  ```js
  const base = new URL('data/', document.baseURI);
  const manifest = await (await fetch(new URL('manifest.json', base))).json();
  const places = await (await fetch(new URL(manifest.placesFile, base))).json();
  ```
- Wenn Daten fehlen: sichtbare Fehlermeldung im UI („Daten fehlen, bitte `npm run data`“),
  keine Exception in der Konsole. (`public/data/` existiert in deinem Branch noch nicht; das ist
  ok. Für die eigene Prüfung darfst du temporär eine kleine Fixture unter `/tmp` und
  `FREIZEITKARTE_DATA_URL` verwenden, aber nichts unter `public/data/` committen.)

## UI-Aufbau (ein Dokument, drei Routen)

`index.html` (lang `de`):
```
<header>
  Marke/Titel „Freizeitkarte Schweiz“ (Link auf #/karte)
  <nav> Buttons/Radio: „Karte“ (#/karte) | „Liste“ (#/liste)  — aria-pressed
  <div id="result-count" aria-live="polite">…</div>
</header>
<aside id="filters"> … Filterformular … </aside>
<main id="view-root"></main>
<div id="detail-root" hidden></div>
<div id="app-status" role="status">…Laden…</div>
```
- Header sticky, Filter als Panel/Sidebar (Desktop), auf Handy per Button „Filter“ auf-/zuklappbar.
- Beim Wechsel Karte↔Liste bleiben alle Filter erhalten.
- Unten/oben eine Anzeige der Trefferzahl, z. B. `1'234 Orte`; Element-ID `#result-count`.
  Dieselbe Zahl in beiden Ansichten (zentral berechnet).

## Zustand / Filter (F4, exakte Semantik)

`state`:
```js
{ view:'map'|'list', cats:[], canton:'', minRating:0, minReviews:0, q:'',
  sort:'rating'|'reviews'|'name', page:1, detailId:null }
```
- `cats`: ODER-Verknüpfung; leer = alle Kategorien.
- `canton`: einzelnes Kantonskürzel; leer = alle.
- `minRating`: 0 = keine Einschränkung; sonst `rating != null && rating >= minRating`.
- `minReviews`: 0 = keine Einschränkung; sonst `reviews >= minReviews`.
- `q`: getrimmt, case-insensitiv, Substring in `name` **oder** `city` (Umlaute tolerant: `q`
  normalisieren, z. B. `ä→a`).
- Filterung zentral in `filterPlaces(places, state)`. `filtered.length` ist die Trefferzahl.
- Sortierung: `rating` absteigend (Orte ohne Bewertung ans Ende), `reviews` absteigend,
  `name` aufsteigend (`localeCompare('de')`).
- `page`: 1-basiert, 24 pro Seite; bei Filter-/Suchänderung auf 1 zurücksetzen.
- `updateState(patch)`: State patchen, abhängige Ansicht aktualisieren, URL schreiben.
- `window.__freizeitkarte = { ready:true, manifest, places, state, filtered:()=>filtered,
  filterPlaces, updateState, categoryLabel(slug), cantonName(code) }` nach Initialisierung;
  zusätzlich `window.__appReady = true` (Tests nutzen das).

## URL-Vertrag (F4)

Hash-Routing, Query-Parameter:
- Karte: `#/karte?cats=museum,seebad&kt=BE&minr=4&minrev=10&q=bern`
- Liste: `#/liste?...&sort=reviews&page=2`
- Detail: `#/ort/<id>?...` (Query der vorherigen Ansicht bleibt erhalten)
Parameter:
`cats` = kommagetrennte Slugs; `kt` = Kantonskürzel; `minr` = Min-Bewertung; `minrev` =
Min-Anzahl Bewertungen; `q` = Suchtext (URL-encoded); `sort` = `rating|reviews|name`;
`page` = positive Ganzzahl.
- Beim Laden: URL parsen und anwenden; unbekannte/ungültige Werte ignorieren (Defaults).
- Bei jeder Filter-/Sortier-/Seiten-/Ansichtsänderung URL per `history.replaceState` bzw.
  `location.hash` aktualisieren (kein Neuladen, kein Scroll-Sprung).
- Neuladen oder geteilter Link stellt exakt dieselbe Auswahl/Ansicht wieder her.
- `#/karte` ohne Query = alle Orte.
- Detail: `#/ort/<encodeURIComponent(id)>`; „zurück“ führt zur vorherigen Ansicht inkl. Filter
  (`router.backHref`).

## Router

`src/router.js`:
- `parseHash()` → `{route:'map'|'list'|'detail', id, query}`.
- `navigate(route, {id, state})`, `syncUrl(state)`.
- `hashchange`-Listener (Browser-Zurück) → State neu parsen + rendern.
- Beim direkten Laden einer Detail-URL ohne geladene Daten: erst Daten laden, dann rendern.
- `openDetail(id)` merkt die aktuelle Filter-Query (für Rücklink) und navigiert zu `#/ort/id?…`.
- `showView()`: `map`/`list` → `view-root` einblenden, `detail-root` verbergen; `detail` →
  umgekehrt. Jeweils `mount/update` bzw. `renderDetail` der Module aufrufen.

## Ansichts-Schnittstellen (verbindlich; andere Tickets implementieren sie)

`src/views/map.js` und `src/views/list.js`:
```js
export function mount(root, ctx) {}   // root = leerer Container; ctx siehe unten
export function update(filtered) {}   // nach Filteränderung erneut aufrufen
export function destroy() {}          // beim Ansichtswechsel aufrufen (Map aufräumen)
```
`src/views/detail.js`:
```js
export function renderDetail(root, place, ctx) {} // place = null wenn unbekannt
export function destroyDetail() {}
```
`ctx` (von `main.js` gebaut):
```js
{
  places,                     // alle Orte
  filtered,                   // aktuell gefilterte Orte (sortiert)
  state,                      // aktueller State (live)
  manifest,                   // Manifest
  categories: manifest.categories,
  cantons: manifest.cantons,
  categoryLabel(slug) -> string,
  cantonName(code) -> string,
  updateState(patch),         // z. B. {sort:'name'}, {page:2}
  openDetail(id),             // navigiert zu #/ort/id und merkt Rückweg
  backHref(),                 // URL der vorherigen Ansicht inkl. Filter
  getPlace(id) -> place|null,
  isMobile() -> boolean
}
```
Die Platzhalter in `src/views/*.js` müssen diese Exporte bereits haben und eine sichtbare
Meldung rendern („Karte folgt“, „Liste folgt“, Detail: Name + Rücklink). `main.js` importiert
statisch; die Dateien werden später von anderen Tickets ersetzt.

## Filterleiste (`src/filters.js`) — Inhalt

- Kategorien: Mehrfachauswahl als Checkbox-Liste (35 Einträge, Label + Anzahl, scrollbar,
  „Alle“/„Keine“). Auf Handy im aufklappbaren Panel.
- Kanton: `<select>` mit „Alle Kantone“ + 26 (Code + Name).
- Mindestbewertung: `<select>` 0/3/3.5/4/4.5 (oder number 0–5, Schritt 0.5).
- Mindestanzahl Bewertungen: `<input type="number" min=0>`.
- Freitextsuche: `<input type="search">` über Name/Ort, mit ~150 ms Debounce.
- „Filter zurücksetzen“-Button.
- Jede Änderung → `updateState(...)`; Trefferzahl sofort aktualisieren; URL aktualisieren.
- Bedienbar per Tastatur, Labels mit `<label for>`, `aria-*`.

## Styling / Responsive

- Ruhiges, klares Layout; Systemschriften (kein Font-CDN nötig); CSS-Variablen.
- Desktop: Filter links (~280 px), Inhalt rechts; Karte füllt Resthöhe.
- 390 px: Filter einklappbar, Ansicht-Umschalter und Filterknopf sichtbar, **kein horizontales
  Scrollen** (`overflow-x:hidden` reicht nicht als Lösung — Layout wirklich fluid).
- Ladezustand und Fehlerzustand sichtbar.
- Karte/Liste/Detail-Platzhalter nehmen die volle verfügbare Höhe ein.

## Selbstprüfung (vor Commit)

```
npm install
npm run build                 # muss ohne public/data klappen
npm run preview &             # oder: npx vite preview --port 4173 --strictPort
# Browser/curl: http://localhost:4173/ lädt; ohne Daten erscheint Fehlermeldung
```
Zusätzlich mit einer temporären Fixture (nicht committen): zwei kleine Orte in `public/data/`
ODER `FREIZEITKARTE_DATA_URL`-Override; Filter setzen, URL prüfen, neu laden, gleiche Auswahl.
Wenn `daten` schon nach `main` gemerged ist: echte Daten verwenden und mit `curl` prüfen, dass
`/data/places.json` erreichbar ist.

## Definition of Done

- Build läuft; App startet mit `npm run preview`; Daten werden geladen (sofern vorhanden).
- Filter wirken zentral, Trefferzahl korrekt, beide Ansichten-Wechsel erhalten Filter.
- URL vollständig (cats/kt/minr/minrev/q/sort/page/view/detail), Reload und geteilter Link
  stellen alles wieder her.
- Platzhalter-Views exportieren exakt die vereinbarte API.
- `window.__appReady` und `window.__freizeitkarte` für Tests vorhanden.
- Commit auf `wk/app-core`.