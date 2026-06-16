import type { InputHTMLAttributes, ReactNode } from 'react';

interface InputProps extends Omit<InputHTMLAttributes<HTMLInputElement>, 'prefix'> {
  prefix?: ReactNode;
}

export function Input({ prefix, className = '', ...rest }: InputProps) {
  const inputCls = ['zz-input', prefix ? 'zz-input--with-prefix' : '', className].filter(Boolean).join(' ');
  return (
    <span className="zz-input-wrap">
      {prefix}
      <input className={inputCls} {...rest} />
    </span>
  );
}
