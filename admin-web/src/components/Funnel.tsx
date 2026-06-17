import { formatInt } from '../lib/format';

export function Funnel({ steps }: { steps: { label: string; value: number; pct: number }[] }) {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
      {steps.map((s, i) => {
        const last = i === steps.length - 1;
        return (
          <div key={s.label}>
            <div style={{ display: 'flex', justifyContent: 'space-between', font: 'var(--fw-medium) 13px/1 var(--font-sans)', color: 'var(--text-body)', marginBottom: 5 }}>
              <span>{s.label}</span>
              <span style={{ fontFamily: 'var(--font-mono)', color: 'var(--text-strong)', fontWeight: 600 }}>{formatInt(s.value)} · {s.pct}%</span>
            </div>
            <div style={{ height: 8, borderRadius: 'var(--radius-pill)', background: 'var(--surface-sunken)', overflow: 'hidden' }}>
              <div style={{ width: `${Math.max(2, Math.min(100, s.pct))}%`, height: '100%', borderRadius: 'var(--radius-pill)', background: last ? 'var(--accent)' : 'var(--brand)' }} />
            </div>
          </div>
        );
      })}
    </div>
  );
}
