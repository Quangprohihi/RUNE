import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button, Input } from '../ds';
import { api } from '../lib/api';
import { setToken, setAdmin } from '../lib/auth';
import { friendlyError } from '../lib/friendlyError';

export function LoginPage() {
  const nav = useNavigate();
  const [email, setEmail] = useState('admin@zenzoo.app');
  const [password, setPassword] = useState('');
  const [err, setErr] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setErr(null);
    setBusy(true);
    try {
      const res = await api.login(email.trim(), password);
      setToken(res.token);
      setAdmin(res.admin);
      nav('/', { replace: true });
    } catch (ex) {
      setErr(friendlyError(ex));
    } finally {
      setBusy(false);
    }
  }

  return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--surface-page)' }}>
      <form onSubmit={submit} style={{ width: 360, background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-xl)', boxShadow: 'var(--shadow-lg)', padding: 28 }}>
        <div style={{ font: 'var(--fw-extra) 22px/1 var(--font-sans)', marginBottom: 4 }}>
          <span style={{ color: '#3FB2A6' }}>Zen</span><span style={{ color: '#1E6CA1' }}>Zoo</span>
          <span style={{ font: 'var(--fw-semibold) 10px/1 var(--font-sans)', letterSpacing: '.2em', textTransform: 'uppercase', color: 'var(--text-faint)', marginLeft: 8 }}>Admin Console</span>
        </div>
        <p style={{ font: 'var(--fw-regular) 13px/1.5 var(--font-sans)', color: 'var(--text-muted)', margin: '0 0 18px' }}>Đăng nhập để vào bảng điều khiển.</p>
        <label style={{ display: 'block', font: 'var(--fw-medium) 12px/1 var(--font-sans)', color: 'var(--text-body)', marginBottom: 6 }}>Email</label>
        <div style={{ marginBottom: 14 }}><Input value={email} onChange={(e) => setEmail(e.target.value)} placeholder="admin@zenzoo.app" autoFocus /></div>
        <label style={{ display: 'block', font: 'var(--fw-medium) 12px/1 var(--font-sans)', color: 'var(--text-body)', marginBottom: 6 }}>Mật khẩu</label>
        <div style={{ marginBottom: 18 }}><Input type="password" value={password} onChange={(e) => setPassword(e.target.value)} placeholder="••••••••" /></div>
        {err && <div role="alert" style={{ font: 'var(--fw-medium) 12px/1.4 var(--font-sans)', color: 'var(--danger-fg)', background: 'var(--danger-bg)', border: '1px solid var(--status-rejected-border)', borderRadius: 'var(--radius-md)', padding: '8px 10px', marginBottom: 14 }}>{err}</div>}
        <Button type="submit" disabled={busy} style={{ width: '100%', justifyContent: 'center' }}>{busy ? 'Đang đăng nhập…' : 'Đăng nhập'}</Button>
      </form>
    </div>
  );
}
