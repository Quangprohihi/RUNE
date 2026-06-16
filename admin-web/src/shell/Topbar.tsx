import { useLocation } from 'react-router-dom';
import { Icon, icons, IconButton, Input } from '../ds';
import { metaFor } from './nav';
import { getAdmin, initialsFromAdmin } from './topbarUtil';

export function Topbar() {
  const { pathname } = useLocation();
  const meta = metaFor(pathname);
  const admin = getAdmin();
  return (
    <header style={{
      position: 'sticky', top: 46, zIndex: 120, background: 'color-mix(in srgb, var(--slate-0) 88%, transparent)',
      backdropFilter: 'blur(10px)', borderBottom: '1px solid var(--border-subtle)', padding: '13px 32px',
      display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 24,
    }}>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ font: 'var(--fw-semibold) 11px/1 var(--font-sans)', letterSpacing: '.13em', textTransform: 'uppercase', color: 'var(--text-faint)' }}>{meta.crumb}</div>
        <h1 style={{ font: 'var(--fw-bold) 24px/1.1 var(--font-sans)', letterSpacing: '-.02em', color: 'var(--text-strong)', margin: '6px 0 0' }}>{meta.title}</h1>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, flex: 'none' }}>
        <div style={{ width: 280 }}>
          <Input placeholder="Tìm nhanh người dùng, giao dịch…" prefix={<Icon size={16}>{icons.search}</Icon>} />
        </div>
        <IconButton label="Thông báo"><Icon>{icons.bell}</Icon></IconButton>
        <IconButton label="Cài đặt"><Icon>{icons.gear}</Icon></IconButton>
        <div style={{ width: 1, height: 30, background: 'var(--border-subtle)' }} />
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 10 }}>
          <span style={{ width: 36, height: 36, flex: 'none', borderRadius: '50%', display: 'inline-flex', alignItems: 'center', justifyContent: 'center', font: 'var(--fw-semibold) 13px/1 var(--font-sans)', background: 'var(--blue-100)', color: 'var(--blue-700)', border: '1px solid color-mix(in srgb, var(--blue-700) 14%, transparent)' }}>{initialsFromAdmin(admin?.name)}</span>
          <span style={{ display: 'flex', flexDirection: 'column', gap: 1, minWidth: 0 }}>
            <span style={{ font: 'var(--fw-semibold) 13px/1.3 var(--font-sans)', color: 'var(--text-strong)' }}>{admin?.name ?? 'Quản trị viên'}</span>
            <span style={{ font: 'var(--fw-regular) 12px/1.3 var(--font-sans)', color: 'var(--text-muted)' }}>{admin?.role ?? '—'}</span>
          </span>
        </span>
      </div>
    </header>
  );
}
