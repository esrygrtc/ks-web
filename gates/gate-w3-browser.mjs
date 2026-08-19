// Gate W3's browser leg (part of the gate; immutable once run).
// Proves with a real browser: (1) cmd-K search returns the quickstart
// for "resume"; (2) a copy button actually copies its code block.
import { chromium } from 'playwright';
const BASE = process.env.GATE_BASE ?? 'http://localhost:4321';
const out = (ok, msg) => console.log(`${ok ? 'ASSERT PASS' : 'ASSERT FAIL'}: ${msg}`);
let fails = 0;
const browser = await chromium.launch();
const ctx = await browser.newContext({ permissions: ['clipboard-read', 'clipboard-write'] });
const page = await ctx.newPage();

// 1. search
await page.goto(`${BASE}/docs/`, { waitUntil: 'networkidle' });
await page.click('[data-cmdk-open]');
await page.fill('[data-cmdk-input]', 'resume');
await page.waitForTimeout(1200);
const hrefs = await page.$$eval('[data-cmdk-results] a', (as) => as.map((a) => a.getAttribute('href')));
if (hrefs.some((h) => h && h.includes('/docs/quickstart'))) out(true, `search "resume" returns the quickstart (${hrefs.length} results)`);
else { out(false, `search "resume" did not surface the quickstart; got: ${hrefs.join(', ') || 'nothing'}`); fails++; }

// 2. copy button, live
await page.goto(`${BASE}/docs/quickstart/`, { waitUntil: 'networkidle' });
const n = await page.$$eval('pre', (els) => els.length);
const b = await page.$$eval('pre .ks-copy', (els) => els.length);
if (n > 0 && n === b) out(true, `every code block has a copy button (${b}/${n})`);
else { out(false, `copy buttons ${b} != code blocks ${n}`); fails++; }
await page.click('pre .ks-copy');
await page.waitForTimeout(300);
const clip = await page.evaluate(() => navigator.clipboard.readText());
if (clip && clip.length > 10) out(true, `copy button copies real content (${clip.split('\n')[0].slice(0, 40)}...)`);
else { out(false, 'clipboard empty after copy click'); fails++; }

await browser.close();
process.exit(fails ? 1 : 0);
