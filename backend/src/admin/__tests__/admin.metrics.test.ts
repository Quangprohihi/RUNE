import { describe, it, expect } from 'vitest';
import {
  rangeDays,
  windowFor,
  deltaPct,
  round1,
  bucketEdges,
  bucketCounts,
  sparkBucketCount,
} from '../admin.metrics';

describe('rangeDays', () => {
  it('maps each range to a day count', () => {
    expect(rangeDays('today')).toBe(1);
    expect(rangeDays('7d')).toBe(7);
    expect(rangeDays('30d')).toBe(30);
    expect(rangeDays('quarter')).toBe(90);
  });
});

describe('deltaPct', () => {
  it('computes signed percentage change rounded to 1dp', () => {
    expect(deltaPct(110, 100)).toBe(10);
    expect(deltaPct(90, 100)).toBe(-10);
    expect(deltaPct(105, 100)).toBe(5);
  });
  it('returns null when the previous value is 0', () => {
    expect(deltaPct(5, 0)).toBeNull();
  });
});

describe('round1', () => {
  it('rounds to one decimal', () => {
    expect(round1(4.24)).toBe(4.2);
    expect(round1(4.25)).toBe(4.3);
  });
});

describe('windowFor', () => {
  it('produces equal-length current and previous windows ending at now', () => {
    const now = new Date('2026-06-16T12:00:00.000Z');
    const w = windowFor('7d', now);
    expect(w.end.toISOString()).toBe('2026-06-16T12:00:00.000Z');
    expect(w.curStart.toISOString()).toBe('2026-06-09T12:00:00.000Z');
    expect(w.prevStart.toISOString()).toBe('2026-06-02T12:00:00.000Z');
    expect(w.prevEnd.toISOString()).toBe(w.curStart.toISOString());
    expect(w.days).toBe(7);
  });
});

describe('bucketEdges + bucketCounts', () => {
  it('splits a window into n buckets and counts timestamps', () => {
    const start = new Date('2026-06-01T00:00:00.000Z');
    const end = new Date('2026-06-05T00:00:00.000Z'); // 4 days
    const edges = bucketEdges(start, end, 4);
    expect(edges).toHaveLength(5);
    const dates = [
      new Date('2026-06-01T01:00:00.000Z'), // bucket 0
      new Date('2026-06-02T01:00:00.000Z'), // bucket 1
      new Date('2026-06-02T05:00:00.000Z'), // bucket 1
      new Date('2026-06-05T00:00:00.000Z'), // last edge → last bucket
    ];
    expect(bucketCounts(dates, edges)).toEqual([1, 2, 0, 1]);
  });
});

describe('sparkBucketCount', () => {
  it('clamps bucket count between 7 and 12', () => {
    expect(sparkBucketCount('today')).toBe(7);
    expect(sparkBucketCount('7d')).toBe(7);
    expect(sparkBucketCount('30d')).toBe(12);
    expect(sparkBucketCount('quarter')).toBe(12);
  });
});
