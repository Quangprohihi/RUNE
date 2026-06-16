import { useEffect, useState } from 'react';
import { Card, Button, SegmentedControl, StatusBadge, ProgressMeter, Icon, icons } from '../ds';
import { KpiCard } from '../components/KpiCard';
import { KpiGridSkeleton } from '../components/LoadingSkeleton';
import { ErrorState } from '../components/ErrorState';
import { api } from '../lib/api';
import { friendlyError } from '../lib/friendlyError';
import { formatInt, formatVndShort, relativeTime } from '../lib/format';
import type { OverviewResponse, HealthResponse, RangeKey, RecentEvent } from '../lib/types';

const dec1 = (n: number) => new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 1 }).format(n);
const pct = (n: number) => new Intl.NumberFormat('vi-VN', { maximumFractionDigits: 1 }).format(n) + '%';

const RANGE_OPTS: { value: RangeKey; label: string }[] = [
  { value: 'today', label: 'Hôm nay' }, { value: '7d', label: '7 ngày' },
  { value: '30d', label: '30 ngày' }, { value: 'quarter', label: 'Quý' },
];

const EVENT_ICON: Record<string, { key: keyof typeof icons; bg: string; fg: string }> = {
  focus_completed: { key: 'overview', bg: 'var(--blue-50)', fg: 'var(--blue-600)' },
  daily_task_claimed: { key: 'overview', bg: 'var(--blue-50)', fg: 'var(--blue-600)' },
  achievement_claimed: { key: 'bell', bg: 'var(--amber-50)', fg: 'var(--amber-600)' },
  shop_purchase: { key: 'gear', bg: 'var(--violet-50)', fg: 'var(--violet-600)' },
  shop_item_used: { key: 'gear', bg: 'var(--violet-50)', fg: 'var(--violet-600)' },
};
function eventStyle(t: string) { return EVENT_ICON[t] ?? { key: 'overview' as const, bg: 'var(--slate-100)', fg: 'var(--slate-600)' }; }

export function OverviewPage() {
  const [range, setRange] = useState<RangeKey>('today');
  const [data, setData] = useState<OverviewResponse | null>(null);
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  function load(r: RangeKey) {
    setLoading(true);
    setError(null);
    api.overview(r)
      .then(setData)
      .catch((e) => setError(friendlyError(e)))
      .finally(() => setLoading(false));
  }

  useEffect(() => { load(range); }, [range]);
  useEffect(() => { api.health().then(setHealth).catch(() => setHealth(null)); }, []);

  return (
    <section style={{ padding: '24px 32px 90px' }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, marginBottom: 20, flexWrap: 'wrap' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <SegmentedControl variant="lite" value={range} options={RANGE_OPTS} onChange={setRange} />
          <span style={{ font: 'var(--fw-regular) 12px/1 var(--font-sans)', color: 'var(--text-faint)' }}>Cập nhật vừa xong</span>
        </div>
        <Button variant="secondary"><Icon size={16}>{icons.download}</Icon>Xuất báo cáo</Button>
      </div>

      {error ? (
        <ErrorState message={error} onRetry={() => load(range)} />
      ) : loading || !data ? (
        <KpiGridSkeleton />
      ) : (
        <>
          <div style={{
            display: 'grid', gridTemplateColumns: 'repeat(4,minmax(0,1fr))', gap: 'var(--kpi-gap, 1px)',
            background: 'var(--kpi-wrap-bg, var(--border-subtle))', border: 'var(--kpi-wrap-border, 1px solid var(--border-subtle))',
            borderRadius: 'var(--kpi-wrap-radius, var(--radius-lg))', overflow: 'var(--kpi-wrap-overflow, hidden)', marginBottom: 22,
          }}>
            <KpiCard label="Người dùng hoạt động / ngày" valueText={formatInt(data.kpis.dau.value)} kpi={data.kpis.dau} color="var(--blue-500)" note="trong kỳ" />
            <KpiCard label="Độ bám DAU/MAU" valueText={pct(data.kpis.stickiness.value)} kpi={data.kpis.stickiness} color="var(--teal-500)" note="dải lành mạnh ≥20%" />
            <KpiCard label="Tổng phút focus" valueText={formatInt(data.kpis.focusMinutes.value)} suffix="′" kpi={data.kpis.focusMinutes} color="var(--blue-500)" />
            <KpiCard label="Phiên focus hoàn thành" valueText={formatInt(data.kpis.focusSessions.value)} kpi={data.kpis.focusSessions} color="var(--blue-500)" />
            <KpiCard label="Người dùng Zen Pro" valueText={formatInt(data.kpis.premiumUsers.value)} kpi={data.kpis.premiumUsers} color="var(--teal-500)" note="tổng hiện tại" />
            <KpiCard label="Doanh thu hôm nay" valueText={formatVndShort(data.kpis.revenue.value)} kpi={data.kpis.revenue} color="var(--blue-500)" />
            <KpiCard label="Streak trung bình" valueText={dec1(data.kpis.avgStreak.value)} suffix=" ngày" kpi={data.kpis.avgStreak} color="var(--green-500)" note="trên toàn hệ thống" />
            <KpiCard label="Free → Zen Pro" valueText={pct(data.kpis.conversion.value)} kpi={data.kpis.conversion} color="var(--green-500)" note="tỉ lệ chuyển đổi" />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0,2fr) minmax(0,1fr)', gap: 20, alignItems: 'start' }}>
            <Card title="Hoạt động gần đây" subtitle="Toàn hệ thống · mới nhất trước" padding="none">
              <div style={{ padding: '4px 18px 8px' }}>
                {data.recent.length === 0 && <div style={{ padding: '16px 0', color: 'var(--text-muted)', font: 'var(--fw-regular) 13px/1.5 var(--font-sans)' }}>Chưa có hoạt động.</div>}
                {data.recent.map((e: RecentEvent, i) => {
                  const st = eventStyle(e.eventType);
                  return (
                    <div key={i} style={{ display: 'flex', gap: 13, padding: '12px 0', borderBottom: i < data.recent.length - 1 ? '1px solid var(--border-subtle)' : 'none' }}>
                      <span style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center', width: 30, height: 30, borderRadius: 8, flex: 'none', background: st.bg, color: st.fg }}><Icon size={15}>{icons[st.key]}</Icon></span>
                      <div style={{ flex: 1, font: 'var(--fw-regular) 13px/1.45 var(--font-sans)', color: 'var(--text-body)' }}>
                        <b style={{ color: 'var(--text-strong)', fontWeight: 600 }}>{e.actor}</b> {e.title}{e.subtitle ? <> · {e.subtitle}</> : null}
                      </div>
                      <span style={{ font: 'var(--fw-medium) 11px/1.6 var(--font-mono)', color: 'var(--text-faint)', whiteSpace: 'nowrap' }}>{relativeTime(e.at)}</span>
                    </div>
                  );
                })}
              </div>
            </Card>

            <div style={{ display: 'flex', flexDirection: 'column', gap: 20 }}>
              <Card title="Tình trạng hệ thống" padding="md">
                <div style={{ display: 'flex', flexDirection: 'column' }}>
                  <StatusRow name="Express API"><StatusBadge status="public" pulse>Đang chạy</StatusBadge></StatusRow>
                  <StatusRow name="PostgreSQL">{health?.db === 'down' ? <StatusBadge status="rejected">Mất kết nối</StatusBadge> : <StatusBadge status="approved">Kết nối OK</StatusBadge>}</StatusRow>
                  <StatusRow name="VNPay IPN">{health?.vnpay ? <StatusBadge status="approved">Hoạt động</StatusBadge> : <StatusBadge status="draft">Chưa cấu hình</StatusBadge>}</StatusRow>
                  <StatusRow name="Gemini Flash" last>{health?.gemini ? <StatusBadge status="progress" pulse>Đang phục vụ</StatusBadge> : <StatusBadge status="draft">Tắt</StatusBadge>}</StatusRow>
                  <p style={{ font: 'var(--fw-regular) 12px/1.5 var(--font-sans)', color: 'var(--text-muted)', margin: '13px 0 0', borderTop: '1px solid var(--border-subtle)', paddingTop: 12 }}>
                    Độ trễ trung bình API <b style={{ fontFamily: 'var(--font-mono)', color: 'var(--text-strong)' }}>{health ? `${health.apiLatencyMs} ms` : '—'}</b> · cập nhật mỗi lần tải.
                  </p>
                </div>
              </Card>

              <Card title="Mục tiêu quý" subtitle="Tiến độ so với chỉ tiêu" padding="md">
                <div style={{ display: 'flex', flexDirection: 'column', gap: 16, paddingTop: 2 }}>
                  {data.goals.map((g, i) => (
                    <ProgressMeter key={i} label={g.label} value={g.value} max={g.max} unit={g.unit} />
                  ))}
                </div>
              </Card>
            </div>
          </div>
        </>
      )}
    </section>
  );
}

function StatusRow({ name, last, children }: { name: string; last?: boolean; children: React.ReactNode }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', padding: '9px 0', borderBottom: last ? 'none' : '1px solid var(--border-subtle)', font: 'var(--fw-medium) 13px/1 var(--font-sans)', color: 'var(--text-body)' }}>
      {name}
      {children}
    </div>
  );
}
