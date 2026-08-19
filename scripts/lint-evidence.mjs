// Evidence lint: every Proof claim row and Compatibility matrix row must
// cite a tag that exists in the synced tag list. An evidence-free row is
// a promise without proof and fails the build.
import { readFileSync } from 'node:fs';
const d = JSON.parse(readFileSync(new URL('../src/generated/proof.json', import.meta.url), 'utf8'));
const tagSet = new Set(d.tags.map((t) => t.tag));
let bad = 0;
for (const row of d.proven) {
  const cited = [...(row.provenBy + ' ' + row.evidence).matchAll(/(gate-[0-9a-z]+-green|v\d+\.\d+\.\d+[\w.-]*)/g)].map((m) => m[1]);
  if (!cited.length) { console.error(`evidence: proven row cites nothing: "${row.claim.slice(0, 50)}"`); bad++; continue; }
  for (const c of cited) if (!tagSet.has(c)) { console.error(`evidence: row cites missing tag ${c}: "${row.claim.slice(0, 40)}"`); bad++; }
}
for (const row of d.matrix) {
  if (!/gate-[0-9a-z]+-green/.test(row.verdict + row.evidence)) { console.error(`evidence: matrix row without a gate tag: ${row.agent}`); bad++; }
}
if (bad) { console.error(`evidence lint: ${bad} violation(s)`); process.exit(1); }
console.log(`evidence lint: clean (${d.proven.length} claims, ${d.matrix.length} matrix rows, all cited)`);
