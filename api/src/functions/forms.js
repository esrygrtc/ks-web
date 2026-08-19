// The four form endpoints. One law above all: the lead is durable BEFORE
// any email is attempted. A lost lead is a lost session; we do not lose
// sessions. Email is a notification, never a dependency.
import { app } from '@azure/functions';
import { TableClient } from '@azure/data-tables';
import { randomUUID, createHash } from 'node:crypto';

const FORMS = {
  partner: { fields: ['name', 'email', 'company', 'agent'], table: 'leads' },
  grants: { fields: ['track', 'name', 'link', 'run', 'credits'], table: 'grants' },
  subscribe: { fields: ['email'], table: 'subscribers' },
  contact: { fields: ['name', 'email', 'message'], table: 'contact' },
};
const RATE_LIMIT = 5;          // submissions
const RATE_WINDOW_MS = 10 * 60 * 1000;

const table = (name) => TableClient.fromConnectionString(process.env.KS_LEADS_CONN, name, { allowInsecureConnection: false });

async function parseBody(req) {
  const ct = req.headers.get('content-type') ?? '';
  if (ct.includes('application/json')) return await req.json();
  const text = await req.text();
  return Object.fromEntries(new URLSearchParams(text));
}

const emailOk = (e) => typeof e === 'string' && /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(e);

async function rateLimited(client, ipHash) {
  const cutoff = new Date(Date.now() - RATE_WINDOW_MS).toISOString();
  let n = 0;
  const iter = client.listEntities({ queryOptions: { filter: `PartitionKey eq '${ipHash}' and RowKey ge '${cutoff}'` } });
  for await (const _ of iter) { n++; if (n >= RATE_LIMIT) return true; }
  return false;
}

// Email notification: strictly AFTER the row is durable, and its failure
// changes nothing about the outcome the submitter sees. Provider is a
// Resend-compatible HTTP API; unconfigured is a recorded state, not an
// error.
async function notify(form, row) {
  if (!process.env.KS_EMAIL_KEY || !process.env.KS_EMAIL_TO) return 'unconfigured';
  try {
    const res = await fetch(process.env.KS_EMAIL_API ?? 'https://api.resend.com/emails', {
      method: 'POST',
      headers: { authorization: `Bearer ${process.env.KS_EMAIL_KEY}`, 'content-type': 'application/json' },
      body: JSON.stringify({
        from: process.env.KS_EMAIL_FROM ?? 'ledger@keepstate.ai',
        to: [process.env.KS_EMAIL_TO],
        subject: `[ks-web] ${form} submission ${row.rowKey}`,
        text: JSON.stringify(row, null, 2),
      }),
    });
    return res.ok ? 'sent' : `failed:${res.status}`;
  } catch (e) {
    return `failed:${e?.message ?? 'unknown'}`;
  }
}

const redirect = (to) => ({ status: 303, headers: { location: to } });

for (const [form, spec] of Object.entries(FORMS)) {
  app.http(form, {
    methods: ['POST'],
    authLevel: 'anonymous',
    route: form,
    handler: async (req, ctx) => {
      let body;
      try { body = await parseBody(req); } catch { return redirect('/sorry?why=body'); }

      // Honeypot: bots fill the hidden field. Pretend success, store
      // nothing: a bot is not a lead, and telling it so teaches it.
      if (body.website) return redirect('/thanks');

      const missing = spec.fields.filter((f) => !String(body[f] ?? '').trim());
      if (missing.length) return redirect(`/sorry?why=missing&fields=${missing.join(',')}`);
      if (spec.fields.includes('email') && !emailOk(body.email)) return redirect('/sorry?why=email');

      const ip = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim() || 'unknown';
      const ipHash = createHash('sha256').update(form + ip).digest('hex').slice(0, 24);
      const client = table(spec.table);

      try {
        if (await rateLimited(client, ipHash)) {
          return { status: 429, headers: { 'content-type': 'text/plain' }, body: 'Slow down: five submissions in ten minutes is the ceiling. Your earlier ones are safely stored.' };
        }
        const row = {
          partitionKey: ipHash,
          rowKey: `${new Date().toISOString()}_${randomUUID().slice(0, 8)}`,
          form,
          ...Object.fromEntries(spec.fields.map((f) => [f, String(body[f]).slice(0, 4000)])),
          emailStatus: 'pending',
        };
        await client.createEntity(row);          // durability FIRST
        const emailStatus = await notify(form, row);   // notification second
        try { await client.updateEntity({ partitionKey: row.partitionKey, rowKey: row.rowKey, emailStatus }, 'Merge'); } catch {}
        return redirect('/thanks');
      } catch (e) {
        ctx.error(`${form}: durable write failed: ${e?.message}`);
        return redirect('/sorry?why=storage');
      }
    },
  });
}
