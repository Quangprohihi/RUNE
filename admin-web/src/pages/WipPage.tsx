import { useParams } from 'react-router-dom';

export function WipPage() {
  const { screen } = useParams();
  return (
    <section style={{ padding: '24px 32px 90px' }}>
      <div style={{ padding: 40, textAlign: 'center', background: 'var(--surface-card)', border: '1px dashed var(--border-default)', borderRadius: 'var(--radius-lg)', color: 'var(--text-muted)', font: 'var(--fw-medium) 14px/1.5 var(--font-sans)' }}>
        Màn <b style={{ color: 'var(--text-strong)', fontFamily: 'var(--font-mono)' }}>{screen}</b> đang được xây dựng.
      </div>
    </section>
  );
}
