# Ticket `karte` — F2 Kartenansicht

Du bist der Arbeiter für dieses Ticket. Projekt-Repo `freizeitkarte-deepseek` (eigener
git-Worktree). Aufgabe: `AUFGABE.md` F2, Abnahme `ABNAHME.md` „Karte (F2)“. Das Grundgerüst
(Routing, Filter, URL, Datenladen, View-API) ist bereits auf `main` gemerged (Ticket `app-core`),
die aufbereiteten Daten liegen unter `public/data/` (Ticket `daten`).

## Branch / Abgabe

1. Erster Schritt: `git checkout -B wk/karte main` (lokales `main` enthält app-core + daten).
2. Nur deine Dateien ändern.
3. Commit auf `wk/karte`, nicht mergen. Melde am Ende: Umsetzung, Prüfungen, Messwerte
   (Anzahl Orte/Marker, Ladezeit bis interaktiv), Screenshot-Hinweis falls erstellt.

## Deine Dateien (Eigentum)

- `src/views/map.js` (ersetzt den Platzhalter vollständig)
- `src/views/map.css` (neu; von `map.js` importiert)
- optional `docs/karte.md` (kurz)
- NICHT: `package.json`, `index.html`, `src/main.js`, `src/state.js`, `src/filters.js`,
  `src/router.js`, `src/styles.css`, `src/views/list.js`, `src/views/detail.js`, `tests/`,
  `README.md`, `scripts/`, `public/data/`.

## View-API (verbindlich, von app-core aufgerufen)

```js
export function mount(root, ctx) {}   // root: leerer Container (#view-root)
export function update(filtered) {}   // nach jeder Filteränderung
export function destroy() {}          // beim Ansichtswechsel
```
`ctx` enthält: `places, filtered, state, manifest, categories, cantons,
categoryLabel(slug), cantonName(code), updateState(patch), openDetail(id), backHref(),
getPlace(id), isMobile()`. (Details in `tickets/app-core/rd.md`.)

## Anforderungen

- Leaflet (`leaflet` + `leaflet.markercluster` sind in `package.json`) mit OpenStreetMap-Kacheln
  `https://tile.openstreetmap.org/{z}/{x}/{y}.png`, Attribution „© OpenStreetMap contributors“.
- Startausschnitt: ganze Schweiz, `map.fitBounds([[45.818,5.955],[47.808,10.492]], {padding:[10,10]})`
  bzw. äquivalenter Center/Zoom (ca. `[46.8, 8.23]`, Zoom 7).
- Alle gefilterten Orte als Marker, bei vielen Punkten **geclustert**
  (`L.markerClusterGroup({chunkedLoading:true, removeOutsideVisibleBounds:true,
  maxClusterRadius:50})`). Für Performance `L.canvas({padding:0.5})` als Renderer und
  `L.circleMarker` (Radius ~5) verwenden; Markerobjekte einmal cachen, bei `update` nur
  `clearLayers()` + `addLayers(<subset>)`.
- Mit allen Orten ohne Filter muss Zoomen/Verschieben flüssig bleiben (nicht jedes Mal neu
  erzeugen; chunkedLoading; keine DOM-Marker).
- Klick auf Marker: Popup mit **Name, Kategorie-Label, Bewertung** (z. B. „4.5 ★ (82)“ oder
  „keine Bewertung“) und einem Link „Details ansehen“ → `#/ort/<id>` inklusive aktueller Filter
  (`ctx.openDetail(id)` bzw. passender `href`). Popup-Inhalt HTML-escaped.
- Farbliche Unterscheidung nach Kategorie ist optional, aber Marker müssen sichtbar sein.
- Nach Filteränderung (`update(filtered)`) zeigt die Karte sofort den neuen Markerbestand,
  ohne den Kartenausschnitt zu resetten. Beim ersten Mount ganzer Schweiz-Ausschnitt.
- Ansichtswechsel zurück zur Karte: `mount` erneut, Zustand/Ausschnitt mindestens auf Schweiz
  gesetzt; ausreichend, wenn Karte wieder benutzbar ist.
- Handy 390 px: Karte füllt verfügbare Höhe, keine horizontale Scrollbar (Layout kommt von
  app-core; dein Modul darf keine feste Breite setzen).
- Fehlerfrei ohne Daten/leere Filter (leere Cluster-Gruppe, kein Absturz).

## Test-/Debug-Haken (für Prüfung)

Nach erfolgreichem Mount setze:
```js
window.__karte = { map, cluster, markers, ready: true };
root.__map = map;
```
`cluster` = MarkerClusterGroup, `markers` = gecachte Marker (Array oder Map Id→Marker).
`ready` erst `true`, wenn der erste `addLayers`-Aufruf erfolgt ist.

## Selbstprüfung (vor Commit)

```bash
npm install
npm run build
npx vite preview --port 4173 --strictPort &
```
Dann im Browser/Playwright prüfen: `#/karte` zeigt Schweiz mit Clustern; Klick auf Marker →
Popup mit Name/Kategorie/Bewertung + Detail-Link; Filter (z. B. `cats=museum`) reduziert
Marker; `#/liste` und zurück behält Filter; mit allen Orten zoomen/verschieben fühlt sich
flüssig an. Miss die Zeit bis `window.__karte.ready === true` nach Navigation (Ziel < 2 s bei
allen Orten, lokal).

## Definition of Done

- Akzeptanzkriterien „Karte (F2)“ erfüllt.
- Build grün, keine Konsolenfehler, keine Regressionen in app-core.
- Commit auf `wk/karte`.