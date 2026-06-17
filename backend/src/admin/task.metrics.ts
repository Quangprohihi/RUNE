/** Pure helpers for the tasks / milestones (economy faucet) screen. */

/** Validate an admin-entered reward → rounded non-negative int, or throw 400. */
export function parseReward(v: unknown): number {
  const n = Number(v);
  if (!Number.isFinite(n) || n < 0) {
    throw Object.assign(new Error('Phần thưởng không hợp lệ'), { status: 400 });
  }
  return Math.round(n);
}

/** Max tokens a user can earn per day from tasks = Σ rewardTokens over active templates. */
export function dailyTokenFaucet(tasks: { rewardTokens: number; isActive: boolean }[]): number {
  return tasks.filter((t) => t.isActive).reduce((s, t) => s + t.rewardTokens, 0);
}
