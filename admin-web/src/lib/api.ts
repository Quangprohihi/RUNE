import { ApiError } from './friendlyError';
import { getToken, clearToken } from './auth';
import type {
  AdminMe, LoginResponse, OverviewResponse, HealthResponse,
  UsersResponse, UsersQuery, RangeKey,
  BillingSummary, PaymentsResponse, PaymentsQuery, PaymentStatus,
  UserDetail, SubscriptionAction, AnalyticsResponse, AnalyticsQuery,
} from './types';

const BASE = '/admin/api';

async function request<T>(path: string, opts: RequestInit = {}): Promise<T> {
  const token = getToken();
  const headers: Record<string, string> = { ...(opts.headers as Record<string, string>) };
  if (token) headers['Authorization'] = `Bearer ${token}`;
  if (opts.body && !headers['Content-Type']) headers['Content-Type'] = 'application/json';

  const res = await fetch(BASE + path, { ...opts, headers });

  // Session-expired: only when we *were* authed (don't hijack the login form's 401).
  if (res.status === 401 && token) {
    clearToken();
    if (typeof window !== 'undefined' && window.location) window.location.assign('/console/login');
    throw new ApiError(401, 'Unauthorized');
  }

  if (!res.ok) {
    let msg = `Lỗi ${res.status}`;
    try {
      const data = await res.json();
      if (data?.error) msg = data.error;
      else if (data?.message) msg = data.message;
    } catch { /* non-JSON body */ }
    throw new ApiError(res.status, msg);
  }

  return res.json() as Promise<T>;
}

function buildUsersQuery(p: UsersQuery): string {
  const sp = new URLSearchParams();
  if (p.q) sp.set('q', p.q);
  if (p.plan) sp.set('plan', p.plan);
  if (p.status) sp.set('status', p.status);
  if (p.page) sp.set('page', String(p.page));
  if (p.pageSize) sp.set('pageSize', String(p.pageSize));
  const s = sp.toString();
  return s ? `?${s}` : '';
}

function buildPaymentsQuery(p: PaymentsQuery): string {
  const sp = new URLSearchParams();
  if (p.status) sp.set('status', p.status);
  if (p.from) sp.set('from', p.from);
  if (p.to) sp.set('to', p.to);
  if (p.page) sp.set('page', String(p.page));
  if (p.pageSize) sp.set('pageSize', String(p.pageSize));
  const s = sp.toString();
  return s ? `?${s}` : '';
}

export const api = {
  login: (email: string, password: string) => {
    // Clear any stale token so a wrong-password 401 isn't mistaken for "session expired".
    clearToken();
    return request<LoginResponse>('/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) });
  },
  me: () => request<AdminMe>('/auth/me'),
  overview: (range: RangeKey) => request<OverviewResponse>(`/overview?range=${range}`),
  health: () => request<HealthResponse>('/health'),
  users: (params: UsersQuery) => request<UsersResponse>(`/users${buildUsersQuery(params)}`),
  userDetail: (id: string) => request<UserDetail>(`/users/${id}`),
  userSubscription: (id: string, body: SubscriptionAction) =>
    request<{ plan: string; status: string; expiresAt: string | null }>(`/users/${id}/subscription`, { method: 'POST', body: JSON.stringify(body) }),
  forceLogout: (id: string) => request<{ ok: boolean; revoked: number }>(`/users/${id}/force-logout`, { method: 'POST' }),
  payments: (params: PaymentsQuery = {}) => request<PaymentsResponse>(`/payments${buildPaymentsQuery(params)}`),
  confirmPayment: (id: string) => request<{ id: string; status: PaymentStatus }>(`/payments/${id}/confirm`, { method: 'POST' }),
  billing: { summary: (range: RangeKey) => request<BillingSummary>(`/billing/summary?range=${range}`) },
  updatePackage: (code: string, body: { amountVnd?: number; durationDays?: number; isActive?: boolean }) =>
    request<unknown>(`/packages/${code}`, { method: 'PUT', body: JSON.stringify(body) }),
  analytics: (p: AnalyticsQuery = {}) => {
    const sp = new URLSearchParams();
    if (p.range) sp.set('range', p.range);
    if (p.granularity) sp.set('granularity', p.granularity);
    if (p.compare) sp.set('compare', 'true');
    if (p.from) sp.set('from', p.from);
    if (p.to) sp.set('to', p.to);
    const s = sp.toString();
    return request<AnalyticsResponse>(`/analytics${s ? `?${s}` : ''}`);
  },
};
