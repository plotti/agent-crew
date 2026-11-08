# eval `daten`

Prüfer-Befehle (Router führt sie in einem temporären Worktree von `wk/daten` aus; `node_modules`
aus dem Haupt-Repo verlinken oder `npm install`). Alle Befehle vom Repo-Root.

```bash
git checkout wk/daten   # im Prüf-Worktree
ls -l scripts/build-data.mjs scripts/data/cantons.geojson tests/data.test.mjs docs/relevance.md
node -e "const g=require('./scripts/data/cantons.geojson'); if(g.features.length!==26)process.exit(1); console.log('cantons ok')"
# xlsx für das Skript bereitstellen (Repo-package.json kommt von app-core):
mkdir -p /tmp/fk-eval-deps && npm install --prefix /tmp/fk-eval-deps xlsx@0.18.5 >/dev/null 2>&1
NODE_PATH=/tmp/fk-eval-deps/node_modules node scripts/build-data.mjs
NODE_PATH=/tmp/fk-eval-deps/node_modules node --test tests/data.test.mjs
```

Erwartet:
- `cantons ok`
- Build endet mit `Behalten: <n>` und `Behalten pro Kategorie:`; Exit 0.
- Tests: `# fail 0`, alle ok.
- `public/data/manifest.json`, `places.json`, `stats.json` vorhanden; `places.json` < 15 MB.
- Statistik-Zahlen konsistent: `manifest.count == places.length == stats.kept`.

Zusätzliche Prüfungen des Routers (eigene Befehle):

```bash
node - <<'JS'
const fs=require('fs');
const p=JSON.parse(fs.readFileSync('public/data/places.json'));
const m=JSON.parse(fs.readFileSync('public/data/manifest.json'));
const s=JSON.parse(fs.readFileSync('public/data/stats.json'));
const ids=new Set(p.map(x=>x.id));
const cats=new Set(m.categories.map(c=>c.slug));
const ct=new Set(['AG','AI','AR','BE','BL','BS','FR','GE','GL','GR','JU','LU','NE','NW','OW','SG','SH','SO','SZ','TG','TI','UR','VD','VS','ZG','ZH']);
let bad=[];
if(ids.size!==p.length) bad.push('dup ids');
if(m.count!==p.length||s.kept!==p.length) bad.push('count mismatch');
for(const x of p){
  if(!x.id||!x.name||!x.cat||!x.canton) bad.push('missing '+x.id);
  if(!cats.has(x.cat)) bad.push('bad cat '+x.cat);
  if(!ct.has(x.canton)) bad.push('bad canton '+x.canton);
  if(!(x.lat>45.7&&x.lat<47.9&&x.lng>5.8&&x.lng<10.6)) bad.push('outside '+x.id);
  if(x.cat==='gokart' && /restaurant|hotel|garage|mechaniker/i.test(x.type||'')) bad.push('gokart noise '+x.id+' '+(x.type||''));
  if(x.cat==='museum' && /restaurant|hotel|café|cafe|bar/i.test(x.type||'')) bad.push('museum noise '+x.id+' '+(x.type||''));
  if(x.cat==='seebad' && /restaurant|hotel/i.test(x.type||'')) bad.push('seebad noise '+x.id+' '+(x.type||''));
  if(bad.length>30) break;
}
console.log('places',p.length,'cats',m.categories.length,'cantons',m.cantons.length);
console.log('discarded',s.discardedClosed,s.discardedOutside,s.discardedIrrelevant,'dups',s.duplicatesRemoved);
if(bad.length){console.error(bad.slice(0,30)); process.exit(1)}
console.log('invariants ok');
JS
```

Erwartet: `invariants ok`, 35 Kategorien im Manifest, 26 Kantone.
Zusätzlich prüfen:
```bash
# Museum-Kategorie enthält Restaurants? (Stichprobe der Namen)
node -e "const p=require('./public/data/places.json'); console.log('museum',p.filter(x=>x.cat==='museum').length,'gokart',p.filter(x=>x.cat==='gokart').length)"
# Rohdaten unverändert: Permissions/Inhalt – Skript hat nur gelesen; git status im Repo sauber
git status --porcelain
```
Erwartet: gokart deutlich kleiner als 1403, museum deutlich kleiner als 7517, aber > 0; keine
fremden Änderungen ausser den Commits.