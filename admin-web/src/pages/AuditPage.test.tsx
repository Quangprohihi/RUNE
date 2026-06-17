import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { AuditPage } from './AuditPage';
import type { AdminAuditResponse, WalletAuditResponse } from '../lib/types';

const adminResp: AdminAuditResponse = {
  total: 2, page: 1, pageSize: 15,
  items: [
    { id: 'a1', at: '2026-06-17T10:00:00.000Z', actorId: 'adm_super', actorEmail: 'admin@zenzoo.app', actorRole: 'super-admin', action: 'package.update', resourceType: 'package', resourceId: 'zen_pro_monthly', ip: '127.0.0.1', metadata: { amountVnd: 29000 } },
    { id: 'a2', at: '2026-06-17T09:00:00.000Z', actorId: 'adm_mod', actorEmail: 'mod@zenzoo.app', actorRole: 'moderator', action: 'subscription.extend', resourceType: 'user', resourceId: '80b9b182-b9cd-452b-975e-bccc01c9a291', ip: '10.0.0.8', metadata: { days: 30 } },
  ],
};
const walletResp: WalletAuditResponse = {
  total: 1, page: 1, pageSize: 15,
  items: [{ id: 'w1', at: '2026-06-10T08:00:00.000Z', actor: 'Quang Vũ', reason: 'Daily task claimed', amount: 20, currency: 'tokens', refType: 'daily_task' }],
};

const m = vi.hoisted(() => ({ adminAudit: vi.fn(), walletAudit: vi.fn() }));
vi.mock('../lib/api', () => ({
  api: {
    adminAudit: (...a: unknown[]) => m.adminAudit(...a),
    walletAudit: (...a: unknown[]) => m.walletAudit(...a),
  },
}));

function renderPage() { return render(<MemoryRouter><AuditPage /></MemoryRouter>); }

describe('AuditPage', () => {
  beforeEach(() => {
    m.adminAudit.mockReset().mockResolvedValue(adminResp);
    m.walletAudit.mockReset().mockResolvedValue(walletResp);
  });

  it('renders admin-action rows on the default tab', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('admin@zenzoo.app')).toBeInTheDocument());
    expect(screen.getByText('mod@zenzoo.app')).toBeInTheDocument();
    expect(screen.getByText('package.update')).toBeInTheDocument(); // raw action code (unique to row)
  });

  it('switches to the wallet tab and queries the wallet ledger', async () => {
    renderPage();
    await waitFor(() => expect(m.adminAudit).toHaveBeenCalled());
    fireEvent.click(screen.getByText('Giao dịch ví'));
    await waitFor(() => expect(m.walletAudit).toHaveBeenCalled());
    expect(await screen.findByText('Quang Vũ')).toBeInTheDocument();
    expect(screen.getByText('Daily task claimed')).toBeInTheDocument();
  });

  it('passes the action filter to the admin-audit API', async () => {
    renderPage();
    await waitFor(() => expect(m.adminAudit).toHaveBeenCalled());
    fireEvent.change(screen.getByLabelText('Lọc theo hành động'), { target: { value: 'payment.confirm' } });
    await waitFor(() => {
      const last = m.adminAudit.mock.calls.at(-1)![0] as { action?: string };
      expect(last.action).toBe('payment.confirm');
    });
  });
});
