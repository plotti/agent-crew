---
description: Zeigt den Stand der Crew: Board, offene Tickets, hängende Branches
allowed-tools: Bash, Read
---

Führe `${CLAUDE_PLUGIN_ROOT}/scripts/board.sh` aus und fasse das Ergebnis in drei Zeilen zusammen:

- Was ist fertig (Status `merged`).
- Was läuft und seit wann keine Änderung mehr.
- Was blockiert ist und warum.

Wenn `.crew/board.md` nicht existiert, sage kurz, dass in diesem Verzeichnis keine Crew läuft.
