import type { AdminMe } from './types';

const TOKEN_KEY = 'zz_admin_token';
const ADMIN_KEY = 'zz_admin_user';
const THEME_KEY = 'zz_admin_theme';

export function setToken(token: string, remember = true): void {
  if (remember) {
    localStorage.setItem(TOKEN_KEY, token);
    sessionStorage.removeItem(TOKEN_KEY);
  } else {
    sessionStorage.setItem(TOKEN_KEY, token);
    localStorage.removeItem(TOKEN_KEY);
  }
}
export function getToken(): string | null {
  return localStorage.getItem(TOKEN_KEY) ?? sessionStorage.getItem(TOKEN_KEY);
}
export function isAuthed(): boolean { return !!getToken(); }
export function clearToken(): void {
  localStorage.removeItem(TOKEN_KEY);
  sessionStorage.removeItem(TOKEN_KEY);
  localStorage.removeItem(ADMIN_KEY);
}
export function setAdmin(a: AdminMe): void { localStorage.setItem(ADMIN_KEY, JSON.stringify(a)); }
export function getAdmin(): AdminMe | null {
  const raw = localStorage.getItem(ADMIN_KEY);
  try { return raw ? (JSON.parse(raw) as AdminMe) : null; } catch { return null; }
}
export function getTheme(): 'a' | 'b' { return localStorage.getItem(THEME_KEY) === 'b' ? 'b' : 'a'; }
export function setTheme(t: 'a' | 'b'): void { localStorage.setItem(THEME_KEY, t); }
