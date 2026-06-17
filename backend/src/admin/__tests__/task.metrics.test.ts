import { describe, it, expect } from 'vitest';
import { parseReward, dailyTokenFaucet } from '../task.metrics';

describe('parseReward', () => {
  it('rounds a valid non-negative number', () => {
    expect(parseReward(20)).toBe(20);
    expect(parseReward('5')).toBe(5);
    expect(parseReward(4.6)).toBe(5);
    expect(parseReward(0)).toBe(0);
  });

  it('rejects negative or non-numeric values with a 400', () => {
    expect(() => parseReward(-1)).toThrow();
    expect(() => parseReward('xyz')).toThrow();
    try { parseReward(-3); } catch (e: any) { expect(e.status).toBe(400); }
  });
});

describe('dailyTokenFaucet', () => {
  it('sums rewardTokens of active templates only', () => {
    const tasks = [
      { rewardTokens: 20, isActive: true },
      { rewardTokens: 30, isActive: true },
      { rewardTokens: 100, isActive: false },
    ];
    expect(dailyTokenFaucet(tasks)).toBe(50);
  });

  it('is zero for no active tasks', () => {
    expect(dailyTokenFaucet([{ rewardTokens: 10, isActive: false }])).toBe(0);
    expect(dailyTokenFaucet([])).toBe(0);
  });
});
