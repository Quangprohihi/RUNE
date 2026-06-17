import { describe, it, expect } from 'vitest';
import { economySummary, parsePriceTokens } from '../shop.metrics';

describe('economySummary', () => {
  it('derives faucet/sink/net/diamond from signed wallet sums', () => {
    // tokenCredit=+5000, tokenDebit=-1800, diamondCredit=+120
    expect(economySummary(5000, -1800, 120)).toEqual({
      tokenFaucet: 5000, tokenSink: 1800, tokenNet: 3200, diamondFaucet: 120,
    });
  });

  it('treats missing/zero sums as zero and never negative sink', () => {
    expect(economySummary(0, 0, 0)).toEqual({ tokenFaucet: 0, tokenSink: 0, tokenNet: 0, diamondFaucet: 0 });
    // debit passed as positive magnitude is still treated as a sink
    expect(economySummary(100, 40, 0)).toEqual({ tokenFaucet: 100, tokenSink: 40, tokenNet: 60, diamondFaucet: 0 });
  });

  it('allows a negative net when sink exceeds faucet', () => {
    expect(economySummary(100, -300, 0).tokenNet).toBe(-200);
  });
});

describe('parsePriceTokens', () => {
  it('rounds a valid non-negative number', () => {
    expect(parsePriceTokens(120)).toBe(120);
    expect(parsePriceTokens('45')).toBe(45);
    expect(parsePriceTokens(45.7)).toBe(46);
    expect(parsePriceTokens(0)).toBe(0);
  });

  it('rejects negative or non-numeric values with a 400', () => {
    expect(() => parsePriceTokens(-1)).toThrow();
    expect(() => parsePriceTokens('abc')).toThrow();
    try { parsePriceTokens(-5); } catch (e: any) { expect(e.status).toBe(400); }
  });
});
