# eval `app-core`

Im Prüf-Worktree von `wk/app-core`. Für den Funktionstest echte Daten aus dem Haupt-Repo
verlinken, falls im Branch noch kein `public/data` liegt (nicht committen!):

```bash
if [ ! -f public/data/manifest.json ]; then ln -s /Users/plotti/code/freizeitkarte-deepseek/public/data public/data; fi
npm install
npm run build
```

Erwartet: `vite build` Exit 0, `dist/index.html` + `dist/assets/*.js` vorhanden.

Statische Vertragsprüfung:
```bash
grep -q "export function mount" src/views/map.js && grep -q "export function update" src/views/map.js
grep -q "export function mount" src/views/list.js && grep -q "export function update" src/views/list.js
grep -q "export function renderDetail" src/views/detail.js
grep -q "__appReady" src/main.js
grep -q "history.replaceState\|location.hash" src/router.js
```
Erwartet: alle Exit 0.

Server + Browser-Smoke (Playwright ist in den devDependencies; Chromium liegt im Cache):
```bash
npx vite preview --port 4173 --strictPort >/tmp/fk-preview.log 2>&1 &
SRV=$!; sleep 2
node --input-type=module - <<'JS'
import { chromium } from 'playwright';
const b = await chromium.launch({headless:true});
const p = await b.newPage();
const errors=[]; p.on('pageerror',e=>errors.push(String(e)));
await p.goto('http://localhost:4173/#/karte');
await p.waitForFunction(()=>window.__appReady===true,{timeout:30000});
const base = await p.evaluate(()=>({
  count: window.__freizeitkarte.filtered().length,
  total: window.__freizeitkarte.places.length,
  manifest: window.__freizeitkarte.manifest.count,
  hash: location.hash,
  countEl: document.querySelector('#result-count')?.textContent || ''
}));
if(!(base.total===base.manifest && base.count===base.total)) { console.log('BAD base',base); process.exit(1); }
await p.evaluate(()=>window.__freizeitkarte.updateState({cats:['museum'],minRating:4,minReviews:10,q:'zür'}));
const f = await p.evaluate(()=>({
  count: window.__freizeitkarte.filtered().length,
  hash: location.hash,
  countEl: document.querySelector('#result-count')?.textContent || ''
}));
if(!f.hash.includes('cats=museum') || !f.hash.includes('minr=4') || !f.hash.includes('minrev=10')) { console.log('BAD url',f); process.exit(1); }
if(f.count>=base.total) { console.log('BAD filter no-op',f); process.exit(1); }
const digits=s=>String(s).replace(/[^0-9]/g,'');
if(!digits(f.countEl).includes(String(f.count))) { console.log('BAD count element',f); process.exit(1); }
// Reload / geteilter Link
await p.reload();
await p.waitForFunction(()=>window.__appReady===true,{timeout:30000});
const r = await p.evaluate(()=>({count:window.__freizeitkarte.filtered().length, st:window.__freizeitkarte.state, hash:location.hash}));
if(r.count!==f.count || r.st.minRating!==4 || r.st.minReviews!==10 || r.st.canton!=='') { console.log('BAD restore',r); process.exit(1); }
// Ansichtswechsel behält Filter
await p.click('text=Liste');
const l = await p.evaluate(()=>({count:window.__freizeitkarte.filtered().length, hash:location.hash, view:window.__freizeitkarte.state.view}));
if(l.view!=='list' || l.count!==f.count || !l.hash.startsWith('#/liste')) { console.log('BAD view switch',l); process.exit(1); }
if(errors.length){console.log('PAGE ERRORS',errors);process.exit(1);}
console.log('SMOKE OK', {total:base.total, filtered:f.count, hash:f.hash});
await b.close();
JS
RC=$?; kill $SRV 2>/dev/null; exit $RC
```

Erwartet: `SMOKE OK { total: <n>, filtered: <m>, hash: '#/karte?cats=museum&…' }`, Exit 0.

Zusätzlich:
```bash
npm run build >/dev/null && echo build-ok
node -e "const fs=require('fs');const h=fs.readFileSync('index.html','utf8');if(!/name=\"viewport\"/.test(h))process.exit(1);if(!/id=\"result-count\"/.test(h))process.exit(1);console.log('html-ok')"
```
Erwartet: `build-ok`, `html-ok`.