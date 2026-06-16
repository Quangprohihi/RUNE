import type { ReactNode } from 'react';
import type { UserStatus } from '../lib/types';

export type DesignStatus =
  | 'draft' | 'pending' | 'progress' | 'review'
  | 'approved' | 'public' | 'suspended' | 'rejected';

const SOLID: Record<DesignStatus, string> = {
  draft: 'var(--status-draft-solid)',
  pending: 'var(--status-pending-solid)',
  progress: 'var(--status-progress-solid)',
  review: 'var(--status-review-solid)',
  approved: 'var(--status-approved-solid)',
  public: 'var(--status-public-solid)',
  suspended: 'var(--status-suspended-solid)',
  rejected: 'var(--status-rejected-solid)',
};

export function StatusBadge({
  status, pulse = false, children,
}: { status: DesignStatus; pulse?: boolean; children: ReactNode }) {
  const cls = ['zz-badge', pulse ? 'zz-badge--pulse' : ''].filter(Boolean).join(' ');
  return (
    <span
      className={cls}
      style={{
        background: `var(--status-${status}-bg)`,
        color: `var(--status-${status}-fg)`,
        borderColor: `var(--status-${status}-border)`,
      }}
    >
      <span className="zz-badge__dot" style={{ background: SOLID[status] }} />
      {children}
    </span>
  );
}

export function statusFromUserStatus(s: UserStatus): { status: DesignStatus; label: string } {
  switch (s) {
    case 'review': return { status: 'pending', label: 'Đang xem xét' };
    case 'suspended': return { status: 'suspended', label: 'Tạm khóa' };
    case 'active':
    default: return { status: 'approved', label: 'Active' };
  }
}
