import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { LoginPage } from './LoginPage';

const navigateMock = vi.fn();
vi.mock('react-router-dom', async (orig) => ({
  ...(await orig<typeof import('react-router-dom')>()),
  useNavigate: () => navigateMock,
}));

const loginMock = vi.fn();
vi.mock('../lib/api', () => ({ api: { login: (...a: unknown[]) => loginMock(...a) } }));

function renderPage() { return render(<MemoryRouter><LoginPage /></MemoryRouter>); }

describe('LoginPage (redesigned)', () => {
  beforeEach(() => { localStorage.clear(); sessionStorage.clear(); navigateMock.mockClear(); loginMock.mockReset(); });

  it('renders the redesigned brand + form controls', () => {
    renderPage();
    expect(screen.getByText('Đăng nhập quản trị')).toBeInTheDocument();
    expect(screen.getByText('Khu vực giới hạn — chỉ dành cho quản trị viên ZenZoo.')).toBeInTheDocument();
    expect(screen.getByText('Ghi nhớ thiết bị này')).toBeInTheDocument();
    expect(screen.getByText('Quên mật khẩu?')).toBeInTheDocument();
    expect(screen.getByRole('button', { name: /Đăng nhập với Google Workspace/ })).toBeInTheDocument();
  });

  it('toggles password visibility', () => {
    renderPage();
    const pass = screen.getByPlaceholderText('••••••••') as HTMLInputElement;
    expect(pass.type).toBe('password');
    fireEvent.click(screen.getByLabelText('Hiện/ẩn mật khẩu'));
    expect(pass.type).toBe('text');
  });

  it('logs in then navigates home', async () => {
    loginMock.mockResolvedValue({ token: 't', admin: { id: '1', email: 'a@b.c', name: 'A', role: 'super-admin' } });
    renderPage();
    fireEvent.change(screen.getByPlaceholderText('admin@zenzoo.app'), { target: { value: 'admin@zenzoo.app' } });
    fireEvent.change(screen.getByPlaceholderText('••••••••'), { target: { value: 'zenzoo-admin' } });
    fireEvent.click(screen.getByRole('button', { name: 'Đăng nhập' }));
    await waitFor(() => expect(navigateMock).toHaveBeenCalledWith('/', { replace: true }));
    expect(localStorage.getItem('zz_admin_token')).toBe('t');
  });

  it('shows the server error on bad login', async () => {
    loginMock.mockRejectedValue(Object.assign(new Error('Sai email hoặc mật khẩu quản trị'), { name: 'ApiError', status: 401 }));
    renderPage();
    fireEvent.click(screen.getByRole('button', { name: 'Đăng nhập' }));
    await waitFor(() => expect(screen.getByRole('alert')).toHaveTextContent('Sai email hoặc mật khẩu quản trị'));
  });

  it('placeholder buttons show a "đang phát triển" note', () => {
    renderPage();
    fireEvent.click(screen.getByText('Quên mật khẩu?'));
    expect(screen.getByText(/đang phát triển/i)).toBeInTheDocument();
  });
});
