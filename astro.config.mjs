import { defineConfig } from 'astro/config';
import mdx from '@astrojs/mdx';
import tailwind from '@astrojs/tailwind';
import sitemap from '@astrojs/sitemap';
import rehypeCopy from './scripts/rehype-copy.mjs';

export default defineConfig({
  site: 'https://keepstate.ai',
  integrations: [mdx(), tailwind(), sitemap({ filter: (p) => !p.includes('/design-system') })],
  markdown: { rehypePlugins: [rehypeCopy] },
  build: { inlineStylesheets: 'always' },
});
