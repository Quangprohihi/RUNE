import { useEffect, useMemo, useState } from 'react';
import { Card, Button, Input, Tag, SegmentedControl, Icon, icons } from '../ds';
import type { TagTone } from '../ds';
import { ErrorState } from '../components/ErrorState';
import { Skeleton } from '../components/LoadingSkeleton';
import { api } from '../lib/api';
import { friendlyError } from '../lib/friendlyError';
import { formatInt, formatDateTimeUtc } from '../lib/format';
import { toCsv, downloadCsv } from '../lib/csv';
import { pageList } from '../lib/pageList';
import type { AdminAuditResponse, WalletAuditResponse, AdminAuditRow, WalletAuditRow } from '../lib/types';

type Tab = 'admin' | 'wallet';

const ACTION_LABELS: Record<string, string> = {
  'payment.confirm': 'Xác nhận đơn',
  'subscription.cancel': 'Hủy subscription',
  'subscription.extend': 'Gia hạn subscription',
  'package.update': 'Sửa gói',
  'user.force_logout': 'Buộc đăng xuất',
  'shop.update': 'Sửa vật phẩm shop',
  'task.update': 'Sửa nhiệm vụ',
  'milestone.update': 'Sửa mốc điểm',
};
const actionLabel = (a: string) => ACTION_LABELS[a] ?? a;

const ACTION_FILTERS: { value: string; label: string }[] = [
  { value: '', label: 'Tất cả hành động' },
  { value: 'payment.confirm', label: 'Xác nhận đơn' },
  { value: 'subscription.extend', label: 'Gia hạn subscription' },
  { value: 'subscription.cancel', label: 'Hủy subscription' },
  { value: 'package.update', label: 'Sửa gói' },
  { value: 'shop.update', label: 'Sửa vật phẩm shop' },
  { value: 'task.update', label: 'Sửa nhiệm vụ' },
  { value: 'milestone.update', label: 'Sửa mốc điểm' },
  { value: 'user.force_logout', label: 'Buộc đăng xuất' },
];

const RESOURCE_LABELS: Record<string, string> = {
  payment_order: 'Đơn TT', user: 'Người dùng', package: 'Gói', shop_item: 'Vật phẩm',
  task_template: 'Nhiệm vụ', milestone: 'Mốc điểm',
};

const roleTone = (role: string): TagTone =>
  role === 'super-admin' ? 'accent' : role === 'moderator' ? 'neutral' : 'outline';

function shortId(id: string): string {
  return id.length > 12 ? `${id.slice(0, 8)}…` : id;
}

function metaSummary(action: string, m: Record<string, unknown> | null): string {
  if (!m) return '';
  if (action === 'subscription.extend' && m.days != null) return `+${m.days} ngày`;
  if ((action === 'package.update' || action === 'payment.confirm') && m.amountVnd != null) return `${formatInt(Number(m.amountVnd))}đ`;
  if (action === 'user.force_logout' && m.revoked != null) return `${m.revoked} phiên`;
  return '';
}

const TH: React.CSSProperties = { textAlign: 'left', font: 'var(--fw-semibold) 11px/1 var(--font-sans)', letterSpacing: '.06em', textTransform: 'uppercase', color: 'var(--text-muted)', padding: '11px 16px', background: 'var(--slate-50)', borderBottom: '1px solid var(--border-default)', whiteSpace: 'nowrap' };
const TD: React.CSSProperties = { padding: '13px 16px', borderBottom: '1px solid var(--border-subtle)', verticalAlign: 'top' };
const MONO: React.CSSProperties = { ...TD, fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--text-body)', whiteSpace: 'nowrap' };

export function AuditPage() {
  const [tab, setTab] = useState<Tab>('admin');
  const [page, setPage] = useState(1);
  const [action, setAction] = useState('');
  const [q, setQ] = useState('');
  const pageSize = 15;
  const [admin, setAdmin] = useState<AdminAuditResponse | null>(null);
  const [wallet, setWallet] = useState<WalletAuditResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    setError(null);
    if (tab === 'admin') {
      api.adminAudit({ action: action || undefined, q: q.trim() || undefined, page, pageSize })
        .then(setAdmin).catch((e) => setError(friendlyError(e))).finally(() => setLoading(false));
    } else {
      api.walletAudit({ page, pageSize })
        .then(setWallet).catch((e) => setError(friendlyError(e))).finally(() => setLoading(false));
    }
  }

  useEffect(() => {
    const t = setTimeout(load, 250);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [tab, page, action, q]);

  const data = tab === 'admin' ? admin : wallet;
  const total = data?.total ?? 0;
  const totalPages = data ? Math.max(1, Math.ceil(total / data.pageSize)) : 1;
  const pages = useMemo(() => pageList(page, totalPages), [page, totalPages]);

  function exportCsv() {
    if (tab === 'admin') {
      const items = admin?.items ?? [];
      const csv = toCsv(
        ['Thời gian (UTC)', 'Admin', 'Vai trò', 'Hành động', 'Loại đối tượng', 'Mã đối tượng', 'IP'],
        items,
        (r) => [formatDateTimeUtc(r.at), r.actorEmail, r.actorRole, actionLabel(r.action), r.resourceType, r.resourceId, r.ip ?? ''],
      );
      downloadCsv('zenzoo-admin-audit.csv', csv);
    } else {
      const items = wallet?.items ?? [];
      const csv = toCsv(
        ['Thời gian (UTC)', 'Người dùng', 'Lý do', 'Số tiền', 'Đơn vị', 'Loại'],
        items,
        (r) => [formatDateTimeUtc(r.at), r.actor, r.reason, String(r.amount), r.currency, r.refType],
      );
      downloadCsv('zenzoo-wallet-ledger.csv', csv);
    }
  }

  const adminCols = 5;
  const walletCols = 5;

  return (
    <section style={{ padding: '24px 32px 90px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 16, flexWrap: 'wrap' }}>
        <SegmentedControl<Tab>
          value={tab}
          onChange={(t) => { setPage(1); setTab(t); }}
          options={[{ value: 'admin', label: 'Hành động admin' }, { value: 'wallet', label: 'Giao dịch ví' }]}
        />
        <div style={{ flex: 1 }} />
        {tab === 'admin' && (
          <>
            <select
              value={action}
              onChange={(e) => { setPage(1); setAction(e.target.value); }}
              aria-label="Lọc theo hành động"
              style={{ height: 36, padding: '0 10px', borderRadius: 8, border: '1px solid var(--border-default)', background: 'var(--surface)', font: 'var(--fw-regular) 13px/1 var(--font-sans)', color: 'var(--text-body)' }}
            >
              {ACTION_FILTERS.map((o) => <option key={o.value} value={o.value}>{o.label}</option>)}
            </select>
            <div style={{ minWidth: 200, maxWidth: 280 }}>
              <Input value={q} onChange={(e) => { setPage(1); setQ(e.target.value); }} placeholder="Tìm theo email admin…" prefix={<Icon size={16}>{icons.search}</Icon>} />
            </div>
          </>
        )}
        <Button variant="secondary" onClick={exportCsv}><Icon size={16}>{icons.download}</Icon>Xuất CSV</Button>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, marginBottom: 14, flexWrap: 'wrap' }}>
        <span style={{ font: 'var(--fw-regular) 12px/1.4 var(--font-sans)', color: 'var(--text-faint)' }}>
          {tab === 'admin'
            ? 'Mọi thao tác ghi của quản trị viên (xác nhận đơn, hủy/gia hạn gói, sửa giá, buộc đăng xuất).'
            : 'Sổ giao dịch ví người dùng (token / kim cương / năng lượng).'}
        </span>
        <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-faint)' }}>
          <b style={{ color: 'var(--text-body)', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{data ? formatInt(total) : '—'}</b> bản ghi
        </span>
      </div>

      {error ? (
        <ErrorState message={error} onRetry={load} />
      ) : (
        <Card padding="none">
          <div style={{ overflowX: 'auto' }}>
            {tab === 'admin' ? (
              <table style={{ width: '100%', borderCollapse: 'collapse', font: 'var(--fw-regular) 13px/1.4 var(--font-sans)' }}>
                <thead>
                  <tr>
                    <th style={TH}>Thời gian (UTC)</th><th style={TH}>Admin</th>
                    <th style={TH}>Hành động</th><th style={TH}>Đối tượng</th><th style={TH}>IP</th>
                  </tr>
                </thead>
                <tbody>
                  {loading && !admin && Array.from({ length: 8 }).map((_, i) => (
                    <tr key={`s${i}`}><td style={TD} colSpan={adminCols}><Skeleton height={28} /></td></tr>
                  ))}
                  {admin?.items.map((r: AdminAuditRow) => {
                    const detail = metaSummary(r.action, r.metadata);
                    return (
                      <tr key={r.id} className="zz-row">
                        <td style={MONO}>{formatDateTimeUtc(r.at)}</td>
                        <td style={TD}>
                          <span style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                            <span style={{ font: 'var(--fw-medium) 13px/1.3 var(--font-sans)', color: 'var(--text-strong)' }}>{r.actorEmail}</span>
                            <span><Tag tone={roleTone(r.actorRole)}>{r.actorRole}</Tag></span>
                          </span>
                        </td>
                        <td style={TD}>
                          <span style={{ display: 'flex', flexDirection: 'column', gap: 3 }}>
                            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--brand)' }}>{r.action}</span>
                            <span style={{ font: 'var(--fw-regular) 12px/1.3 var(--font-sans)', color: 'var(--text-muted)' }}>{actionLabel(r.action)}{detail ? ` · ${detail}` : ''}</span>
                          </span>
                        </td>
                        <td style={TD}>
                          <span style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                            <span style={{ font: 'var(--fw-regular) 12px/1.3 var(--font-sans)', color: 'var(--text-body)' }}>{RESOURCE_LABELS[r.resourceType] ?? r.resourceType}</span>
                            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-faint)' }} title={r.resourceId}>{shortId(r.resourceId)}</span>
                          </span>
                        </td>
                        <td style={MONO}>{r.ip ?? '—'}</td>
                      </tr>
                    );
                  })}
                  {admin && admin.items.length === 0 && (
                    <tr><td style={{ ...TD, textAlign: 'center', color: 'var(--text-muted)' }} colSpan={adminCols}>Chưa có hành động admin nào khớp bộ lọc.</td></tr>
                  )}
                </tbody>
              </table>
            ) : (
              <table style={{ width: '100%', borderCollapse: 'collapse', font: 'var(--fw-regular) 13px/1.4 var(--font-sans)' }}>
                <thead>
                  <tr>
                    <th style={TH}>Thời gian (UTC)</th><th style={TH}>Người dùng</th>
                    <th style={TH}>Lý do</th><th style={{ ...TH, textAlign: 'right' }}>Số tiền</th><th style={TH}>Loại</th>
                  </tr>
                </thead>
                <tbody>
                  {loading && !wallet && Array.from({ length: 8 }).map((_, i) => (
                    <tr key={`s${i}`}><td style={TD} colSpan={walletCols}><Skeleton height={28} /></td></tr>
                  ))}
                  {wallet?.items.map((r: WalletAuditRow) => (
                    <tr key={r.id} className="zz-row">
                      <td style={MONO}>{formatDateTimeUtc(r.at)}</td>
                      <td style={{ ...TD, font: 'var(--fw-medium) 13px/1.3 var(--font-sans)', color: 'var(--text-strong)' }}>{r.actor}</td>
                      <td style={{ ...TD, color: 'var(--text-body)' }}>{r.reason}</td>
                      <td style={{ ...TD, textAlign: 'right', fontFamily: 'var(--font-mono)', fontSize: 13, color: r.amount < 0 ? 'var(--status-danger, #c0392b)' : 'var(--text-strong)' }}>
                        {r.amount > 0 ? `+${formatInt(r.amount)}` : formatInt(r.amount)}
                      </td>
                      <td style={TD}><Tag tone="neutral">{r.refType || r.currency}</Tag></td>
                    </tr>
                  ))}
                  {wallet && wallet.items.length === 0 && (
                    <tr><td style={{ ...TD, textAlign: 'center', color: 'var(--text-muted)' }} colSpan={walletCols}>Chưa có giao dịch ví.</td></tr>
                  )}
                </tbody>
              </table>
            )}
          </div>

          <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, padding: '13px 16px', borderTop: '1px solid var(--border-subtle)', background: 'var(--slate-25)', flexWrap: 'wrap' }}>
            <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-muted)' }}>
              <b style={{ color: 'var(--text-body)', fontWeight: 600, fontVariantNumeric: 'tabular-nums' }}>{data ? formatInt(total) : '—'}</b> bản ghi
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
            <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-faint)' }}>15 dòng / trang</span>
          </div>
        </Card>
      )}
    </section>
  );
}
