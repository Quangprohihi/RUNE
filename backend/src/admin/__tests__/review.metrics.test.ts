import { describe, it, expect } from 'vitest';
import {
  sortNewestFirst, averageRating, ratingDistribution, sentimentSplit,
  themeBreakdown, summarizeReviews,
} from '../review.metrics';
import { APP_REVIEWS, REVIEW_THEMES } from '../review.data';
import type { AppReview } from '../review.data';

const review = (over: Partial<AppReview>): AppReview => ({
  id: 'x', author: 'Test', rating: 5, at: '2026-07-01T00:00:00.000Z',
  platform: 'Android', appVersion: '1.0.0', text: 'nội dung', tags: [], ...over,
});

describe('sortNewestFirst', () => {
  it('sorts by date descending without mutating the input', () => {
    const input = [
      review({ id: 'a', at: '2026-07-01T00:00:00.000Z' }),
      review({ id: 'b', at: '2026-07-20T00:00:00.000Z' }),
      review({ id: 'c', at: '2026-07-10T00:00:00.000Z' }),
    ];
    expect(sortNewestFirst(input).map((r) => r.id)).toEqual(['b', 'c', 'a']);
    expect(input.map((r) => r.id)).toEqual(['a', 'b', 'c']);
  });
});

describe('averageRating', () => {
  it('rounds to one decimal', () => {
    expect(averageRating([review({ rating: 5 }), review({ rating: 4 }), review({ rating: 3 })])).toBe(4);
    expect(averageRating([review({ rating: 5 }), review({ rating: 2 }), review({ rating: 4 })])).toBe(3.7);
  });

  it('returns 0 for an empty list', () => {
    expect(averageRating([])).toBe(0);
  });
});

describe('ratingDistribution', () => {
  it('returns 5→1 buckets with percentages', () => {
    const rows = ratingDistribution([review({ rating: 5 }), review({ rating: 5 }), review({ rating: 3 }), review({ rating: 1 })]);
    expect(rows.map((r) => r.stars)).toEqual([5, 4, 3, 2, 1]);
    expect(rows.map((r) => r.count)).toEqual([2, 0, 1, 0, 1]);
    expect(rows[0].pct).toBe(50);
    expect(rows[1].pct).toBe(0);
  });

  it('keeps percentages at 0 when there are no reviews', () => {
    expect(ratingDistribution([]).every((r) => r.count === 0 && r.pct === 0)).toBe(true);
  });
});

describe('sentimentSplit', () => {
  it('buckets 4-5★ positive, 3★ neutral, 1-2★ negative', () => {
    const rows = [5, 4, 3, 2, 1].map((rating) => review({ rating }));
    expect(sentimentSplit(rows)).toEqual({ positive: 2, neutral: 1, negative: 2 });
  });
});

describe('themeBreakdown', () => {
  it('counts a theme once per review even when tagged twice', () => {
    const rows = themeBreakdown(
      [review({ tags: [{ theme: 'pet', tone: 'praise' }, { theme: 'pet', tone: 'request' }] })],
      REVIEW_THEMES,
    );
    const pet = rows.find((r) => r.key === 'pet')!;
    expect(pet.mentions).toBe(1);
    expect(pet.praise).toBe(1);
    expect(pet.request).toBe(1);
  });

  it('drops themes nobody mentioned and sorts by mentions desc', () => {
    const rows = themeBreakdown([
      review({ tags: [{ theme: 'pomodoro', tone: 'praise' }] }),
      review({ tags: [{ theme: 'pet', tone: 'request' }] }),
      review({ tags: [{ theme: 'pet', tone: 'request' }] }),
    ], REVIEW_THEMES);
    expect(rows.map((r) => r.key)).toEqual(['pet', 'pomodoro']);
    expect(rows[0].label).toBe('Nuôi pet & sưu tầm');
  });
});

describe('summarizeReviews on the shipped survey data', () => {
  const s = summarizeReviews(APP_REVIEWS, REVIEW_THEMES);

  it('reports 20 reviews averaging 3.6★', () => {
    expect(s.total).toBe(20);
    expect(s.average).toBe(3.6);
  });

  it('splits sentiment 11 / 7 / 2 and reports satisfaction', () => {
    expect(s.sentiment).toEqual({ positive: 11, neutral: 7, negative: 2 });
    expect(s.satisfactionPct).toBe(55);
  });

  it('counts reviews carrying a feature request and reviews reporting a problem', () => {
    expect(s.requestCount).toBe(11);
    expect(s.issueCount).toBe(5);
  });

  it('ranks pet and pomodoro as the loudest themes', () => {
    expect(s.themes[0]).toMatchObject({ key: 'pet', mentions: 8, request: 7, praise: 2, issue: 0 });
    expect(s.themes[1]).toMatchObject({ key: 'pomodoro', mentions: 7, praise: 7, request: 0 });
  });

  it('has a distribution that sums back to the total', () => {
    expect(s.distribution.reduce((n, r) => n + r.count, 0)).toBe(20);
    expect(s.distribution.find((r) => r.stars === 5)!.count).toBe(3);
    expect(s.distribution.find((r) => r.stars === 1)!.count).toBe(0);
  });
});
