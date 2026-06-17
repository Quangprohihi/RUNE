import { describe, it, expect } from 'vitest';
import { extendExpiry } from '../subscription.util';

describe('extendExpiry', () => {
  const now = new Date('2026-06-17T00:00:00.000Z');

  it('extends from now when there is no current expiry or it has lapsed', () => {
    expect(extendExpiry(null, 30, now).toISOString()).toBe('2026-07-17T00:00:00.000Z');
    expect(extendExpiry(new Date('2026-06-01T00:00:00.000Z'), 30, now).toISOString()).toBe('2026-07-17T00:00:00.000Z');
  });

  it('extends from the current expiry when it is still in the future', () => {
    expect(extendExpiry(new Date('2026-07-01T00:00:00.000Z'), 30, now).toISOString()).toBe('2026-07-31T00:00:00.000Z');
  });
});
