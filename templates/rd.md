# Ticket `<name>` — <was in einem Satz>

Du bist der Arbeiter für dieses Ticket. Projekt: `<projekt-pfad>`, Branch `wk/<name>` (von `main`
abzweigen). Aufgabe: <Aufgabendatei>, Abschnitt <F-nummer>. Abnahme: <Abnahmedatei>, Abschnitt
„<Kriterium>“.

## Kontext

<Was schon auf main liegt und benutzt werden muss: bestehende Module, Daten, Schnittstellen.
Was Abhängigkeiten sind (andere Tickets) und deshalb schon da ist.>

## Branch / Abgabe

1. Erster Schritt: `git checkout -B wk/<name> main`.
2. Nur deine Dateien ändern (siehe unten).
3. Commit auf `wk/<name>`, **nicht mergen** – das macht der Router.
4. Meldung: Umsetzung, ausgeführte Prüfungen mit Ausgabe, Messwerte, offene Punkte.

## Deine Dateien (Eigentum)

- `<datei>` — <was darin entstehen soll>
- `<datei>` (neu) — <zweck>

## NICHT anfassen

- `<datei>`, `<datei>` — gehört dem Ticket `<anderes>`
- `package.json`, `README.md`, Tests, Aufbau-Dateien — gehören app-core / dem Router

## Schnittstelle (verbindlich)

<Was andere Teile von deinem Modul erwarten: Funktionsnamen, Signaturen, Datenformate, URLs.
Ohne diesen Abschnitt baut der Arbeiter an dem vorbei, was das nächste Ticket braucht.>

## Fertig ist, wenn

- <prüfbare Aussage>
- <prüfbare Aussage>

Die Beweise dafür stehen in `eval.md` – führe sie aus, bevor du meldest.
