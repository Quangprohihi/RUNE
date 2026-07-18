import type { RangeKey } from './types';

/** Human phrase for the selected range — used in KPI notes and chart subtitles. */
export function rangePhrase(range: RangeKey): string {
  switch (range) {
    case 'today': return 'hôm nay';
    case '7d': return '7 ngày qua';
    case '30d': return '30 ngày qua';
    case 'quarter': return 'quý này';
  }
}

/** Revenue KPI label that follows the selected range (never a stale "hôm nay"). */
export function revenueLabel(range: RangeKey): string {
  switch (range) {
    case 'today': return 'Doanh thu hôm nay';
    case '7d': return 'Doanh thu 7 ngày';
    case '30d': return 'Doanh thu 30 ngày';
    case 'quarter': return 'Doanh thu quý';
  }
}

/** How the backend buckets the sparkline for this range (see sparkBucketCount). */
export function bucketNoun(range: RangeKey): string {
  switch (range) {
    case 'today': return 'giờ';
    case '7d': return 'ngày';
    case '30d':
    case 'quarter': return '12 đoạn';
  }
}

const RANGE_DAYS: Record<RangeKey, number> = { today: 1, '7d': 7, '30d': 30, quarter: 90 };
const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * X-axis labels for the overview spark series. Mirrors the backend windowing:
 * a rolling window of rangeDays ending now, split into n equal buckets
 * (labels are each bucket's start).
 */
export function sparkLabels(range: RangeKey, n: number, now: Date = new Date()): string[] {
  const span = RANGE_DAYS[range] * DAY_MS;
  const start = now.getTime() - span;
  const labels: string[] = [];
  for (let i = 0; i < Math.max(1, n); i++) {
    const t = new Date(start + (span * i) / Math.max(1, n));
    labels.push(range === 'today' ? `${t.getHours()}h` : `${t.getDate()}/${t.getMonth() + 1}`);
  }
  return labels;
}
