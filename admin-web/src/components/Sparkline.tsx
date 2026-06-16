export function Sparkline({ data, color = 'var(--blue-500)' }: { data: number[]; color?: string }) {
  const W = 120, H = 34, P = 3;
  if (!data || data.length < 2) {
    // flat baseline for point-in-time KPIs with no series
    return (
      <svg viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" style={{ width: '100%', height: 34, marginTop: 'auto', color, display: 'block' }}>
        <line x1={P} y1={H - P} x2={W - P} y2={H - P} stroke="currentColor" strokeWidth={1.75} opacity={0.25} vectorEffect="non-scaling-stroke" />
      </svg>
    );
  }
  const max = Math.max(...data), min = Math.min(...data);
  const span = max - min || 1;
  const n = data.length;
  const x = (i: number) => P + (i * (W - 2 * P)) / (n - 1);
  const y = (v: number) => (H - P) - ((v - min) / span) * (H - 2 * P);
  const line = data.map((v, i) => `${x(i).toFixed(1)},${y(v).toFixed(1)}`).join(' ');
  const area = `${x(0).toFixed(1)},${H - P} ${line} ${x(n - 1).toFixed(1)},${H - P}`;
  return (
    <svg viewBox={`0 0 ${W} ${H}`} preserveAspectRatio="none" style={{ width: '100%', height: 34, marginTop: 'auto', color, display: 'block' }}>
      <polygon points={area} fill="currentColor" opacity={0.1} />
      <polyline points={line} fill="none" stroke="currentColor" strokeWidth={1.75} strokeLinecap="round" strokeLinejoin="round" vectorEffect="non-scaling-stroke" />
    </svg>
  );
}
