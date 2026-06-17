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
  const pageSize = 15;
  const [tx, setTx] = useState<PaymentsResponse | null>(null);
  const [txErr, setTxErr] = useState<string | null>(null);
  const [txLoading, setTxLoading] = useState(true);

  function loadSummary() {
    setSumErr(null);
    api.billing.summary(range).then(setSummary).catch((e) => setSumErr(friendlyError(e)));
  }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { loadSummary(); }, [range]);

  function loadTx() {
    setTxLoading(true);
    setTxErr(null);
    api.payments({ status: filter === 'all' ? undefined : filter, from: from || undefined, to: to || undefined, page, pageSize })
      .then(setTx).catch((e) => setTxErr(friendlyError(e))).finally(() => setTxLoading(false));
  }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { loadTx(); }, [filter, from, to, page]);

  async function confirmOrder(id: string) {
    if (typeof window !== 'undefined' && !window.confirm('Xác nhận đơn này là đã thanh toán?')) return;
    try {
      await api.confirmPayment(id);
      loadTx();
      loadSummary();
    } catch (e) {
      setTxErr(friendlyError(e));
    }
  }

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
        <ErrorState message={sumErr} onRetry={loadSummary} />
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
                      <th style={{ ...TH, textAlign: 'right' }}>Số tiền</th><th style={TH}>Trạng thái</th><th style={{ ...TH, textAlign: 'right' }}></th>
                    </tr>
                  </thead>
                  <tbody>
                    {txLoading && !tx && Array.from({ length: 6 }).map((_, i) => (<tr key={`s${i}`}><td style={TD} colSpan={6}><Skeleton height={24} /></td></tr>))}
                    {tx?.items.map((o: PaymentRow) => {
                      const b = STATUS_BADGE[o.status] ?? { status: 'draft' as DesignStatus, label: o.status };
                      const canConfirm = o.status === 'pending' || o.status === 'review';
                      return (
                        <tr key={o.id}>
                          <td style={{ ...TD, fontFamily: 'var(--font-mono)', fontSize: 12, color: 'var(--text-body)' }}>{o.vnpTxnRef}</td>
                          <td style={{ ...TD, color: 'var(--text-strong)' }}>{o.user}</td>
                          <td style={TD}>{o.productCode === 'zen_pro_yearly' ? <Tag tone="accent">Yearly</Tag> : o.productCode === 'zen_pro_monthly' ? <Tag tone="neutral">Monthly</Tag> : <Tag tone="outline">{o.productCode}</Tag>}</td>
                          <td style={{ ...TD, textAlign: 'right', fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--text-strong)' }}>{formatInt(o.amountVnd)}đ</td>
                          <td style={TD}><StatusBadge status={b.status}>{b.label}</StatusBadge></td>
                          <td style={{ ...TD, textAlign: 'right' }}>{canConfirm && (
                            <button type="button" onClick={() => confirmOrder(o.id)} style={{ font: 'var(--fw-semibold) 12px/1 var(--font-sans)', color: 'var(--brand)', background: 'transparent', border: 'none', cursor: 'pointer', whiteSpace: 'nowrap' }}>Xác nhận</button>
                          )}</td>
                        </tr>
                      );
                    })}
                    {tx && tx.items.length === 0 && (<tr><td style={{ ...TD, textAlign: 'center', color: 'var(--text-muted)' }} colSpan={6}>Không có giao dịch khớp bộ lọc.</td></tr>)}
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

function planLabel(code: string): string {
  if (code === 'zen_pro_monthly') return 'Monthly';
  if (code === 'zen_pro_yearly') return 'Yearly';
  return code;
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
