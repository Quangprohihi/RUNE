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
