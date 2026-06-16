import { describe, it, expect, beforeEach, vi } from 'vitest';
import { api } from './api';
import { ApiError } from './friendlyError';
import { setToken, getToken } from './auth';

function mockFetch(status: number, body: unknown) {
  return vi.fn().mockResolvedValue({
    status,
    ok: status >= 200 && status < 300,
    json: async () => body,
  } as Response);
}

describe('api', () => {
  beforeEach(() => {
    localStorage.clear();
    vi.restoreAllMocks();
  });

  it('attaches the bearer token when present', async () => {
    setToken('tok123');
    const f = mockFetch(200, { range: '7d' });
    vi.stubGlobal('fetch', f);
    await api.overview('7d');
    const [, init] = f.mock.calls[0];
    expect((init.headers as Record<string, string>)['Authorization']).toBe('Bearer tok123');
    expect(f.mock.calls[0][0]).toBe('/admin/api/overview?range=7d');
  });

  it('clears the token on a 401 when already authed', async () => {
    setToken('tok123');
    vi.stubGlobal('fetch', mockFetch(401, { error: 'nope' }));
    vi.stubGlobal('location', { assign: vi.fn() } as unknown as Location);
    await expect(api.overview('today')).rejects.toBeInstanceOf(ApiError);
    expect(getToken()).toBeNull();
  });

  it('passes a login 401 through with the server message (no redirect)', async () => {
    vi.stubGlobal('fetch', mockFetch(401, { error: 'Sai email hoặc mật khẩu quản trị' }));
    await expect(api.login('a@b.c', 'x')).rejects.toMatchObject({
      status: 401,
      message: 'Sai email hoặc mật khẩu quản trị',
    });
  });
});
