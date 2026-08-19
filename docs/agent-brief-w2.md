# W2 page-builder brief (read fully before writing anything)

You are building ONE page (or one small set) of keepstate.ai from its
Claude Design composite. Work only on your assigned files.

## Read first
- CLAUDE.md (the laws; especially UI Laws and house lints)
- design/<your composite>.dc.html: your page's spec. Both the static
  HTML (structure, inline styles) and the <script> data blocks (copy
  often lives in JS arrays). Extract with python3, e.g.:
  python3 -c "import re;s=open('design/X.dc.html').read();t=re.sub(r'<script.*?</script>',' ',s,flags=re.S);t=re.sub(r'<style.*?</style>',' ',t,flags=re.S);print(re.sub(r'<[^>]+>','\n',t))"
  and read script data with targeted s.find()/slices.
- src/layouts/Site.astro (use it: title, description props)
- src/components/ (REUSE these; do not reinvent: Button, Field,
  MetricCard, Badge, StatusChip, StatusPill, BudgetBar, Terminal,
  DiamondTimeline, MonoTable, Banner, Toast, Modal, Tabs, CmdK,
  Skeleton, EmptyState, ArtifactCard, Footer)
- src/pages/proof.astro as a style reference
- design/tokens.json: the ONLY color source. Use Tailwind token classes
  (bg-paper, text-ink, text-claret, border-sand, bg-parchment, text-slate,
  text-taupe, bg-blushBg, font-serif/sans/mono, text-9..34, rounded-2..6,
  rounded-pill, shadow-e1..e3). ZERO hex literals in src/ (gate-enforced).

## Laws that will fail the build if you break them
1. NO em dashes anywhere (the char U+2014, and U+2013 outside digit
   ranges). The composites use them; transform to " · " or restructure
   the sentence. Applies to page copy AND your copy file.
2. Numbers: a number that is a CLAIM (a measurement, a rate, a
   duration) may appear ONLY if it exists in src/generated/proof.json
   or the product evidence, and must carry a Badge (MEASURED/ESTIMATED)
   or an evidence link (use MetricCard, or a diamond link to /proof).
   Numbers that are OFFERS (prices, quotas from the Pricing design) are
   spec, not claims. Sample/demo numbers from composites (41.2M, $4,100
   etc.) are illustrations: do NOT ship them as facts. Either use the
   real measured equivalents (19.1x dedup, 25/25 cycles + Wilson CI
   [86.7%, 100.0%], 13.7-25.2 s resumes, door held 4 of 4 / walked 3 of
   4 for aider, +0 MiB RSS over 7 h) with evidence links to /proof, or
   keep the element clearly labeled as an illustration of the UI, or
   render the honest unavailable state.
3. No fake dashboards, no invented customers/testimonials. The
   Customers page ships placeholder CARDS explicitly labeled as
   placeholders per the design.
4. Copy verbatim: put the exact prose lines you carried from the
   composite (after dedashing) into design/copy/<page>.txt, one line
   per line, at least 6 substantive lines. The copy lint asserts each
   line appears in your built page. Only include lines you actually
   rendered.

## Mechanics
- Internal links: only to pages that will exist after W2: /, /manifesto,
  /pricing, /proof, /compatibility, /customers, /enterprise, /security,
  /grants, /careers, /status, /about, /press, /contact,
  /product/sessions, /product/fork, /product/gateway-cost,
  /product/governance-replay, and home anchors /#why-now /#partner.
  Docs/ledger/changelog/legal do NOT exist yet: do not link to them.
- Forms (grants, partner intake, subscribe): render the designed form UI
  with method="post" action="/api/<name>"; backends arrive at W4. Include
  honeypot field style="display:none" name="website".
- Verify YOUR page compiles: npm run build -- --outDir /tmp/dist-<yourpage>
  (never plain npm run build; never touch dist/). Then run:
  node scripts/lint-emdash.mjs
- Do not touch: gates/, scripts/, tokens.json, other pages, components
  (if a component lacks a variant you need, build the variant locally in
  your page with token classes rather than editing shared components).
- Astro syntax notes: frontmatter between --- fences; {expr} for
  interpolation; class not className; map with (item) => (<el/>).
