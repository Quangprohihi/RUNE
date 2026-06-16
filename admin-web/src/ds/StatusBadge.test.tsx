import { describe, it, expect } from 'vitest';
import { render } from '@testing-library/react';
import { StatusBadge, statusFromUserStatus } from './StatusBadge';

describe('statusFromUserStatus', () => {
  it('maps account status to a design status + label', () => {
    expect(statusFromUserStatus('active')).toEqual({ status: 'approved', label: 'Active' });
    expect(statusFromUserStatus('review')).toEqual({ status: 'pending', label: 'Đang xem xét' });
    expect(statusFromUserStatus('suspended')).toEqual({ status: 'suspended', label: 'Tạm khóa' });
  });
});

describe('StatusBadge', () => {
  it('renders the label and applies the status class', () => {
    const { getByText } = render(<StatusBadge status="public" pulse>Đang chạy</StatusBadge>);
    const el = getByText('Đang chạy').closest('.zz-badge')!;
    expect(el).toBeTruthy();
    expect(el.className).toContain('zz-badge--pulse');
  });
});
