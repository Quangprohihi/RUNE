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
