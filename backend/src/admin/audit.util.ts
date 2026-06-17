/** Pure helpers for the admin audit trail. */

/** Best client IP for an admin action: first x-forwarded-for hop, else Express req.ip. */
export function clientIp(xff?: string, reqIp?: string): string | null {
  const fromXff = xff?.split(',')[0]?.trim();
  return fromXff || reqIp || null;
}
