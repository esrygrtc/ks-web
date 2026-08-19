// Tailwind is configured EXCLUSIVELY from design/tokens.json
// (constitution). No hex value may appear outside that file.
const tokens = require('./design/tokens.json');

const fontSize = Object.fromEntries(
  tokens.fontSizePx.map((px) => [String(px), `${px}px`])
);
const borderRadius = Object.fromEntries(
  tokens.radiusPx.map((px) => [px === 100 ? 'pill' : String(px), `${px}px`])
);

module.exports = {
  content: ['./src/**/*.{astro,md,mdx,ts,tsx}'],
  theme: {
    colors: tokens.color,
    fontFamily: {
      serif: tokens.font.serif.split(',').map((s) => s.trim()),
      sans: tokens.font.sans.split(',').map((s) => s.trim()),
      mono: tokens.font.mono.split(',').map((s) => s.trim()),
    },
    fontSize,
    borderRadius,
    extend: {
      boxShadow: Object.fromEntries(tokens.shadow.map((s, i) => [`e${i + 1}`, s])),
    },
  },
  plugins: [],
};
