// House-style lint: em dashes fail the build across all content and UI
// strings. En dash allowed ONLY between digits (numeric ranges).
// Scope: everything a reader sees: src/ and design/copy/.
import { readFileSync, readdirSync, statSync } from 'node:fs';
import { join } from 'node:path';
const roots = ['src', 'design/copy'];
const exts = ['.astro', '.md', '.mdx', '.ts', '.js', '.json', '.txt'];
let bad = 0;
const walk = (d) => {
  for (const e of readdirSync(d)) {
    const p = join(d, e);
    if (statSync(p).isDirectory()) { walk(p); continue; }
    if (!exts.some((x) => p.endsWith(x))) continue;
    const lines = readFileSync(p, 'utf8').split('\n');
    lines.forEach((line, i) => {
      if (line.includes('—')) { console.error(`emdash: ${p}:${i + 1}: em dash`); bad++; }
      const en = line.replace(/\d–\d/g, '');
      if (en.includes('–')) { console.error(`emdash: ${p}:${i + 1}: en dash outside a numeric range`); bad++; }
    });
  }
};
roots.forEach(walk);
if (bad) { console.error(`emdash lint: ${bad} violation(s)`); process.exit(1); }
console.log('emdash lint: clean');
