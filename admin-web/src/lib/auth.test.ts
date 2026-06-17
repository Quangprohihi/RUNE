import { describe, it, expect, beforeEach } from 'vitest';
import { setToken, getToken, clearToken, isAuthed } from './auth';

describe('auth token storage', () => {
  beforeEach(() => { localStorage.clear(); sessionStorage.clear(); });

  it('remember=true persists in localStorage only', () => {
    setToken('tok', true);
    expect(localStorage.getItem('zz_admin_token')).toBe('tok');
    expect(sessionStorage.getItem('zz_admin_token')).toBeNull();
    expect(getToken()).toBe('tok');
    expect(isAuthed()).toBe(true);
  });

  it('remember=false uses sessionStorage only', () => {
    setToken('tok', false);
    expect(sessionStorage.getItem('zz_admin_token')).toBe('tok');
    expect(localStorage.getItem('zz_admin_token')).toBeNull();
    expect(getToken()).toBe('tok');
  });

  it('switching remember moves the token (no duplicate)', () => {
    setToken('a', false);
    setToken('b', true);
    expect(localStorage.getItem('zz_admin_token')).toBe('b');
    expect(sessionStorage.getItem('zz_admin_token')).toBeNull();
  });

  it('clearToken wipes both stores', () => {
    setToken('tok', true);
    clearToken();
    expect(getToken()).toBeNull();
    expect(isAuthed()).toBe(false);
  });

  it('defaults to remember=true when omitted', () => {
    setToken('tok');
    expect(localStorage.getItem('zz_admin_token')).toBe('tok');
  });
});
