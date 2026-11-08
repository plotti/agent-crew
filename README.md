# Agent Crew

Ein Router-Agent, der eine grössere Aufgabe in Tickets zerlegt, je Ticket einen Arbeiter startet und
erst mergt, wenn die Prüfung grün ist – **die Prüfung, die vor der Arbeit geschrieben wurde**.

Das ist der Nachbau aus dem Blogpost **[Drei Agenten-Crews, eine
Aufgabe](https://www.datapeople.ch/blog/2026-11-08-drei-agenten-crews/)**: Ein Router in Claude Code,
der nichts selbst schreibt, Arbeiter als Subagenten, ein Board, ein Watchdog – nachgebaut nach dem
Muster, das DeepSeek in seinem Super-Agenten-Prototyp zeigt. Dort bauen drei verschiedene Systeme
dieselbe App; dieses Plugin ist der dritte Kandidat, zum Nachbauen.

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

## Beispiele

In `examples/` liegt ein vollständiger, echter Lauf: 36 Excel-Dateien wurden zu einer Web-App mit
17'776 Orten (Karte, Liste, Filter, Detailseiten), sechs Tickets in drei Wellen, 52 Minuten,
1,03 Dollar. Die laufende App: [freizeitkarte-nachbau.fly.dev](https://freizeitkarte-nachbau.fly.dev/).

Zum Nachbauen nimmt man es sich am besten in dieser Reihenfolge vor:

1. `examples/freizeitkarte-board.md` – wie ein fertiges Board aussieht (Status, Wellen, Merge-Liste).
2. `examples/freizeitkarte-tickets/karte/rd.md` und `…/karte/eval.md` – das Muster für ein Ticket:
   verbindliche Schnittstelle, Datei-Eigentum, prüfbare Befehle mit Messwerten.
3. `examples/freizeitkarte-tickets/daten/eval.md` – eine Prüfung, die Zahlen statt Meinungen liefert.
4. `examples/freizeitkarte-tickets/qualitaet/eval.md` – die Schlussprüfung: frischer Klon, alle
   Befehle von Hand, 21 Kriterien.

Details in [examples/README.md](examples/README.md).

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

## Selbst weitergeben

Das Repo ist gleichzeitig der Marketplace: mehr braucht es nicht, um es jemandem zu geben.

```
/plugin marketplace add plotti/agent-crew
/plugin install agent-crew@agent-crew
```

Kein `version` im Plugin-Manifest heisst: Updates folgen dem Commit, `claude plugin update
agent-crew@agent-crew` holt den neuen Stand. Setzt du eine `version`, musst du sie bei jedem Release
erhöhen, sonst heisst es „already at the latest version“. Automatische Updates sind bei eigenen
Marketplaces standardmässig aus (in `/plugin` → Marketplaces einschaltbar) – der Freund holt sich
den neuen Stand also selbst.

Ohne Marketplace, aus einem Klon: `claude --plugin-dir /pfad/zu/agent-crew` (eine Sitzung lang).

Der Vertrag (`skills/crew/SKILL.md`) ist reiner Text und modell-unabhängig – er funktioniert auch
ohne Plugin, wenn du die Datei in ein `~/.claude/skills/crew/` kopierst. Dann fehlen aber Wächter,
Watchdog, Kommandos und die Arbeiter-Definition.

Der Beitrag, aus dem das hier entstanden ist: **[Drei Agenten-Crews, eine
Aufgabe](https://www.datapeople.ch/blog/2026-11-08-drei-agenten-crews/)** – FirstMate, DeepSeeks
Super-Agent und dieser Nachbau auf derselben Aufgabe, mit Zeiten, Kosten und der Frage, was ein
Arbeiter tut, wenn im Nachbarverzeichnis ein verwandtes Projekt liegt.

## Lizenz

MIT – siehe [LICENSE](LICENSE). Nimm es, bau damit, gib es weiter.
