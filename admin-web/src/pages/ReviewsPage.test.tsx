import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { ReviewsPage } from './ReviewsPage';
import type { ReviewsResponse } from '../lib/types';

const resp: ReviewsResponse = {
  items: [
    {
      id: 'rv-11', author: 'Lý Phương Thảo', rating: 5, at: '2026-07-24T08:27:00.000Z',
      platform: 'Android', appVersion: '1.0.0',
      text: 'Mình thích việc chỉ cần bấm một cái là bắt đầu phiên Pomodoro luôn.',
      tags: [{ theme: 'pomodoro', tone: 'praise' }],
    },
    {
      id: 'rv-06', author: 'Vũ Đình Nam', rating: 3, at: '2026-07-19T10:48:00.000Z',
      platform: 'Android', appVersion: '1.0.0',
      text: 'Pet vẫn đang bị khóa nhưng tôi muốn có thêm nhiều Pet.',
      tags: [{ theme: 'pet', tone: 'request' }],
    },
    {
      id: 'rv-18', author: 'Chu Anh Khoa', rating: 2, at: '2026-07-31T15:04:00.000Z',
      platform: 'Android', appVersion: '1.0.0',
      text: 'Giao diện app khá thô sơ.',
      tags: [{ theme: 'ui', tone: 'issue' }],
    },
  ],
  themes: [
    { key: 'pet', label: 'Nuôi pet & sưu tầm' },
    { key: 'pomodoro', label: 'Pomodoro' },
    { key: 'ui', label: 'Giao diện & trải nghiệm' },
  ],
  summary: {
    total: 3, average: 3.3,
    distribution: [
      { stars: 5, count: 1, pct: 33.3 }, { stars: 4, count: 0, pct: 0 }, { stars: 3, count: 1, pct: 33.3 },
      { stars: 2, count: 1, pct: 33.3 }, { stars: 1, count: 0, pct: 0 },
    ],
    sentiment: { positive: 1, neutral: 1, negative: 1 },
    satisfactionPct: 33.3, requestCount: 1, issueCount: 1,
    themes: [
      { key: 'pet', label: 'Nuôi pet & sưu tầm', mentions: 1, praise: 0, request: 1, issue: 0 },
      { key: 'pomodoro', label: 'Pomodoro', mentions: 1, praise: 1, request: 0, issue: 0 },
      { key: 'ui', label: 'Giao diện & trải nghiệm', mentions: 1, praise: 0, request: 0, issue: 1 },
    ],
  },
};

const m = vi.hoisted(() => ({ reviews: vi.fn() }));
vi.mock('../lib/api', () => ({ api: { reviews: () => m.reviews() } }));

function renderPage() { return render(<MemoryRouter><ReviewsPage /></MemoryRouter>); }

describe('ReviewsPage', () => {
  beforeEach(() => { m.reviews.mockReset().mockResolvedValue(resp); });

  it('renders the summary strip', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Điểm trung bình')).toBeInTheDocument());
    expect(screen.getByText('3,3')).toBeInTheDocument();
    expect(screen.getByText('Tỉ lệ hài lòng')).toBeInTheDocument();
    expect(screen.getByText('1 đánh giá từ 4★')).toBeInTheDocument();
    expect(screen.getByText('Yêu cầu tính năng')).toBeInTheDocument();
    expect(screen.getByText('Lỗi & điểm chê')).toBeInTheDocument();
  });

  it('renders the distribution, sentiment donut and theme breakdown', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Phân bố số sao')).toBeInTheDocument());
    expect(screen.getByText('Sắc thái đánh giá')).toBeInTheDocument();
    expect(screen.getByText('Tích cực')).toBeInTheDocument();
    expect(screen.getByText('Chủ đề người dùng nhắc tới')).toBeInTheDocument();
    expect(screen.getByText('Nuôi pet & sưu tầm')).toBeInTheDocument();
  });

  it('lists every review with author, text and tag', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Lý Phương Thảo')).toBeInTheDocument());
    expect(screen.getByText('Vũ Đình Nam')).toBeInTheDocument();
    expect(screen.getByText('Giao diện app khá thô sơ.')).toBeInTheDocument();
    expect(screen.getByText('Pomodoro · khen')).toBeInTheDocument();
    expect(screen.getByText('Nuôi pet & sưu tầm · mong muốn')).toBeInTheDocument();
    expect(screen.getByText('Giao diện & trải nghiệm · lỗi / chê')).toBeInTheDocument();
  });

  it('filters by star rating', async () => {
    renderPage();
    await screen.findByText('Lý Phương Thảo');
    fireEvent.click(screen.getByRole('button', { name: '5★' }));
    expect(screen.getByText('Lý Phương Thảo')).toBeInTheDocument();
    expect(screen.queryByText('Vũ Đình Nam')).not.toBeInTheDocument();

    fireEvent.click(screen.getByRole('button', { name: '1–2★' }));
    expect(screen.getByText('Chu Anh Khoa')).toBeInTheDocument();
    expect(screen.queryByText('Lý Phương Thảo')).not.toBeInTheDocument();
  });

  it('filters by theme', async () => {
    renderPage();
    await screen.findByText('Lý Phương Thảo');
    fireEvent.change(screen.getByLabelText('Lọc theo chủ đề'), { target: { value: 'pet' } });
    expect(screen.getByText('Vũ Đình Nam')).toBeInTheDocument();
    expect(screen.queryByText('Lý Phương Thảo')).not.toBeInTheDocument();
  });

  it('searches inside the review text and shows an empty state on no match', async () => {
    renderPage();
    await screen.findByText('Lý Phương Thảo');
    const box = screen.getByPlaceholderText('Tìm trong nội dung đánh giá…');
    fireEvent.change(box, { target: { value: 'thô sơ' } });
    expect(screen.getByText('Giao diện app khá thô sơ.')).toBeInTheDocument();
    expect(screen.queryByText('Lý Phương Thảo')).not.toBeInTheDocument();

    fireEvent.change(box, { target: { value: 'zzzz' } });
    expect(screen.getByText('Không có đánh giá nào khớp bộ lọc.')).toBeInTheDocument();
  });

  it('surfaces a retryable error when the request fails', async () => {
    m.reviews.mockRejectedValueOnce(new Error('boom'));
    renderPage();
    await waitFor(() => expect(screen.getByText('Không tải được dữ liệu')).toBeInTheDocument());
    m.reviews.mockResolvedValue(resp);
    fireEvent.click(screen.getByText('Thử lại'));
    await waitFor(() => expect(screen.getByText('Điểm trung bình')).toBeInTheDocument());
  });
});
