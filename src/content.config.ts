import { defineCollection, z } from 'astro:content';
import { glob } from 'astro/loaders';

const docs = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/docs' }),
  schema: z.object({
    title: z.string(),
    section: z.enum(['Start', 'Concepts', 'Guides', 'Reference', 'Operations']),
    order: z.number(),
    description: z.string().optional(),
    generated: z.string().optional(),
  }),
});
const ledger = defineCollection({
  loader: glob({ pattern: '**/*.{md,mdx}', base: './src/content/ledger' }),
  schema: z.object({
    title: z.string(),
    date: z.string(),
    draft: z.boolean().default(false),
    standfirst: z.string(),
  }),
});
export const collections = { docs, ledger };
