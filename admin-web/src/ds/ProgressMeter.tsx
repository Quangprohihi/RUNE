import { formatPercent, formatInt } from '../lib/format';

interface ProgressMeterProps {
  label: string;
  value: number;
  max?: number;
  unit?: string;
  threshold?: number;
}

export function ProgressMeter({ label, value, max = 100, unit, threshold }: ProgressMeterProps) {
  const pct = Math.max(0, Math.min(100, (value / max) * 100));
  const valueText = unit === '%' ? formatPercent(value) : max !== 100 ? `${formatInt(value)} / ${formatInt(max)}` : formatPercent(value);
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: 6 }}>
        <span style={{ font: 'var(--fw-medium) 13px/1 var(--font-sans)', color: 'var(--text-body)' }}>{label}</span>
        <span style={{ font: 'var(--fw-semibold) 13px/1 var(--font-mono)', color: 'var(--text-strong)' }}>{valueText}</span>
      </div>
      <div style={{ position: 'relative', height: 8, borderRadius: 'var(--radius-pill)', background: 'var(--surface-sunken)', overflow: 'hidden' }}>
        <div style={{ width: `${pct}%`, height: '100%', borderRadius: 'var(--radius-pill)', background: 'var(--brand)' }} />
        {threshold != null && (
          <div style={{ position: 'absolute', top: -2, bottom: -2, left: `${Math.min(100, (threshold / max) * 100)}%`, width: 2, background: 'var(--border-strong)' }} />
        )}
      </div>
    </div>
  );
}
