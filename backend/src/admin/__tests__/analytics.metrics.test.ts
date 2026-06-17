import { describe, it, expect } from 'vitest';
import { analyticsWindow, granularityBuckets, distinctPerBucket, hourlyAverage } from '../analytics.metrics';

describe('analyticsWindow', () => {
  const now = new Date('2026-06-17T12:00:00.000Z');
  it('preset week → 7-day current + equal previous window', () => {
    const w = analyticsWindow('week', now);
    expect(w.curEnd.toISOString()).toBe('2026-06-17T12:00:00.000Z');
    expect(w.curStart.toISOString()).toBe('2026-06-10T12:00:00.000Z');
    expect(w.prevStart.toISOString()).toBe('2026-06-03T12:00:00.000Z');
    expect(w.prevEnd.toISOString()).toBe(w.curStart.toISOString());
  });
  it('custom uses from/to with inclusive end-of-day', () => {
    const w = analyticsWindow('custom', now, '2026-06-01', '2026-06-07');
    expect(w.curStart.toISOString()).toBe('2026-06-01T00:00:00.000Z');
    expect(w.curEnd.toISOString()).toBe('2026-06-07T23:59:59.999Z');
  });
});

describe('granularityBuckets', () => {
  it('splits a 7-day window into 7 day-buckets (8 edges)', () => {
    const start = new Date('2026-06-10T00:00:00.000Z');
    const end = new Date('2026-06-17T00:00:00.000Z');
    expect(granularityBuckets(start, end, 'day')).toHaveLength(8);
  });
  it('uses fewer buckets at coarser granularity', () => {
    const start = new Date('2026-04-01T00:00:00.000Z');
    const end = new Date('2026-06-30T00:00:00.000Z'); // ~90 days
    expect(granularityBuckets(start, end, 'month').length).toBeLessThan(granularityBuckets(start, end, 'day').length);
  });
});

describe('distinctPerBucket', () => {
  it('counts distinct users per bucket', () => {
    const edges = [new Date('2026-06-01'), new Date('2026-06-02'), new Date('2026-06-03')];
    const rows = [
      { userId: 'a', at: new Date('2026-06-01T05:00:00Z') },
      { userId: 'a', at: new Date('2026-06-01T09:00:00Z') }, // same user, same bucket → counts once
      { userId: 'b', at: new Date('2026-06-01T10:00:00Z') },
      { userId: 'c', at: new Date('2026-06-02T10:00:00Z') },
    ];
    expect(distinctPerBucket(rows, edges)).toEqual([2, 1]);
  });
});

describe('hourlyAverage', () => {
  it('buckets minutes into 12 two-hour slots and divides by days', () => {
    const points = [
      { at: new Date('2026-06-01T20:30:00Z'), minutes: 60 }, // bucket 10 (20-22h)
      { at: new Date('2026-06-02T21:00:00Z'), minutes: 40 }, // bucket 10
      { at: new Date('2026-06-01T01:00:00Z'), minutes: 20 }, // bucket 0
    ];
    const out = hourlyAverage(points, 2);
    expect(out).toHaveLength(12);
    expect(out[10]).toBe(50); // (60+40)/2
    expect(out[0]).toBe(10); // 20/2
  });
});
