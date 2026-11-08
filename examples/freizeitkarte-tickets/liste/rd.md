# Ticket `liste` — F3 Listenansicht

Du bist der Arbeiter für dieses Ticket. Projekt-Repo `freizeitkarte-deepseek` (eigener
git-Worktree). Aufgabe: `AUFGABE.md` F3, Abnahme `ABNAHME.md` „Liste (F3)“. Grundgerüst,
Filter, URL und Daten sind auf `main` vorhanden (Tickets `app-core`, `daten`).

## Branch / Abgabe

1. Erster Schritt: `git checkout -B wk/liste main`.
2. Nur deine Dateien ändern.
3. Commit auf `wk/liste`, nicht mergen. Melde: Umsetzung, Prüfungen (Sortierung, Paging, URL).

## Deine Dateien (Eigentum)

- `src/views/list.js` (ersetzt den Platzhalter vollständig)
- `src/views/list.css` (neu; von `list.js` importiert)
- optional `docs/liste.md`
- NICHT: `package.json`, `index.html`, `src/main.js`, `src/state.js`, `src/filters.js`,
  `src/router.js`, `src/styles.css`, `src/views/map.js`, `src/views/detail.js`, `tests/`,
  `README.md`, `scripts/`, `public/data/`.

## View-API (verbindlich, von app-core aufgerufen)

```js
export function mount(root, ctx) {}   // root: leerer Container (#view-root)
export function update(filtered) {}   // nach Filter-/Sortier-/Seitenänderung
export function destroy() {}          // beim Ansichtswechsel
```
`ctx`: `places, filtered, state, manifest, categories, cantons, categoryLabel(slug),
cantonName(code), updateState(patch), openDetail(id), backHref(), getPlace(id), isMobile()`.
`ctx.filtered` ist bereits **sortiert** (Rating absteigend/Reviews absteigend/Name aufsteigend,
Orte ohne Rating ans Ende) und enthält alle Treffer; die Liste zeigt nur die aktuelle Seite
(24 pro Seite, `state.page`, 1-basiert).

## Anforderungen

- Karten (Listeneinträge) mit:
  - Foto (`photo`) oder Platzhalter (einfacher CSS/SVG-Platzhalter, klar erkennbar),
    `loading="lazy"`, `onerror` → Platzhalter, sinnvolles `alt` (`name`),
  - Name, Kategorie-Label, Ort (`city`) und Kanton (`canton` + Name), Bewertung (z. B. „4.6 ★“)
    und Anzahl Bewertungen (z. B. „(123)“); fehlende Werte sauber darstellen („keine Bewertung“).
- Jede Karte ist ein Link zur Detailansicht: `ctx.openDetail(place.id)` bzw.
  `href="#/ort/<id>"` unter Beibehaltung der Filter-Query. Bedienbar per Tastatur.
- Sortierung: `<select>` mit „Bewertung“, „Anzahl Bewertungen“, „Name“; Änderung ruft
  `ctx.updateState({sort:'rating'|'reviews'|'name', page:1})` (URL wird von app-core
  geschrieben). Die tatsächliche Sortierung liefert app-core in `filtered`; du musst nicht
  selbst sortieren (darfst es aber defensiv tun).
- Paging: 24 pro Seite, „Zurück“/„Weiter“ + „Seite X von Y“; ruft
  `ctx.updateState({page:n})`. Nur die aktuelle Seite wird gerendert (nicht alle Orte!).
  Bei Filteränderung setzt app-core `page` auf 1 zurück.
- Trefferzahl in der Liste (z. B. „1'234 Orte“) anzeigen; die zentrale Anzeige
  (`#result-count`) bleibt app-core, du darfst zusätzlich eine eigene Zeile zeigen — sie muss
  aber dieselbe Zahl haben.
- Leerer Zustand: „Keine Orte für diese Filter“ + Hinweis/Reset-Link.
- Responsive: 1 Spalte auf Handy, 2–3 Spalten auf Desktop; kein horizontales Scrollen bei
  390 px; Filter bleiben erreichbar (app-core).
- Wiederverwendung beim Ansichtswechsel: `mount`/`update` müssen mit beliebigem `filtered`
  funktionieren; `destroy` räumt Listener auf.

## Test-/Debug-Haken

Nach Mount: `window.__liste = { root, renderedIds, page, pages }`, `renderedIds` = IDs der
aktuell gerenderten Einträge (für Prüfung, dass nicht alle gerendert werden).

## Selbstprüfung (vor Commit)

```bash
npm install && npm run build
npx vite preview --port 4173 --strictPort &
```
Prüfen: `#/liste` zeigt Karten mit allen Pflichtfeldern; Sortierung per Select ändert
Reihenfolge/URL (`sort=`); „Weiter“ → Seite 2, URL `page=2`, andere Einträge; Filter in der
Sidebar ändert Liste und Trefferzahl; Klick auf Karte öffnet `#/ort/<id>` (Platzhalter-Detail
reicht in deinem Branch); 390 px ohne horizontales Scrollen.

## Definition of Done

- Kriterien „Liste (F3)“ erfüllt (Foto/Platzhalter, Felder, Sortierung, Paging, URL).
- Build grün, keine Konsolenfehler.
- Commit auf `wk/liste`.