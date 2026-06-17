import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { UserMenu } from './UserMenu';
import { setToken, getToken } from '../lib/auth';

const navigateMock = vi.fn();
vi.mock('react-router-dom', async (orig) => ({
  ...(await orig<typeof import('react-router-dom')>()),
  useNavigate: () => navigateMock,
}));

describe('UserMenu', () => {
  beforeEach(() => { localStorage.clear(); sessionStorage.clear(); navigateMock.mockClear(); });

  it('opens the menu and logs out', async () => {
    setToken('tok', true);
    render(<MemoryRouter><UserMenu /></MemoryRouter>);
    expect(screen.queryByText('Đăng xuất')).toBeNull();
    fireEvent.click(screen.getByLabelText('Tài khoản quản trị'));
    expect(screen.getByText('Đăng xuất')).toBeInTheDocument();
    fireEvent.click(screen.getByText('Đăng xuất'));
    await waitFor(() => expect(navigateMock).toHaveBeenCalledWith('/login', { replace: true }));
    expect(getToken()).toBeNull();
  });
});
