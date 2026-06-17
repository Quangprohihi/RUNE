export type RangeKey = 'today' | '7d' | '30d' | 'quarter';

export interface Kpi { value: number; deltaPct: number | null; spark: number[]; }

export interface OverviewKpis {
  dau: Kpi; stickiness: Kpi; focusMinutes: Kpi; focusSessions: Kpi;
  premiumUsers: Kpi; revenue: Kpi; avgStreak: Kpi; conversion: Kpi;
}

export interface Goal { label: string; value: number; max: number; unit?: string; }
export interface RecentEvent { eventType: string; title: string; subtitle: string; actor: string; at: string; }
export interface OverviewResponse { range: RangeKey; kpis: OverviewKpis; goals: Goal[]; recent: RecentEvent[]; }

export interface HealthResponse { db: 'ok' | 'down'; vnpay: boolean; gemini: boolean; apiLatencyMs: number; }

export type AdminRole = 'support' | 'moderator' | 'super-admin';
export interface AdminMe { id: string; email: string; name: string; role: AdminRole; }
export interface LoginResponse { token: string; admin: AdminMe; }

export type UserStatus = 'active' | 'suspended' | 'review';
export interface UserRow {
  id: string; email: string; displayName: string; provider: string; createdAt: string;
  plan: string; status: UserStatus; level: number; streak: number; lastLoginAt: string | null;
}
export interface UsersResponse { total: number; page: number; pageSize: number; items: UserRow[]; }
export interface UsersQuery { q?: string; plan?: string; status?: string; page?: number; pageSize?: number; }

export interface BillingKpi { value: number; deltaPct?: number | null; }
export interface BillingSummary {
  range: RangeKey;
  kpis: { revenue: BillingKpi; mrr: BillingKpi; arpu: BillingKpi; refundRate: BillingKpi };
  packages: { code: string; label: string; priceVnd: number; subscribers: number }[];
}
export type PaymentStatus = 'pending' | 'paid' | 'failed' | 'review' | 'refunded';
export interface PaymentRow {
  id: string; vnpTxnRef: string; user: string; productCode: string; amountVnd: number;
  status: PaymentStatus; bankCode: string | null; payDate: string | null; paidAt: string | null; createdAt: string;
}
export interface PaymentsResponse { total: number; page: number; pageSize: number; items: PaymentRow[]; }
export interface PaymentsQuery { status?: string; from?: string; to?: string; page?: number; pageSize?: number; }
