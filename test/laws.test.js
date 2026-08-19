// The UI Laws, enforced as tests. These are the soul of Phase W1: if any
// of them can be made to pass while the law is broken, the gate's
// sabotage mode exists to prove they cannot.
import { describe, it, expect } from 'vitest';
import { experimental_AstroContainer as AstroContainer } from 'astro/container';
import MetricCard from '../src/components/MetricCard.astro';
import StatusChip from '../src/components/StatusChip.astro';
import BudgetBar from '../src/components/BudgetBar.astro';
import ArtifactCard from '../src/components/ArtifactCard.astro';
import EmptyState from '../src/components/EmptyState.astro';
import Badge from '../src/components/Badge.astro';

const render = async (Component, props) => {
  const container = await AstroContainer.create();
  return container.renderToString(Component, { props });
};

describe('UI Law 1: absence is not zero', () => {
  it('metric card with null data renders unavailable', async () => {
    const html = await render(MetricCard, { label: 'x', value: null, badge: 'MEASURED' });
    expect(html).toContain('unavailable');
    expect(html).toContain('data-state="unavailable"');
  });
  it('metric card with null data cannot render 0', async () => {
    const html = await render(MetricCard, { label: 'x', value: null, badge: 'MEASURED' });
    expect(html).not.toMatch(/data-state="value"/);
    expect(html).not.toMatch(/>\s*0\s*</);
  });
  it('metric card with undefined data cannot render 0', async () => {
    const html = await render(MetricCard, { label: 'x', value: undefined, badge: 'MEASURED' });
    expect(html).toContain('unavailable');
    expect(html).not.toMatch(/>\s*0\s*</);
  });
  it('metric card with NaN cannot render a number', async () => {
    const html = await render(MetricCard, { label: 'x', value: NaN, badge: 'MEASURED' });
    expect(html).toContain('unavailable');
    expect(html).not.toContain('NaN');
  });
  it('a measured zero renders 0: a zero is a measurement', async () => {
    const html = await render(MetricCard, { label: 'x', value: 0, badge: 'MEASURED' });
    expect(html).toContain('data-state="value"');
    expect(html).toMatch(/>0</);
    expect(html).not.toContain('unavailable');
  });
  it('budget bar with a missing meter renders unavailable, never $0', async () => {
    const html = await render(BudgetBar, { label: 'x', spent: null, cap: 500 });
    expect(html).toContain('unavailable');
    expect(html).not.toContain('$0');
  });
});

describe('UI Law 2: every number carries provenance', () => {
  it('metric card without badge or evidence link refuses to render', async () => {
    await expect(render(MetricCard, { label: 'x', value: 5 })).rejects.toThrow(/Law 2/);
  });
  it('badge accepts only MEASURED or ESTIMATED', async () => {
    await expect(render(Badge, { kind: 'PROBABLY' })).rejects.toThrow();
    expect(await render(Badge, { kind: 'ESTIMATED' })).toContain('ESTIMATED');
  });
});

describe('UI Law 3: the status chip cannot fake green', () => {
  it('status chip without feed renders UNAVAILABLE', async () => {
    const html = await render(StatusChip, {});
    expect(html).toContain('data-status="unavailable"');
    expect(html).toContain('status unavailable');
  });
  it('green is impossible without live data', async () => {
    for (const feed of [undefined, null]) {
      const html = await render(StatusChip, { feed });
      expect(html).not.toContain('operational');
      expect(html).not.toContain('bg-moss');
    }
  });
  it('a live feed renders its true state, timestamped', async () => {
    const ok = await render(StatusChip, { feed: { status: 'operational', asOf: '12:04Z' } });
    expect(ok).toContain('data-status="operational"');
    expect(ok).toContain('12:04Z');
    const bad = await render(StatusChip, { feed: { status: 'incident', asOf: '12:04Z' } });
    expect(bad).toContain('data-status="incident"');
  });
});

describe('house rules made visual', () => {
  it('a preserved artifact renders no delete affordance at all', async () => {
    const html = await render(ArtifactCard, { id: 'c_0040', size: '1.2 GB', preserved: true, ruling: 'Legal hold LH-19', retention: '7 years' });
    expect(html).toContain('preserved under ruling');
    expect(html.toLowerCase()).not.toContain('delete');
  });
  it('every empty state teaches a command', async () => {
    const html = await render(EmptyState, { title: 'No sessions yet.', command: 'ks run --image claude-code' });
    expect(html).toContain('ks run --image claude-code');
  });
});
