/** Pure, DB-agnostic helpers for the analytics endpoint. */
export type AnalyticsRange = 'today' | 'week' | 'month' | 'quarter' | 'year' | 'custom';
export type Granularity = 'day' | 'week' | 'month' | 'quarter';

const DAY = 24 * 60 * 60 * 1000;
const RANGE_DAYS: Record<string, number> = { today: 1, week: 7, month: 30, quarter: 90, year: 365 };
const GRAN_DAYS: Record<string, number> = { day: 1, week: 7, month: 30, quarter: 90 };

/** Current + previous (equal-length) windows for a range. Custom uses from/to (to is inclusive end-of-day). */
export function analyticsWindow(range: AnalyticsRange, now: Date, from?: string, to?: string) {
  let curStart: Date;
  let curEnd: Date;
  if (range === 'custom' && from && to) {
    curStart = new Date(from);
    curEnd = new Date(to);
    curEnd.setUTCHours(23, 59, 59, 999);
  } else {
    curEnd = new Date(now.getTime());
    curStart = new Date(now.getTime() - (RANGE_DAYS[range] ?? 1) * DAY);
  }
  const span = curEnd.getTime() - curStart.getTime();
  return { curStart, curEnd, prevStart: new Date(curStart.getTime() - span), prevEnd: new Date(curStart.getTime()), span };
}

/** Bucket-edge timestamps (length n+1) dividing [start,end] by granularity, capped at 60 buckets. */
export function granularityBuckets(start: Date, end: Date, gran: Granularity): Date[] {
  const sizeDays = GRAN_DAYS[gran] ?? 1;
  const span = Math.max(1, end.getTime() - start.getTime());
  let n = Math.max(1, Math.ceil(span / (sizeDays * DAY)));
  if (n > 60) n = 60;
  const edges: Date[] = [];
  for (let i = 0; i <= n; i++) edges.push(new Date(start.getTime() + (span * i) / n));
  return edges;
}

/** Distinct userIds per bucket (last bucket inclusive on the upper edge). */
export function distinctPerBucket(rows: { userId: string; at: Date }[], edges: Date[]): number[] {
  const n = edges.length - 1;
  const sets = Array.from({ length: n }, () => new Set<string>());
  for (const r of rows) {
    const t = r.at.getTime();
    for (let i = 0; i < n; i++) {
      const lo = edges[i].getTime();
      const hi = edges[i + 1].getTime();
      const inBucket = i === n - 1 ? t >= lo && t <= hi : t >= lo && t < hi;
      if (inBucket) { sets[i].add(r.userId); break; }
    }
  }
  return sets.map((s) => s.size);
}

/** Average minutes per 12 two-hour buckets (sum by hour-of-day / number of days). */
export function hourlyAverage(points: { at: Date; minutes: number }[], days: number): number[] {
  const buckets = new Array(12).fill(0);
  for (const p of points) buckets[Math.floor(p.at.getUTCHours() / 2)] += p.minutes;
  const d = Math.max(1, days);
  return buckets.map((m) => Math.round(m / d));
}
