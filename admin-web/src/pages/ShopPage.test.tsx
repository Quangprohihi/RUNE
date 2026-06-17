import { describe, it, expect, vi, beforeEach } from 'vitest';
import { render, screen, waitFor, fireEvent } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { ShopPage } from './ShopPage';
import type { EconomyResponse, ShopItemsResponse } from '../lib/types';

const eco: EconomyResponse = {
  range: '30d',
  kpis: { tokenFaucet: 5000, tokenSink: 1800, tokenNet: 3200, diamondFaucet: 120 },
  activeItems: 7,
};
const itemsResp: ShopItemsResponse = {
  items: [
    { id: 'i1', code: 'companion_eagle', name: 'Eagle', emoji: '🦅', itemType: 'companion', priceTokens: 260, effectType: 'love', effectValue: 0, isHot: true, isActive: true },
    { id: 'i2', code: 'boost_focus', name: 'Focus Boost', emoji: '⚡', itemType: 'boost', priceTokens: 50, effectType: 'energy', effectValue: 10, isHot: false, isActive: true },
  ],
};

const m = vi.hoisted(() => ({ economy: vi.fn(), shopItems: vi.fn(), updateShopItem: vi.fn() }));
vi.mock('../lib/api', () => ({
  api: {
    economy: (...a: unknown[]) => m.economy(...a),
    shopItems: (...a: unknown[]) => m.shopItems(...a),
    updateShopItem: (...a: unknown[]) => m.updateShopItem(...a),
  },
}));

function renderPage() { return render(<MemoryRouter><ShopPage /></MemoryRouter>); }

describe('ShopPage', () => {
  beforeEach(() => {
    m.economy.mockReset().mockResolvedValue(eco);
    m.shopItems.mockReset().mockResolvedValue(itemsResp);
    m.updateShopItem.mockReset().mockResolvedValue(itemsResp.items[0]);
  });

  it('renders economy KPIs and item rows', async () => {
    renderPage();
    await waitFor(() => expect(screen.getByText('Token phát hành')).toBeInTheDocument());
    expect(screen.getByText('Kim cương phát hành')).toBeInTheDocument();
    expect(await screen.findByText('Eagle')).toBeInTheDocument();
    expect(screen.getByText('companion_eagle')).toBeInTheDocument();
  });

  it('re-queries economy when the range changes', async () => {
    renderPage();
    await waitFor(() => expect(m.economy).toHaveBeenCalledWith('30d'));
    fireEvent.click(screen.getByText('Quý'));
    await waitFor(() => expect(m.economy).toHaveBeenCalledWith('quarter'));
  });

  it('edits an item price and calls updateShopItem', async () => {
    renderPage();
    await screen.findByText('Eagle');
    fireEvent.click(screen.getAllByText('Sửa')[0]);
    const input = await screen.findByLabelText('Giá token');
    fireEvent.change(input, { target: { value: '300' } });
    fireEvent.click(screen.getByText('Lưu'));
    await waitFor(() => {
      expect(m.updateShopItem).toHaveBeenCalledWith('i1', { priceTokens: 300, isActive: true, isHot: true });
    });
  });
});
