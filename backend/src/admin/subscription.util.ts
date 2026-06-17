/** Pure helper for extending a subscription's expiry. */
const DAY_MS = 24 * 60 * 60 * 1000;

/** Extend from the later of `now` and the current (still-valid) expiry, by `days`. */
export function extendExpiry(current: Date | null, days: number, now: Date): Date {
  const base = current && current.getTime() > now.getTime() ? current : now;
  return new Date(base.getTime() + days * DAY_MS);
}
