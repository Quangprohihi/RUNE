import { useRef, useState } from 'react';
import { formatInt } from '../lib/format';

interface LineChartProps {
  labels: string[];
  cur: number[];
  prev: number[] | null;
  /** series hue — defaults to the DS primary blue */
  color?: string;
  /** value formatter for the hover tooltip (e.g. formatVndShort for revenue) */
  format?: (v: number) => string;
}

export function LineChart({ labels, cur, prev, color = 'var(--blue-500)', format = formatInt }: LineChartProps) {
  const W = 620, H = 190, P = 12;
  const wrapRef = useRef<HTMLDivElement>(null);
  const [hover, setHover] = useState<number | null>(null);

  const max = Math.max(1, ...cur, ...(prev ?? []));
  const n = Math.max(1, cur.length);
  const x = (i: number) => (n <= 1 ? W / 2 : P + (i * (W - 2 * P)) / (n - 1));
  const y = (v: number) => (H - P) - (v / max) * (H - 2 * P);
  const lineOf = (arr: number[]) => arr.map((v, i) => `${x(i).toFixed(1)},${y(v).toFixed(1)}`).join(' ');
  const line = lineOf(cur);
  const area = `${x(0).toFixed(1)},${H - P} ${line} ${x(cur.length - 1).toFixed(1)},${H - P}`;
  const gridYs = [0.25, 0.5, 0.75].map((f) => (H - P) - f * (H - 2 * P));
  const labIdx = [0, Math.floor((n - 1) * 0.25), Math.floor((n - 1) * 0.5), Math.floor((n - 1) * 0.75), n - 1];

  function onMove(e: React.MouseEvent<HTMLDivElement>) {
    const el = wrapRef.current;
    if (!el || n <= 1) return;
    const rect = el.getBoundingClientRect();
    const frac = (e.clientX - rect.left) / rect.width;
    const i = Math.round(((frac * W - P) / (W - 2 * P)) * (n - 1));
    setHover(Math.max(0, Math.min(n - 1, i)));
  }

  const hx = hover != null ? (x(hover) / W) * 100 : 0;
  const tooltipLeft = hover != null && hx > 65;

  return (
    <div>
      <div style={{ display: 'flex', gap: 16, marginBottom: 10, font: 'var(--fw-medium) 12px/1 var(--font-sans)', color: 'var(--text-muted)' }}>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}><span style={{ width: 14, height: 3, background: color, display: 'inline-block', borderRadius: 2 }} />Kỳ này</span>
        {prev && <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}><span style={{ width: 14, borderTop: '2px dashed var(--slate-400)', display: 'inline-block' }} />Kỳ trước</span>}
      </div>
      <div ref={wrapRef} style={{ position: 'relative' }} onMouseMove={onMove} onMouseLeave={() => setHover(null)}>
        <svg viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" style={{ width: '100%', height: 190, display: 'block' }}>
          {gridYs.map((gy, i) => <line key={i} x1={P} y1={gy} x2={W - P} y2={gy} stroke="var(--border-subtle)" strokeWidth={1} vectorEffect="non-scaling-stroke" />)}
          <polygon points={area} fill={color} opacity={0.09} />
          {prev && <polyline points={lineOf(prev)} fill="none" stroke="var(--slate-400)" strokeWidth={1.75} strokeDasharray="5 4" vectorEffect="non-scaling-stroke" />}
          <polyline points={line} fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" vectorEffect="non-scaling-stroke" />
          {hover != null && (
            <>
              <line x1={x(hover)} y1={P} x2={x(hover)} y2={H - P} stroke="var(--slate-400)" strokeWidth={1} strokeDasharray="3 3" vectorEffect="non-scaling-stroke" />
              <circle cx={x(hover)} cy={y(cur[hover] ?? 0)} r={4.5} fill={color} stroke="var(--surface-card)" strokeWidth={2} />
            </>
          )}
        </svg>
        {hover != null && (
          <div style={{
            position: 'absolute', top: 6, left: `${hx}%`, transform: tooltipLeft ? 'translateX(calc(-100% - 10px))' : 'translateX(10px)',
            background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 8,
            boxShadow: '0 4px 14px rgba(15,30,50,.12)', padding: '7px 10px', pointerEvents: 'none', whiteSpace: 'nowrap',
          }}>
            <div style={{ font: 'var(--fw-medium) 11px/1.3 var(--font-mono)', color: 'var(--text-faint)' }}>{labels[hover] ?? ''}</div>
            <div style={{ font: 'var(--fw-semibold) 13px/1.4 var(--font-sans)', color: 'var(--text-strong)' }}>
              {format(cur[hover] ?? 0)}
              {prev && prev[hover] != null && <span style={{ color: 'var(--text-muted)', fontWeight: 400 }}> · kỳ trước {format(prev[hover])}</span>}
            </div>
          </div>
        )}
      </div>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, font: 'var(--fw-regular) 11px/1 var(--font-mono)', color: 'var(--text-faint)' }}>
        {labIdx.map((idx, i) => <span key={i}>{labels[idx] ?? ''}</span>)}
      </div>
    </div>
  );
}
