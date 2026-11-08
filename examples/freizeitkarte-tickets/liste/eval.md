# eval `liste`

Im Prüf-Worktree von `wk/liste` (app-core + daten von `main`).

```bash
npm install && npm run build
npx vite preview --port 4173 --strictPort >/tmp/fk-preview.log 2>&1 &
SRV=$!; sleep 2
node --input-type=module - <<'JS'
import { chromium } from 'playwright';
const b=await chromium.launch({headless:true});
const p=await b.newPage();
const errs=[]; p.on('pageerror',e=>errs.push(String(e)));
await p.goto('http://localhost:4173/#/liste');
await p.waitForFunction(()=>window.__appReady===true && !!window.__liste,{timeout:30000});
const s=await p.evaluate(()=>({
  rendered: window.__liste.renderedIds.length,
  filtered: window.__freizeitkarte.filtered().length,
  cards: document.querySelectorAll('[data-place-id]').length,
  firstText: (document.querySelector('[data-place-id]')?.textContent||'').replace(/\s+/g,' ').trim(),
  hasImgOrPlaceholder: [...document.querySelectorAll('[data-place-id]')].every(el=>el.querySelector('img,[data-photo-placeholder]')),
  count: document.querySelector('#result-count')?.textContent||'',
  page: window.__liste.page
}));
if(s.rendered>24 || s.cards>24){console.log('BAD renders all',s);process.exit(1);}
if(s.rendered!==Math.min(24,s.filtered)){console.log('BAD page size',s);process.exit(1);}
if(!s.hasImgOrPlaceholder){console.log('BAD card photo',s);process.exit(1);}
if(!/Orte/.test(s.count)){console.log('BAD count',s);process.exit(1);}
// Sortierung
const sort=await p.evaluate(async ()=>{
  const fk=window.__freizeitkarte;
  const first=()=>document.querySelector('[data-place-id]')?.getAttribute('data-name')||document.querySelector('[data-place-id]')?.textContent;
  const a=first(); fk.updateState({sort:'name',page:1});
  await new Promise(r=>setTimeout(r,300));
  const b=first();
  return {a,b,hash:location.hash};
});
if(!sort.hash.includes('sort=name')){console.log('BAD sort url',sort);process.exit(1);}
if(sort.a===sort.b){console.log('WARN sort first unchanged',sort)}
// Paging
const pg=await p.evaluate(async ()=>{
  const fk=window.__freizeitkarte, before=[...window.__liste.renderedIds];
  fk.updateState({page:2}); await new Promise(r=>setTimeout(r,300));
  return {after:[...window.__liste.renderedIds], page:window.__liste.page, hash:location.hash,
          same: before.length===window.__liste.renderedIds.length && before.every((x,i)=>x===window.__liste.renderedIds[i])};
});
if(pg.page!==2 || !pg.hash.includes('page=2') || pg.same){console.log('BAD paging',pg);process.exit(1);}
// Filter
const f=await p.evaluate(async ()=>{
  const fk=window.__freizeitkarte; fk.updateState({cats:['museum'],page:1});
  await new Promise(r=>setTimeout(r,400));
  return {filtered:fk.filtered().length, rendered:window.__liste.renderedIds.length,
          count:document.querySelector('#result-count')?.textContent||''};
});
if(f.filtered===0||f.rendered!==Math.min(24,f.filtered)){console.log('BAD filter',f);process.exit(1);}
// Karte -> Detail
const link=await p.evaluate(()=>{const el=document.querySelector('[data-place-id]'); const a=el.closest('a')||el.querySelector('a'); if(!a) return null; a.click(); return {href:a.getAttribute('href'),hash:location.hash};});
if(!link || !/#\/ort\//.test(link.href)){console.log('BAD detail link',link);process.exit(1);}
if(errs.length){console.log('PAGE ERRORS',errs);process.exit(1);}
console.log('LISTE OK',{...s,sort,pg,f});
await b.close();
JS
RC=$?; kill $SRV 2>/dev/null; exit $RC
```

Erwartet: `LISTE OK`, Exit 0: 24 Einträge gerendert (nicht alle), Foto oder Platzhalter in
jeder Karte, Sort-URL, Seite 2 mit anderen IDs, Filter aktualisiert, Link `#/ort/…`.

Mobile:
```bash
node --input-type=module - <<'JS'
import { chromium } from 'playwright';
const b=await chromium.launch(); const p=await b.newPage({viewport:{width:390,height:844}});
await p.goto('http://localhost:4173/#/liste');
await p.waitForFunction(()=>window.__appReady===true,{timeout:30000});
const r=await p.evaluate(()=>({scrollW:document.documentElement.scrollWidth,innerW:innerWidth,
  cards:document.querySelectorAll('[data-place-id]').length}));
if(r.scrollW>r.innerW+1){console.log('BAD overflow',r);process.exit(1)}
console.log('MOBILE OK',r); await b.close();
JS
```