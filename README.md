# Agent Crew

Ein Router-Agent, der eine grössere Aufgabe in Tickets zerlegt, je Ticket einen Arbeiter startet und
erst mergt, wenn die Prüfung grün ist – **die Prüfung, die vor der Arbeit geschrieben wurde**.

Das ist der Nachbau aus dem Blogpost *„Drei Agenten-Crews, eine Aufgabe“*
(https://www.datapeople.ch/blog/2026-11-08-drei-agenten-crews/): Ein Router in Claude Code, der
nichts selbst schreibt, Arbeiter als Subagenten, ein Board, ein Watchdog – nachgebaut nach dem
Muster, das DeepSeek in seinem Super-Agenten-Prototyp zeigt.

## Installation

```
/plugin marketplace add plotti/agent-crew
/plugin install agent-crew@agent-crew
```

Ohne Marketplace, aus einem lokalen Klon (eine Sitzung lang):

```bash
claude --plugin-dir ~/code/agent-crew
```

## Loslegen

```
/agent-crew:crew AUFGABE.md
```

Der Router fragt nach Projektpfad und Abnahmedatei, legt `.crew/` an, schreibt 4–7 Tickets
(`rd.md` = was zu tun ist, `eval.md` = wie es geprüft wird), zeigt das Board und startet dann die
Arbeiter. Stand jederzeit mit:

```
/agent-crew:board
```

Voraussetzungen: Claude Code, ein Git-Repo mit `main`, eine Aufgabendatei mit nummerierten
Arbeitspaketen und eine Abnahmedatei mit prüfbaren Kriterien. Fehlt die Abnahmedatei, leitet der
Router Kriterien aus der Aufgabe ab und legt sie dir vor, **bevor** er Arbeiter startet.

## Was drin ist

| Teil | Datei | Zweck |
|---|---|---|
| Router-Vertrag | `skills/crew/SKILL.md` | Der eigentliche Inhalt: Ablauf, Regeln, Rollen |
| Arbeiter | `agents/worker.md` | Ein-Ticket-Arbeiter: Branch `wk/<name>`, kein Merge, Meldung mit Messwerten |
| Start | `commands/crew.md` | `/agent-crew:crew` |
| Stand | `commands/board.md`, `scripts/board.sh` | Board, Branch-Alter, hängende Kandidaten |
| Wächter | `hooks/router-guard.sh` | Blockiert den Router, wenn er ausserhalb von `.crew/` schreiben will |
| Watchdog | `scripts/watchdog.sh` | Alle 10 Minuten ein Bericht an den Router |
| Muster | `templates/` | `rd.md`, `eval.md`, `board.md` zum Ausfüllen |
| Beispiel | `examples/` | Ein echter Lauf: 6 Tickets, Board, Prüfanleitungen (Freizeitkarte Schweiz) |

## Der Wächter

Die Regel „der Router schreibt keinen Feature-Code“ ist als Hook erzwungen, nicht nur als Bitte:
`PreToolUse` auf `Write|Edit|NotebookEdit` blockiert Schreibzugriff ausserhalb von `.crew/`.

Drei Bedingungen müssen alle zutreffen, damit blockiert wird:

1. Im Projekt läuft eine Crew (`.crew/board.md` existiert).
2. Der Aufruf kommt **nicht** aus einem Subagenten (kein `agent_id` im Hook-Eingabe-JSON) – Arbeiter
   sind Subagenten und werden nie blockiert.
3. Die Zieldatei liegt ausserhalb von `.crew/`.

Bekannte Grenzen, ehrlich gesagt:

- Der Wächter sieht `Write`, `Edit` und `NotebookEdit`. Ein Router, der per Bash-Heredoc in eine
  Quelldatei schreibt, kommt daran vorbei. Es ist ein Stolperdraht, kein Gefängnis.
- Läuft im selben Klon eine zweite Sitzung, gilt der Wächter auch für deren Hauptagenten. Wer
  während eines Crewlaufs selbst am Code arbeiten will, nimmt einen zweiten Klon – das ist ohnehin
  die sauberere Trennung.
- Kein `python3` und kein `jq` gefunden, unlesbares JSON: der Wächter blockiert nichts. Ein Wächter,
  der den Lauf kaputt macht, ist schlimmer als keiner.
- POSIX (macOS, Linux). Unter Windows braucht es Git-Bash.

## Zwei Lehren aus dem echten Lauf

**Isolation.** In unserem Benchmark hat der billigste Arbeiter im Nachbarverzeichnis ein verwandtes
Projekt gefunden und Dateien zeichengleich übernommen – angekündigt als „nur für Kontext ansehen“.
Ein eigener Klon pro Crew ist Pflicht, und die Arbeiteranweisung in `agents/worker.md` verbietet
Blicke nach draussen ausdrücklich. Verhindern kann das nur der Captain: Rechte, Container, ein
eigenes Konto. Ein Agent mit Vollzugriff auf das Home-Verzeichnis liest, was er findet.

**Prüfung vor der Arbeit.** Der Unterschied zwischen einer Crew und einem Haufen Agenten ist
`eval.md`: bevor ein Arbeiter anfängt, steht fest, woran das Ergebnis gemessen wird. Fertig ist
nicht, wenn der Arbeiter „fertig“ sagt, sondern wenn der Router die Befehle ausgeführt hat. Ohne
diesen Schritt ist die Crew nur ein schnellerer Haufen.

## Kosten

Ein Crewlauf in der Grösse des Beispiels (36 Excel-Dateien → Web-App mit 17'776 Orten, 6 Tickets)
hat 52 Minuten und **1,03 Dollar** gekostet – mit DeepSeek V4.1 Flash über OpenRouter und
Prompt-Caching, weil der wiederkehrende Repo-Kontext gecacht wird. Mit Claude-Modellen kostet
derselbe Lauf ein Vielfaches; für einen Prototyp ist das Modell zweitrangig, der Vertrag ist der
Unterschied. Wichtig: `/cost` nur glauben, wenn das Modell bekannt ist – für fremde Modelle rechnet
Claude Code mit Claude-Preisen.

## Wenn du es weitergeben willst

Diese Dateien als Repo auf GitHub legen (Name `agent-crew`, damit die beiden Befehle oben stimmen),
dann reicht der Freundin / dem Freund:

```
/plugin marketplace add <dein-konto>/agent-crew
/plugin install agent-crew@agent-crew
```

Kein `version` im Plugin-Manifest heisst: Updates folgen dem Commit, `claude plugin update
agent-crew@agent-crew` holt den neuen Stand. Setzt du eine `version`, musst du sie bei jedem Release
erhöhen, sonst heisst es „already at the latest version“.

Der Vertrag (`skills/crew/SKILL.md`) ist reiner Text und modell-unabhängig – er funktioniert auch
ohne Plugin, wenn du die Datei in ein `~/.claude/skills/crew/` kopierst. Dann fehlen aber Wächter,
Watchdog, Kommandos und die Arbeiter-Definition.
