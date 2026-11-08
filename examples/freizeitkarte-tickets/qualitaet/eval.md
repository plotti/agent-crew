# eval `qualitaet`

Im Prüf-Worktree von `wk/qualitaet` (alle Features auf `main`).

```bash
npm ci
npm run data           # muss erneut sauber durchlaufen, Statistik ausgeben
npm test               # node --test (Daten-Tests)
npm run build
npm run test:e2e       # Playwright: baut + startet Preview selbst
```

Erwartet: alle Exit 0; `test:e2e` ohne `skip`; Testausgabe enthält den Performance-Messwert
(< 3000 ms) und Mobile-Prüfung; keine Seite-Fehler.

Dokument-/Vertragsprüfung:
```bash
test -f README.md && test -f ABNAHME-PRUEFUNG.md && test -f playwright.config.js
grep -q "npm run data" README.md && grep -q "npm run build" README.md
grep -q "npm run preview" README.md && grep -q "npm test" README.md
grep -q "test:e2e" README.md
grep -c "^- \[\|^| " ABNAHME-PRUEFUNG.md   # alle 21 Kriterien dokumentiert
git ls-files | grep -E "node_modules|dist/|\.venv" && echo "BAD: Artefakte eingecheckt" || echo "clean"
ls public/data/manifest.json public/data/places.json public/data/stats.json
```

Erwartet: alle Pflichtdateien; README nennt `data`, `build`, `preview`, `test`, `test:e2e`;
`ABNAHME-PRUEFUNG.md` deckt alle 21 Kriterien; keine Artefakte eingecheckt.

Unabhängige Gesamtprüfung (Router, kann zusätzlich laufen):
```bash
npx vite preview --port 4174 --strictPort >/tmp/fk-q.log 2>&1 &
SRV=$!; sleep 2
node --input-type=module - <<'JS'
import { chromium } from 'playwright';
const b=await chromium.launch({headless:true});
for (const [w,h,mobile] of [[1440,900,false],[390,844,true]]) {
  const p=await b.newPage({viewport:{width:w,height:h}});
  const errs=[]; p.on('pageerror',e=>errs.push(String(e)));
  const t0=Date.now();
  await p.goto('http://localhost:4174/#/karte');
  await p.waitForFunction(()=>window.__appReady===true && window.__karte?.ready===true,{timeout:30000});
  const ready=Date.now()-t0;
  const r=await p.evaluate(()=>({sw:document.documentElement.scrollWidth,iw:innerWidth,
    count:window.__freizeitkarte.filtered().length,
    total:window.__freizeitkarte.places.length,
    countEl:document.querySelector('#result-count')?.textContent||''}));
  if(r.sw>r.iw+1){console.log('OVERFLOW',{w,h,r});process.exit(1)}
  if(r.count!==r.total){console.log('COUNT BAD',r);process.exit(1)}
  console.log(mobile?'MOBILE':'DESKTOP', {...r, readyMs:ready, errs:errs.length});
}
await b.close();
JS
RC=$?; kill $SRV 2>/dev/null; exit $RC
```
Erwartet: beide Viewports ohne Overflow, Trefferzahl = alle Orte, `readyMs` notieren
(Ziel < 3000), keine Fehler.

Alternative akzeptierte Nachweise: Screenshots `docs/screenshots/*.png` sind optional, nicht
Pflicht.