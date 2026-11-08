# Ticket `qualitaet` — F6 Qualität, Tests, README, Gesamtabnahme

Du bist der Arbeiter für dieses Ticket. Projekt-Repo `freizeitkarte-deepseek` (eigener
git-Worktree). Auf `main` sind alle Features gemerged (Daten, app-core, Karte, Liste, Detail).
Deine Aufgabe: F6 aus `AUFGABE.md`, alle 21 Kriterien aus `ABNAHME.md` nachweisbar erfüllen,
README schreiben, Playwright-Tests und Daten-Tests grün bekommen, Messwerte dokumentieren.
Du darfst dafür projektweit Fehler beheben (jede Datei), aber keine Features neu erfinden oder
die Datenaufbereitung/Ansichten ohne Not umbauen.

## Branch / Abgabe

1. Erster Schritt: `git checkout -B wk/qualitaet main`.
2. Commit auf `wk/qualitaet`, nicht mergen.
3. Melde: Testergebnisse (Anzahl Tests, Laufzeit), Performance-Messwert (ms bis bedienbar),
   Mobile-Prüfung, Datenstatistik, gefundene/behobene Fehler, offene Schwächen.

## Deine Dateien

- `README.md` (Pflicht, neu)
- `playwright.config.js`
- `tests/e2e/*.spec.js` (neu)
- `ABNAHME-PRUEFUNG.md` (Prüfmatrix mit Befehlen/Messwerten)
- Fehlerbehebungen in beliebigen bestehenden Dateien, wenn Tests/Kriterien es verlangen
- NICHT die Rohdaten, keine `node_modules`/`dist` committen.

## Datenstand / Befehle

- Daten: `public/data/{manifest,places,stats}.json` (committet, erzeugt von `npm run data`).
- `package.json` hat bereits: `dev, build, preview, start, data, test (node --test tests/),
  test:e2e (playwright test)`. Korrigiere Skripte nur, wenn sie nicht funktionieren.
- Playwright/Chromium ist lokal verfügbar (`~/Library/Caches/ms-playwright`); falls die
  Browserversion nicht passt: `npx playwright install chromium`.

## 1. Automatisierte Tests (Pflicht)

### Daten-Tests
- `tests/data.test.mjs` existiert (Ticket `daten`) und läuft via `npm test` (`node --test tests/`).
- Ergänze/repariere nur wenn nötig; die Tests müssen die F1-Kriterien abdecken:
  eindeutige `place_id`, nur `OPERATIONAL`, nur Schweiz, genau eine Kategorie aus 35 und ein
  Kanton aus 26, Relevanz (keine Restaurants/Hotels/Garagen in `gokart`, keine Restaurants in
  `museum`), Statistik konsistent.

### Browser-Tests (Playwright, Produktions-Build)
`playwright.config.js`:
```js
import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './tests/e2e',
  timeout: 60_000,
  use: { baseURL: 'http://localhost:4173', headless: true },
  webServer: {
    command: 'npm run build && npm run preview',
    url: 'http://localhost:4173',
    reuseExistingServer: false,
    timeout: 180_000
  }
});
```
`tests/e2e/app.spec.js` (dürfen 2–3 Dateien sein) deckt ab:
1. **Karte:** `#/karte`; `#map .leaflet-container` sichtbar; Cluster/Marker vorhanden
   (`window.__karte.ready`); Marker-Klick (echter Klick: per `window.__karte` einen Marker
   wählen, `map.setView(latlng, 16)`, dann auf die projizierte Containerposition klicken) öffnet
   Popup mit Name, Kategorie, Bewertung; Popup-Link „Details ansehen“ führt zu `#/ort/…`.
   Fallback, falls echter Klick flaky: Marker-Click-Event auslösen, aber Popup-DOM prüfen.
2. **Liste:** `#/liste`; Karten zeigen Foto **oder** Platzhalter, Name, Kategorie, Ort, Kanton,
   Bewertung, Anzahl Bewertungen; nur ≤ 24 Einträge gerendert; Sortierung nach Bewertung /
   Anzahl Bewertungen / Name ändert die Reihenfolge; „Weiter“ → Seite 2 mit anderen Einträgen
   und `page=2` in der URL.
3. **Filter gemeinsam:** Kategorie (z. B. `museum` + `seebad`), Kanton, Mindestbewertung,
   Mindestanzahl Bewertungen, Freitext; Trefferzahl in Karte und Liste **identisch**; URL
   enthält die Filter; Reload und direktes Öffnen des geteilten Links stellen dieselbe Auswahl
   her; Ansichtswechsel behält Filter.
4. **Detail:** Direktaufruf `#/ort/<id>`; zeigt Foto/Platzhalter, Name, Kategorie, Adresse,
   Kanton, Bewertung, Öffnungszeiten, Telefon, Website- und Maps-Link (sofern vorhanden);
   aus Liste erreichbar; Rücklink führt zur vorherigen Ansicht mit Filtern.
5. **Performance:** im Produktions-Preview die Zeit von Navigation bis bedienbar messen
   (`window.__appReady` + Karte bereit bzw. Liste gerendert) — **< 3000 ms**; den Messwert im
   Test ausgeben (`console.log`). Bei Überschreitung optimieren (z. B. Daten kompakter,
   Marker-Strategie, Rendering), nicht die Schwelle hochsetzen.
6. **Mobile 390 px:** `viewport: {width:390,height:844}`; `document.documentElement.scrollWidth
   <= window.innerWidth + 1`; Filter (Button/Panel) und Umschalter Karte↔Liste erreichbar und
   bedienbar; Liste und Detail ebenfalls ohne horizontales Scrollen.

Tests müssen wiederholbar grün sein (`npm run test:e2e`). Keine `test.skip`.

## 2. README.md (Pflicht)

Auf Deutsch, mit funktionierenden Befehlen **in einem frischen Klon**:
- Projektüberblick, Screenshot/Struktur optional.
- Voraussetzungen: Node ≥ 20, npm, Python nicht nötig.
- Setup: `npm install`
- **Datenaufbereitung:** `npm run data` (einziger Befehl; liest
  `~/code/freizeitkarte-daten/` nur lesend, schreibt `public/data/`; optional
  `FREIZEITKARTE_RAW=/pfad npm run data`). Ausgabe-Statistik (Zeilen, Duplikate, geschlossen,
  verworfen, behalten pro Kategorie) als Beispiel-Auszug aus `stats.json`/Build-Output
  dokumentieren, inkl. Gesamtzahl.
- **Build:** `npm run build`
- **Start:** `npm run preview` (bzw. `npm start`) → http://localhost:4173
- **Tests:** `npm test` (Daten), `npm run test:e2e` (Browser; baut + startet selbst)
- Relevanzregel verständlich erklärt oder auf `docs/relevance.md` verwiesen (mit den
  Go-Kart-/Museum-Beispielen).
- Datenformat/Architektur kurz, Hinweis auf statische App (kein Server), OSM-Kacheln brauchen
  Internet.
- Ein Abschnitt „Frischer Klon“: `git clone … && cd … && npm ci && npm run data && npm run
  build && npm test && npm run test:e2e`.

## 3. Gesamtabnahme `ABNAHME-PRUEFUNG.md`

Tabelle aller 21 Kriterien aus `ABNAHME.md`, Spalten: Kriterium | Status | Nachweis (Befehl +
Messwert/Beobachtung). Für jedes Kriterium einen konkreten, wiederholbaren Befehl oder
Testnamen. Konkrete Messwerte eintragen (Performance ms, Anzahl Orte, Duplikate, etc.).

## 4. Prüfen in frischem Klon (Pflicht)

Simuliere einen frischen Klon (ohne `node_modules`, `dist`, ohne untracked Dateien):
```bash
rm -rf /tmp/fk-fresh && git clone /Users/plotti/code/freizeitkarte-deepseek /tmp/fk-fresh
cd /tmp/fk-fresh && npm ci && npm run data && npm run build && npm test
```
Danach `npm run test:e2e` (baut/startet selbst). Alles muss grün sein; dokumentiere die
Ausgaben im README/Abschluss. Achtung: In `/tmp/fk-fresh` ist `main` der Stand vor deinem
Merge; für den Test deines Branches vorher `git -C /tmp/fk-fresh checkout wk/qualitaet` bzw.
den Klon vom Prüf-Worktree machen. Alternativ lokale Kopie ohne node_modules/dist.

## 5. Definition of Done

- `npm test` und `npm run test:e2e` grün, ohne Skips.
- Performance < 3000 ms, 390 px ohne horizontales Scrollen (beides gemessen).
- README vollständig, Befehle im frischen Klon verifiziert.
- `ABNAHME-PRUEFUNG.md` mit allen 21 Kriterien und Nachweisen.
- Build grün, keine Konsolenfehler in den Tests.
- Keine Rohdaten im Repo, keine `node_modules`/`dist` committet.
- Commit auf `wk/qualitaet`.