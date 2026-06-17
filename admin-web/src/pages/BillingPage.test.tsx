import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { BillingPage } from './BillingPage';
import type { BillingSummary, PaymentsResponse } from '../lib/types';

const summary: BillingSummary = {
  range: '30d',
  kpis: { revenue: { value: 1247000, deltaPct: 9.4 }, mrr: { value: 233250 }, arpu: { value: 2500 }, refundRate: { value: 0 } },
  packages: [
    { code: 'free', label: 'Free', priceVnd: 0, subscribers: 6508 },
    { code: 'zen_pro_monthly', label: 'Zen Pro · Monthly', priceVnd: 29000, subscribers: 4 },
    { code: 'zen_pro_yearly', label: 'Zen Pro · Yearly', priceVnd: 279000, subscribers: 2 },
  ],
};
const payments: PaymentsResponse = {
  total: 1, page: 1, pageSize: 25,
  items: [{ id: 'p1', vnpTxnRef: 'VNP123', user: 'Lê Quốc Bảo', productCode: 'zen_pro_yearly', amountVnd: 279000, status: 'paid', bankCode: 'NCB', payDate: null, paidAt: '2026-06-13T09:14:00.000Z', createdAt: '2026-06-13T09:14:00.000Z' }],
};

const { summaryMock, paymentsMock, confirmMock } = vi.hoisted(() => ({ summaryMock: vi.fn(), paymentsMock: vi.fn(), confirmMock: vi.fn() }));
vi.mock('../lib/api', () => ({ api: { billing: { summary: (...a: unknown[]) => summaryMock(...a) }, payments: (...a: unknown[]) => paymentsMock(...a), confirmPayment: (...a: unknown[]) => confirmMock(...a) } }));

function renderPage() { return render(<MemoryRouter><BillingPage /></MemoryRouter>); }

describe('BillingPage', () => {
  beforeEach(() => {
    summaryMock.mockReset().mockResolvedValue(summary);
    paymentsMock.mockReset().mockResolvedValue(payments);
    confirmMock.mockReset().mockResolvedValue({ id: 'p1', status: 'paid' });
  });

  it('renders KPIs, a transaction row, and package cards', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Doanh thu')).toBeInTheDocument());
    expect(screen.getByText('MRR')).toBeInTheDocument();
    expect(screen.getByText('ARPU')).toBeInTheDocument();
    expect(screen.getByText('Tỉ lệ hoàn tiền')).toBeInTheDocument();
    await waitFor(() => expect(screen.getByText('VNP123')).toBeInTheDocument());
    expect(screen.getByText('Lê Quốc Bảo')).toBeInTheDocument();
    // "Thành công" is both a filter button and the row's status badge — scope to the badge span.
    expect(screen.getByText('Thành công', { selector: 'span' })).toBeInTheDocument();
    expect(screen.getByText('Zen Pro · Monthly')).toBeInTheDocument();
  });

  it('passes the status filter to the payments API', async () => {
    renderPage();
    await waitFor(() => expect(paymentsMock).toHaveBeenCalled());
    fireEvent.click(screen.getByRole('button', { name: 'Thành công' }));
    await waitFor(() => {
      const last = paymentsMock.mock.calls.at(-1)![0] as { status?: string };
      expect(last.status).toBe('paid');
    });
  });

  it('confirms a pending order via the API', async () => {
    paymentsMock.mockReset().mockResolvedValue({ total: 1, page: 1, pageSize: 15, items: [{ ...payments.items[0], id: 'pend1', vnpTxnRef: 'PEND1', status: 'pending' }] });
    vi.spyOn(window, 'confirm').mockReturnValue(true);
    renderPage();
    await waitFor(() => expect(screen.getByText('PEND1')).toBeInTheDocument());
    fireEvent.click(screen.getByRole('button', { name: 'Xác nhận' }));
    await waitFor(() => expect(confirmMock).toHaveBeenCalledWith('pend1'));
  });
});
