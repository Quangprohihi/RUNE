import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MemoryRouter, Routes, Route } from 'react-router-dom';
import { UserDetailPage } from './UserDetailPage';
import type { UserDetail } from '../lib/types';

const detail: UserDetail = {
  id: 'u1', email: 'a@b.c', displayName: 'Nguyễn Thị Hương', provider: 'google', createdAt: '2026-03-12T00:00:00.000Z',
  status: 'active', lastLoginAt: null,
  subscription: { plan: 'premium', status: 'active', expiresAt: '2026-07-13T00:00:00.000Z' },
  pet: { name: 'Kiki', species: 'Red Fox', level: 12, exp: 340, expToNext: 500, energy: 80, mood: 76, hunger: 72, love: 68 },
  wallet: { tokens: 1234, diamonds: 20, energy: 50 },
  streak: { currentStreak: 17, bestStreak: 31 },
  focusSessions: [{ id: 's1', label: 'Ôn thi PRM393', plannedMinutes: 45, companionCode: 'Eagle', status: 'completed', startedAt: '2026-06-13T00:00:00.000Z' }],
  activityEvents: [],
  _count: { refreshTokens: 2 },
};

const { detailMock, subMock, logoutMock } = vi.hoisted(() => ({ detailMock: vi.fn(), subMock: vi.fn(), logoutMock: vi.fn() }));
vi.mock('../lib/api', () => ({ api: { userDetail: (...a: unknown[]) => detailMock(...a), userSubscription: (...a: unknown[]) => subMock(...a), forceLogout: (...a: unknown[]) => logoutMock(...a) } }));

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/users/u1']}>
      <Routes><Route path="/users/:id" element={<UserDetailPage />} /></Routes>
    </MemoryRouter>,
  );
}

describe('UserDetailPage', () => {
  beforeEach(() => {
    detailMock.mockReset().mockResolvedValue(detail);
    subMock.mockReset().mockResolvedValue({ plan: 'free', status: 'expired', expiresAt: null });
    logoutMock.mockReset().mockResolvedValue({ ok: true, revoked: 1 });
  });

  it('renders the user header, subscription, and pet', async () => {
    renderPage();
    // name appears in both breadcrumb and header
    await waitFor(() => expect(screen.getAllByText('Nguyễn Thị Hương').length).toBeGreaterThan(0));
    expect(screen.getByText('Gói đăng ký')).toBeInTheDocument();
    expect(screen.getByText(/Kiki/)).toBeInTheDocument();
  });

  it('cancels the subscription via the API', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(true);
    renderPage();
    await waitFor(() => expect(screen.getByRole('button', { name: 'Hủy' })).toBeInTheDocument());
    fireEvent.click(screen.getByRole('button', { name: 'Hủy' }));
    await waitFor(() => expect(subMock).toHaveBeenCalledWith('u1', expect.objectContaining({ action: 'cancel' })));
  });

  it('extends the subscription via the API', async () => {
    vi.spyOn(window, 'confirm').mockReturnValue(true);
    renderPage();
    await waitFor(() => expect(screen.getByRole('button', { name: 'Gia hạn +30' })).toBeInTheDocument());
    fireEvent.click(screen.getByRole('button', { name: 'Gia hạn +30' }));
    await waitFor(() => expect(subMock).toHaveBeenCalledWith('u1', { action: 'extend', days: 30 }));
  });
});
