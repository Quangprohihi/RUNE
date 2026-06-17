export function LineChart({ labels, cur, prev }: { labels: string[]; cur: number[]; prev: number[] | null }) {
  const W = 620, H = 190, P = 12;
  const max = Math.max(1, ...cur, ...(prev ?? []));
  const n = Math.max(1, cur.length);
  const x = (i: number) => (n <= 1 ? W / 2 : P + (i * (W - 2 * P)) / (n - 1));
  const y = (v: number) => (H - P) - (v / max) * (H - 2 * P);
  const lineOf = (arr: number[]) => arr.map((v, i) => `${x(i).toFixed(1)},${y(v).toFixed(1)}`).join(' ');
  const line = lineOf(cur);
  const area = `${x(0).toFixed(1)},${H - P} ${line} ${x(cur.length - 1).toFixed(1)},${H - P}`;
  const gridYs = [0.25, 0.5, 0.75].map((f) => (H - P) - f * (H - 2 * P));
  const labIdx = [0, Math.floor((n - 1) * 0.25), Math.floor((n - 1) * 0.5), Math.floor((n - 1) * 0.75), n - 1];

  return (
    <div>
      <div style={{ display: 'flex', gap: 16, marginBottom: 10, font: 'var(--fw-medium) 12px/1 var(--font-sans)', color: 'var(--text-muted)' }}>
        <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}><span style={{ width: 14, height: 3, background: 'var(--blue-500)', display: 'inline-block', borderRadius: 2 }} />Kỳ này</span>
        {prev && <span style={{ display: 'inline-flex', alignItems: 'center', gap: 6 }}><span style={{ width: 14, borderTop: '2px dashed var(--slate-400)', display: 'inline-block' }} />Kỳ trước</span>}
      </div>
      <svg viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" style={{ width: '100%', height: 190, display: 'block' }}>
        {gridYs.map((gy, i) => <line key={i} x1={P} y1={gy} x2={W - P} y2={gy} stroke="var(--border-subtle)" strokeWidth={1} vectorEffect="non-scaling-stroke" />)}
        <polygon points={area} fill="var(--blue-500)" opacity={0.09} />
        {prev && <polyline points={lineOf(prev)} fill="none" stroke="var(--slate-400)" strokeWidth={1.75} strokeDasharray="5 4" vectorEffect="non-scaling-stroke" />}
        <polyline points={line} fill="none" stroke="var(--blue-500)" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" vectorEffect="non-scaling-stroke" />
      </svg>
      <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 6, font: 'var(--fw-regular) 11px/1 var(--font-mono)', color: 'var(--text-faint)' }}>
        {labIdx.map((idx, i) => <span key={i}>{labels[idx] ?? ''}</span>)}
      </div>
    </div>
  );
}
