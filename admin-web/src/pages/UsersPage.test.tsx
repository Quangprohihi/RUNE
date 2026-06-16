import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { UsersPage } from './UsersPage';
import type { UsersResponse } from '../lib/types';

const page1: UsersResponse = {
  total: 2, page: 1, pageSize: 25,
  items: [
    { id: 'u1', email: 'huong.nt@gmail.com', displayName: 'Nguyễn Thị Hương', provider: 'google', createdAt: '2026-03-12T00:00:00.000Z', plan: 'premium', status: 'active', level: 12, streak: 17, lastLoginAt: '2026-06-13T09:14:00.000Z' },
    { id: 'u2', email: 'nam.vh@fpt.edu.vn', displayName: 'Vũ Hoàng Nam', provider: 'password', createdAt: '2026-05-07T00:00:00.000Z', plan: 'free', status: 'suspended', level: 5, streak: 0, lastLoginAt: null },
  ],
};

const { usersMock } = vi.hoisted(() => ({ usersMock: vi.fn() }));
vi.mock('../lib/api', () => ({ api: { users: (...a: unknown[]) => usersMock(...a) } }));

function renderPage() {
  return render(<MemoryRouter><UsersPage /></MemoryRouter>);
}

describe('UsersPage', () => {
  beforeEach(() => { usersMock.mockClear(); usersMock.mockResolvedValue(page1); });

  it('renders user rows with status labels', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Nguyễn Thị Hương')).toBeInTheDocument());
    // 'Active' and 'Tạm khóa' also appear as filter-tab buttons; scope to the status badge span.
    expect(screen.getByText('Active', { selector: 'span' })).toBeInTheDocument();
    expect(screen.getByText('Tạm khóa', { selector: 'span' })).toBeInTheDocument();
    expect(screen.getByText('huong.nt@gmail.com')).toBeInTheDocument();
  });

  it('passes the status filter to the API when a tab is clicked', async () => {
    renderPage();
    await waitFor(() => expect(usersMock).toHaveBeenCalled());
    fireEvent.click(screen.getByText('Tạm khóa', { selector: 'button' }));
    await waitFor(() => {
      const lastCall = usersMock.mock.calls.at(-1)![0] as { status?: string };
      expect(lastCall.status).toBe('suspended');
    });
  });

  it('has an export CSV button', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Xuất CSV')).toBeInTheDocument());
  });
});
