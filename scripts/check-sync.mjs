// The hash check behind UI Law 4: regenerate proof.json to a temp path
// and compare byte-for-byte with the committed one. A mismatch means
// either a hand edit (forbidden) or staleness against the product repo.
import { readFileSync, renameSync, copyFileSync } from 'node:fs';
import { execSync } from 'node:child_process';
const p = new URL('../src/generated/proof.json', import.meta.url).pathname;
const committed = readFileSync(p, 'utf8');
copyFileSync(p, p + '.bak');
try {
  execSync(`node ${new URL('./sync-claims.mjs', import.meta.url).pathname}`, { stdio: 'pipe' });
  const fresh = readFileSync(p, 'utf8');
  if (fresh !== committed) {
    console.error('check-sync: MISMATCH - proof.json disagrees with a fresh generation (hand edit or stale sync)');
    process.exitCode = 1; // NOT process.exit: that skips finally and strands the .bak
  } else {
    console.log('check-sync: proof.json matches a fresh generation');
  }
} finally {
  renameSync(p + '.bak', p);
}
