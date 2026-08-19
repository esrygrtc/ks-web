// sync-claims: the ONLY way Proof and Compatibility content enters this
// repo. Reads the product repo read-only (claims.md + git tags) and
// emits src/generated/proof.json with a source hash. Hand-editing the
// output is forbidden; scripts/check-sync.mjs catches both hand edits
// and staleness by regenerating and diffing.
//
// Voice transform, mechanical and deterministic: the product's em dashes
// become middle dots (the web house style bans em dashes); en dashes
// survive only between digits. No other rewriting of any kind.
import { readFileSync, writeFileSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { createHash } from 'node:crypto';

const REPO = process.env.KS_PRODUCT_REPO ?? '/Users/c/keepstate';
const md = readFileSync(`${REPO}/docs/claims.md`, 'utf8');
const tagsRaw = execSync(`git -C ${REPO} tag -l --format='%(refname:short)|%(contents:subject)'`, { encoding: 'utf8' });
let tags; // dedash below, after its definition

const dedash = (s) => s
  .replace(/\s+—\s+/g, ' · ')
  .replace(/—/g, ' · ')
  .replace(/(\d)\s*–\s*(\d)/g, '$1-$2')
  .replace(/–/g, '-');

tags = tagsRaw.trim().split('\n').map((l) => {
  const [tag, ...rest] = l.split('|');
  return { tag, subject: dedash(rest.join('|')) };
});

const cells = (line) => line.trim().replace(/^\||\|$/g, '').split('|').map((c) => dedash(c.trim()));

const section = (name) => {
  const i = md.indexOf(`## ${name}`);
  if (i < 0) throw new Error(`claims.md: section "${name}" missing`);
  const j = md.indexOf('\n## ', i + 4);
  return md.slice(i, j < 0 ? md.length : j);
};

// Proven table
const proven = [];
for (const line of section('Proven').split('\n')) {
  if (!line.trim().startsWith('|')) continue;
  const c = cells(line);
  if (c.length < 3 || c[0] === 'Claim' || /^-+$/.test(c[0].replace(/[: ]/g, '-'))) continue;
  if (/^[-: ]+$/.test(c[0])) continue;
  proven.push({ claim: c[0], provenBy: c[1], evidence: c[2] });
}

// Anti-claims: bold-led bullets, kept as prose; the compatibility matrix
// table inside the section becomes structured rows.
const anti = section('Deliberately not claimed');
const antiClaims = [];
for (const m of anti.matchAll(/^- \*\*([^*]+)\*\*(.*?)(?=\n- \*\*|\n## |$)/gms)) {
  antiClaims.push({ head: dedash(m[1].trim()), body: dedash(m[2].replace(/\n {2}/g, ' ').replace(/\|.*\|/gs, '').replace(/\s+/g, ' ').trim()) });
}
const matrix = [];
for (const line of anti.split('\n')) {
  if (!line.trim().startsWith('|')) continue;
  const c = cells(line);
  if (c.length < 3 || c[0] === 'Agent' || /^[-: ]+$/.test(c[0])) continue;
  matrix.push({ agent: c[0], verdict: c[1], evidence: c[2] });
}

const closing = dedash(section('The rule this file exists to enforce')
  .split('\n').slice(1).join(' ').replace(/\s+/g, ' ').trim());

const invariant = dedash(md.slice(0, md.indexOf('## ')).split('\n').filter((l) => l.trim() && !l.startsWith('#')).join(' ').replace(/\s+/g, ' '));

const out = {
  $generated: 'by scripts/sync-claims.mjs; DO NOT EDIT. Re-run the script.',
  sourceSha: createHash('sha256').update(md).update(tagsRaw).digest('hex'),
  syncedFrom: { repo: 'esrygrtc/ks', file: 'docs/claims.md' },
  invariant, tags, proven, antiClaims, matrix, closing,
};
writeFileSync(new URL('../src/generated/proof.json', import.meta.url), JSON.stringify(out, null, 2) + '\n');
console.log(`sync-claims: ${proven.length} proven rows, ${antiClaims.length} anti-claims, ${matrix.length} matrix rows, ${tags.length} tags, source ${out.sourceSha.slice(0, 12)}`);
