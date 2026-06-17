import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, Button, Input, Tag, Avatar, IconButton, StatusBadge, statusFromUserStatus, Icon, icons } from '../ds';
import { ErrorState } from '../components/ErrorState';
import { Skeleton } from '../components/LoadingSkeleton';
import { api } from '../lib/api';
import { friendlyError } from '../lib/friendlyError';
import { formatInt, formatDate, formatDateTimeUtc } from '../lib/format';
import { toCsv, downloadCsv } from '../lib/csv';
import type { UsersResponse, UserRow, UsersQuery } from '../lib/types';

type FilterKey = 'all' | 'active' | 'pro' | 'lock' | 'review';
const FILTERS: { key: FilterKey; label: string }[] = [
  { key: 'all', label: 'Tất cả' }, { key: 'active', label: 'Active' },
  { key: 'pro', label: 'Zen Pro' }, { key: 'lock', label: 'Tạm khóa' }, { key: 'review', label: 'Đang xem xét' },
];
function filterToQuery(f: FilterKey): Partial<UsersQuery> {
  switch (f) {
    case 'active': return { status: 'active' };
    case 'pro': return { plan: 'premium' };
    case 'lock': return { status: 'suspended' };
    case 'review': return { status: 'review' };
    default: return {};
  }
}

const TH: React.CSSProperties = { textAlign: 'left', font: 'var(--fw-semibold) 11px/1 var(--font-sans)', letterSpacing: '.06em', textTransform: 'uppercase', color: 'var(--text-muted)', padding: '11px 16px', background: 'var(--slate-50)', borderBottom: '1px solid var(--border-default)', whiteSpace: 'nowrap' };
const TD: React.CSSProperties = { padding: 'var(--row-py, 13px) 16px', borderBottom: '1px solid var(--border-subtle)' };
const MONO: React.CSSProperties = { ...TD, fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--text-body)', whiteSpace: 'nowrap' };

export function UsersPage() {
  const nav = useNavigate();
  const [q, setQ] = useState('');
  const [filter, setFilter] = useState<FilterKey>('all');
  const [page, setPage] = useState(1);
  const pageSize = 15;
  const [data, setData] = useState<UsersResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    setError(null);
    api.users({ q: q.trim() || undefined, page, pageSize, ...filterToQuery(filter) })
      .then(setData)
      .catch((e) => setError(friendlyError(e)))
      .finally(() => setLoading(false));
  }

  // debounce search; reload on filter/page change
  useEffect(() => {
    const t = setTimeout(load, 300);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, filter, page]);

  const totalPages = data ? Math.max(1, Math.ceil(data.total / data.pageSize)) : 1;
  const pages = useMemo(() => pageList(page, totalPages), [page, totalPages]);

  function exportCsv() {
    const items = data?.items ?? [];
    const csv = toCsv(
      ['Tên', 'Email', 'Provider', 'Gói', 'Ngày tạo', 'Đăng nhập cuối', 'Streak', 'Lv Kiki', 'Trạng thái'],
      items,
      (u) => [u.displayName, u.email, u.provider, u.plan, formatDate(u.createdAt), formatDateTimeUtc(u.lastLoginAt), u.streak, u.level, u.status],
    );
    downloadCsv('zenzoo-users.csv', csv);
  }

  return (
    <section style={{ padding: '24px 32px 90px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
        <div style={{ flex: 1, minWidth: 240, maxWidth: 400 }}>
          <Input value={q} onChange={(e) => { setPage(1); setQ(e.target.value); }} placeholder="Tìm theo tên, email hoặc userId…" prefix={<Icon size={16}>{icons.search}</Icon>} />
        </div>
        <Button variant="secondary"><Icon size={16}>{icons.filter}</Icon>Bộ lọc</Button>
        <Button variant="secondary" onClick={exportCsv}><Icon size={16}>{icons.download}</Icon>Xuất CSV</Button>
        <Button variant="primary" title="Sẽ bổ sung ở giai đoạn sau"><Icon size={16}>{icons.plus}</Icon>Mời / Tạo</Button>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, marginBottom: 14, flexWrap: 'wrap' }}>
        <div className="zz-seg zz-seg--lite">
          {FILTERS.map((f) => (
            <button key={f.key} type="button" className={`zz-seg__opt${filter === f.key ? ' zz-seg__opt--on' : ''}`} onClick={() => { setPage(1); setFilter(f.key); }}>{f.label}</button>
          ))}
        </div>
        <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-faint)' }}>
          <b style={{ color: 'var(--text-body)', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{data ? formatInt(data.total) : '—'}</b> người dùng
        </span>
      </div>

      {error ? (
        <ErrorState message={error} onRetry={load} />
      ) : (
        <Card padding="none">
          <div style={{ overflowX: 'auto' }}>
            <table style={{ width: '100%', borderCollapse: 'collapse', font: 'var(--fw-regular) 13px/1.4 var(--font-sans)' }}>
              <thead>
                <tr>
                  <th style={TH}>Người dùng</th><th style={TH}>Provider</th><th style={TH}>Gói</th>
                  <th style={TH}>Ngày tạo</th><th style={TH}>Đăng nhập cuối (UTC)</th>
                  <th style={{ ...TH, textAlign: 'right' }}>Streak</th><th style={{ ...TH, textAlign: 'right' }}>Lv. Kiki</th>
                  <th style={TH}>Trạng thái</th><th style={{ ...TH, width: 44 }}></th>
                </tr>
              </thead>
              <tbody>
                {loading && !data && Array.from({ length: 8 }).map((_, i) => (
                  <tr key={`s${i}`}><td style={TD} colSpan={9}><Skeleton height={28} /></td></tr>
                ))}
                {data?.items.map((u: UserRow) => {
                  const st = statusFromUserStatus(u.status);
                  return (
                    <tr key={u.id} className="zz-row" style={{ cursor: 'pointer' }} onClick={() => nav(`/users/${u.id}`)}>
                      <td style={TD}>
                        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 10 }}>
                          <Avatar name={u.displayName} />
                          <span style={{ display: 'flex', flexDirection: 'column', gap: 1, minWidth: 0 }}>
                            <span style={{ font: 'var(--fw-medium) 13px/1.3 var(--font-sans)', color: 'var(--text-strong)', whiteSpace: 'nowrap' }}>{u.displayName}</span>
                            <span style={{ font: 'var(--fw-regular) 12px/1.3 var(--font-sans)', color: 'var(--text-muted)', whiteSpace: 'nowrap' }}>{u.email}</span>
                          </span>
                        </span>
                      </td>
                      <td style={TD}><Tag tone="neutral">{u.provider}</Tag></td>
                      <td style={TD}>{u.plan !== 'free' ? <Tag tone="accent">Zen Pro</Tag> : <Tag tone="outline">Free</Tag>}</td>
                      <td style={MONO}>{formatDate(u.createdAt)}</td>
                      <td style={MONO}>{formatDateTimeUtc(u.lastLoginAt)}</td>
                      <td style={{ ...TD, textAlign: 'right', fontFamily: 'var(--font-mono)', fontSize: 13, color: u.streak ? 'var(--text-strong)' : 'var(--text-faint)' }}>{u.streak}</td>
                      <td style={{ ...TD, textAlign: 'right', fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-strong)' }}>{u.level}</td>
                      <td style={TD}><StatusBadge status={st.status}>{st.label}</StatusBadge></td>
                      <td style={{ ...TD, padding: 'var(--row-py, 13px) 8px', textAlign: 'right' }} onClick={(e) => e.stopPropagation()}>
                        <IconButton label="Tùy chọn" size="sm"><Icon size={16}>{icons.dots}</Icon></IconButton>
                      </td>
                    </tr>
                  );
                })}
                {data && data.items.length === 0 && (
                  <tr><td style={{ ...TD, textAlign: 'center', color: 'var(--text-muted)' }} colSpan={9}>Không có người dùng khớp bộ lọc.</td></tr>
                )}
              </tbody>
            </table>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, padding: '13px 16px', borderTop: '1px solid var(--border-subtle)', background: 'var(--slate-25)', flexWrap: 'wrap' }}>
            <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-muted)' }}>
              <b style={{ color: 'var(--text-body)', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{data ? formatInt(data.total) : '—'}</b> người dùng
            </span>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, font: 'var(--fw-medium) 12px/1 var(--font-mono)' }}>
              {pages.map((p, i) => p === '…' ? (
                <span key={`e${i}`} style={{ color: 'var(--text-faint)', padding: '0 4px' }}>…</span>
              ) : (
                <button key={p} type="button" onClick={() => setPage(p as number)} style={{
                  minWidth: 28, height: 28, padding: '0 8px', borderRadius: 7, border: 'none', cursor: 'pointer',
                  fontFamily: 'var(--font-mono)', fontSize: 12,
                  background: p === page ? 'var(--brand)' : 'transparent', color: p === page ? '#fff' : 'var(--text-body)',
                }}>{p}</button>
              ))}
            </div>
            <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-faint)' }}>25 / 50 / 100 dòng</span>
          </div>
        </Card>
      )}
    </section>
  );
}

function pageList(current: number, total: number): (number | '…')[] {
  if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);
  // Always expose first, last, and the current page ± 1 (each clickable), with
  // ellipses bridging gaps — so any page is reachable by stepping or jumping.
  const wanted = [1, total, current, current - 1, current + 1].filter((n) => n >= 1 && n <= total);
  const sorted = Array.from(new Set(wanted)).sort((a, b) => a - b);
  const out: (number | '…')[] = [];
  let prev = 0;
  for (const n of sorted) {
    if (prev && n - prev > 1) out.push('…');
    out.push(n);
    prev = n;
  }
  return out;
}
