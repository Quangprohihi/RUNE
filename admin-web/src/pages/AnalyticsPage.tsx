import { useEffect, useState } from 'react';
import { Card } from '../ds';
import { KpiCard } from '../components/KpiCard';
import { RangePicker } from '../components/RangePicker';
import type { RangeValue } from '../components/RangePicker';
import { LineChart } from '../components/LineChart';
import { Funnel } from '../components/Funnel';
import { HourlyBars } from '../components/HourlyBars';
import { ErrorState } from '../components/ErrorState';
import { Skeleton } from '../components/LoadingSkeleton';
import { api } from '../lib/api';
import { friendlyError } from '../lib/friendlyError';
import { formatInt, formatVndShort } from '../lib/format';
import type { AnalyticsResponse } from '../lib/types';

const GRAN_LABEL: Record<string, string> = { day: 'ngày', week: 'tuần', month: 'tháng', quarter: 'quý' };

export function AnalyticsPage() {
  const [value, setValue] = useState<RangeValue>({ range: 'month', granularity: 'day', compare: false });
  const [data, setData] = useState<AnalyticsResponse | null>(null);
  const [err, setErr] = useState<string | null>(null);

  function load() {
    setErr(null);
    api.analytics(value).then(setData).catch((e) => setErr(friendlyError(e)));
  }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  useEffect(() => { load(); }, [value]);

  const k = data?.kpis;
  return (
    <section style={{ padding: '24px 32px 90px' }}>
      <div style={{ marginBottom: 20 }}>
        <RangePicker label={data?.rangeLabel ?? 'Đang tải…'} value={value} onApply={setValue} />
      </div>

      {err ? <ErrorState message={err} onRetry={load} /> : (
        <>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,minmax(0,1fr))', gap: 14, marginBottom: 22 }}>
            {!k ? Array.from({ length: 4 }).map((_, i) => (
              <div key={i} style={{ minHeight: 120, padding: 16, background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-lg)' }}><Skeleton height={12} width="55%" /><div style={{ height: 12 }} /><Skeleton height={26} width="45%" /></div>
            )) : (
              <>
                <KpiCard label="Người dùng hoạt động" valueText={formatInt(k.activeUsers.value)} kpi={{ value: k.activeUsers.value, deltaPct: k.activeUsers.deltaPct, spark: [] }} color="var(--blue-500)" hideSpark />
                <KpiCard label="Phút focus" valueText={formatInt(k.focusMinutes.value)} suffix="′" kpi={{ value: k.focusMinutes.value, deltaPct: k.focusMinutes.deltaPct, spark: [] }} color="var(--blue-500)" hideSpark />
                <KpiCard label="Doanh thu" valueText={formatVndShort(k.revenue.value)} kpi={{ value: k.revenue.value, deltaPct: k.revenue.deltaPct, spark: [] }} color="var(--teal-500)" hideSpark />
                <KpiCard label="Zen Pro mới" valueText={formatInt(k.newPro.value)} kpi={{ value: k.newPro.value, deltaPct: k.newPro.deltaPct, spark: [] }} color="var(--green-500)" hideSpark />
              </>
            )}
          </div>

          <Card title="Người dùng hoạt động" subtitle={data ? `${data.rangeLabel} · gom theo ${GRAN_LABEL[data.granularity] ?? data.granularity}` : ''} padding="md" style={{ marginBottom: 20 }}>
            {data ? <LineChart labels={data.bucketLabels} cur={data.series.cur} prev={data.series.prev} /> : <Skeleton height={190} />}
          </Card>

          <div style={{ display: 'grid', gridTemplateColumns: 'minmax(0,1fr) minmax(0,1fr)', gap: 20, alignItems: 'start' }}>
            <Card title="Phễu chuyển đổi" subtitle="Free → Zen Pro" padding="md">
              {data ? <Funnel steps={data.funnel} /> : <Skeleton height={200} />}
            </Card>
            <Card title="Phút focus theo khung giờ" subtitle="Trung bình mỗi ngày" padding="md">
              {data ? <HourlyBars bars={data.hourly} /> : <Skeleton height={160} />}
            </Card>
          </div>
        </>
      )}
    </section>
  );
}
