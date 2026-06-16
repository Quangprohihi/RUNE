import type { ReactNode } from 'react';

export type TagTone = 'neutral' | 'accent' | 'outline';

export function Tag({ tone = 'neutral', children }: { tone?: TagTone; children: ReactNode }) {
  return <span className={`zz-tag zz-tag--${tone}`}>{children}</span>;
}
