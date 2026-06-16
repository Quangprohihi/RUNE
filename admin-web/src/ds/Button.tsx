import type { ButtonHTMLAttributes, ReactNode } from 'react';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary';
  size?: 'sm' | 'md';
  children: ReactNode;
}

export function Button({ variant = 'primary', size = 'md', className = '', children, ...rest }: ButtonProps) {
  const cls = ['zz-btn', `zz-btn--${variant}`, size === 'sm' ? 'zz-btn--sm' : '', className].filter(Boolean).join(' ');
  return <button className={cls} {...rest}>{children}</button>;
}
