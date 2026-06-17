import type { Kpi } from '../lib/types';
import { Sparkline } from './Sparkline';
import { formatPercent } from '../lib/format';

interface KpiCardProps {
  label: string;
  valueText: string;
  suffix?: string;
  kpi: Kpi;
  color?: string;
  /** override the delta line note for point-in-time KPIs */
  note?: string;
  /** hide the sparkline (billing KPIs have no sparkline) */
  hideSpark?: boolean;
}

export function KpiCard({ label, valueText, suffix, kpi, color = 'var(--blue-500)', note, hideSpark }: KpiCardProps) {
  const d = kpi.deltaPct;
  const up = d != null && d >= 0;
  return (
    <div style={{
      background: 'var(--kpi-cell-bg, var(--surface-card))', border: 'var(--kpi-cell-border, none)',
      borderRadius: 'var(--kpi-cell-radius, 0px)', boxShadow: 'var(--kpi-cell-shadow, none)',
      padding: '15px 16px 13px', display: 'flex', flexDirection: 'column', minHeight: 150,
    }}>
      <span style={{ font: 'var(--fw-semibold) 11px/1.3 var(--font-sans)', letterSpacing: '.05em', textTransform: 'uppercase', color: 'var(--text-muted)' }}>{label}</span>
      <div style={{ font: 'var(--fw-extra) 30px/1 var(--font-sans)', letterSpacing: '-.02em', color: 'var(--text-strong)', marginTop: 13, fontVariantNumeric: 'tabular-nums' }}>
        {valueText}{suffix && <span style={{ fontSize: 16, color: 'var(--text-muted)', fontWeight: 600 }}>{suffix}</span>}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 4, font: 'var(--fw-semibold) 12px/1 var(--font-sans)', marginTop: 8, color: d == null ? 'var(--text-faint)' : up ? 'var(--green-600)' : 'var(--red-600)' }}>
        {d == null ? (
          <span style={{ fontWeight: 400 }}>{note ?? '—'}</span>
        ) : (
          <>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round">
              {up ? <><path d="M7 7h10v10" /><path d="M7 17 17 7" /></> : <><path d="M7 7l10 10" /><path d="M17 7v10H7" /></>}
            </svg>
            {formatPercent(Math.abs(d))}
            <span style={{ color: 'var(--text-faint)', fontWeight: 400, marginLeft: 2 }}>vs kỳ trước</span>
          </>
        )}
      </div>
      {!hideSpark && <Sparkline data={kpi.spark} color={color} />}
    </div>
  );
}
