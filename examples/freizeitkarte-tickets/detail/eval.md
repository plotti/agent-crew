# eval `detail`

Im Prüf-Worktree von `wk/detail` (app-core + daten von `main`).

```bash
npm install && npm run build
npx vite preview --port 4173 --strictPort >/tmp/fk-preview.log 2>&1 &
SRV=$!; sleep 2
node --input-type=module - <<'JS'
import fs from 'node:fs';
import { chromium } from 'playwright';
const places=JSON.parse(fs.readFileSync('public/data/places.json','utf8'));
const full=places.find(x=>x.photo&&x.desc&&x.phone&&x.site&&x.hours&&x.addr) || places[0];
const bare=places.find(x=>!x.photo&&!x.desc&&!x.phone&&!x.site&&!x.hours) || places.find(x=>!x.phone) || places[0];
const b=await chromium.launch({headless:true}); const p=await b.newPage();
const errs=[]; p.on('pageerror',e=>errs.push(String(e)));
await p.goto('http://localhost:4173/#/ort/'+encodeURIComponent(full.id));
await p.waitForFunction(()=>window.__detail?.rendered===true,{timeout:30000});
const s=await p.evaluate(()=>({
  id: window.__detail.id,
  attr: document.querySelector('[data-detail-id]')?.getAttribute('data-detail-id'),
  text: (document.querySelector('#detail-root')?.textContent||'').replace(/\s+/g,' ').trim(),
  tel: [...document.querySelectorAll('a[href^="tel:"]')].length,
  site: [...document.querySelectorAll('a[href^="http"]')].map(a=>a.href),
  back: document.querySelector('a[href*="#/"]')?.getAttribute('href')||'',
  imgs: document.querySelectorAll('#detail-root img').length
}));
const need=[full.name, full.city, full.canton];
for(const n of need) if(n && !s.text.includes(n)){console.log('MISSING',n,s);process.exit(1);}
if(s.id!==full.id || s.attr!==full.id){console.log('BAD id',s);process.exit(1);}
if(full.phone && s.tel<1){console.log('BAD tel',s);process.exit(1);}
if(full.site && !s.site.some(u=>u.includes(full.site.replace(/^https?:\/\//,'').replace(/\/$/,'')))){console.log('BAD site',s);process.exit(1);}
if(!s.back.includes('#/')){console.log('BAD back',s);process.exit(1);}
if(!s.imgs>0){console.log('BAD photo',s);process.exit(1);}
// Ort ohne optionale Felder
await p.goto('http://localhost:4173/#/ort/'+encodeURIComponent(bare.id));
await p.waitForFunction(()=>window.__detail?.rendered===true,{timeout:30000});
const t2=await p.evaluate(()=>(document.querySelector('#detail-root')?.textContent||''));
if(/\bnull\b|\bundefined\b/i.test(t2)){console.log('BAD null/undefined',t2.slice(0,300));process.exit(1);}
// Unbekannte ID
await p.goto('http://localhost:4173/#/ort/gibt-es-nicht-123');
await p.waitForTimeout(600);
const t3=await p.evaluate(()=>(document.querySelector('#detail-root')?.textContent||''));
if(!/nicht gefunden/i.test(t3)){console.log('BAD unknown id',t3.slice(0,200));process.exit(1);}
if(errs.length){console.log('PAGE ERRORS',errs);process.exit(1);}
console.log('DETAIL OK',{full:full.id,bare:bare.id,text:s.text.slice(0,180)});
await b.close();
JS
RC=$?; kill $SRV 2>/dev/null; exit $RC
```

Erwartet: `DETAIL OK`, Exit 0; Pflichtfelder im Text; `tel:`, Website-Link, Rücklink `#/…`;
unbekannte ID freundliche Meldung; kein `null`/`undefined`.

Mobile:
```bash
node --input-type=module - <<'JS'
import fs from 'node:fs';
import { chromium } from 'playwright';
const places=JSON.parse(fs.readFileSync('public/data/places.json','utf8'));
const p0=places.find(x=>x.photo)||places[0];
const b=await chromium.launch(); const p=await b.newPage({viewport:{width:390,height:844}});
await p.goto('http://localhost:4173/#/ort/'+encodeURIComponent(p0.id));
await p.waitForFunction(()=>window.__detail?.rendered===true,{timeout:30000});
const r=await p.evaluate(()=>({scrollW:document.documentElement.scrollWidth,innerW:innerWidth}));
if(r.scrollW>r.innerW+1){console.log('BAD overflow',r);process.exit(1)}
console.log('MOBILE OK',r); await b.close();
JS
```