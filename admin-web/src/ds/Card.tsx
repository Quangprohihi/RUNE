import type { CSSProperties, ReactNode } from 'react';

interface CardProps {
  title?: string;
  subtitle?: string;
  padding?: 'none' | 'md';
  actions?: ReactNode;
  style?: CSSProperties;
  children?: ReactNode;
}

export function Card({ title, subtitle, padding = 'md', actions, style, children }: CardProps) {
  const bodyPad = padding === 'none' ? 0 : '16px 18px 18px';
  return (
    <section
      style={{
        background: 'var(--surface-card)',
        border: '1px solid var(--border-subtle)',
        borderRadius: 'var(--radius-lg)',
        boxShadow: 'var(--shadow-sm)',
        ...style,
      }}
    >
      {(title || subtitle || actions) && (
        <header
          style={{
            display: 'flex', alignItems: 'flex-start', justifyContent: 'space-between',
            gap: 12, padding: '14px 18px', borderBottom: '1px solid var(--border-subtle)',
          }}
        >
          <div>
            {title && <div style={{ font: 'var(--fw-semibold) 14px/1.2 var(--font-sans)', color: 'var(--text-strong)' }}>{title}</div>}
            {subtitle && <div style={{ font: 'var(--fw-regular) 12px/1.3 var(--font-sans)', color: 'var(--text-muted)', marginTop: 3 }}>{subtitle}</div>}
          </div>
          {actions}
        </header>
      )}
      <div style={{ padding: bodyPad }}>{children}</div>
    </section>
  );
}
