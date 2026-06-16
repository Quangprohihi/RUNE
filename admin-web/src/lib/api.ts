import { ApiError } from './friendlyError';
import { getToken, clearToken } from './auth';
import type {
  AdminMe, LoginResponse, OverviewResponse, HealthResponse,
  UsersResponse, UsersQuery, RangeKey,
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

export const api = {
  login: (email: string, password: string) =>
    request<LoginResponse>('/auth/login', { method: 'POST', body: JSON.stringify({ email, password }) }),
  me: () => request<AdminMe>('/auth/me'),
  overview: (range: RangeKey) => request<OverviewResponse>(`/overview?range=${range}`),
  health: () => request<HealthResponse>('/health'),
  users: (params: UsersQuery) => request<UsersResponse>(`/users${buildUsersQuery(params)}`),
};
