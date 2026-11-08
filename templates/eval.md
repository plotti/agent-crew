# eval `<name>`

Prüfanleitung für das Ticket `<name>`. Der Router führt sie **selbst** aus, bevor er mergt – nicht
der Arbeiter, und nicht „hat der Arbeiter gesagt“.

Alles hier muss ausführbar sein: Befehl, erwartete Ausgabe, Abbruchkriterium. Wenn ein Kriterium
nicht in einen Befehl passt, ist es kein Kriterium, sondern eine Meinung.

## Prüfumgebung

```bash
# Im Prüf-Worktree von wk/<name>, enthält main + diesen Branch.
git checkout wk/<name>
npm install            # node_modules aus dem Haupt-Repo verlinken, falls vorhanden
npm run build
```

## 1. <Kriterium aus der Abnahme>

```bash
<Befehl>
```

Erwartet: <Ausgabe, Zahl, Exit-Code>. Bricht ab bei: <Fehlerbild>.

## 2. <Kriterium: Grenzfall>

```bash
<Befehl>
```

Erwartet: <Ausgabe>. Bricht ab bei: <Fehlerbild>.

## 3. Messwerte

```bash
<Befehl, der eine Zahl ausgibt, z. B. Ladezeit bis interaktiv>
```

Erwartet: <Schwellwert>, z. B. „Karte bedienbar unter 3000 ms“.

## Ergebnis

| Kriterium | Befehl | Ergebnis | Bestanden |
|---|---|---|---|
| <Kriterium> | `<befehl>` | <Ausgabe> | ja/nein |
| <Kriterium> | `<befehl>` | <Ausgabe> | ja/nein |

Beispiel einer echten Prüfung: `examples/freizeitkarte-tickets/karte/eval.md` – dort lädt ein
Playwright-Skript die gebaute App, wartet auf `window.__karte.ready` und vergleicht Markerzahl,
Zoomstufe und Kartenmitte mit der Erwartung.
