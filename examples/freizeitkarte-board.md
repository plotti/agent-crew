# Board — Freizeitkarte Schweiz

Aktualisiert: 2026-11-07 14:58

| Ticket | Status | hängt ab von | Branch | Notiz |
|---|---|---|---|---|
| daten | merged | — | wk/daten | F1: 179'906 Zeilen → 17'776 Orte, 35 Kategorien, 26 Kantone, Tests 9/9 grün |
| app-core | merged | — | wk/app-core | Vite-Gerüst, Filter F4, URL, View-API — Build + Smoke mit echten Daten grün |
| karte | merged | app-core, daten | wk/karte | F2: 17'776 Marker geclustert, ready ~0,8 s, Popup+Detaillink, mobile ok |
| liste | merged | app-core, daten | wk/liste | F3: Karten, Sortierung, Paging — 24/Seite, Sort+Paging+URL grün, mobile ok |
| detail | merged | app-core, daten | wk/detail | F5: Detailseite #/ort/:id, alle Felder, Direktlink/Rücklink, mobile ok |
| qualitaet | merged | alle | wk/qualitaet | F6: README, Playwright 15/15, Performance 562–607 ms, 21 Kriterien dokumentiert |

Legende: offen / ready / läuft / fertig / geprüft / merged / blockiert.

## Reihenfolge

1. Welle 1 (parallel, max 3): `daten`, `app-core`.
2. Nach Merge beider: Welle 2 (parallel, max 3): `karte`, `liste`, `detail`.
3. Nach Merge aller: Welle 3: `qualitaet`.
4. Router: Gesamtprüfung gegen ABNAHME.md (21 Kriterien), Schlussmeldung.

## Merges

| Ticket | Branch | Merge-Commit | Notiz |
|---|---|---|---|
| app-core | wk/app-core | dccb40d | Gerüst, Filter, Routing |
| daten | wk/daten | 2405832 | 17'776 Orte, 35 Kategorien, 26 Kantone |
| liste | wk/liste | 689f573 | Fast-forward |
| karte | wk/karte | 28e5362 | Leaflet + Cluster |
| detail | wk/detail | 8321c52 | #/ort/:id |
| qualitaet | wk/qualitaet | 0f90522 | Tests, README, Abnahmeprüfung |

## Router-Abnahme

- Node-Tests: 9/9 grün (`npm test`).
- Playwright: 15/15 grün, keine Skips (`npm run test:e2e`).
- Frischer Klon `/tmp/fk-fresh-final`: `npm ci`, `npm run data`, `npm run build`, `npm test`, `npm run test:e2e` alle Exit 0.
- Performance (Produktions-Preview): Karte bedienbar nach 562–607 ms, Liste nach 329–357 ms (Ziel < 3000 ms).
- Mobile 390 px: kein horizontales Scrollen auf Karte, Liste, Detail.
- Gesamtprüfung ABNAHME.md: 21/21 erfüllt (siehe `ABNAHME-PRUEFUNG.md` im Repo).