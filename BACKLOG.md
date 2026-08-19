# BACKLOG — keepstate-web

Gaps between design/ and WEBPLAN.md, recorded per the kickoff rule: gaps
go here, not into guesses. Plus anything found later that the current
phase's scope fence forbids fixing.

## Design gaps (WEBPLAN names the page; design/ has no dedicated file)

### G1. Compatibility page has no dedicated design
WEBPLAN W2 names Compatibility as a sync-claims-generated page. The word
appears inside six composites (Docs, Security, Grants, Customers, Footer,
Component Sheet) but no `Compatibility.dc.html` exists. Resolution when
W2 arrives: generate it with the same table components the Proof design
uses (Proof.dc.html is the design source for evidence-linked claim rows);
confirm with the founder before building anything novel.

### G2. About, Press, Contact have no designs
WEBPLAN W2 lists all three. No dedicated composites exist, and the Footer
System's link inventory surfaces Status/Support but none of these three.
The words appear only inside body copy of other pages. Resolution:
either the founder supplies designs, or W2 ships them as simple
Manifesto-layout text pages (Manifesto.dc.html is the minimal-page
design), or WEBPLAN is amended to drop them from day zero. Founder call.

### G3. Changelog page has no dedicated design
WEBPLAN W3 wires a changelog to the product repo's tag notes. Mentioned
in Footer System, Legal & Support, and The Ledger but no composite.
Likely resolution: render as a Ledger-index variant; confirm at W3.

## Design exceeds day-zero scope (exists, deliberately not built)

### G4. Full console designs are post-launch material
`Console Overview.dc.html`, `Console Pages.dc.html`, and
`Console Session Detail.dc.html` are complete product-UI designs. The
constitution's scope fence ships only the honest early-access shell
(sign-in, waitlist, invite-pending, from Auth & System States.dc.html +
Onboarding.dc.html). The three console composites are preserved as the
spec for the future real console and MUST NOT be built as mockups with
numbers; that would violate UI Law 2.

## Facts about the export format (constraints, not gaps)

### G5. No tokens.json or guidelines file ships in the export
The composites carry the design system inline (verified consistent:
Newsreader/Inter/JetBrains Mono; palette led by #FBFAF7 paper, #16130F
ink, #7A2530 claret, #39404C slate, #EFEBE1/#D8D2C4 parchment tones).
tokens.json must be EXTRACTED from the composites at W0, with the
Component Sheet as the primary source and every other page as a
cross-check; any color appearing in pages but absent from the sheet is
resolved with the founder before entering tokens.json.

### G6. Export references Google Fonts and a dc-runtime support.js
Both are design-preview plumbing. The constitution requires self-hosted
woff2 subsets and no third-party CDNs; support.js is the composite
viewer runtime, not shippable code. Neither may reach production; the
W5 header gate (CSP without third-party origins) enforces this
mechanically.

### G7. Status page design exists but WEBPLAN never names a /status page
Status.dc.html is a full page design and four pages link to it. WEBPLAN
only specifies the footer status feed. Resolution: build /status at W2
using the design, defaulting to unavailable-by-honesty (UI Law 3), since
shipping a designed page the footer links to is cheaper than an orphan
lint failure. Flagged here because it is technically a plan amendment.
