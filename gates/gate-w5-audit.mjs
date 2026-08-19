// Gate W5's measurement leg (part of the gate; immutable once run).
// Budgets, not vibes: Lighthouse mobile-throttled + axe per page.
import { chromium } from 'playwright';
import AxeBuilder from '@axe-core/playwright';
import lighthouse from 'lighthouse';
import { launch } from 'chrome-launcher';

const BASE = process.env.GATE_BASE ?? 'http://localhost:4321';
const PAGES = [
  { path: '/', kind: 'marketing' },
  { path: '/pricing/', kind: 'marketing' },
  { path: '/docs/', kind: 'docs' },
  { path: '/docs/quickstart/', kind: 'docs' },
];
const PERF_MIN = { marketing: 95, docs: 90 };
let fails = 0;
const out = (ok, msg) => { console.log(`${ok ? 'ASSERT PASS' : 'ASSERT FAIL'}: ${msg}`); if (!ok) fails++; };

const chrome = await launch({ chromeFlags: ['--headless=new'], chromePath: process.env.CHROME_PATH });
for (const p of PAGES) {
  const r = await lighthouse(`${BASE}${p.path}`, {
    port: chrome.port, output: 'json', logLevel: 'error',
    onlyCategories: ['performance', 'accessibility'],
    formFactor: 'mobile', screenEmulation: { mobile: true, width: 360, height: 740, deviceScaleFactor: 2 },
  });
  const lr = r.lhr;
  const perf = Math.round((lr.categories.performance.score ?? 0) * 100);
  const a11y = Math.round((lr.categories.accessibility.score ?? 0) * 100);
  const lcp = lr.audits['largest-contentful-paint'].numericValue;
  const cls = lr.audits['cumulative-layout-shift'].numericValue;
  out(perf >= PERF_MIN[p.kind], `${p.path} performance ${perf} >= ${PERF_MIN[p.kind]} (${p.kind})`);
  out(a11y >= 95, `${p.path} accessibility ${a11y} >= 95`);
  out(lcp < 1800, `${p.path} LCP ${Math.round(lcp)}ms < 1800ms (throttled mobile)`);
  out(cls < 0.1, `${p.path} CLS ${cls.toFixed(3)} < 0.1`);
}
await chrome.kill();

const browser = await chromium.launch();
const page = await browser.newPage();
for (const p of PAGES) {
  await page.goto(`${BASE}${p.path}`, { waitUntil: 'networkidle' });
  const res = await new AxeBuilder({ page }).analyze();
  const critical = res.violations.filter((v) => v.impact === 'critical');
  out(critical.length === 0, `${p.path} axe critical violations: ${critical.length}${critical.length ? ' (' + critical.map((c) => c.id).join(',') + ')' : ''}`);
}
await browser.close();
process.exit(fails ? 1 : 0);
