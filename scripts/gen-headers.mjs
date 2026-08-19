// Generates dist/staticwebapp.config.json at build time. The CSP carries
// sha256 hashes for every inline script the build actually emitted, so
// script-src needs no unsafe-inline (the law) and a script injected at
// runtime by anything else simply does not run.
// style-src keeps 'unsafe-inline': the design system drives dynamic
// values (pill colors, bar widths) through style attributes; scoped
// interpretation recorded in docs/phase-w5.md.
import { readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { createHash } from 'node:crypto';

const dist = new URL('../dist', import.meta.url).pathname;
const hashes = new Set();
const walk = (d) => readdirSync(d).forEach((e) => {
  const p = join(d, e);
  if (statSync(p).isDirectory()) return walk(p);
  if (!p.endsWith('.html')) return;
  const html = readFileSync(p, 'utf8');
  for (const m of html.matchAll(/<script(?:\s+type="module")?\s*>([\s\S]*?)<\/script>/g)) {
    hashes.add(`'sha256-${createHash('sha256').update(m[1]).digest('base64')}'`);
  }
});
walk(dist);

const csp = [
  "default-src 'self'",
  `script-src 'self' ${[...hashes].join(' ')}`,
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data:",
  "font-src 'self'",
  "connect-src 'self'",
  "frame-ancestors 'none'",
  "base-uri 'self'",
  "form-action 'self' https://github.com https://identity.7.azurestaticapps.net",
].join('; ');

const config = {
  platform: { apiRuntime: 'node:20' },
  responseOverrides: { 404: { rewrite: '/404.html' } },
  // Cache policy (W6): hashed assets immutable for a year; HTML short so
  // deploys propagate in minutes; fonts immutable (content-stable names).
  routes: [
    { route: '/api/*', allowedRoles: ['anonymous'] },
    { route: '/_astro/*', headers: { 'Cache-Control': 'public, max-age=31536000, immutable' } },
    { route: '/fonts/*', headers: { 'Cache-Control': 'public, max-age=31536000, immutable' } },
    { route: '/pagefind/*', headers: { 'Cache-Control': 'public, max-age=3600' } },
  ],
  globalHeaders: {
    'Cache-Control': 'public, max-age=300, must-revalidate',
    'Content-Security-Policy': csp,
    // HSTS without preload: preload is one-way like a license (tripwire).
    'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    'X-Content-Type-Options': 'nosniff',
    'Referrer-Policy': 'strict-origin-when-cross-origin',
    'X-Frame-Options': 'DENY',
    'Permissions-Policy': 'camera=(), microphone=(), geolocation=(), interest-cohort=()',
  },
};
writeFileSync(join(dist, 'staticwebapp.config.json'), JSON.stringify(config, null, 2) + '\n');
console.log(`gen-headers: CSP with ${hashes.size} inline-script hash(es), no unsafe-inline for scripts`);
