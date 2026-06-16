import { Link, useLocation } from 'react-router-dom';
import { NAV_GROUPS } from './nav';
import type { NavBadge, NavItem } from './nav';
import { Icon, navIcons } from '../ds';

function Badge({ badge }: { badge: NavBadge }) {
  if (badge.tone === 'teal-outline') {
    return <span style={{ marginLeft: 'auto', font: 'var(--fw-semibold) 9px/1 var(--font-sans)', letterSpacing: '.04em', textTransform: 'uppercase', padding: '2px 6px', borderRadius: 999, color: 'var(--teal-500)', border: '1px solid var(--teal-500)' }}>{badge.text}</span>;
  }
  const bg = badge.tone === 'amber' ? 'var(--amber-500)' : 'var(--rail-hover, rgba(255,255,255,.08))';
  const fg = badge.tone === 'amber' ? '#fff' : 'var(--rail-muted, #6C7B93)';
  return <span style={{ marginLeft: 'auto', font: 'var(--fw-semibold) 10px/1 var(--font-mono)', padding: '2px 7px', borderRadius: 999, background: bg, color: fg }}>{badge.text}</span>;
}

function NavRow({ item, active }: { item: NavItem; active: boolean }) {
  const base = {
    display: 'flex', alignItems: 'center', gap: 11, padding: '8px 11px', borderRadius: 7,
    color: 'var(--rail-fg)', font: 'var(--fw-medium) 13.5px/1 var(--font-sans)',
    position: 'relative' as const, cursor: 'pointer', whiteSpace: 'nowrap' as const,
    ...(active ? { background: 'var(--rail-active-bg)', color: 'var(--rail-active-fg)', fontWeight: 600, boxShadow: 'inset 2px 0 0 0 var(--rail-active-bar)' } : {}),
  };
  const inner = (
    <>
      <span style={{ display: 'inline-flex', flex: 'none' }}><Icon>{navIcons[item.screen] ?? navIcons.overview}</Icon></span>
      <span>{item.label}</span>
      {item.badge && <Badge badge={item.badge} />}
    </>
  );
  return <Link className="zz-nav" to={item.to} style={base}>{inner}</Link>;
}

export function Sidebar() {
  const { pathname } = useLocation();
  const isActive = (to: string) => (to === '/' ? pathname === '/' : pathname.startsWith(to));
  return (
    <aside className="zz-rail" style={{
      gridColumn: 1, background: 'var(--rail-bg, var(--slate-900))', borderRight: '1px solid var(--rail-edge, var(--slate-900))',
      position: 'sticky', top: 46, alignSelf: 'start', height: 'calc(100vh - 46px)', overflowY: 'auto', display: 'flex', flexDirection: 'column',
    }}>
      <div style={{ padding: '18px 16px 14px', borderBottom: '1px solid var(--rail-border, rgba(255,255,255,.08))' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 11, padding: '10px 13px', borderRadius: 11, background: 'var(--rail-plate-bg, rgba(255,255,255,.04))', border: '1px solid var(--rail-plate-border, rgba(255,255,255,.10))' }}>
          <img src={`${import.meta.env.BASE_URL}zenzoo-mark.png`} alt="ZenZoo" style={{ width: 34, height: 34, objectFit: 'contain', flex: 'none' }} />
          <div style={{ display: 'flex', flexDirection: 'column', gap: 3, lineHeight: 1 }}>
            <span style={{ font: 'var(--fw-extra) 19px/1 var(--font-sans)', letterSpacing: '-.01em' }}><span style={{ color: '#3FB2A6' }}>Zen</span><span style={{ color: '#1E6CA1' }}>Zoo</span></span>
            <span style={{ font: 'var(--fw-semibold) 9px/1 var(--font-sans)', letterSpacing: '.2em', textTransform: 'uppercase', color: 'var(--rail-group, #6C7B93)' }}>Admin Console</span>
          </div>
        </div>
      </div>
      <nav style={{ padding: '12px 10px 24px', flex: 1, display: 'flex', flexDirection: 'column', gap: 2 }}>
        {NAV_GROUPS.map((g) => (
          <div key={g.title}>
            <div style={{ font: 'var(--fw-semibold) 10px/1 var(--font-sans)', letterSpacing: '.13em', textTransform: 'uppercase', color: 'var(--rail-group, #6C7B93)', padding: '14px 12px 6px' }}>{g.title}</div>
            {g.items.map((it) => <NavRow key={it.screen} item={it} active={isActive(it.to)} />)}
          </div>
        ))}
      </nav>
      <div style={{ padding: '13px 18px', borderTop: '1px solid var(--rail-border, rgba(255,255,255,.08))', font: 'var(--fw-regular) 11px/1.4 var(--font-sans)', color: 'var(--rail-foot, #6C7B93)' }}>
        Phiên bản 2.4.0 · môi trường <span style={{ fontFamily: 'var(--font-mono)' }}>production</span>
      </div>
    </aside>
  );
}
