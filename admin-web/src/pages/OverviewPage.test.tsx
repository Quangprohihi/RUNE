import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { OverviewPage } from './OverviewPage';
import type { OverviewResponse, HealthResponse, ReviewsResponse } from '../lib/types';

const { overview, health, reviews } = vi.hoisted(() => {
  const overview: OverviewResponse = {
    range: 'today',
    kpis: {
      dau: { value: 1842, deltaPct: 6.3, spark: [1, 2, 3, 4, 5, 6, 7] },
      stickiness: { value: 27, deltaPct: null, spark: [] },
      focusMinutes: { value: 41250, deltaPct: 4.8, spark: [1, 2, 3] },
      focusSessions: { value: 1310, deltaPct: -2.1, spark: [3, 2, 1] },
      premiumUsers: { value: 312, deltaPct: null, spark: [] },
      revenue: { value: 1247000, deltaPct: 9.4, spark: [10, 20, 30, 40, 50, 60, 70] },
      avgStreak: { value: 4.2, deltaPct: null, spark: [] },
      conversion: { value: 4.6, deltaPct: null, spark: [] },
    },
    goals: [{ label: 'Doanh thu quý', value: 78, max: 100, unit: '%' }],
    recent: [{ eventType: 'focus_completed', title: 'hoàn thành phiên Deep Focus 45′', subtitle: 'đồng hành Eagle', actor: 'Trần Minh Anh', at: new Date().toISOString() }],
    mix: {
      plans: { free: 41, pro: 9 },
      revenueByProvider: [
        { provider: 'vietqr', amountVnd: 58000 },
        { provider: 'vnpay', amountVnd: 29000 },
      ],
    },
  };
  const health: HealthResponse = { db: 'ok', vnpay: true, gemini: true, apiLatencyMs: 142 };
  const reviews: ReviewsResponse = {
    items: [{
      id: 'rv-01', author: 'Nguyễn Ngọc Ánh', rating: 4, at: '2026-07-14T09:12:00.000Z',
      platform: 'Android', appVersion: '1.0.0', text: 'Giao diện bắt mắt.',
      tags: [{ theme: 'pet', tone: 'request' }],
    }],
    themes: [{ key: 'pet', label: 'Nuôi pet & sưu tầm' }],
    summary: {
      total: 20, average: 3.6,
      distribution: [
        { stars: 5, count: 3, pct: 15 }, { stars: 4, count: 8, pct: 40 }, { stars: 3, count: 7, pct: 35 },
        { stars: 2, count: 2, pct: 10 }, { stars: 1, count: 0, pct: 0 },
      ],
      sentiment: { positive: 11, neutral: 7, negative: 2 },
      satisfactionPct: 55, requestCount: 11, issueCount: 5,
      themes: [{ key: 'pet', label: 'Nuôi pet & sưu tầm', mentions: 8, praise: 2, request: 7, issue: 0 }],
    },
  };
  return { overview, health, reviews };
});

vi.mock('../lib/api', () => ({
  api: {
    overview: vi.fn().mockResolvedValue(overview),
    health: vi.fn().mockResolvedValue(health),
    reviews: vi.fn().mockResolvedValue(reviews),
  },
}));

import { api } from '../lib/api';

function renderPage() {
  return render(<MemoryRouter><OverviewPage /></MemoryRouter>);
}

describe('OverviewPage', () => {
  beforeEach(() => vi.clearAllMocks());

  it('renders the trimmed KPI set and the DAU value once loaded', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Người dùng hoạt động')).toBeInTheDocument());
    expect(screen.getByText('1.842')).toBeInTheDocument();
    expect(screen.getByText('Tổng phút focus')).toBeInTheDocument();
    expect(screen.getByText('Người dùng Zen Pro')).toBeInTheDocument();
    expect(screen.getByText('Free → Zen Pro')).toBeInTheDocument();
  });

  it('does not render the removed KPI tiles', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Người dùng hoạt động')).toBeInTheDocument());
    expect(screen.queryByText(/\/ ngày/)).not.toBeInTheDocument();
    expect(screen.queryByText('Độ bám DAU/MAU')).not.toBeInTheDocument();
    expect(screen.queryByText('Phiên focus hoàn thành')).not.toBeInTheDocument();
    expect(screen.queryByText('Streak trung bình')).not.toBeInTheDocument();
  });

  it('keeps the revenue label in sync with the selected range', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Doanh thu hôm nay')).toBeInTheDocument());

    fireEvent.click(screen.getByText('30 ngày'));
    await waitFor(() => expect(screen.getByText('Doanh thu 30 ngày')).toBeInTheDocument());
    expect(screen.queryByText('Doanh thu hôm nay')).not.toBeInTheDocument();
    expect(api.overview).toHaveBeenLastCalledWith('30d');

    fireEvent.click(screen.getByText('Quý'));
    // "Doanh thu quý" giờ xuất hiện 2 nơi: thẻ KPI + nhãn trong "Mục tiêu quý"
    await waitFor(() => expect(screen.getAllByText('Doanh thu quý').length).toBe(2));
  });

  it('renders the two trend charts', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Xu hướng doanh thu')).toBeInTheDocument());
    expect(screen.getByText('Xu hướng người dùng hoạt động')).toBeInTheDocument();
  });

  it('renders the composition donuts with legend values', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Cơ cấu người dùng')).toBeInTheDocument());
    expect(screen.getByText('Doanh thu theo cổng thanh toán')).toBeInTheDocument();
    // plan mix legend: Free 41 · Zen Pro 9 (9 also appears as the KPI value → getAllByText)
    expect(screen.getByText('Free')).toBeInTheDocument();
    expect(screen.getByText('41')).toBeInTheDocument();
    // provider legend with formatted money
    expect(screen.getByText('VietQR')).toBeInTheDocument();
    expect(screen.getByText('VNPay')).toBeInTheDocument();
    expect(screen.getByText('58k đ')).toBeInTheDocument();
    expect(screen.getByText('29k đ')).toBeInTheDocument();
  });

  it('shows the recent activity actor', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Trần Minh Anh')).toBeInTheDocument());
  });

  it('summarises user reviews with the average, sentiment split and top request', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Phản hồi người dùng')).toBeInTheDocument());
    expect(screen.getByText('Khảo sát bản dùng thử · 20 đánh giá')).toBeInTheDocument();
    expect(screen.getByLabelText('3.6 trên 5 sao')).toBeInTheDocument();
    expect(screen.getByText('11 lượt từ 4★ trở lên')).toBeInTheDocument();
    expect(screen.getByText('Tích cực 11')).toBeInTheDocument();
    expect(screen.getByText('Nuôi pet & sưu tầm')).toBeInTheDocument();
    expect(screen.getByText('Xem tất cả →')).toHaveAttribute('href', '/reviews');
  });
});
