import type { ButtonHTMLAttributes, ReactNode } from 'react';

interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  label: string;
  size?: 'sm' | 'md';
  children: ReactNode;
}

export function IconButton({ label, size = 'md', className = '', children, ...rest }: IconButtonProps) {
  const cls = ['zz-iconbtn', size === 'sm' ? 'zz-iconbtn--sm' : '', className].filter(Boolean).join(' ');
  return <button className={cls} aria-label={label} title={label} {...rest}>{children}</button>;
}
