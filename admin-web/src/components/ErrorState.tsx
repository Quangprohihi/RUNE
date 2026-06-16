import { Button } from '../ds';

export function ErrorState({ message, onRetry }: { message: string; onRetry?: () => void }) {
  return (
    <div style={{ padding: 32, textAlign: 'center', background: 'var(--surface-card)', border: '1px solid var(--status-rejected-border)', borderRadius: 'var(--radius-lg)' }}>
      <div style={{ font: 'var(--fw-semibold) 14px/1.4 var(--font-sans)', color: 'var(--danger-fg)', marginBottom: 4 }}>Không tải được dữ liệu</div>
      <div style={{ font: 'var(--fw-regular) 13px/1.5 var(--font-sans)', color: 'var(--text-muted)', marginBottom: onRetry ? 14 : 0 }}>{message}</div>
      {onRetry && <Button variant="secondary" size="sm" onClick={onRetry}>Thử lại</Button>}
    </div>
  );
}
