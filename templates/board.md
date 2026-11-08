# Board — <projekt>

Aktualisiert: <datum zeit>

| Ticket | Status | hängt ab von | Branch | Notiz |
|---|---|---|---|---|
| `<name>` | offen | — | `wk/<name>` | <was es liefert, in einem Halbsatz> |
| `<name>` | offen | `<name>` | `wk/<name>` | <…> |

Legende: `offen` / `ready` / `läuft` / `fertig` (Arbeiter meldet) / `geprüft` (eval.md grün) /
`merged` / `blockiert`.

## Reihenfolge

1. Welle 1 (parallel, max 3): `<name>`, `<name>` — unabhängig, verschiedene Dateien.
2. Nach Merge beider: Welle 2: `<name>`, `<name>`, `<name>` — bauen auf Welle 1 auf.
3. Nach Merge aller: Welle 3: `<name>` — Qualität, Tests, README, Gesamtprüfung.

## Merges

| Ticket | Branch | Merge-Commit | Notiz |
|---|---|---|---|
| `<name>` | `wk/<name>` | `<sha>` | <eine Zeile> |

## Abnahme durch den Router

- <Befehl> → <Ergebnis>
- <Befehl> → <Ergebnis>
- Gesamtprüfung gegen <Abnahmedatei>: <n>/<n> Kriterien erfüllt.
