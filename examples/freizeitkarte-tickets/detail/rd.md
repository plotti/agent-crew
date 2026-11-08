# Ticket `detail` — F5 Detailansicht

Du bist der Arbeiter für dieses Ticket. Projekt-Repo `freizeitkarte-deepseek` (eigener
git-Worktree). Aufgabe: `AUFGABE.md` F5, Abnahme `ABNAHME.md` „Detail (F5)“. Grundgerüst,
Routing, URL, Daten sind auf `main` (Tickets `app-core`, `daten`).

## Branch / Abgabe

1. Erster Schritt: `git checkout -B wk/detail main`.
2. Nur deine Dateien ändern.
3. Commit auf `wk/detail`, nicht mergen. Melde: Umsetzung und Prüfungen (Direktlink, Rückweg,
   Pflichtfelder, fehlende Werte).

## Deine Dateien (Eigentum)

- `src/views/detail.js` (ersetzt den Platzhalter vollständig)
- `src/views/detail.css` (neu; von `detail.js` importiert)
- optional `docs/detail.md`
- NICHT: `package.json`, `index.html`, `src/main.js`, `src/state.js`, `src/filters.js`,
  `src/router.js`, `src/styles.css`, `src/views/map.js`, `src/views/list.js`, `tests/`,
  `README.md`, `scripts/`, `public/data/`.

## View-API (verbindlich)

```js
export function renderDetail(root, place, ctx) {}  // root: #detail-root, place: Ort|null
export function destroyDetail() {}
```
`ctx`: `places, filtered, state, manifest, categories, cantons, categoryLabel(slug),
cantonName(code), updateState(patch), openDetail(id), backHref(), getPlace(id), isMobile()`.
Die Route `#/ort/<id>` parst app-core und ruft `renderDetail`; die Filter-Query bleibt in der
URL erhalten, `ctx.backHref()` liefert den Rücklink zur vorherigen Ansicht (Karte oder Liste)
inklusive Filtern.

## Anforderungen (alle Felder, sofern vorhanden)

- **Foto** (`photo`) groß, mit Platzhalter wenn keins vorhanden (gleiche Sprache wie Liste),
  `alt=name`.
- **Name**, **Kategorie** (Label aus `cat`), **Adresse** (`addr`), **Kanton** (Kürzel + Name),
  **Bewertung** (z. B. „4.5 ★ (82 Bewertungen)“; ohne Bewertung „keine Bewertung“).
- **Öffnungszeiten** (`hours`): als Liste/Tabelle „Tag: Zeiten“; wenn `null`: „Öffnungszeiten
  nicht verfügbar“.
- **Beschreibung** (`desc`): nur wenn vorhanden, lesbarer Fliesstext.
- **Telefon** (`phone`): klickbarer `tel:`-Link.
- **Website** (`site`): Link mit `target="_blank" rel="noopener"` und sichtbarem Ziel.
- **Google Maps** (`maps`, sonst aus `id` generierbar): Link `target="_blank" rel="noopener"`.
- Fehlende Felder auslassen bzw. klar als „nicht verfügbar“ kennzeichnen — kein „null“/„undefined“
  im Text, kein kaputtes Layout.
- Eigene URL `#/ort/<id>`: Direktaufruf lädt denselben Ort; unbekannte ID → „Ort nicht gefunden“
  + Rücklink, kein Absturz.
- Rücklink „← Zurück zur Karte/Liste“ mit `ctx.backHref()`; Browser-Zurück funktioniert
  (app-core).
- Responsive 390 px: einspaltig, kein horizontales Scrollen, Text bricht um; Foto nicht breiter
  als der Viewport.
- Semantisch sauber (`<h1>`, `<main>`-Inhalt, `<a>`, `<dl>` o. Ä.), Tastaturbedienbar.
- Erreichbar aus Karte (Popup-Link) und Liste (Karten-Link) — app-core/Tickets liefern die
  Links; du stellst nur sicher, dass die Route existiert und rendert.

## Test-/Debug-Haken

Nach Render: `window.__detail = { id: place?.id ?? null, rendered: true }` und ein
`data-detail-id="<id>"`-Attribut am Container.

## Selbstprüfung (vor Commit)

```bash
npm install && npm run build
npx vite preview --port 4173 --strictPort &
```
Prüfen: `#/ort/<bekannte-id>` direkt öffnen (ID aus `public/data/places.json` nehmen, z. B.
`node -e "console.log(require('./public/data/places.json')[0].id)"`), alle vorhandenen Felder
sichtbar, Links korrekt; von `#/liste` eine Karte anklicken → Detail; zurück → gleiche Filter;
390 px ohne horizontales Scrollen; unbekannte ID freundliche Meldung.

## Definition of Done

- Kriterien „Detail (F5)“ erfüllt.
- Build grün, keine Konsolenfehler.
- Commit auf `wk/detail`.