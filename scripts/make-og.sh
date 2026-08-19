#!/bin/bash
# Generates public/og.png (1200x630) from a token-styled HTML template.
# Reproducible: re-run any time; fonts come from the self-hosted woff2.
set -euo pipefail
cd "$(dirname "$0")/.."
cat > /tmp/og.html <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><style>
@font-face { font-family: NR; src: url('PWD/public/fonts/Newsreader-500-normal.woff2') format('woff2'); }
@font-face { font-family: JM; src: url('PWD/public/fonts/JetBrainsMono-400-normal.woff2') format('woff2'); }
body { margin:0; width:1200px; height:630px; background:#FBFAF7; display:flex; align-items:center; justify-content:center; }
.card { text-align:left; padding:0 96px; width:100%; }
.mark { display:flex; align-items:center; gap:18px; margin-bottom:28px; }
.diamond { width:26px; height:26px; background:#7A2530; transform:rotate(45deg); }
.name { font-family:NR, Georgia, serif; font-size:56px; color:#16130F; }
.tag { font-family:NR, Georgia, serif; font-size:34px; line-height:1.3; color:#39404C; max-width:900px; }
.line { font-family:JM, monospace; font-size:20px; color:#7A6F60; margin-top:36px; }
.line b { color:#7A2530; font-weight:400; }
</style></head><body><div class="card">
<div class="mark"><div class="diamond"></div><div class="name">KeepState</div></div>
<div class="tag">The durable agent session cloud. Agents survive kill -9 with memory, files, and processes intact.</div>
<div class="line">run · checkpoint · fork · resume · replay &nbsp;&nbsp;<b>every claim cites its gate: /proof</b></div>
</div></body></html>
HTML
sed -i '' "s|PWD|$(pwd)|g" /tmp/og.html
npx playwright screenshot --viewport-size=1200,630 "file:///tmp/og.html" public/og.png >/dev/null 2>&1
echo "og.png: $(ls -la public/og.png | awk '{print $5}') bytes"
