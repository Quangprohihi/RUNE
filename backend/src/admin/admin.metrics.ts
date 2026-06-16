/**
 * Pure, DB-agnostic helpers for the admin overview KPIs.
 * No Prisma here — the route fetches rows and feeds them in, so these
 * stay unit-testable without a database.
 */
export type RangeKey = 'today' | '7d' | '30d' | 'quarter';

const DAY_MS = 24 * 60 * 60 * 1000;

export function rangeDays(range: RangeKey): number {
  switch (range) {
    case 'today': return 1;
    case '7d': return 7;
    case '30d': return 30;
    case 'quarter': return 90;
    default: return 1;
  }
}

export function round1(n: number): number {
  return Math.round(n * 10) / 10;
}

export function deltaPct(curr: number, prev: number): number | null {
  if (!prev) return null;
  return round1(((curr - prev) / prev) * 100);
}

export function windowFor(range: RangeKey, now: Date) {
  const days = rangeDays(range);
  const ms = days * DAY_MS;
  const end = new Date(now.getTime());
  const curStart = new Date(now.getTime() - ms);
  const prevStart = new Date(now.getTime() - 2 * ms);
  return { curStart, prevStart, prevEnd: curStart, end, days };
}

export function bucketEdges(start: Date, end: Date, n: number): Date[] {
  const edges: Date[] = [];
  const span = end.getTime() - start.getTime();
  for (let i = 0; i <= n; i++) {
    edges.push(new Date(start.getTime() + (span * i) / n));
  }
  return edges;
}

export function bucketCounts(dates: Date[], edges: Date[]): number[] {
  const n = edges.length - 1;
  const counts = new Array(n).fill(0);
  for (const d of dates) {
    const t = d.getTime();
    for (let i = 0; i < n; i++) {
      const lo = edges[i].getTime();
      const hi = edges[i + 1].getTime();
      const inBucket = i === n - 1 ? t >= lo && t <= hi : t >= lo && t < hi;
      if (inBucket) { counts[i]++; break; }
    }
  }
  return counts;
}

export function sparkBucketCount(range: RangeKey): number {
  return Math.min(12, Math.max(7, rangeDays(range)));
}

/** Bucketed sums (for value-weighted sparks like revenue / focus minutes). */
export function bucketSums(
  points: { at: Date; value: number }[],
  edges: Date[],
): number[] {
  const n = edges.length - 1;
  const sums = new Array(n).fill(0);
  for (const p of points) {
    const t = p.at.getTime();
    for (let i = 0; i < n; i++) {
      const lo = edges[i].getTime();
      const hi = edges[i + 1].getTime();
      const inBucket = i === n - 1 ? t >= lo && t <= hi : t >= lo && t < hi;
      if (inBucket) { sums[i] += p.value; break; }
    }
  }
  return sums;
}
