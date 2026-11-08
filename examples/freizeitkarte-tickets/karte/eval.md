# eval `karte`

Im Prüf-Worktree von `wk/karte` (enthält app-core + daten von `main`). `node_modules` aus dem
Haupt-Repo verlinken, falls vorhanden, sonst `npm install`.

```bash
npm install
npm run build
npx vite preview --port 4173 --strictPort >/tmp/fk-preview.log 2>&1 &
SRV=$!; sleep 2
node --input-type=module - <<'JS'
import { chromium } from 'playwright';
const b = await chromium.launch({headless:true});
const p = await b.newPage();
const errs=[]; p.on('pageerror',e=>errs.push(String(e)));
await p.goto('http://localhost:4173/#/karte');
await p.waitForFunction(()=>window.__karte?.ready===true,{timeout:30000});
const s = await p.evaluate(()=>{
  const k=window.__karte, fk=window.__freizeitkarte;
  return {
    markers: k.markers.length ?? [...k.markers.values()].length,
    filtered: fk.filtered().length,
    total: fk.places.length,
    zoom: k.map.getZoom(),
    center: k.map.getCenter(),
    clusterLayers: k.cluster.getLayers().length,
    mapEl: !!document.querySelector('#map .leaflet-container'),
    readyMs: performance.now()
  };
});
if(s.markers!==s.filtered) {console.log('BAD markers',s);process.exit(1);}
if(!s.mapEl || s.zoom<5) {console.log('BAD map',s);process.exit(1);}
if(s.center.lat<45.5||s.center.lat>48||s.center.lng<5.5||s.center.lng>10.8){console.log('BAD center',s);process.exit(1);}
if(s.readyMs>3000){console.log('SLOW initial',s.readyMs);}
// Marker-Klick -> Popup mit Name/Kategorie/Bewertung + Detail-Link
const pop = await p.evaluate(()=>{
  const k=window.__karte;
  const arr = Array.isArray(k.markers)?k.markers:[...k.markers.values()];
  const m = arr.find(x=>x.getPopup());
  if(!m) return {err:'no marker with popup'};
  m.fire('click');
  const el=document.querySelector('.leaflet-popup-content');
  return {text:el?el.textContent:'', html:el?el.innerHTML:'', id:m.__placeId};
});
if(!pop.text || !/Details ansehen/i.test(pop.text) || !/#\/ort\//.test(pop.html)){console.log('BAD popup',pop);process.exit(1);}
// Filter wirkt auf Markerbestand
const after = await p.evaluate(async ()=>{
  const fk=window.__freizeitkarte;
  fk.updateState({cats:['museum']});
  await new Promise(r=>setTimeout(r,400));
  const k=window.__karte;
  return {markers:k.markers.length ?? [...k.markers.values()].length, filtered:fk.filtered().length,
          countEl:document.querySelector('#result-count')?.textContent||''};
});
if(after.filtered===0 || after.markers!==after.filtered){console.log('BAD filter',after);process.exit(1);}
// Pan/Zoom ohne Fehler
await p.evaluate(()=>{const m=window.__karte.map;m.panBy([200,120]);m.setZoom(m.getZoom()+1);});
await p.waitForTimeout(500);
if(errs.length){console.log('PAGE ERRORS',errs);process.exit(1);}
console.log('KARTE OK',{...s, after});
await b.close();
JS
RC=$?; kill $SRV 2>/dev/null; exit $RC
```

Erwartet: `KARTE OK`, Exit 0; `markers === filtered === total` beim Start; Popup-Text enthält
Name, Kategorie und Bewertung, HTML enthält `#/ort/`; nach Filter `cats=museum` sinkt die
Markenzahl auf `filtered`; keine Seite-Fehler. Zusätzlich `readyMs` notieren (soll < 3000 sein).

CSS/Responsive-Stichprobe:
```bash
node --input-type=module - <<'JS'
import { chromium } from 'playwright';
const b=await chromium.launch();
const p=await b.newPage({viewport:{width:390,height:844}});
await p.goto('http://localhost:4173/#/karte');
await p.waitForFunction(()=>window.__karte?.ready===true,{timeout:30000});
const r=await p.evaluate(()=>({scrollW:document.documentElement.scrollWidth,innerW:innerWidth,
  mapH:document.querySelector('#view-root')?.getBoundingClientRect().height||0}));
if(r.scrollW>r.innerW+1){console.log('BAD overflow',r);process.exit(1)}
if(r.mapH<300){console.log('BAD map height',r);process.exit(1)}
console.log('MOBILE OK',r); await b.close();
JS
```
(Server wie oben laufen lassen.)