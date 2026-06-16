import { describe, it, expect } from 'vitest';
import { formatInt, formatPercent, formatVndShort, formatDate, formatDateTimeUtc } from './format';

describe('formatInt', () => {
  it('groups thousands with vi-VN separators', () => {
    expect(formatInt(1842)).toBe('1.842');
    expect(formatInt(41250)).toBe('41.250');
  });
});

describe('formatPercent', () => {
  it('formats with comma decimals and a percent sign', () => {
    expect(formatPercent(27)).toBe('27%');
    expect(formatPercent(4.6)).toBe('4,6%');
  });
});

describe('formatVndShort', () => {
  it('shows millions/thousands shorthand', () => {
    expect(formatVndShort(1247000)).toBe('1,25 tr đ');
    expect(formatVndShort(279000)).toBe('279k đ');
    expect(formatVndShort(500)).toBe('500 đ');
  });
});

describe('formatDate / formatDateTimeUtc', () => {
  it('renders UTC dd/MM/yyyy and dd/MM · HH:mm', () => {
    expect(formatDate('2026-03-12T09:14:00.000Z')).toBe('12/03/2026');
    expect(formatDateTimeUtc('2026-06-13T09:14:00.000Z')).toBe('13/06 · 09:14');
  });
  it('renders an em dash for null/invalid', () => {
    expect(formatDate(null)).toBe('—');
    expect(formatDateTimeUtc(undefined)).toBe('—');
  });
});
