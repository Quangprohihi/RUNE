import { Link, useParams } from 'react-router-dom';

export function UserDetailPage() {
  const { id } = useParams();
  return (
    <section style={{ padding: '20px 32px 90px' }}>
      <div style={{ font: 'var(--fw-regular) 13px/1 var(--font-sans)', color: 'var(--text-muted)', marginBottom: 14 }}>
        <Link to="/users" style={{ color: 'var(--text-link)' }}>Người dùng</Link> · <span style={{ fontFamily: 'var(--font-mono)' }}>{id}</span>
      </div>
      <div style={{ padding: 40, textAlign: 'center', background: 'var(--surface-card)', border: '1px dashed var(--border-default)', borderRadius: 'var(--radius-lg)', color: 'var(--text-muted)', font: 'var(--fw-medium) 14px/1.5 var(--font-sans)' }}>
        Hồ sơ chi tiết người dùng <b style={{ color: 'var(--text-strong)', fontFamily: 'var(--font-mono)' }}>{id}</b> sẽ được dựng ở giai đoạn sau.
      </div>
    </section>
  );
}
