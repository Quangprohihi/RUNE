import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { OverviewPage } from './OverviewPage';
import type { OverviewResponse, HealthResponse } from '../lib/types';

const { overview, health } = vi.hoisted(() => {
  const overview: OverviewResponse = {
    range: 'today',
    kpis: {
      dau: { value: 1842, deltaPct: 6.3, spark: [1, 2, 3, 4] },
      stickiness: { value: 27, deltaPct: null, spark: [] },
      focusMinutes: { value: 41250, deltaPct: 4.8, spark: [1, 2, 3] },
      focusSessions: { value: 1310, deltaPct: -2.1, spark: [3, 2, 1] },
      premiumUsers: { value: 312, deltaPct: null, spark: [] },
      revenue: { value: 1247000, deltaPct: 9.4, spark: [1, 2] },
      avgStreak: { value: 4.2, deltaPct: null, spark: [] },
      conversion: { value: 4.6, deltaPct: null, spark: [] },
    },
    goals: [{ label: 'Doanh thu quý', value: 78, max: 100, unit: '%' }],
    recent: [{ eventType: 'focus_completed', title: 'hoàn thành phiên Deep Focus 45′', subtitle: 'đồng hành Eagle', actor: 'Trần Minh Anh', at: new Date().toISOString() }],
  };
  const health: HealthResponse = { db: 'ok', vnpay: true, gemini: true, apiLatencyMs: 142 };
  return { overview, health };
});

vi.mock('../lib/api', () => ({
  api: {
    overview: vi.fn().mockResolvedValue(overview),
    health: vi.fn().mockResolvedValue(health),
  },
}));

function renderPage() {
  return render(<MemoryRouter><OverviewPage /></MemoryRouter>);
}

describe('OverviewPage', () => {
  beforeEach(() => vi.clearAllMocks());

  it('renders the 8 KPI labels and the DAU value once loaded', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Người dùng hoạt động / ngày')).toBeInTheDocument());
    expect(screen.getByText('1.842')).toBeInTheDocument();
    expect(screen.getByText('Doanh thu hôm nay')).toBeInTheDocument();
    expect(screen.getByText('Streak trung bình')).toBeInTheDocument();
  });

  it('shows the recent activity actor', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Trần Minh Anh')).toBeInTheDocument());
  });
});
