export function Skeleton({ height = 16, width = '100%', radius = 6 }: { height?: number; width?: number | string; radius?: number }) {
  return <span style={{ display: 'block', height, width, borderRadius: radius, background: 'linear-gradient(90deg, var(--slate-100), var(--slate-200), var(--slate-100))', backgroundSize: '200% 100%', animation: 'zzshimmer 1.2s ease-in-out infinite' }} />;
}

export function KpiGridSkeleton() {
  return (
    <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,minmax(0,1fr))', gap: 14, marginBottom: 22 }}>
      {Array.from({ length: 8 }).map((_, i) => (
        <div key={i} style={{ minHeight: 150, padding: 16, background: 'var(--surface-card)', border: '1px solid var(--border-subtle)', borderRadius: 'var(--radius-lg)' }}>
          <Skeleton height={12} width="60%" />
          <div style={{ height: 12 }} />
          <Skeleton height={26} width="45%" />
        </div>
      ))}
    </div>
  );
}
