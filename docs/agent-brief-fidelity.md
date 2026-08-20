# Fidelity rebuild brief (founder ruling, 2026-08-20)

The founder ruled: the built pages drifted from the Claude Design
composites and THE DESIGN IS THE SPEC, down to every detail: content,
section order, colors, divs, fonts, sizes, animations. Your job is to
make your page(s) visually indistinguishable from the composite.

## The loop (looking is the job)
1. Serve the design dir: cd design && python3 -m http.server <PORT_A> &
2. Screenshot the composite FULL PAGE:
   npx playwright screenshot --full-page --viewport-size=1280,900 \
     --wait-for-timeout=3000 "http://localhost:<PORT_A>/<Name>.dc.html" /tmp/<page>-design.png
3. READ the screenshot with the Read tool. Study it.
4. Read the composite SOURCE (python3 slicing; the body markup carries
   exact inline styles; the DCLogic script carries data + animations).
5. Rebuild the page to mirror it 1:1. Use Tailwind arbitrary values for
   exact px (text-[30px], tracking-[-0.02em], clamp() in brackets).
6. Build to your own dir: npx astro build --outDir /tmp/dist-<page>
   Serve it: python3 -m http.server <PORT_B> -d /tmp/dist-<page> &
   Screenshot your page the same way. READ IT. Compare side by side.
7. Iterate until they match. Kill your servers when done.

## Laws that survive the fidelity ruling (constitution)
- Colors ONLY via tokens.json classes/values (28 named colors now,
  including mist/slateLine/slateSoft/inkLine for dark bands). If the
  composite uses a hex with no token: use the visually nearest token,
  add a comment `/* TODO token <hex> */`, and list it in your report.
- No em dashes in copy (en dash allowed between digits, e.g. 50–70%).
- Design content is VERBATIM, including its numbers ("under 100 ms",
  "50–70%"): the founder overruled the proof-only-numbers rule for
  marketing depiction. THREE carve-outs remain, constitution-level:
  (a) live status/uptime data may never fake green: match the Status
  layout exactly but render its unavailable states; (b) named
  third-party people/companies/quotes that do not exist stay as the
  designed placeholder treatment (report them); (c) the console ships
  the honest shell, not mock dashboards.
- Links: composite .dc.html hrefs map to real routes (/pricing, /proof,
  /docs, /manifesto, /#partner, ...). No links to nonexistent pages.
- Forms that already work (action="/api/...", honeypot) KEEP their
  working mechanics inside the design's exact visual shell.
- Animations in the DCLogic script are part of the design: reproduce
  them with vanilla inline <script> (see src/pages/index.astro for the
  reference pattern: typewriter, IntersectionObserver draw-ins,
  count-ups, prefers-reduced-motion static fallback).
- Update design/copy/<page>.txt with 8+ verbatim lines you rendered
  (subdirs allowed, e.g. design/copy/legal/terms.txt).
- Do not touch: gates/, scripts/, tokens files, other agents' pages.
  src/pages/index.astro is DONE: read it as the reference, never edit.

## Report (under 15 lines)
Sections matched, animations implemented, carve-outs applied, hexes
missing from tokens, copy file line count, final screenshot verdict
(you looked at both: say "match" only if a designer would).
