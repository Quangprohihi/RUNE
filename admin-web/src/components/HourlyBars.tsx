export function HourlyBars({ bars }: { bars: { label: string; minutes: number }[] }) {
  const max = Math.max(1, ...bars.map((b) => b.minutes));
  const peak = bars.reduce((m, b, i) => (b.minutes > bars[m].minutes ? i : m), 0);
  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'flex-end', gap: 6, height: 140 }}>
        {bars.map((b, i) => (
          <div key={b.label} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'flex-end', height: '100%' }}>
            <div title={`${b.minutes}′`} style={{ width: '100%', height: `${Math.max(2, (b.minutes / max) * 100)}%`, borderRadius: '4px 4px 0 0', background: i === peak ? 'var(--blue-600)' : 'var(--blue-300)' }} />
          </div>
        ))}
      </div>
      <div style={{ display: 'flex', gap: 6, marginTop: 6 }}>
        {bars.map((b) => <span key={b.label} style={{ flex: 1, textAlign: 'center', font: 'var(--fw-regular) 9px/1 var(--font-mono)', color: 'var(--text-faint)' }}>{b.label.split('-')[0]}</span>)}
      </div>
    </div>
  );
}
