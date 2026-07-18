import { describe, it, expect } from 'vitest';
import { rangePhrase, revenueLabel, bucketNoun, sparkLabels } from './rangeLabels';

describe('rangePhrase', () => {
  it('names each range in Vietnamese', () => {
    expect(rangePhrase('today')).toBe('hôm nay');
    expect(rangePhrase('7d')).toBe('7 ngày qua');
    expect(rangePhrase('30d')).toBe('30 ngày qua');
    expect(rangePhrase('quarter')).toBe('quý này');
  });
});

describe('revenueLabel', () => {
  it('matches the selected range instead of always saying "hôm nay"', () => {
    expect(revenueLabel('today')).toBe('Doanh thu hôm nay');
    expect(revenueLabel('7d')).toBe('Doanh thu 7 ngày');
    expect(revenueLabel('30d')).toBe('Doanh thu 30 ngày');
    expect(revenueLabel('quarter')).toBe('Doanh thu quý');
  });
});

describe('bucketNoun', () => {
  it('describes the spark bucket granularity', () => {
    expect(bucketNoun('today')).toBe('giờ');
    expect(bucketNoun('7d')).toBe('ngày');
    expect(bucketNoun('30d')).toBe('12 đoạn');
    expect(bucketNoun('quarter')).toBe('12 đoạn');
  });
});

describe('sparkLabels', () => {
  const now = new Date('2026-07-18T15:00:00');

  it('labels a 24h window with hours', () => {
    const labels = sparkLabels('today', 7, now);
    expect(labels).toHaveLength(7);
    // window starts 24h ago at 15:00 the previous day
    expect(labels[0]).toBe('15h');
    // every label is an hour string
    for (const l of labels) expect(l).toMatch(/^\d{1,2}h$/);
  });

  it('labels a 7-day window with day/month', () => {
    const labels = sparkLabels('7d', 7, now);
    expect(labels).toHaveLength(7);
    expect(labels[0]).toBe('11/7'); // 7 days before 18/7
    expect(labels[6]).toBe('17/7');
  });

  it('labels a 30-day window with day/month at bucket starts', () => {
    const labels = sparkLabels('30d', 12, now);
    expect(labels).toHaveLength(12);
    expect(labels[0]).toBe('18/6'); // 30 days before 18/7
    for (const l of labels) expect(l).toMatch(/^\d{1,2}\/\d{1,2}$/);
  });

  it('handles a single bucket without crashing', () => {
    expect(sparkLabels('7d', 1, now)).toHaveLength(1);
  });
});
