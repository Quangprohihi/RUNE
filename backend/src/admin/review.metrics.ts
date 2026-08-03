/** Pure helpers for the user-review screen (không chạm DB — nhận vào mảng AppReview). */

import { round1 } from './admin.metrics';
import { REVIEW_THEMES } from './review.data';
import type { AppReview, ReviewTheme, ReviewThemeKey, ReviewTone } from './review.data';

export interface RatingBucket { stars: number; count: number; pct: number; }
export interface SentimentSplit { positive: number; neutral: number; negative: number; }
export interface ThemeStat {
  key: ReviewThemeKey; label: string;
  /** số review có nhắc chủ đề này (một review chỉ đếm một lần dù gắn nhiều tag) */
  mentions: number;
  praise: number; request: number; issue: number;
}
export interface ReviewSummary {
  total: number;
  average: number;
  distribution: RatingBucket[];
  sentiment: SentimentSplit;
  /** % review từ 4★ trở lên */
  satisfactionPct: number;
  /** số review nêu ít nhất một mong muốn / số review nêu ít nhất một lỗi hoặc điểm chê */
  requestCount: number;
  issueCount: number;
  themes: ThemeStat[];
}

/** Mới nhất trước — copy rồi mới sort để không đụng vào mảng nguồn. */
export function sortNewestFirst(reviews: AppReview[]): AppReview[] {
  return [...reviews].sort((a, b) => new Date(b.at).getTime() - new Date(a.at).getTime());
}

export function averageRating(reviews: AppReview[]): number {
  if (reviews.length === 0) return 0;
  return round1(reviews.reduce((s, r) => s + r.rating, 0) / reviews.length);
}

export function ratingDistribution(reviews: AppReview[]): RatingBucket[] {
  const total = reviews.length;
  return [5, 4, 3, 2, 1].map((stars) => {
    const count = reviews.filter((r) => r.rating === stars).length;
    return { stars, count, pct: total > 0 ? round1((count / total) * 100) : 0 };
  });
}

export function sentimentSplit(reviews: AppReview[]): SentimentSplit {
  return {
    positive: reviews.filter((r) => r.rating >= 4).length,
    neutral: reviews.filter((r) => r.rating === 3).length,
    negative: reviews.filter((r) => r.rating <= 2).length,
  };
}

const hasTone = (r: AppReview, tone: ReviewTone) => r.tags.some((t) => t.tone === tone);

export function themeBreakdown(reviews: AppReview[], themes: ReviewTheme[] = REVIEW_THEMES): ThemeStat[] {
  return themes
    .map(({ key, label }) => {
      const mentioning = reviews.filter((r) => r.tags.some((t) => t.theme === key));
      const withTone = (tone: ReviewTone) =>
        mentioning.filter((r) => r.tags.some((t) => t.theme === key && t.tone === tone)).length;
      return {
        key, label,
        mentions: mentioning.length,
        praise: withTone('praise'),
        request: withTone('request'),
        issue: withTone('issue'),
      };
    })
    .filter((t) => t.mentions > 0)
    .sort((a, b) => b.mentions - a.mentions);
}

export function summarizeReviews(reviews: AppReview[], themes: ReviewTheme[] = REVIEW_THEMES): ReviewSummary {
  const total = reviews.length;
  const sentiment = sentimentSplit(reviews);
  return {
    total,
    average: averageRating(reviews),
    distribution: ratingDistribution(reviews),
    sentiment,
    satisfactionPct: total > 0 ? round1((sentiment.positive / total) * 100) : 0,
    requestCount: reviews.filter((r) => hasTone(r, 'request')).length,
    issueCount: reviews.filter((r) => hasTone(r, 'issue')).length,
    themes: themeBreakdown(reviews, themes),
  };
}
