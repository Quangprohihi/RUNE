import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { AnalyticsPage } from './AnalyticsPage';
import type { AnalyticsResponse } from '../lib/types';

const resp: AnalyticsResponse = {
  range: 'month', granularity: 'day', compare: false, rangeLabel: 'Tháng · 18/05 – 17/06',
  kpis: { activeUsers: { value: 1842, deltaPct: 6.3 }, focusMinutes: { value: 41250, deltaPct: 4.8 }, revenue: { value: 1247000, deltaPct: 9.4 }, newPro: { value: 11, deltaPct: 2 } },
  series: { label: 'Người dùng hoạt động', cur: [1, 2, 3, 4, 5], prev: null },
  bucketLabels: ['18/05', '25/05', '01/06', '08/06', '17/06'],
  funnel: [{ label: 'Cài đặt app', value: 6820, pct: 100 }, { label: 'Nâng cấp Zen Pro', value: 312, pct: 4.6 }],
  hourly: Array.from({ length: 12 }, (_, i) => ({ label: `${i * 2}-${i * 2 + 2}`, minutes: i * 5 })),
};

const aMock = vi.hoisted(() => ({ fn: vi.fn() }));
vi.mock('../lib/api', () => ({ api: { analytics: (...a: unknown[]) => aMock.fn(...a) } }));

function renderPage() { return render(<MemoryRouter><AnalyticsPage /></MemoryRouter>); }

describe('AnalyticsPage', () => {
  beforeEach(() => { aMock.fn.mockReset().mockResolvedValue(resp); });

  it('renders KPIs, chart legend, funnel, and hourly', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Zen Pro mới')).toBeInTheDocument());
    expect(screen.getByText('Phút focus')).toBeInTheDocument();
    expect(screen.getByText('Kỳ này')).toBeInTheDocument();
    expect(screen.getByText('Phễu chuyển đổi')).toBeInTheDocument();
    expect(screen.getByText('Phút focus theo khung giờ')).toBeInTheDocument();
  });

  it('re-queries when a preset is applied', async () => {
    renderPage();
    await waitFor(() => expect(aMock.fn).toHaveBeenCalled());
    fireEvent.click(screen.getByRole('button', { name: /18\/05/ }));
    fireEvent.click(screen.getByText('Quý này'));
    fireEvent.click(screen.getByText('Áp dụng'));
    await waitFor(() => {
      const last = aMock.fn.mock.calls.at(-1)![0] as { range?: string };
      expect(last.range).toBe('quarter');
    });
  });
});
