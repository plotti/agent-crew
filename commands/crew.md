---
description: Startet eine Agenten-Crew für ein Projekt (Router + Tickets + Board + Arbeiter)
argument-hint: "[pfad/zur/AUFGABE.md] [projekt-pfad]"
---

Starte eine Crew. Gehe so vor:

1. **Lade den Vertrag.** Invoke das Skill `agent-crew:crew` und halte dich daran: du bist der Router,
   du schreibst keinen Feature-Code.

2. **Kläre drei Dinge**, falls nicht übergeben (frag den Captain nur, wenn es nicht aus dem
   Arbeitsverzeichnis hervorgeht):
   - Projektpfad und Branch, auf dem gebaut wird (`main`).
   - Aufgabendatei (z. B. `AUFGABE.md`) mit nummerierten Arbeitspaketen.
   - Abnahmedatei (z. B. `ABNAHME.md`) mit prüfbaren Kriterien. Fehlt sie, leite 10–20 Kriterien aus
     der Aufgabe ab und **lass sie vom Captain bestätigen, bevor** du Arbeiter startest.

3. **Lege `.crew/` an:** `tickets/` und `log/`, dazu `.crew/board.md` nach
   `templates/board.md` aus dem Plugin.

4. **Schreibe die Tickets** (4–7) nach `templates/rd.md` und `templates/eval.md`: je Ticket, welche
   Dateien dem Arbeiter gehören, welche tabu sind, und welche Befehle beweisen, dass es fertig ist.

5. **Board + Plan** dem Captain zeigen, dann starten: je Ticket ein Subagent `agent-crew:worker`,
   parallel wo möglich, höchstens 3 gleichzeitig.

6. **Prüfen und mergen** nach `eval.md` (die Befehle führst du selbst aus), Status im Board
   aktualisieren, bei jedem Merge eine Zeile an den Captain. Am Schluss: Gesamtprüfung gegen die
   Abnahmekriterien und drei ehrliche Schwächen.

Watchdog optional im Hintergrund starten: `scripts/watchdog.sh` (Ziel per `CREW_TMUX`), Stand
jederzeit mit `scripts/board.sh`.
