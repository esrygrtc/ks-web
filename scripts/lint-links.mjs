// Link lint: zero broken internal links, zero orphan pages, over dist/.
// Exemptions are declared here, visibly, not hidden in logic:
const EXEMPT_ORPHANS = [
  '/design-system/', // internal tooling, linked from nowhere by design
  '/',               // the root is not an orphan
  '/404.html', '/500.html', // error pages: reached by failure, not by links
  '/thanks/', '/sorry/',    // form redirect targets: reached by 303, not by links
];
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { join } from 'node:path';
const dist = new URL('../dist', import.meta.url).pathname;
const pages = [];
const walk = (d) => readdirSync(d).forEach((e) => {
  const p = join(d, e);
  statSync(p).isDirectory() ? walk(p) : p.endsWith('.html') && pages.push(p);
});
walk(dist);
const route = (p) => p.slice(dist.length).replace(/index\.html$/, '');
const resolves = (href) => {
  const clean = href.split('#')[0].split('?')[0];
  if (!clean) return true;
  const c = clean.endsWith('/') ? clean : clean;
  return ['', '.html'].some((s) => existsSync(join(dist, c + s))) ||
    existsSync(join(dist, c, 'index.html')) || existsSync(join(dist, c.replace(/\/$/, '') + '/index.html'));
};
let bad = 0;
const linked = new Set(['/']);
for (const p of pages) {
  // Script bodies are code, not navigation: a template literal like
  // href="${d.url}" inside CmdK's renderer is not a link on the page.
  const html = readFileSync(p, 'utf8').replace(/<script[\s\S]*?<\/script>/g, ' ');
  for (const m of html.matchAll(/href="([^"]+)"/g)) {
    const href = m[1];
    if (/^(https?:|mailto:|#)/.test(href)) continue;
    if (!resolves(href)) { console.error(`links: ${route(p)} -> broken ${href}`); bad++; }
    else linked.add('/' + href.split('#')[0].replace(/^\//, '').replace(/\/$/, '') + (href.split('#')[0] === '/' ? '' : '/'));
  }
}
for (const p of pages) {
  const r = route(p);
  if (!linked.has(r) && !EXEMPT_ORPHANS.includes(r)) { console.error(`links: orphan page ${r}`); bad++; }
}
if (bad) { console.error(`link lint: ${bad} violation(s)`); process.exit(1); }
console.log(`link lint: clean (${pages.length} pages, no broken links, no orphans)`);
