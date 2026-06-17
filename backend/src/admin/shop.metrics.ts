/** Pure helpers for the shop / game-economy screen. */

/**
 * Economy snapshot from signed WalletTransaction sums.
 * `tokenDebit` / diamond debits may arrive as negative (raw sum) or positive
 * (magnitude) — either way the sink is the absolute value.
 */
export function economySummary(tokenCredit: number, tokenDebit: number, diamondCredit: number) {
  const tokenFaucet = Math.max(0, tokenCredit);
  const tokenSink = Math.abs(tokenDebit);
  return {
    tokenFaucet,
    tokenSink,
    tokenNet: tokenFaucet - tokenSink,
    diamondFaucet: Math.max(0, diamondCredit),
  };
}

/** Validate an admin-entered token price → rounded non-negative int, or throw 400. */
export function parsePriceTokens(v: unknown): number {
  const n = Number(v);
  if (!Number.isFinite(n) || n < 0) {
    throw Object.assign(new Error('Giá token không hợp lệ'), { status: 400 });
  }
  return Math.round(n);
}
