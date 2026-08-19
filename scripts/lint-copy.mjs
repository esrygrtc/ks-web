// Copy fidelity: pages whose copy was specified verbatim in the design
// are checked line-by-line: every line of design/copy/<page>.txt must
// appear in the built page's visible text. Drift fails.
import { readFileSync, readdirSync, existsSync, statSync } from 'node:fs';
import { join, relative } from 'node:path';
const copyDir = new URL('../design/copy/', import.meta.url).pathname;
const dist = new URL('../dist/', import.meta.url).pathname;
const strip = (h) => h.replace(/<script[\s\S]*?<\/script>/g, ' ').replace(/<[^>]+>/g, ' ').replace(/&amp;/g, '&').replace(/&#39;|&#x27;/g, "'").replace(/&quot;/g, '"').replace(/\s+/g, ' ');
let bad = 0, checked = 0;
const files = [];
const walk = (d) => readdirSync(d).forEach((e) => {
  const p = join(d, e);
  statSync(p).isDirectory() ? walk(p) : p.endsWith('.txt') && files.push(relative(copyDir, p));
});
walk(copyDir);
for (const f of files) {
  const page = f.replace('.txt', '');
  const candidates = [`${dist}${page}/index.html`, `${dist}${page}.html`, page === 'index' ? `${dist}index.html` : null].filter(Boolean);
  const target = candidates.find(existsSync);
  if (!target) { console.error(`copy: no built page for design/copy/${f}`); bad++; continue; }
  const text = strip(readFileSync(target, 'utf8'));
  for (const line of readFileSync(copyDir + f, 'utf8').split('\n').map((l) => l.trim()).filter((l) => l && !l.startsWith('#'))) {
    checked++;
    if (!text.includes(line.replace(/\s+/g, ' '))) { console.error(`copy: ${page} drifted from design: "${line.slice(0, 70)}"`); bad++; }
  }
}
if (bad) { console.error(`copy lint: ${bad} violation(s)`); process.exit(1); }
console.log(`copy lint: clean (${checked} verbatim lines held)`);
