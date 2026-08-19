// sync-docs: every piece of product-derived documentation enters this
// repo through here, snapshot-vendored like sync-claims. Sources:
//   QUICKSTART.md          -> src/content/docs/quickstart.md
//   docs/limitations.md    -> src/content/docs/limits.md
//   cmd/keepstate/usage.go -> CLI reference data (the REAL verbs)
//   internal/ksd/server.go -> API route inventory
//   OPERATOR.md section 6  -> troubleshooting table
//   git tags with bodies   -> changelog entries
// Dedash applies to prose ONLY, never inside fenced code blocks: the
// quickstart's commands are gate-tested bytes and must survive verbatim.
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { execSync } from 'node:child_process';
import { createHash } from 'node:crypto';

const REPO = process.env.KS_PRODUCT_REPO ?? '/Users/c/keepstate';
const SNAP = new URL('../design/.sync/', import.meta.url).pathname;
const live = existsSync(`${REPO}/QUICKSTART.md`);
mkdirSync(SNAP, { recursive: true });

const src = (name, path) => {
  if (live) {
    const b = readFileSync(`${REPO}/${path}`, 'utf8');
    writeFileSync(`${SNAP}${name}`, b);
    return b;
  }
  return readFileSync(`${SNAP}${name}`, 'utf8');
};
const quickstart = src('QUICKSTART.md', 'QUICKSTART.md');
const limitations = src('limitations.md', 'docs/limitations.md');
const usageGo = src('usage.go', 'cmd/keepstate/usage.go');
const serverGo = src('server.go', 'internal/ksd/server.go');
const operator = src('OPERATOR.md', 'OPERATOR.md');
const tagsFull = live
  ? execSync(`git -C ${REPO} tag -l --format='%%TAG%%|%(refname:short)|%(creatordate:short)%%BODY%%%(contents)'`, { encoding: 'utf8' })
  : readFileSync(`${SNAP}tags-full.txt`, 'utf8');
if (live) writeFileSync(`${SNAP}tags-full.txt`, tagsFull);
if (!live) console.error('sync-docs: product repo absent; regenerating from vendored snapshots');

// Product-internal markdown links point at files that exist in the
// product repo, not on this site. claims.md maps to /proof (same
// content, generated); everything else unlinks to its text.
const relink = (line) => line
  .replace(/\[([^\]]+)\]\((?:\.\.\/)?(?:docs\/)?claims\.md[^)]*\)/g, '[$1](/proof)')
  .replace(/\[([^\]]+)\]\((?!https?:\/\/|\/|#)[^)]+\)/g, '$1');

const dedashProse = (md) => {
  let inFence = false;
  return md.split('\n').map((l) => {
    if (l.trim().startsWith('```')) { inFence = !inFence; return l; }
    if (inFence) return l;
    return relink(l).replace(/\s+—\s+/g, ' · ').replace(/—/g, ' · ')
      .replace(/(\d)\s*–\s*(\d)/g, '$1-$2').replace(/–/g, '-');
  }).join('\n');
};

// CLI verbs from the map in usage.go: "name": { synopsis, `usage` }
const verbs = [];
for (const m of usageGo.matchAll(/"([a-z-]+)": \{\s*"((?:[^"\\]|\\.)*)",\s*`([^`]*)`/g)) {
  verbs.push({ verb: m[1], synopsis: m[2].replace(/\\"/g, '"'), usage: m[3] });
}
// API routes from server.go
const routes = [...serverGo.matchAll(/HandleFunc\("([A-Z]+) ([^"]+)"/g)].map((m) => ({ method: m[1], path: m[2] }));

// Troubleshooting table from OPERATOR.md section 6
const sec6 = operator.slice(operator.indexOf('## 6. When something is wrong'));
const trouble = [];
for (const line of sec6.split('\n')) {
  if (!line.startsWith('|')) continue;
  const c = line.replace(/^\||\|$/g, '').split('|').map((x) => dedashProse(x.trim()));
  if (c.length >= 3 && c[0] !== 'Symptom' && !/^[-: ]+$/.test(c[0])) trouble.push({ symptom: c[0], meaning: c[1], action: c[2] });
}

// Changelog from tag bodies
const changelog = [];
for (const chunk of tagsFull.split('%TAG%|').slice(1)) {
  const [head, ...bodyParts] = chunk.split('%BODY%');
  const [tag, date] = head.split('|');
  const body = dedashProse(bodyParts.join('%BODY%').trim());
  changelog.push({ tag: tag.trim(), date: (date ?? '').trim(), body });
}
changelog.sort((a, b) => (a.date < b.date ? 1 : -1));

// Emit content files (generated; the hash registry knows their sources)
const qsOut = `---\ntitle: Quickstart\nsection: Start\norder: 1\ngenerated: sync-docs\n---\n` + dedashProse(quickstart);
writeFileSync('src/content/docs/quickstart.md', qsOut);
const limOut = `---\ntitle: Limits\nsection: Reference\norder: 40\ngenerated: sync-docs\n---\n` +
  `> Synced from the product repository's own limitations file. Every limit cites a measurement or names the missing gate.\n\n` + dedashProse(limitations);
writeFileSync('src/content/docs/limits.md', limOut);

const out = {
  $generated: 'by scripts/sync-docs.mjs; DO NOT EDIT. Re-run the script.',
  sourceSha: createHash('sha256').update(quickstart).update(limitations).update(usageGo).update(serverGo).update(operator).update(tagsFull).digest('hex'),
  productVersion: changelog.find((c) => c.tag.startsWith('v'))?.tag ?? 'unknown',
  verbs, routes, trouble, changelog,
};
writeFileSync('src/generated/docs.json', JSON.stringify(out, null, 2) + '\n');
console.log(`sync-docs: ${verbs.length} verbs, ${routes.length} routes, ${trouble.length} troubleshooting rows, ${changelog.length} changelog entries, source ${out.sourceSha.slice(0, 12)}`);
