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
  packages: { code: string; label: string; priceVnd: number; subscribers: number; isActive?: boolean }[];
}
export type PaymentStatus = 'pending' | 'paid' | 'failed' | 'review' | 'refunded';
export interface PaymentRow {
  id: string; provider: string; vnpTxnRef: string; user: string; productCode: string; amountVnd: number;
  status: PaymentStatus; bankCode: string | null; payDate: string | null; paidAt: string | null; createdAt: string;
}
export interface PaymentsResponse { total: number; page: number; pageSize: number; items: PaymentRow[]; }
export interface PaymentsQuery { status?: string; from?: string; to?: string; page?: number; pageSize?: number; }

export interface UserDetail {
  id: string; email: string; displayName: string; provider: string; createdAt: string;
  status?: UserStatus; lastLoginAt?: string | null;
  subscription: { plan: string; status: string; expiresAt: string | null } | null;
  pet: { name: string; species: string; level: number; exp: number; expToNext: number; energy: number; mood: number; hunger: number; love: number } | null;
  wallet: { tokens: number; diamonds: number; energy: number } | null;
  streak: { currentStreak: number; bestStreak: number } | null;
  focusSessions: { id: string; label: string; plannedMinutes: number; companionCode: string | null; status: string; startedAt: string }[];
  activityEvents: { id: string; title: string; subtitle: string; icon: string; createdAt: string }[];
  _count?: { refreshTokens: number };
}
export interface SubscriptionAction { action: 'cancel' | 'extend'; days?: number; }

export interface AnalyticsKpi { value: number; deltaPct: number | null; }
export interface AnalyticsResponse {
  range: string; granularity: string; compare: boolean; rangeLabel: string;
  kpis: { activeUsers: AnalyticsKpi; focusMinutes: AnalyticsKpi; revenue: AnalyticsKpi; newPro: AnalyticsKpi };
  series: { label: string; cur: number[]; prev: number[] | null };
  bucketLabels: string[];
  funnel: { label: string; value: number; pct: number }[];
  hourly: { label: string; minutes: number }[];
}
export interface AnalyticsQuery { range?: string; granularity?: string; compare?: boolean; from?: string; to?: string; }

export interface AdminAuditRow {
  id: string; at: string; actorId: string; actorEmail: string; actorRole: string;
  action: string; resourceType: string; resourceId: string; ip: string | null;
  metadata: Record<string, unknown> | null;
}
export interface AdminAuditResponse { total: number; page: number; pageSize: number; items: AdminAuditRow[]; }
export interface WalletAuditRow {
  id: string; at: string; actor: string; reason: string; amount: number; currency: string; refType: string;
}
export interface WalletAuditResponse { total: number; page: number; pageSize: number; items: WalletAuditRow[]; }
export interface AuditQuery { action?: string; q?: string; page?: number; pageSize?: number; }

export interface ShopItem {
  id: string; code: string; name: string; emoji: string; itemType: string;
  priceTokens: number; effectType: string; effectValue: number; isHot: boolean; isActive: boolean;
}
export interface ShopItemsResponse { items: ShopItem[]; }
export interface EconomyKpis { tokenFaucet: number; tokenSink: number; tokenNet: number; diamondFaucet: number; }
export interface EconomyResponse { range: RangeKey; kpis: EconomyKpis; activeItems: number; }
export interface ShopItemUpdate { priceTokens?: number; isActive?: boolean; isHot?: boolean; }

export interface TaskTemplate {
  id: string; code: string; title: string; description: string; taskType: string;
  targetValue: number; rewardTokens: number; rewardDiamonds: number; rewardPoints: number; isActive: boolean;
}
export interface DailyMilestone {
  id: string; pointsRequired: number; rewardTokens: number; rewardDiamonds: number; isActive: boolean;
}
export interface TaskKpis { activeTasks: number; dailyTokenFaucet: number; activeMilestones: number; }
export interface TaskConfigResponse { kpis: TaskKpis; tasks: TaskTemplate[]; milestones: DailyMilestone[]; }
export interface TaskUpdate { rewardTokens?: number; rewardDiamonds?: number; rewardPoints?: number; isActive?: boolean; }
export interface MilestoneUpdate { rewardTokens?: number; rewardDiamonds?: number; isActive?: boolean; }
