/** Pure, DB-agnostic billing metric helpers. No Prisma here. */
const MONTHLY_VND = 29000;
const YEARLY_VND = 279000;

export function monthlyEquivalentVnd(productCode: string): number {
  if (productCode === 'zen_pro_monthly') return MONTHLY_VND;
  if (productCode === 'zen_pro_yearly') return Math.round(YEARLY_VND / 12);
  return 0;
}

export function computeMrr(monthly: number, yearly: number): number {
  return monthly * MONTHLY_VND + yearly * Math.round(YEARLY_VND / 12);
}

export function refundRate(refunded: number, paid: number): number {
  const denom = paid + refunded;
  if (denom === 0) return 0;
  return Math.round((refunded / denom) * 1000) / 10;
}

export function arpu(revenue: number, activeUsers: number): number {
  if (activeUsers === 0) return 0;
  return Math.round(revenue / activeUsers);
}

/** orders MUST be newest-first by paidAt; counts each premium user once by newest package. */
export function bucketLatestPaidByUser(
  orders: { userId: string; productCode: string; paidAt: Date | string | null }[],
  premiumUserIds: Set<string>,
): { monthly: number; yearly: number } {
  const seen = new Set<string>();
  let monthly = 0;
  let yearly = 0;
  for (const o of orders) {
    if (!premiumUserIds.has(o.userId) || seen.has(o.userId)) continue;
    seen.add(o.userId);
    if (o.productCode === 'zen_pro_monthly') monthly++;
    else if (o.productCode === 'zen_pro_yearly') yearly++;
  }
  return { monthly, yearly };
}
