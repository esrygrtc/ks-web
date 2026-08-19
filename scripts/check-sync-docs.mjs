// Regenerate docs artifacts and compare byte-for-byte (UI Law 4 for docs).
import { readFileSync, writeFileSync } from 'node:fs';
import { execSync } from 'node:child_process';
const files = ['src/generated/docs.json', 'src/content/docs/quickstart.md', 'src/content/docs/limits.md'];
const before = files.map((f) => readFileSync(f, 'utf8'));
try {
  execSync(`node ${new URL('./sync-docs.mjs', import.meta.url).pathname}`, { stdio: 'pipe' });
  const after = files.map((f) => readFileSync(f, 'utf8'));
  let ok = true;
  files.forEach((f, i) => { if (before[i] !== after[i]) { console.error(`check-sync-docs: MISMATCH in ${f}`); ok = false; } });
  if (ok) console.log('check-sync-docs: all synced docs match fresh generation');
  else process.exitCode = 1;
} finally {
  files.forEach((f, i) => writeFileSync(f, before[i]));
}
