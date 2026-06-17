import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { TasksPage } from './TasksPage';
import type { TaskConfigResponse } from '../lib/types';

const cfg: TaskConfigResponse = {
  kpis: { activeTasks: 2, dailyTokenFaucet: 50, activeMilestones: 1 },
  tasks: [
    { id: 't1', code: 'daily_login', title: 'Daily Login', description: 'd', taskType: 'daily_login', targetValue: 1, rewardTokens: 20, rewardDiamonds: 1, rewardPoints: 120, isActive: true },
  ],
  milestones: [
    { id: 'm1', pointsRequired: 200, rewardTokens: 30, rewardDiamonds: 2, isActive: true },
  ],
};

const m = vi.hoisted(() => ({ taskConfig: vi.fn(), updateTask: vi.fn(), updateMilestone: vi.fn() }));
vi.mock('../lib/api', () => ({
  api: {
    taskConfig: (...a: unknown[]) => m.taskConfig(...a),
    updateTask: (...a: unknown[]) => m.updateTask(...a),
    updateMilestone: (...a: unknown[]) => m.updateMilestone(...a),
  },
}));

function renderPage() { return render(<MemoryRouter><TasksPage /></MemoryRouter>); }

describe('TasksPage', () => {
  beforeEach(() => {
    m.taskConfig.mockReset().mockResolvedValue(cfg);
    m.updateTask.mockReset().mockResolvedValue(cfg.tasks[0]);
    m.updateMilestone.mockReset().mockResolvedValue(cfg.milestones[0]);
  });

  it('renders KPIs, a task row, and the milestone section', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Nhiệm vụ đang bật')).toBeInTheDocument());
    expect(screen.getByText('Token phát / ngày')).toBeInTheDocument();
    expect(await screen.findByText('Daily Login')).toBeInTheDocument();
    expect(screen.getByText('daily_login')).toBeInTheDocument(); // raw code, unique
    expect(screen.getByText('Mốc điểm trong ngày')).toBeInTheDocument(); // milestone card title
  });

  it('edits a task reward and calls updateTask', async () => {
    renderPage();
    await screen.findByText('Daily Login');
    fireEvent.click(screen.getAllByText('Sửa')[0]);
    const tok = await screen.findByLabelText('Token thưởng');
    fireEvent.change(tok, { target: { value: '35' } });
    fireEvent.click(screen.getByText('Lưu'));
    await waitFor(() => {
      expect(m.updateTask).toHaveBeenCalledWith('t1', { rewardTokens: 35, rewardDiamonds: 1, rewardPoints: 120, isActive: true });
    });
  });
});
