import type { AdminMe } from './types';

const TOKEN_KEY = 'zz_admin_token';
const ADMIN_KEY = 'zz_admin_user';
const THEME_KEY = 'zz_admin_theme';

export function getToken(): string | null { return localStorage.getItem(TOKEN_KEY); }
export function setToken(t: string): void { localStorage.setItem(TOKEN_KEY, t); }
export function isAuthed(): boolean { return !!getToken(); }
export function clearToken(): void {
  localStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(ADMIN_KEY);
}
export function setAdmin(a: AdminMe): void { localStorage.setItem(ADMIN_KEY, JSON.stringify(a)); }
export function getAdmin(): AdminMe | null {
  const raw = localStorage.getItem(ADMIN_KEY);
  try { return raw ? (JSON.parse(raw) as AdminMe) : null; } catch { return null; }
}
export function getTheme(): 'a' | 'b' { return localStorage.getItem(THEME_KEY) === 'b' ? 'b' : 'a'; }
export function setTheme(t: 'a' | 'b'): void { localStorage.setItem(THEME_KEY, t); }
