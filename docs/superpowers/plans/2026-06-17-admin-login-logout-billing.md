# Admin Console — Login redesign + Logout + Billing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the admin Login with the new ManLab "ZenZoo Login" design, add a topbar avatar **Logout** menu, and build the read-only **"Thanh toán & Gói"** (Billing) screen wired to real revenue/transaction/package data.

**Architecture:** Frontend = the existing React+Vite+TS SPA in `admin-web/` (served by Express at `/console`). Backend = Express+Prisma in `backend/` (runs in Docker). This phase replaces `LoginPage.tsx`, extends `lib/auth.ts` (remember → local vs session storage), adds a `UserMenu` to the topbar, adds pure billing-metric helpers + two read-only admin endpoints, and adds `BillingPage`. Order: **Login → Logout → Billing**.

**Tech Stack:** React 18, Vite 5, react-router-dom 6, Vitest+RTL (frontend); Express 5, Prisma 7, Vitest (backend, in-container).

## Global Constraints

- **Execution environment (Docker):** backend runs in container `zenzoo_backend`. Run backend tooling **in-container**: `docker compose exec -T backend sh -c "<cmd>"` (prisma, `npm test`, `tsc`). **After editing backend source, `docker compose restart backend`** (the ts-node-dev watcher does NOT fire on this Windows bind-mount) before cur/smoke-testing. Frontend tooling runs on the **host**: `cd admin-web && npm <...>`. Commit on the **host**: `cd e:/ChuyenNha/Prm393/rune && git add <paths> && git commit`. Stage only the listed paths.
- **Frontend build** outputs to `backend/admin-web/dist` (Vite `outDir`), served by the container at `/console`. After FE changes, `cd admin-web && npm run build` to refresh what the container serves.
- **Read-only billing:** no admin endpoint may mutate a PaymentOrder or Subscription this phase. No refund/confirm/package-price write.
- **Design system:** use ManLab CSS variables only (no hardcoded hex except the brand wordmark colors `#3FB2A6`/`#1E6CA1` and the Google logo colors, which are verbatim from the design). Vietnamese UI copy exactly as written. Money/number formatting via existing `lib/format.ts`.
- **Auth:** admin token via `getToken()`; `/admin/api/*` gated by `requireAdmin`. Don't touch the user-facing payment flow (`/payments/vnpay/*`).
- **Design source (login):** `login_design/thi-t-k-l-i-trang-web-hi-n-i/project/ZenZoo Login.dc.html` (+ `screenshots/00-login.png`). **Design source (billing):** `admin_report/project/ZenZoo Admin.dc.html` section "Thanh toán & Gói".
- Spec: `docs/superpowers/specs/2026-06-17-admin-billing-logout-design.md`.

---

## File Structure

**Frontend:**
- Modify `admin-web/src/lib/auth.ts` — `setToken(token, remember)`, getToken/clearToken across local+session (Task 1).
- Create `admin-web/src/lib/auth.test.ts` (Task 1).
- Replace `admin-web/src/pages/LoginPage.tsx` + create `LoginPage.test.tsx` (Task 2).
- Create `admin-web/src/shell/UserMenu.tsx`; modify `admin-web/src/shell/Topbar.tsx` (Task 3) + `UserMenu.test.tsx`.
- Add focus style `.zzl-field` to `admin-web/src/ds/ds.css` (Task 2).
- Modify `admin-web/src/ds/KpiCard.tsx` (add `hideSpark`) (Task 7).
- Modify `admin-web/src/lib/types.ts`, `admin-web/src/lib/api.ts`, `admin-web/src/shell/nav.ts`, `admin-web/src/App.tsx` (Task 7).
- Create `admin-web/src/pages/BillingPage.tsx` + `BillingPage.test.tsx` (Task 7).

**Backend:**
- Create `backend/src/admin/billing.metrics.ts` + `backend/src/admin/__tests__/billing.metrics.test.ts` (Task 5).
- Modify `backend/src/routes/admin.routes.ts` — extend `/payments`, add `/billing/summary` (Task 6).

---

## Phase A — Login redesign

### Task 1: `auth.ts` remember → local/session storage (TDD)

**Files:**
- Modify: `admin-web/src/lib/auth.ts`
- Test: `admin-web/src/lib/auth.test.ts`

**Interfaces:**
- Produces: `setToken(token: string, remember?: boolean): void` (default `true`), `getToken(): string | null`, `clearToken(): void`, `isAuthed(): boolean`, `setAdmin(a)`, `getAdmin()`, `getTheme()`, `setTheme()` (existing signatures preserved except `setToken` gains `remember`).

- [ ] **Step 1.1: Write the failing test** `admin-web/src/lib/auth.test.ts`:

```ts
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
```

- [ ] **Step 1.2: Run; verify fail.** `cd admin-web && npm test`. Expected: FAIL (current `setToken` takes 1 arg / uses only localStorage).

- [ ] **Step 1.3: Replace `admin-web/src/lib/auth.ts`:**

```ts
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
```

- [ ] **Step 1.4: Run; verify pass.** `cd admin-web && npm test`. Expected: PASS (auth + all earlier suites). Then `npm run typecheck` → exit 0.

- [ ] **Step 1.5: Commit.**

```bash
git add admin-web/src/lib/auth.ts admin-web/src/lib/auth.test.ts
git commit -m "feat(admin-web): auth setToken honors remember (local vs session storage)"
```

---

### Task 2: LoginPage redesign (+ test)

**Files:**
- Replace: `admin-web/src/pages/LoginPage.tsx`
- Modify: `admin-web/src/ds/ds.css` (add `.zzl-field` focus style)
- Test: `admin-web/src/pages/LoginPage.test.tsx`

**Interfaces:**
- Consumes: `api.login(email, password)`, `setToken(token, remember)`, `setAdmin`, `friendlyError`, `useNavigate`.

- [ ] **Step 2.1: Add the focus style** to the END of `admin-web/src/ds/ds.css`:

```css
/* ---- Login fields ---- */
.zzl-field:focus { outline: none; border-color: var(--brand); box-shadow: 0 0 0 3px var(--focus-ring, rgba(28,80,201,.18)); }
```

- [ ] **Step 2.2: Write the failing test** `admin-web/src/pages/LoginPage.test.tsx`:

```tsx
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { LoginPage } from './LoginPage';

const navigateMock = vi.fn();
vi.mock('react-router-dom', async (orig) => ({
  ...(await orig<typeof import('react-router-dom')>()),
  useNavigate: () => navigateMock,
}));

const loginMock = vi.fn();
vi.mock('../lib/api', () => ({ api: { login: (...a: unknown[]) => loginMock(...a) } }));

function renderPage() { return render(<MemoryRouter><LoginPage /></MemoryRouter>); }

describe('LoginPage (redesigned)', () => {
  beforeEach(() => { localStorage.clear(); sessionStorage.clear(); navigateMock.mockClear(); loginMock.mockReset(); });

  it('renders the redesigned brand + form controls', () => {
    renderPage();
    expect(screen.getByText('Đăng nhập quản trị')).toBeInTheDocument();
    expect(screen.getByText('Khu vực giới hạn — chỉ dành cho quản trị viên ZenZoo.')).toBeInTheDocument();
    expect(screen.getByText('Ghi nhớ thiết bị này')).toBeInTheDocument();
    expect(screen.getByText('Quên mật khẩu?')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Đăng nhập với Google Workspace/ })).toBeInTheDocument();
  });

  it('toggles password visibility', () => {
    renderPage();
    const pass = screen.getByPlaceholderText('••••••••') as HTMLInputElement;
    expect(pass.type).toBe('password');
    fireEvent.click(screen.getByLabelText('Hiện/ẩn mật khẩu'));
    expect(pass.type).toBe('text');
  });

  it('logs in then navigates home', async () => {
    loginMock.mockResolvedValue({ token: 't', admin: { id: '1', email: 'a@b.c', name: 'A', role: 'super-admin' } });
    renderPage();
    fireEvent.change(screen.getByPlaceholderText('admin@zenzoo.app'), { target: { value: 'admin@zenzoo.app' } });
    fireEvent.change(screen.getByPlaceholderText('••••••••'), { target: { value: 'zenzoo-admin' } });
    fireEvent.click(screen.getByRole('button', { name: 'Đăng nhập' }));
    await waitFor(() => expect(navigateMock).toHaveBeenCalledWith('/', { replace: true }));
    expect(localStorage.getItem('zz_admin_token')).toBe('t');
  });

  it('shows the server error on bad login', async () => {
    loginMock.mockRejectedValue(Object.assign(new Error('Sai email hoặc mật khẩu quản trị'), { name: 'ApiError', status: 401 }));
    renderPage();
    fireEvent.click(screen.getByRole('button', { name: 'Đăng nhập' }));
    await waitFor(() => expect(screen.getByRole('alert')).toHaveTextContent('Sai email hoặc mật khẩu quản trị'));
  });

  it('placeholder buttons show a "đang phát triển" note', () => {
    renderPage();
    fireEvent.click(screen.getByText('Quên mật khẩu?'));
    expect(screen.getByText(/đang phát triển/i)).toBeInTheDocument();
  });
});
```

> Note: the bad-login test relies on `friendlyError` returning the message for a 401 carrying a real server message (the Phase-1 fix). The thrown object mimics `ApiError` (name+status+message).

- [ ] **Step 2.3: Run; verify fail.** `cd admin-web && npm test`. Expected: FAIL (current LoginPage lacks the new copy/controls).

- [ ] **Step 2.4: Replace `admin-web/src/pages/LoginPage.tsx`** (faithful to `ZenZoo Login.dc.html`):

```tsx
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../lib/api';
import { setToken, setAdmin } from '../lib/auth';
import { friendlyError } from '../lib/friendlyError';

const FIELD: React.CSSProperties = {
  height: 42, width: '100%', border: '1px solid var(--border-default)', borderRadius: 'var(--radius-md)',
  font: 'var(--fw-regular) 14px/1 var(--font-sans)', color: 'var(--text-strong)',
  background: 'var(--surface-card)', transition: 'border-color .15s, box-shadow .15s',
};
const LABEL: React.CSSProperties = { font: 'var(--fw-semibold) 12px/1 var(--font-sans)', color: 'var(--text-strong)' };

export function LoginPage() {
  const nav = useNavigate();
  const [email, setEmail] = useState('admin@zenzoo.app');
  const [password, setPassword] = useState('');
  const [showPass, setShowPass] = useState(false);
  const [remember, setRemember] = useState(true);
  const [err, setErr] = useState<string | null>(null);
  const [note, setNote] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setErr(null); setNote(null); setBusy(true);
    try {
      const res = await api.login(email.trim(), password);
      setToken(res.token, remember);
      setAdmin(res.admin);
      nav('/', { replace: true });
    } catch (ex) {
      setErr(friendlyError(ex));
    } finally {
      setBusy(false);
    }
  }
  const wip = () => { setErr(null); setNote('Tính năng đang phát triển — vui lòng liên hệ super-admin.'); };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 32, background: 'var(--slate-50)', fontFamily: 'var(--font-sans)' }}>
      <div style={{ width: '100%', maxWidth: 400, display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
        {/* brand */}
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14, marginBottom: 28 }}>
          <img src={`${import.meta.env.BASE_URL}zenzoo-mark.png`} alt="ZenZoo" style={{ width: 52, height: 52, objectFit: 'contain' }} />
          <div style={{ textAlign: 'center' }}>
            <div style={{ font: 'var(--fw-extra) 24px/1 var(--font-sans)', letterSpacing: '-.01em' }}><span style={{ color: '#3FB2A6' }}>Zen</span><span style={{ color: '#1E6CA1' }}>Zoo</span></div>
            <div style={{ font: 'var(--fw-semibold) 10px/1 var(--font-sans)', letterSpacing: '.22em', textTransform: 'uppercase', color: 'var(--text-faint)', marginTop: 7 }}>Admin Console</div>
          </div>
        </div>

        {/* card */}
        <div style={{ width: '100%', background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-lg)', boxShadow: 'var(--shadow-sm)', padding: '28px 28px 26px' }}>
          <h1 style={{ font: 'var(--fw-bold) 19px/1.2 var(--font-sans)', letterSpacing: '-.01em', color: 'var(--text-strong)', margin: '0 0 4px' }}>Đăng nhập quản trị</h1>
          <p style={{ font: 'var(--fw-regular) 13px/1.5 var(--font-sans)', color: 'var(--text-muted)', margin: '0 0 22px' }}>Khu vực giới hạn — chỉ dành cho quản trị viên ZenZoo.</p>

          <form onSubmit={submit} style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <label htmlFor="zzl-email" style={LABEL}>Email</label>
              <input id="zzl-email" className="zzl-field" type="email" autoComplete="username" placeholder="admin@zenzoo.app"
                value={email} onChange={(e) => setEmail(e.target.value)} autoFocus style={{ ...FIELD, padding: '0 13px' }} />
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
                <label htmlFor="zzl-pass" style={LABEL}>Mật khẩu</label>
                <span onClick={wip} style={{ font: 'var(--fw-medium) 12px/1 var(--font-sans)', color: 'var(--text-link)', cursor: 'pointer' }}>Quên mật khẩu?</span>
              </div>
              <div style={{ position: 'relative', display: 'flex', alignItems: 'center' }}>
                <input id="zzl-pass" className="zzl-field" type={showPass ? 'text' : 'password'} autoComplete="current-password" placeholder="••••••••"
                  value={password} onChange={(e) => setPassword(e.target.value)} style={{ ...FIELD, padding: '0 42px 0 13px' }} />
                <button type="button" onClick={() => setShowPass((s) => !s)} aria-label="Hiện/ẩn mật khẩu"
                  style={{ position: 'absolute', right: 4, width: 34, height: 34, display: 'inline-flex', alignItems: 'center', justifyContent: 'center', border: 'none', background: 'transparent', cursor: 'pointer', color: 'var(--text-muted)', borderRadius: 'var(--radius-sm)' }}>
                  <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round">
                    {showPass
                      ? (<><path d="M10.733 5.076a10.744 10.744 0 0 1 11.205 6.575 1 1 0 0 1 0 .696 10.747 10.747 0 0 1-1.444 2.49" /><path d="M14.084 14.158a3 3 0 0 1-4.242-4.242" /><path d="M17.479 17.499a10.75 10.75 0 0 1-15.417-5.151 1 1 0 0 1 0-.696 10.75 10.75 0 0 1 4.446-5.143" /><path d="m2 2 20 20" /></>)
                      : (<><path d="M2.062 12.348a1 1 0 0 1 0-.696 10.75 10.75 0 0 1 19.876 0 1 1 0 0 1 0 .696 10.75 10.75 0 0 1-19.876 0" /><circle cx="12" cy="12" r="3" /></>)}
                  </svg>
                </button>
              </div>
            </div>

            <label style={{ display: 'flex', alignItems: 'center', gap: 9, cursor: 'pointer', userSelect: 'none', marginTop: -2 }}>
              <input type="checkbox" checked={remember} onChange={(e) => setRemember(e.target.checked)} style={{ width: 16, height: 16, accentColor: 'var(--brand)', cursor: 'pointer' }} />
              <span style={{ font: 'var(--fw-regular) 13px/1 var(--font-sans)', color: 'var(--text-body)' }}>Ghi nhớ thiết bị này</span>
            </label>

            {err && <div role="alert" style={{ font: 'var(--fw-medium) 12px/1.4 var(--font-sans)', color: 'var(--danger-fg)', background: 'var(--danger-bg)', border: '1px solid var(--status-rejected-border)', borderRadius: 'var(--radius-md)', padding: '8px 10px' }}>{err}</div>}
            {note && <div style={{ font: 'var(--fw-medium) 12px/1.4 var(--font-sans)', color: 'var(--text-muted)', background: 'var(--surface-sunken)', borderRadius: 'var(--radius-md)', padding: '8px 10px' }}>{note}</div>}

            <button type="submit" disabled={busy}
              style={{ height: 42, width: '100%', border: 'none', borderRadius: 'var(--radius-md)', backgroundColor: 'var(--brand)', color: '#fff', cursor: busy ? 'default' : 'pointer', font: 'var(--fw-semibold) 14px/1 var(--font-sans)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 8, opacity: busy ? 0.7 : 1 }}>
              <svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><path d="M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4" /><polyline points="10 17 15 12 10 7" /><line x1="15" x2="3" y1="12" y2="12" /></svg>
              {busy ? 'Đang đăng nhập…' : 'Đăng nhập'}
            </button>
          </form>

          <div style={{ display: 'flex', alignItems: 'center', gap: 12, margin: '20px 0 16px' }}>
            <span style={{ flex: 1, height: 1, background: 'var(--border-subtle)' }} />
            <span style={{ font: 'var(--fw-medium) 11px/1 var(--font-sans)', color: 'var(--text-faint)', textTransform: 'uppercase', letterSpacing: '.08em' }}>hoặc</span>
            <span style={{ flex: 1, height: 1, background: 'var(--border-subtle)' }} />
          </div>

          <button type="button" onClick={wip}
            style={{ height: 42, width: '100%', border: '1px solid var(--border-default)', borderRadius: 'var(--radius-md)', backgroundColor: 'var(--surface-card)', color: 'var(--text-strong)', cursor: 'pointer', font: 'var(--fw-semibold) 13.5px/1 var(--font-sans)', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', gap: 10 }}>
            <svg width="17" height="17" viewBox="0 0 24 24" aria-hidden="true"><path fill="#4285F4" d="M22.56 12.25c0-.78-.07-1.53-.2-2.25H12v4.26h5.92a5.06 5.06 0 0 1-2.2 3.32v2.77h3.57c2.08-1.92 3.27-4.74 3.27-8.1z" /><path fill="#34A853" d="M12 23c2.97 0 5.46-.98 7.28-2.66l-3.57-2.77c-.98.66-2.23 1.06-3.71 1.06-2.86 0-5.29-1.93-6.16-4.53H2.18v2.84A11 11 0 0 0 12 23z" /><path fill="#FBBC05" d="M5.84 14.1a6.6 6.6 0 0 1 0-4.2V7.06H2.18a11 11 0 0 0 0 9.88l3.66-2.84z" /><path fill="#EA4335" d="M12 5.38c1.62 0 3.06.56 4.21 1.64l3.15-3.15C17.45 2.09 14.97 1 12 1A11 11 0 0 0 2.18 7.06l3.66 2.84C6.71 7.3 9.14 5.38 12 5.38z" /></svg>
            Đăng nhập với Google Workspace
          </button>
        </div>

        {/* footer */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 7, marginTop: 22, font: 'var(--fw-regular) 12px/1.4 var(--font-sans)', color: 'var(--text-faint)' }}>
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.9" strokeLinecap="round" strokeLinejoin="round"><rect width="18" height="11" x="3" y="11" rx="2" ry="2" /><path d="M7 11V7a5 5 0 0 1 10 0v4" /></svg>
          Kết nối được mã hóa · ZenZoo Admin v2.4.0
        </div>
      </div>
    </div>
  );
}
```

- [ ] **Step 2.5: Run; verify pass.** `cd admin-web && npm test` (LoginPage + all suites) and `npm run typecheck` (exit 0).

- [ ] **Step 2.6: Commit.**

```bash
git add admin-web/src/pages/LoginPage.tsx admin-web/src/pages/LoginPage.test.tsx admin-web/src/ds/ds.css
git commit -m "feat(admin-web): redesign login page (ManLab) + remember-device"
```

---

## Phase B — Logout

### Task 3: Topbar avatar `UserMenu` with logout (+ test)

**Files:**
- Create: `admin-web/src/shell/UserMenu.tsx`
- Modify: `admin-web/src/shell/Topbar.tsx`
- Test: `admin-web/src/shell/UserMenu.test.tsx`

**Interfaces:**
- Consumes: `getAdmin()`, `clearToken()` from `lib/auth`; `useNavigate`; `initialsFromAdmin` from `shell/topbarUtil`.
- Produces: `<UserMenu />` (default export-free named export) rendered by `Topbar`.

- [ ] **Step 3.1: Write the failing test** `admin-web/src/shell/UserMenu.test.tsx`:

```tsx
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { UserMenu } from './UserMenu';
import { setToken, getToken } from '../lib/auth';

const navigateMock = vi.fn();
vi.mock('react-router-dom', async (orig) => ({
  ...(await orig<typeof import('react-router-dom')>()),
  useNavigate: () => navigateMock,
}));

describe('UserMenu', () => {
  beforeEach(() => { localStorage.clear(); sessionStorage.clear(); navigateMock.mockClear(); });

  it('opens the menu and logs out', async () => {
    setToken('tok', true);
    render(<MemoryRouter><UserMenu /></MemoryRouter>);
    // menu hidden initially
    expect(screen.queryByText('Đăng xuất')).toBeNull();
    fireEvent.click(screen.getByLabelText('Tài khoản quản trị'));
    expect(screen.getByText('Đăng xuất')).toBeInTheDocument();
    fireEvent.click(screen.getByText('Đăng xuất'));
    await waitFor(() => expect(navigateMock).toHaveBeenCalledWith('/login', { replace: true }));
    expect(getToken()).toBeNull();
  });
});
```

- [ ] **Step 3.2: Run; verify fail.** `cd admin-web && npm test`. Expected: FAIL (no `./UserMenu`).

- [ ] **Step 3.3: Create `admin-web/src/shell/UserMenu.tsx`:**

```tsx
import { useEffect, useRef, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { getAdmin, clearToken } from '../lib/auth';
import { initialsFromAdmin } from './topbarUtil';

export function UserMenu() {
  const nav = useNavigate();
  const admin = getAdmin();
  const [open, setOpen] = useState(false);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (!open) return;
    const onDoc = (e: MouseEvent) => { if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false); };
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') setOpen(false); };
    document.addEventListener('mousedown', onDoc);
    document.addEventListener('keydown', onKey);
    return () => { document.removeEventListener('mousedown', onDoc); document.removeEventListener('keydown', onKey); };
  }, [open]);

  function logout() {
    clearToken();
    nav('/login', { replace: true });
  }

  return (
    <div ref={ref} style={{ position: 'relative' }}>
      <button type="button" aria-label="Tài khoản quản trị" onClick={() => setOpen((o) => !o)}
        style={{ display: 'inline-flex', alignItems: 'center', gap: 10, background: 'transparent', border: 'none', cursor: 'pointer', padding: 0 }}>
        <span style={{ width: 36, height: 36, flex: 'none', borderRadius: '50%', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', font: 'var(--fw-semibold) 13px/1 var(--font-sans)', background: 'var(--blue-100)', color: 'var(--blue-700)', border: '1px solid color-mix(in srgb, var(--blue-700) 14%, transparent)' }}>{initialsFromAdmin(admin?.name)}</span>
        <span style={{ display: 'flex', flexDirection: 'column', gap: 1, minWidth: 0, textAlign: 'left' }}>
          <span style={{ font: 'var(--fw-semibold) 13px/1.3 var(--font-sans)', color: 'var(--text-strong)', whiteSpace: 'nowrap' }}>{admin?.name ?? 'Quản trị viên'}</span>
          <span style={{ font: 'var(--fw-regular) 12px/1.3 var(--font-sans)', color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>{admin?.role ?? '—'}</span>
        </span>
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="var(--text-faint)" strokeWidth="1.75" strokeLinecap="round" strokeLinejoin="round" style={{ marginLeft: 2 }}><path d="m6 9 6 6 6-6" /></svg>
      </button>

      {open && (
        <div role="menu" style={{ position: 'absolute', right: 0, top: 'calc(100% + 8px)', minWidth: 220, background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-lg)', boxShadow: 'var(--shadow-lg)', padding: 6, zIndex: 400 }}>
          <div style={{ padding: '8px 10px 10px', borderBottom: '1px solid var(--border-subtle)' }}>
            <div style={{ font: 'var(--fw-semibold) 13px/1.3 var(--font-sans)', color: 'var(--text-strong)' }}>{admin?.name ?? 'Quản trị viên'}</div>
            <div style={{ font: 'var(--fw-regular) 12px/1.3 var(--font-mono)', color: 'var(--text-muted)' }}>{admin?.email ?? '—'}</div>
            <div style={{ font: 'var(--fw-medium) 11px/1 var(--font-sans)', color: 'var(--text-faint)', textTransform: 'uppercase', letterSpacing: '.06em', marginTop: 4 }}>{admin?.role ?? ''}</div>
          </div>
          <button type="button" role="menuitem" onClick={logout}
            style={{ display: 'flex', alignItems: 'center', gap: 9, width: '100%', marginTop: 4, padding: '9px 10px', border: 'none', background: 'transparent', cursor: 'pointer', borderRadius: 'var(--radius-md)', font: 'var(--fw-medium) 13px/1 var(--font-sans)', color: 'var(--danger-fg)', textAlign: 'left' }}
            onMouseEnter={(e) => (e.currentTarget.style.background = 'var(--danger-bg)')}
            onMouseLeave={(e) => (e.currentTarget.style.background = 'transparent')}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.85" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><polyline points="16 17 21 12 16 7" /><line x1="21" x2="9" y1="12" y2="12" /></svg>
            Đăng xuất
          </button>
        </div>
      )}
    </div>
  );
}
```

- [ ] **Step 3.4: Wire into `Topbar.tsx`.** In `admin-web/src/shell/Topbar.tsx`, replace the static avatar `<span>…</span>` block (the one rendering initials + name + role) with `<UserMenu />`, and add `import { UserMenu } from './UserMenu';`. Remove the now-unused `getAdmin`/`initialsFromAdmin` usage from Topbar if they become unused (keep the import only if still referenced). Concretely: delete the trailing `<span style={{ display: 'inline-flex', alignItems: 'center', gap: 10 }}>…</span>` avatar block and put `<UserMenu />` in its place inside the right-side controls `div`.

- [ ] **Step 3.5: Run; verify pass.** `cd admin-web && npm test` (UserMenu + all) and `npm run typecheck` (exit 0). If Topbar has an unused-import TS error, remove the dead import.

- [ ] **Step 3.6: Commit.**

```bash
git add admin-web/src/shell/UserMenu.tsx admin-web/src/shell/UserMenu.test.tsx admin-web/src/shell/Topbar.tsx
git commit -m "feat(admin-web): topbar avatar menu with logout"
```

---

## Phase C — Billing ("Thanh toán & Gói")

### Task 4: `billing.metrics.ts` pure helpers (TDD)

**Files:**
- Create: `backend/src/admin/billing.metrics.ts`
- Test: `backend/src/admin/__tests__/billing.metrics.test.ts`

**Interfaces:**
- Produces: `monthlyEquivalentVnd(code: string): number`, `computeMrr(monthly: number, yearly: number): number`, `refundRate(refunded: number, paid: number): number`, `arpu(revenue: number, activeUsers: number): number`, `bucketLatestPaidByUser(orders: {userId:string;productCode:string;paidAt:Date|string|null}[], premiumUserIds: Set<string>): {monthly:number;yearly:number}`.

- [ ] **Step 4.1: Write the failing test** `backend/src/admin/__tests__/billing.metrics.test.ts`:

```ts
import { describe, it, expect } from 'vitest';
import { monthlyEquivalentVnd, computeMrr, refundRate, arpu, bucketLatestPaidByUser } from '../billing.metrics';

describe('monthlyEquivalentVnd', () => {
  it('maps package codes to monthly value', () => {
    expect(monthlyEquivalentVnd('zen_pro_monthly')).toBe(29000);
    expect(monthlyEquivalentVnd('zen_pro_yearly')).toBe(Math.round(279000 / 12));
    expect(monthlyEquivalentVnd('unknown')).toBe(0);
  });
});

describe('computeMrr', () => {
  it('sums monthly + yearly-normalized recurring revenue', () => {
    expect(computeMrr(2, 1)).toBe(2 * 29000 + Math.round(279000 / 12));
    expect(computeMrr(0, 0)).toBe(0);
  });
});

describe('refundRate', () => {
  it('is refunded/(paid+refunded) %, 1dp, 0 when no orders', () => {
    expect(refundRate(1, 9)).toBe(10);
    expect(refundRate(0, 50)).toBe(0);
    expect(refundRate(0, 0)).toBe(0);
  });
});

describe('arpu', () => {
  it('is revenue/activeUsers rounded, 0 when no users', () => {
    expect(arpu(100000, 40)).toBe(2500);
    expect(arpu(100000, 0)).toBe(0);
  });
});

describe('bucketLatestPaidByUser', () => {
  it('counts each premium user once by their newest paid order package', () => {
    const orders = [
      { userId: 'u1', productCode: 'zen_pro_yearly', paidAt: '2026-06-10' },  // newest for u1
      { userId: 'u1', productCode: 'zen_pro_monthly', paidAt: '2026-01-01' }, // older — ignored
      { userId: 'u2', productCode: 'zen_pro_monthly', paidAt: '2026-06-09' },
      { userId: 'u3', productCode: 'zen_pro_monthly', paidAt: '2026-06-08' }, // u3 not premium — ignored
    ];
    const premium = new Set(['u1', 'u2']);
    expect(bucketLatestPaidByUser(orders, premium)).toEqual({ monthly: 1, yearly: 1 });
  });
});
```

- [ ] **Step 4.2: Run; verify fail.** `docker compose exec -T backend npm test`. Expected: FAIL (no `../billing.metrics`).

- [ ] **Step 4.3: Implement `backend/src/admin/billing.metrics.ts`:**

```ts
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
```

- [ ] **Step 4.4: Run; verify pass.** `docker compose exec -T backend npm test`. Expected: PASS (billing.metrics + admin.metrics).

- [ ] **Step 4.5: Commit.**

```bash
git add backend/src/admin/billing.metrics.ts backend/src/admin/__tests__/billing.metrics.test.ts
git commit -m "feat(backend): pure billing metric helpers (MRR/ARPU/refundRate/package bucket)"
```

---

### Task 5: Backend billing endpoints — extend `/payments`, add `/billing/summary`

**Files:**
- Modify: `backend/src/routes/admin.routes.ts`

**Interfaces:**
- Consumes: `windowFor, deltaPct, RangeKey` (already imported from `../admin/admin.metrics`); `computeMrr, refundRate, arpu, bucketLatestPaidByUser` (new import from `../admin/billing.metrics`).
- Produces: `GET /admin/api/billing/summary?range=` → `{range,kpis:{revenue:{value,deltaPct},mrr:{value},arpu:{value},refundRate:{value}},packages:[{code,label,priceVnd,subscribers}]}`; `GET /admin/api/payments?status=&from=&to=&page=&pageSize=` → `{total,page,pageSize,items:[{id,vnpTxnRef,user,productCode,amountVnd,status,bankCode,payDate,paidAt,createdAt}]}`.

- [ ] **Step 5.1: Add the billing.metrics import** near the top of `backend/src/routes/admin.routes.ts` (after the existing `admin.metrics` import):

```ts
import { computeMrr, refundRate, arpu, bucketLatestPaidByUser } from '../admin/billing.metrics';
```

- [ ] **Step 5.2: Replace the existing `GET /admin/api/payments` handler** (find `app.get('/admin/api/payments'`) with the paginated + date-filtered version:

```ts
  // ---- payments / transactions (paginated, date + status filter) ----
  app.get('/admin/api/payments', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const status = String(req.query.status ?? '').trim();
      const allowed = ['pending', 'paid', 'failed', 'review', 'refunded'];
      const page = Math.max(1, Number(req.query.page ?? 1));
      const pageSize = Math.min(100, Math.max(1, Number(req.query.pageSize ?? 25)));
      const from = String(req.query.from ?? '').trim();
      const to = String(req.query.to ?? '').trim();

      const where: any = {};
      if (allowed.includes(status)) where.status = status;
      const createdAt: any = {};
      if (from) { const d = new Date(from); if (!isNaN(d.getTime())) createdAt.gte = d; }
      if (to) { const d = new Date(to); if (!isNaN(d.getTime())) { d.setUTCHours(23, 59, 59, 999); createdAt.lte = d; } }
      if (createdAt.gte || createdAt.lte) where.createdAt = createdAt;

      const [total, orders] = await Promise.all([
        prisma.paymentOrder.count({ where }),
        prisma.paymentOrder.findMany({
          where,
          skip: (page - 1) * pageSize,
          take: pageSize,
          orderBy: { createdAt: 'desc' },
          include: { user: { select: { displayName: true } } },
        }),
      ]);

      res.json({
        total,
        page,
        pageSize,
        items: orders.map((o: any) => ({
          id: o.id,
          vnpTxnRef: o.vnpTxnRef,
          user: o.user?.displayName ?? '—',
          productCode: o.productCode,
          amountVnd: o.amountVnd,
          status: o.status,
          bankCode: o.bankCode,
          payDate: o.payDate,
          paidAt: o.paidAt,
          createdAt: o.createdAt,
        })),
      });
    } catch (error) {
      next(error);
    }
  });
```

- [ ] **Step 5.3: Add the `GET /admin/api/billing/summary` handler** (place it right after the `/admin/api/payments` handler):

```ts
  // ---- billing summary (read-only KPIs + package breakdown) ----
  app.get('/admin/api/billing/summary', async (req: any, res: any, next: any) => {
    try {
      requireAdmin(req);
      const range = (['today', '7d', '30d', 'quarter'].includes(String(req.query.range))
        ? String(req.query.range)
        : '30d') as RangeKey;
      const now = new Date();
      const { curStart, prevStart, prevEnd, end } = windowFor(range, now);

      const [
        revenueCurAgg, revenuePrevAgg, paidCount, refundedCount,
        dauFocus, dauEvents, totalUsers, premiumSubs, paidSubOrders,
      ] = await Promise.all([
        prisma.paymentOrder.aggregate({ _sum: { amountVnd: true }, where: { status: 'paid', paidAt: { gte: curStart, lte: end } } }),
        prisma.paymentOrder.aggregate({ _sum: { amountVnd: true }, where: { status: 'paid', paidAt: { gte: prevStart, lt: prevEnd } } }),
        prisma.paymentOrder.count({ where: { status: 'paid', paidAt: { gte: curStart, lte: end } } }),
        prisma.paymentOrder.count({ where: { status: 'refunded', updatedAt: { gte: curStart, lte: end } } }),
        prisma.focusSession.findMany({ where: { startedAt: { gte: curStart, lte: end } }, select: { userId: true } }),
        prisma.activityEvent.findMany({ where: { createdAt: { gte: curStart, lte: end } }, select: { userId: true } }),
        prisma.user.count(),
        prisma.subscription.findMany({ where: { plan: { not: 'free' }, status: 'active' }, select: { userId: true } }),
        prisma.paymentOrder.findMany({ where: { status: 'paid', productType: 'subscription' }, orderBy: { paidAt: 'desc' }, select: { userId: true, productCode: true, paidAt: true } }),
      ]);

      const revenue = revenueCurAgg._sum.amountVnd ?? 0;
      const revenuePrev = revenuePrevAgg._sum.amountVnd ?? 0;
      const activeUsers = new Set<string>([...dauFocus.map((r: any) => r.userId), ...dauEvents.map((r: any) => r.userId)]).size;
      const premiumIds = new Set<string>(premiumSubs.map((s: any) => s.userId));
      const { monthly, yearly } = bucketLatestPaidByUser(paidSubOrders as any, premiumIds);
      const freeCount = Math.max(0, totalUsers - premiumIds.size);

      res.json({
        range,
        kpis: {
          revenue: { value: revenue, deltaPct: deltaPct(revenue, revenuePrev) },
          mrr: { value: computeMrr(monthly, yearly) },
          arpu: { value: arpu(revenue, activeUsers) },
          refundRate: { value: refundRate(refundedCount, paidCount) },
        },
        packages: [
          { code: 'free', label: 'Free', priceVnd: 0, subscribers: freeCount },
          { code: 'zen_pro_monthly', label: 'Zen Pro · Monthly', priceVnd: 29000, subscribers: monthly },
          { code: 'zen_pro_yearly', label: 'Zen Pro · Yearly', priceVnd: 279000, subscribers: yearly },
        ],
      });
    } catch (error) {
      next(error);
    }
  });
```

> `refundedCount` filters on `updatedAt` (no `refundedAt` column exists); fine as a proxy since refunds aren't implemented yet (will be 0).

- [ ] **Step 5.4: Restart + smoke test.** `docker compose restart backend` (wait for "listening on port 3000"). Then:
```bash
TOKEN=$(curl -s -X POST localhost:3000/admin/api/auth/login -H "Content-Type: application/json" -d '{"email":"admin@zenzoo.app","password":"zenzoo-admin"}' | node -e "let s='';process.stdin.on('data',d=>s+=d);process.stdin.on('end',()=>console.log(JSON.parse(s).token))")
curl -s "localhost:3000/admin/api/billing/summary?range=quarter" -H "Authorization: Bearer $TOKEN"
curl -s "localhost:3000/admin/api/payments?page=1&pageSize=3&status=paid" -H "Authorization: Bearer $TOKEN"
```
Expected: summary has `kpis.revenue/mrr/arpu/refundRate` + 3 `packages` (Free/Monthly/Yearly with counts); payments returns `{total,page,pageSize,items}` filtered to paid. Also run `docker compose exec -T backend npx tsc --noEmit` → 0 errors in admin.routes.ts/billing.metrics.ts.

- [ ] **Step 5.5: Commit.**

```bash
git add backend/src/routes/admin.routes.ts
git commit -m "feat(backend): billing summary endpoint + paginated/date-filtered payments"
```

---

### Task 6: Frontend Billing — types, api, KpiCard, nav/route, BillingPage (+ test)

**Files:**
- Modify: `admin-web/src/lib/types.ts`, `admin-web/src/lib/api.ts`, `admin-web/src/ds/KpiCard.tsx`, `admin-web/src/shell/nav.ts`, `admin-web/src/App.tsx`
- Create: `admin-web/src/pages/BillingPage.tsx`, `admin-web/src/pages/BillingPage.test.tsx`

**Interfaces:**
- Consumes: `api.billing.summary(range)`, `api.payments(params)`, `Card/SegmentedControl/StatusBadge/Tag/Button/Icon/icons`, `KpiCard` (with `hideSpark`), `ErrorState`, `Skeleton`, `formatVndShort/formatInt/formatDate/formatDateTimeUtc`, `toCsv/downloadCsv`, `friendlyError`.

- [ ] **Step 6.1: Add types** to the END of `admin-web/src/lib/types.ts`:

```ts
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
```

- [ ] **Step 6.2: Extend `admin-web/src/lib/api.ts`.** Add `BillingSummary, PaymentsResponse, PaymentsQuery` to the type import; add a `buildPaymentsQuery` helper and `billing` + updated `payments` to the `api` object:

```ts
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
```
In the `export const api = { … }` object, **replace** the existing `payments`/remove old `users`-style payments if present and add:
```ts
  payments: (params: PaymentsQuery = {}) => request<PaymentsResponse>(`/payments${buildPaymentsQuery(params)}`),
  billing: { summary: (range: RangeKey) => request<BillingSummary>(`/billing/summary?range=${range}`) },
```
(Keep `login`, `me`, `overview`, `health`, `users` as-is. `payments` did not exist on `api` before — this adds it.)

- [ ] **Step 6.3: Add `hideSpark` to `admin-web/src/ds/KpiCard.tsx`.** Add `hideSpark?: boolean` to `KpiCardProps`, destructure it, and wrap the trailing `<Sparkline .../>` so it only renders when not hidden:
```tsx
      {!hideSpark && <Sparkline data={kpi.spark} color={color} />}
```
(The rest of KpiCard is unchanged; `kpi.spark` may be `[]`.)

- [ ] **Step 6.4: Enable the billing nav item + route.**
  - In `admin-web/src/shell/nav.ts`: change the moderation-group `billing` entry from `wip('billing', 'Thanh toán & Gói')` to `{ screen: 'billing', label: 'Thanh toán & Gói', to: '/billing', enabled: true }`. Add to `ROUTE_META`: `'/billing': { crumb: 'Dòng tiền', title: 'Thanh toán & Gói' }`, and in `metaFor` add `if (pathname.startsWith('/billing')) return ROUTE_META['/billing'];` before the default return.
  - In `admin-web/src/App.tsx`: add `import { BillingPage } from './pages/BillingPage';` and a route `<Route path="/billing" element={<BillingPage />} />` inside the protected `AppShell` block.

- [ ] **Step 6.5: Write the failing test** `admin-web/src/pages/BillingPage.test.tsx`:

```tsx
import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { BillingPage } from './BillingPage';
import type { BillingSummary, PaymentsResponse } from '../lib/types';

const summary: BillingSummary = {
  range: '30d',
  kpis: { revenue: { value: 1247000, deltaPct: 9.4 }, mrr: { value: 233250 }, arpu: { value: 2500 }, refundRate: { value: 0 } },
  packages: [
    { code: 'free', label: 'Free', priceVnd: 0, subscribers: 6508 },
    { code: 'zen_pro_monthly', label: 'Zen Pro · Monthly', priceVnd: 29000, subscribers: 4 },
    { code: 'zen_pro_yearly', label: 'Zen Pro · Yearly', priceVnd: 279000, subscribers: 2 },
  ],
};
const payments: PaymentsResponse = {
  total: 1, page: 1, pageSize: 25,
  items: [{ id: 'p1', vnpTxnRef: 'VNP123', user: 'Lê Quốc Bảo', productCode: 'zen_pro_yearly', amountVnd: 279000, status: 'paid', bankCode: 'NCB', payDate: null, paidAt: '2026-06-13T09:14:00.000Z', createdAt: '2026-06-13T09:14:00.000Z' }],
};

const { summaryMock, paymentsMock } = vi.hoisted(() => ({ summaryMock: vi.fn(), paymentsMock: vi.fn() }));
vi.mock('../lib/api', () => ({ api: { billing: { summary: (...a: unknown[]) => summaryMock(...a) }, payments: (...a: unknown[]) => paymentsMock(...a) } }));

function renderPage() { return render(<MemoryRouter><BillingPage /></MemoryRouter>); }

describe('BillingPage', () => {
  beforeEach(() => { summaryMock.mockReset().mockResolvedValue(summary); paymentsMock.mockReset().mockResolvedValue(payments); });

  it('renders KPIs, a transaction row, and package cards', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Doanh thu')).toBeInTheDocument());
    expect(screen.getByText('MRR')).toBeInTheDocument();
    expect(screen.getByText('ARPU')).toBeInTheDocument();
    expect(screen.getByText('Tỉ lệ hoàn tiền')).toBeInTheDocument();
    await waitFor(() => expect(screen.getByText('VNP123')).toBeInTheDocument());
    expect(screen.getByText('Lê Quốc Bảo')).toBeInTheDocument();
    expect(screen.getByText('Thành công')).toBeInTheDocument();
    expect(screen.getByText('Zen Pro · Monthly')).toBeInTheDocument();
  });

  it('passes the status filter to the payments API', async () => {
    renderPage();
    await waitFor(() => expect(paymentsMock).toHaveBeenCalled());
    fireEvent.click(screen.getByRole('button', { name: 'Thành công' }));
    await waitFor(() => {
      const last = paymentsMock.mock.calls.at(-1)![0] as { status?: string };
      expect(last.status).toBe('paid');
    });
  });
});
```

- [ ] **Step 6.6: Run; verify fail.** `cd admin-web && npm test`. Expected: FAIL (no `./BillingPage`).

- [ ] **Step 6.7: Implement `admin-web/src/pages/BillingPage.tsx`:**

```tsx
import { useEffect, useMemo, useState } from 'react';
import { Card, Button, SegmentedControl, StatusBadge, Tag, Icon, icons } from '../ds';
import type { DesignStatus } from '../ds';
import { KpiCard } from '../components/KpiCard';
import { ErrorState } from '../components/ErrorState';
import { Skeleton } from '../components/LoadingSkeleton';
import { api } from '../lib/api';
import { friendlyError } from '../lib/friendlyError';
import { formatVndShort, formatInt, formatDate } from '../lib/format';
import { toCsv, downloadCsv } from '../lib/csv';
import type { BillingSummary, PaymentsResponse, PaymentRow, PaymentStatus, RangeKey } from '../lib/types';

const RANGE_OPTS: { value: RangeKey; label: string }[] = [
  { value: 'today', label: 'Hôm nay' }, { value: '7d', label: '7 ngày' },
  { value: '30d', label: '30 ngày' }, { value: 'quarter', label: 'Quý' },
];

type StatusFilter = 'all' | 'paid' | 'pending' | 'failed' | 'refunded';
const STATUS_FILTERS: { key: StatusFilter; label: string }[] = [
  { key: 'all', label: 'Tất cả' }, { key: 'paid', label: 'Thành công' }, { key: 'pending', label: 'Chờ IPN' },
  { key: 'failed', label: 'Thất bại' }, { key: 'refunded', label: 'Hoàn tiền' },
];

const STATUS_BADGE: Record<PaymentStatus, { status: DesignStatus; label: string }> = {
  paid: { status: 'approved', label: 'Thành công' },
  pending: { status: 'pending', label: 'Chờ IPN' },
  failed: { status: 'rejected', label: 'Thất bại' },
  review: { status: 'review', label: 'Cần đối soát' },
  refunded: { status: 'suspended', label: 'Đã hoàn tiền' },
};
function planLabel(code: string): string {
  if (code === 'zen_pro_monthly') return 'Monthly';
  if (code === 'zen_pro_yearly') return 'Yearly';
  return code;
}
const dec1 = (n: number) => new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 1 }).format(n);

const TH: React.CSSProperties = { textAlign: 'left', font: 'var(--fw-semibold) 11px/1 var(--font-sans)', letterSpacing: '.06em', textTransform: 'uppercase', color: 'var(--text-muted)', padding: '11px 16px', background: 'var(--slate-50)', borderBottom: '1px solid var(--border-default)', whiteSpace: 'nowrap' };
const TD: React.CSSProperties = { padding: 'var(--row-py, 13px) 16px', borderBottom: '1px solid var(--border-subtle)' };

export function BillingPage() {
  const [range, setRange] = useState<RangeKey>('30d');
  const [summary, setSummary] = useState<BillingSummary | null>(null);
  const [sumErr, setSumErr] = useState<string | null>(null);

  const [filter, setFilter] = useState<StatusFilter>('all');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [page, setPage] = useState(1);
  const pageSize = 25;
  const [tx, setTx] = useState<PaymentsResponse | null>(null);
  const [txErr, setTxErr] = useState<string | null>(null);
  const [txLoading, setTxLoading] = useState(true);

  useEffect(() => {
    setSumErr(null);
    api.billing.summary(range).then(setSummary).catch((e) => setSumErr(friendlyError(e)));
  }, [range]);

  function loadTx() {
    setTxLoading(true);
    setTxErr(null);
    api.payments({ status: filter === 'all' ? undefined : filter, from: from || undefined, to: to || undefined, page, pageSize })
      .then(setTx).catch((e) => setTxErr(friendlyError(e))).finally(() => setTxLoading(false));
  }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { loadTx(); }, [filter, from, to, page]);

  const totalPages = tx ? Math.max(1, Math.ceil(tx.total / tx.pageSize)) : 1;
  const pages = useMemo(() => pageList(page, totalPages), [page, totalPages]);

  function exportCsv() {
    const items = tx?.items ?? [];
    const csv = toCsv(
      ['Mã giao dịch', 'Người dùng', 'Gói', 'Số tiền (đ)', 'Trạng thái', 'Ngày tạo'],
      items,
      (o) => [o.vnpTxnRef, o.user, planLabel(o.productCode), o.amountVnd, STATUS_BADGE[o.status]?.label ?? o.status, formatDate(o.createdAt)],
    );
    downloadCsv('zenzoo-transactions.csv', csv);
  }

  const k = summary?.kpis;
  return (
    <section style={{ padding: '24px 32px 90px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, marginBottom: 20, flexWrap: 'wrap' }}>
        <SegmentedControl variant="lite" value={range} options={RANGE_OPTS} onChange={setRange} />
        <Button variant="secondary" onClick={exportCsv}><Icon size={16}>{icons.download}</Icon>Xuất CSV</Button>
      </div>

      {sumErr ? (
        <ErrorState message={sumErr} onRetry={() => api.billing.summary(range).then(setSummary).catch((e) => setSumErr(friendlyError(e)))} />
      ) : (
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,minmax(0,1fr))', gap: 14, marginBottom: 22 }}>
          {!k ? Array.from({ length: 4 }).map((_, i) => (
            <div key={i} style={{ minHeight: 120, padding: 16, background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-lg)' }}><Skeleton height={12} width="55%" /><div style={{ height: 12 }} /><Skeleton height={26} width="45%" /></div>
          )) : (
            <>
              <KpiCard label="Doanh thu" valueText={formatVndShort(k.revenue.value)} kpi={{ value: k.revenue.value, deltaPct: k.revenue.deltaPct ?? null, spark: [] }} color="var(--blue-500)" hideSpark />
              <KpiCard label="MRR" valueText={formatVndShort(k.mrr.value)} kpi={{ value: k.mrr.value, deltaPct: null, spark: [] }} color="var(--teal-500)" hideSpark note="doanh thu định kỳ/tháng" />
              <KpiCard label="ARPU" valueText={formatVndShort(k.arpu.value)} kpi={{ value: k.arpu.value, deltaPct: null, spark: [] }} color="var(--blue-500)" hideSpark note="trên mỗi người hoạt động" />
              <KpiCard label="Tỉ lệ hoàn tiền" valueText={`${dec1(k.refundRate.value)}%`} kpi={{ value: k.refundRate.value, deltaPct: null, spark: [] }} color="var(--green-500)" hideSpark note="trong ngưỡng an toàn" />
            </>
          )}
        </div>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0,2fr) minmax(0,1fr)', gap: 20, alignItems: 'start' }}>
        {/* transactions */}
        <Card title="Giao dịch gần đây" subtitle="Cổng VNPay · mới nhất trước" padding="none">
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '12px 16px', borderBottom: '1px solid var(--border-subtle)', flexWrap: 'wrap' }}>
            <div className="zz-seg zz-seg--lite">
              {STATUS_FILTERS.map((f) => (
                <button key={f.key} type="button" className={`zz-seg__opt${filter === f.key ? ' zz-seg__opt--on' : ''}`} onClick={() => { setPage(1); setFilter(f.key); }}>{f.label}</button>
              ))}
            </div>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6, marginLeft: 'auto' }}>
              <input type="date" value={from} onChange={(e) => { setPage(1); setFrom(e.target.value); }} aria-label="Từ ngày" style={dateInput} />
              <span style={{ color: 'var(--text-faint)' }}>–</span>
              <input type="date" value={to} onChange={(e) => { setPage(1); setTo(e.target.value); }} aria-label="Đến ngày" style={dateInput} />
            </span>
          </div>
          {txErr ? (
            <div style={{ padding: 16 }}><ErrorState message={txErr} onRetry={loadTx} /></div>
          ) : (
            <>
              <div style={{ overflowX: 'auto' }}>
                <table style={{ width: '100%', borderCollapse: 'collapse', font: 'var(--fw-regular) 13px/1.4 var(--font-sans)' }}>
                  <thead>
                    <tr>
                      <th style={TH}>Mã giao dịch</th><th style={TH}>Người dùng</th><th style={TH}>Gói</th>
                      <th style={{ ...TH, textAlign: 'right' }}>Số tiền</th><th style={TH}>Trạng thái</th>
                    </tr>
                  </thead>
                  <tbody>
                    {txLoading && !tx && Array.from({ length: 6 }).map((_, i) => (<tr key={`s${i}`}><td style={TD} colSpan={5}><Skeleton height={24} /></td></tr>))}
                    {tx?.items.map((o: PaymentRow) => {
                      const b = STATUS_BADGE[o.status] ?? { status: 'draft' as DesignStatus, label: o.status };
                      return (
                        <tr key={o.id}>
                          <td style={{ ...TD, fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--text-body)' }}>{o.vnpTxnRef}</td>
                          <td style={{ ...TD, color: 'var(--text-strong)' }}>{o.user}</td>
                          <td style={TD}>{o.productCode === 'zen_pro_yearly' ? <Tag tone="accent">Yearly</Tag> : o.productCode === 'zen_pro_monthly' ? <Tag tone="neutral">Monthly</Tag> : <Tag tone="outline">{o.productCode}</Tag>}</td>
                          <td style={{ ...TD, textAlign: 'right', fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-strong)' }}>{formatInt(o.amountVnd)}đ</td>
                          <td style={TD}><StatusBadge status={b.status}>{b.label}</StatusBadge></td>
                        </tr>
                      );
                    })}
                    {tx && tx.items.length === 0 && (<tr><td style={{ ...TD, textAlign: 'center', color: 'var(--text-muted)' }} colSpan={5}>Không có giao dịch khớp bộ lọc.</td></tr>)}
                  </tbody>
                </table>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, padding: '13px 16px', borderTop: '1px solid var(--border-subtle)', background: 'var(--slate-25)', flexWrap: 'wrap' }}>
                <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-muted)' }}><b style={{ color: 'var(--text-body)', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{tx ? formatInt(tx.total) : '—'}</b> giao dịch</span>
                <div style={{ display: 'flex', alignItems: 'center', gap: 4, font: 'var(--fw-medium) 12px/1 var(--font-mono)' }}>
                  {pages.map((p, i) => p === '…' ? (<span key={`e${i}`} style={{ color: 'var(--text-faint)', padding: '0 4px' }}>…</span>) : (
                    <button key={p} type="button" onClick={() => setPage(p as number)} style={{ minWidth: 28, height: 28, padding: '0 8px', borderRadius: 7, border: 'none', cursor: 'pointer', fontFamily: 'var(--font-mono)', fontSize: 12, background: p === page ? 'var(--brand)' : 'transparent', color: p === page ? '#fff' : 'var(--text-body)' }}>{p}</button>
                  ))}
                </div>
              </div>
            </>
          )}
        </Card>

        {/* package cards */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
          {(summary?.packages ?? []).map((p) => (
            <div key={p.code} style={{ background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-lg)', boxShadow: 'var(--shadow-sm)', padding: '14px 16px', borderLeft: p.code === 'free' ? '1px solid var(--border-subtle)' : '3px solid var(--accent)' }}>
              <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', gap: 8 }}>
                <span style={{ font: 'var(--fw-semibold) 14px/1.2 var(--font-sans)', color: 'var(--text-strong)' }}>{p.label}</span>
                <span style={{ font: 'var(--fw-semibold) 13px/1 var(--font-mono)', color: 'var(--text-body)' }}>{p.priceVnd === 0 ? '0đ' : `${formatInt(p.priceVnd)}đ`}</span>
              </div>
              <div style={{ font: 'var(--fw-regular) 12px/1.4 var(--font-sans)', color: 'var(--text-muted)', marginTop: 6 }}><b style={{ color: 'var(--text-strong)', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{formatInt(p.subscribers)}</b> người dùng</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

const dateInput: React.CSSProperties = { height: 32, padding: '0 8px', border: '1px solid var(--border-default)', borderRadius: 'var(--radius-md)', font: 'var(--fw-regular) 12px/1 var(--font-mono)', color: 'var(--text-body)', background: 'var(--surface-card)' };

function pageList(current: number, total: number): (number | '…')[] {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
  const wanted = [1, total, current, current - 1, current + 1].filter((n) => n >= 1 && n <= total);
  const sorted = Array.from(new Set(wanted)).sort((a, b) => a - b);
  const out: (number | '…')[] = [];
  let prev = 0;
  for (const n of sorted) { if (prev && n - prev > 1) out.push('…'); out.push(n); prev = n; }
  return out;
}
```

- [ ] **Step 6.8: Run; verify pass.** `cd admin-web && npm test` (BillingPage + all suites) and `npm run typecheck` (exit 0).

- [ ] **Step 6.9: Commit.**

```bash
git add admin-web/src/lib/types.ts admin-web/src/lib/api.ts admin-web/src/ds/KpiCard.tsx admin-web/src/shell/nav.ts admin-web/src/App.tsx admin-web/src/pages/BillingPage.tsx admin-web/src/pages/BillingPage.test.tsx
git commit -m "feat(admin-web): Billing page (KPIs, transactions, packages, filters, CSV)"
```

---

### Task 7: Build, integrate & E2E verify

- [ ] **Step 7.1: Full frontend gates.** `cd admin-web && npm run typecheck` (exit 0), `npm test` (ALL suites pass), `npm run build` (succeeds → `backend/admin-web/dist`).
- [ ] **Step 7.2: Backend gate.** `docker compose exec -T backend npm test` (admin.metrics + billing.metrics pass). The container already serves the fresh `dist` (static).
- [ ] **Step 7.3: E2E browser verification** (backend already running on :3000). Use Playwright MCP:
  1. Open `http://localhost:3000/console` → new **login design** renders (brand, card, show/hide eye, Ghi nhớ thiết bị, Quên mật khẩu + Google Workspace, footer). Wrong password → "Sai email hoặc mật khẩu quản trị". Toggle the eye. Log in with `admin@zenzoo.app` / `zenzoo-admin`.
  2. Click sidebar **"Thanh toán & Gói"** → `/console/billing`: 4 KPIs (Doanh thu/MRR/ARPU/Tỉ lệ hoàn tiền) from API; switch range; transaction table with status filter (click "Thành công") + date filter + pagination; 3 package cards with counts; Xuất CSV downloads.
  3. Click the **topbar avatar → "Đăng xuất"** → returns to `/console/login` (token cleared).
  4. Check console: no app errors (favicon 404 ok).
- [ ] **Step 7.4: Final commit.**
```bash
git add -A admin-web backend/src
git commit -m "chore(admin): phase-2 (login redesign + logout + billing) verified"
```

---

## Self-Review (plan author)

**Spec coverage:** Login redesign → Tasks 1–2 (auth remember + LoginPage incl. show/hide, remember, placeholders); Logout → Task 3 (UserMenu + Topbar); Billing backend (summary + paginated payments) → Tasks 4–5; Billing FE (KPIs/table/filters/CSV/packages + range) → Task 6; build/E2E → Task 7. All §1.5/§2/§3/§4 spec sections map to tasks.

**Type consistency:** `setToken(token, remember)` defined in Task 1, used in Task 2. `BillingSummary`/`BillingKpi`/`PaymentRow`/`PaymentsResponse`/`PaymentsQuery` defined in Task 6.1, consumed by api.ts (6.2) + BillingPage (6.7) + matched by backend response in Task 5. `bucketLatestPaidByUser`/`computeMrr`/`refundRate`/`arpu` defined in Task 4, used in Task 5. `STATUS_BADGE` uses `DesignStatus` from `ds` (exported in Phase 1). `KpiCard` `hideSpark` added in 6.3, used in 6.7. `api.payments` newly added (was not on `api` before).

**Known/accepted:** `refundRate`=0 with current data (no refunds); MRR/packages = current snapshot (range-independent), revenue/ARPU/refundRate range-scoped; premium users with no paid order aren't in Monthly/Yearly cards; Quên-mật-khẩu/Google are non-functional placeholders; billing default range `30d`.

