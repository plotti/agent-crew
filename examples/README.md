# Beispiele: ein echter Crewlauf

Hier liegt ein vollständiger Lauf, nicht ein erfundener: **36 Excel-Dateien vom Outscraper-Export
wurden zu einer Web-App mit 17'776 Orten** – Karte mit Clustern, Liste mit Nachladen, Filter,
Detailseiten. Sechs Tickets, drei Wellen, ein Router, Arbeiter als Subagenten. Dauer 52 Minuten,
Kosten 1,03 Dollar (DeepSeek V4.1 Flash über OpenRouter).

Der Beitrag dazu: **[Drei Agenten-Crews, eine Aufgabe](https://www.datapeople.ch/blog/2026-11-08-drei-agenten-crews/)**
– dieselbe Aufgabe, gelöst von FirstMate, von DeepSeeks Super-Agenten und von diesem Nachbau.

Die laufende App: **[freizeitkarte-nachbau.fly.dev](https://freizeitkarte-nachbau.fly.dev/)**

## Was hier liegt

| Datei | Anschauen, wenn du wissen willst … |
|---|---|
| `freizeitkarte-board.md` | … wie ein fertiges Board aussieht: Status, Wellen, Merge-Liste, Router-Abnahme |
| `freizeitkarte-tickets/daten/rd.md` | … wie ein Ticket die Datenarbeit beschreibt: Relevanzregel, Datei-Eigentum, Kantonszuordnung |
| `freizeitkarte-tickets/daten/eval.md` | … wie eine Prüfung aussieht, die Zahlen statt Meinungen liefert (Dubletten, Kategorien, Grenzfälle) |
| `freizeitkarte-tickets/karte/rd.md` + `eval.md` | … das Muster für ein UI-Ticket: verbindliche Schnittstelle, Playwright-Prüfung mit Messwerten |
| `freizeitkarte-tickets/app-core/rd.md` | … wie ein Ticket definiert, welche Dateien tabu sind, damit zwei Arbeiter sich nicht in die Quere kommen |
| `freizeitkarte-tickets/qualitaet/eval.md` | … die Schlussprüfung: frischer Klon, alle Befehle von Hand, 21 Kriterien |

Die Pfade in den Tickets zeigen auf das Verzeichnis, in dem der Lauf damals stattfand
(`~/code/freizeitkarte-deepseek`, Rohdaten in `~/code/freizeitkarte-daten`). Für einen eigenen Lauf
schreibt der Router die Pfade neu – nimm die Dateien als Form, nicht als Inhalt.

## Der Ablauf in vier Zeilen

1. **Welle 1** (parallel): `daten` (Aufbereitung) und `app-core` (Gerüst, Routing, Filter).
2. **Welle 2** (parallel, baut auf Welle 1 auf): `karte`, `liste`, `detail` – je ein View-Modul.
3. **Welle 3**: `qualitaet` – README, Playwright-Tests, Gesamtprüfung gegen die 21 Kriterien.
4. **Router**: eigene Abnahme, dann Meldung an den Captain mit Schlusszahlen und drei Schwächen.
