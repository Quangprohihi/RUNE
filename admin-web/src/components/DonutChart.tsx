import { useState } from 'react';
import { formatInt, formatPercent } from '../lib/format';

export interface DonutSlice { label: string; value: number; color: string; }

interface DonutChartProps {
  slices: DonutSlice[];
  /** value formatter for legend + center (e.g. formatVndShort for money) */
  format?: (v: number) => string;
  /** small caption under the center number, defaults to "Tổng" */
  centerLabel?: string;
}

/**
 * Donut built from stroke-dashed circles: 2px surface gaps between segments,
 * total (or hovered slice) in the center, legend with direct value + % labels.
 */
export function DonutChart({ slices, format = formatInt, centerLabel = 'Tổng' }: DonutChartProps) {
  const [active, setActive] = useState<number | null>(null);

  const total = slices.reduce((s, x) => s + x.value, 0);
  const SIZE = 168, STROKE = 26;
  const r = (SIZE - STROKE) / 2;
  const C = 2 * Math.PI * r;
  const GAP = total > 0 && slices.filter((s) => s.value > 0).length > 1 ? 2.5 : 0;

  let acc = 0;
  const arcs = slices.map((s) => {
    const frac = total > 0 ? s.value / total : 0;
    const len = Math.max(0, frac * C - GAP);
    const arc = { ...s, frac, dash: `${len} ${C - len}`, offset: -acc * C - GAP / 2 };
    acc += frac;
    return arc;
  });

  const shown = active != null ? slices[active] : null;

  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 22, flexWrap: 'wrap' }}>
      <div style={{ position: 'relative', width: SIZE, height: SIZE, flex: 'none' }}>
        <svg width={SIZE} height={SIZE} viewBox={`0 0 ${SIZE} ${SIZE}`} style={{ transform: 'rotate(-90deg)' }}>
          {total === 0 && <circle cx={SIZE / 2} cy={SIZE / 2} r={r} fill="none" stroke="var(--border-subtle)" strokeWidth={STROKE} />}
          {arcs.map((a, i) => a.value > 0 && (
            <circle
              key={i} cx={SIZE / 2} cy={SIZE / 2} r={r} fill="none"
              stroke={a.color} strokeWidth={active == null || active === i ? STROKE : STROKE - 8}
              strokeDasharray={a.dash} strokeDashoffset={a.offset}
              opacity={active == null || active === i ? 1 : 0.35}
              style={{ transition: 'stroke-width .15s ease, opacity .15s ease', cursor: 'pointer' }}
              onMouseEnter={() => setActive(i)} onMouseLeave={() => setActive(null)}
            />
          ))}
        </svg>
        <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', pointerEvents: 'none', textAlign: 'center' }}>
          <span style={{ font: 'var(--fw-extra) 22px/1.1 var(--font-sans)', letterSpacing: '-.02em', color: 'var(--text-strong)', fontVariantNumeric: 'tabular-nums' }}>
            {total === 0 ? '—' : format(shown ? shown.value : total)}
          </span>
          <span style={{ font: 'var(--fw-medium) 11px/1.4 var(--font-sans)', color: 'var(--text-muted)', maxWidth: 90 }}>
            {total === 0 ? 'Chưa có dữ liệu' : shown ? shown.label : centerLabel}
          </span>
        </div>
      </div>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 10, minWidth: 150, flex: 1 }}>
        {slices.map((s, i) => (
          <div
            key={i}
            onMouseEnter={() => setActive(i)} onMouseLeave={() => setActive(null)}
            style={{ display: 'flex', alignItems: 'center', gap: 8, cursor: 'default', opacity: active == null || active === i ? 1 : 0.45, transition: 'opacity .15s ease' }}
          >
            <span style={{ width: 10, height: 10, borderRadius: 3, background: s.color, flex: 'none' }} />
            <span style={{ font: 'var(--fw-medium) 13px/1.3 var(--font-sans)', color: 'var(--text-body)', flex: 1 }}>{s.label}</span>
            <span style={{ font: 'var(--fw-semibold) 13px/1.3 var(--font-sans)', color: 'var(--text-strong)', fontVariantNumeric: 'tabular-nums' }}>{format(s.value)}</span>
            <span style={{ font: 'var(--fw-regular) 12px/1.3 var(--font-mono)', color: 'var(--text-faint)', width: 44, textAlign: 'right' }}>
              {total > 0 ? formatPercent((s.value / total) * 100) : '—'}
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}
