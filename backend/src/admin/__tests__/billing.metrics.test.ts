import { describe, it, expect } from 'vitest';
import { monthlyEquivalentVnd, computeMrr, refundRate, arpu, bucketLatestPaidByUser } from '../billing.metrics';

describe('monthlyEquivalentVnd', () => {
  it('maps package codes to monthly value', () => {
    expect(monthlyEquivalentVnd('zen_pro_monthly')).toBe(29000);
    expect(monthlyEquivalentVnd('zen_pro_yearly')).toBe(Math.round(279000 / 12));
    expect(monthlyEquivalentVnd('unknown')).toBe(0);
  });
});

describe('computeMrr', () => {
  it('sums monthly + yearly-normalized recurring revenue', () => {
    expect(computeMrr(2, 1)).toBe(2 * 29000 + Math.round(279000 / 12));
    expect(computeMrr(0, 0)).toBe(0);
  });
});

describe('refundRate', () => {
  it('is refunded/(paid+refunded) %, 1dp, 0 when no orders', () => {
    expect(refundRate(1, 9)).toBe(10);
    expect(refundRate(0, 50)).toBe(0);
    expect(refundRate(0, 0)).toBe(0);
  });
});

describe('arpu', () => {
  it('is revenue/activeUsers rounded, 0 when no users', () => {
    expect(arpu(100000, 40)).toBe(2500);
    expect(arpu(100000, 0)).toBe(0);
  });
});

describe('bucketLatestPaidByUser', () => {
  it('counts each premium user once by their newest paid order package', () => {
    const orders = [
      { userId: 'u1', productCode: 'zen_pro_yearly', paidAt: '2026-06-10' },
      { userId: 'u1', productCode: 'zen_pro_monthly', paidAt: '2026-01-01' },
      { userId: 'u2', productCode: 'zen_pro_monthly', paidAt: '2026-06-09' },
      { userId: 'u3', productCode: 'zen_pro_monthly', paidAt: '2026-06-08' },
    ];
    const premium = new Set(['u1', 'u2']);
    expect(bucketLatestPaidByUser(orders, premium)).toEqual({ monthly: 1, yearly: 1 });
  });
});
