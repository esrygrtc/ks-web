// Extracts design/tokens.json from the Claude Design composites.
// The Component Sheet is the primary source; every other page is a
// cross-check. Colors found in pages but not the sheet land in
// palette.extended under their hex, never invented names (BACKLOG G5).
import { readFileSync, readdirSync, writeFileSync } from 'node:fs';

const dir = new URL('../design/', import.meta.url).pathname;
const files = readdirSync(dir).filter(f => f.endsWith('.dc.html'));
const sheet = readFileSync(dir + 'Component Sheet.dc.html', 'utf8');
const all = files.map(f => readFileSync(dir + f, 'utf8')).join('\n');

const hexes = s => [...s.matchAll(/#[0-9a-fA-F]{6}\b/g)].map(m => m[0].toLowerCase());
const count = a => a.reduce((m, h) => (m[h] = (m[h] || 0) + 1, m), {});
const sheetCounts = count(hexes(sheet));
const allCounts = count(hexes(all));

// Semantic names for the core palette, assigned only where usage in the
// composites is unambiguous (body backgrounds, ink, links, accents).
const semantic = {
  paper:      '#fbfaf7', // page background (html/body across all pages)
  cream:      '#f7f4ec', // raised surface
  parchment:  '#efebe1', // inset surface / table stripe
  sand:       '#d8d2c4', // borders, rules
  ink:        '#16130f', // primary text
  slate:      '#39404c', // secondary text
  taupe:      '#7a6f60', // tertiary text, captions
  stone:      '#a69e8e', // disabled, placeholders
  claret:     '#7a2530', // brand accent, links, primary buttons
  blush:      '#d9b8b8', // claret tint (charts, hovers)
  shell:      '#e4cfcc', // claret tint lighter
  white:      '#ffffff',
  // second pass (W1): sheet-verified colors promoted from paletteExtended
  moss:       '#4f7a52', // operational dot (status feed)
  claretDeep: '#641e27', // primary button hover
  blushBg:    '#f6ecea', // running pill bg, incident banner bg
  track:      '#ede9df', // meter/budget bar track
  sandDeep:   '#c9c2b2', // aborted pill border, ESTIMATED badge border
  borderMuted:'#c9c4ba', // muted rules
  termMuted:  '#8a8378', // terminal secondary text
  inkBorder:  '#2a2622', // border on ink surfaces
  inkSoft:    '#3a352e', // raised line on ink surfaces
  disabledBg: '#f2efe8', // disabled button bg
  disabledBd: '#e2ddd1', // disabled button border
  shellSoft:  '#efdfdc', // claret tint, faintest
  // third pass (home rebuild): page-verified colors, founder-resolved
  mist:       '#9a9384', // partner strip labels, '+' separators
  slateLine:  '#5a616c', // chip border on the governance slate band
  slateSoft:  '#e6e3dc', // body text on the governance slate band
  inkLine:    '#4a443c', // secondary button border on ink bands
};
const named = new Set(Object.values(semantic));
const extended = {};
for (const [h, n] of Object.entries(allCounts).sort((a, b) => b[1] - a[1])) {
  if (!named.has(h)) extended[h] = { count: n, inComponentSheet: !!sheetCounts[h] };
}

const px = s => [...s.matchAll(/font-size:\s*(\d+)px/g)].map(m => +m[1]);
const sizes = [...new Set(px(sheet))].sort((a, b) => a - b);
const radii = [...new Set([...sheet.matchAll(/border-radius:\s*(\d+)px/g)].map(m => +m[1]))].sort((a, b) => a - b);
const shadows = [...new Set([...sheet.matchAll(/box-shadow:\s*([^;"]+)/g)].map(m => m[1].trim()))];

const tokens = {
  $source: 'extracted by scripts/extract-tokens.mjs from design/*.dc.html; Component Sheet is primary. Do not hand-edit values; re-run the script.',
  color: { ...semantic },
  paletteExtended: extended,
  font: {
    serif: "Newsreader, Georgia, serif",
    sans: "Inter, Helvetica, Arial, sans-serif",
    mono: "'JetBrains Mono', ui-monospace, monospace",
  },
  fontSizePx: sizes,
  radiusPx: radii,
  shadow: shadows,
};
writeFileSync(dir + 'tokens.json', JSON.stringify(tokens, null, 2) + '\n');
console.log('colors named:', Object.keys(semantic).length,
  '| extended:', Object.keys(extended).length,
  '| sizes:', sizes.join(','), '| radii:', radii.join(','), '| shadows:', shadows.length);
