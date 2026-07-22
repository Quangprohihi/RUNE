# Admin Console — "Cửa hàng & Kinh tế" (Shop & Economy) design

Date: 2026-06-17 · Phase 2d · Branch `Rune-Dev`

## Goal
Build `/console/shop` ("Cửa hàng & Kinh tế") — a game-economy dashboard: 4 economy KPIs
+ an editable shop-item catalog. Showcases the ZenZoo token/diamond economy (a core,
demo-friendly part of the product). Sibling of the "Nội dung game" nav group.

## Why this screen
`/admin/api/shop-items` GET+PUT already exist (price/active/hot), so the table + write
actions are nearly free. The only new backend is an economy-KPI aggregation. Reuses the
established Billing pattern (range picker → 4 KpiCards → table → inline edit).

## Backend

### Pure helpers (TDD) `backend/src/admin/shop.metrics.ts`
- `economySummary(tokenCredit, tokenDebit, diamondCredit)` → `{ tokenFaucet, tokenSink, tokenNet, diamondFaucet }`
  (faucet = credits, sink = |debits|, net = faucet − sink). Unit-tested.
- `parsePriceTokens(v): number` — validates an admin-entered price → rounded non-negative int,
  else throws 400. Mirrors the package-price validator. Unit-tested.

### Endpoints
- **GET /admin/api/economy?range=** (NET-NEW, `requireAdmin` base). `range ∈ today|7d|30d|quarter`
  (default 30d), windowed via `windowFor`. Aggregates `WalletTransaction` in-window:
  token credits (amount>0, currency=tokens), token debits (amount<0, tokens), diamond credits
  (amount>0, diamonds). Returns `{ range, kpis: { tokenFaucet, tokenSink, tokenNet, diamondFaucet }, activeItems }`.
- **GET /admin/api/shop-items** (exists; FE-unused) — keep as-is (returns full catalog).
- **PUT /admin/api/shop-items/:id** (harden): use `parsePriceTokens` for `priceTokens`,
  `Boolean()` for isActive/isHot; **add `recordAdminAction('shop.update', 'shop_item', :id, data)`**
  (so shop edits show in the audit log — consistency with Phase 2c).

## Frontend

### types.ts
`ShopItem` (id, code, name, emoji, itemType, priceTokens, effectType, effectValue, isHot, isActive),
`ShopItemsResponse { items }`, `EconomyKpis`, `EconomyResponse { range, kpis, activeItems }`,
`ShopItemUpdate { priceTokens?, isActive?, isHot? }`.

### api.ts
`shopItems()`, `economy(range)`, `updateShopItem(id, body)`.

### ShopPage.tsx (`/console/shop`)
- Range `SegmentedControl` (Hôm nay / 7 ngày / 30 ngày / Quý) → re-queries economy.
- 4 `KpiCard` (hideSpark): **Token phát hành · Token đã tiêu · Cân bằng token · Kim cương phát hành**.
- Items table (client-side paginated, 15/page via shared `pageList`): Vật phẩm (emoji + name + code)
  · Loại (`itemType` Tag) · Giá (priceTokens) · Trạng thái (Active / Hot badges) · Sửa.
- **Sửa** inline (mirrors Billing package edit): edit priceTokens + isActive + isHot → PUT → reload.
- Loading `Skeleton`, `ErrorState` on failure.

### nav/route
`nav.ts`: flip `shop` to enabled `to:'/shop'`; add `ROUTE_META['/shop']` + `metaFor`.
`App.tsx`: add `/shop` route → `ShopPage`.

### Audit integration
Add `shop.update` → "Sửa vật phẩm shop" to the AuditPage action-label map + filter dropdown.

## Tests
- Backend (in-container): `shop.metrics.test.ts` — `economySummary` (faucet/sink/net/diamond),
  `parsePriceTokens` (rounds, rejects negative/NaN).
- Frontend: `ShopPage.test.tsx` — renders the 4 KPI labels + an item row; range change re-queries
  economy; clicking Sửa reveals the form and saving calls updateShopItem with the new price.

## Verification
Backend + FE tests + typecheck + build green; E2E (KPIs + items render real data; range switch;
edit an item price live and confirm it persists + appears in the audit log); diff review
(auth gating, validation, best-effort audit, no secrets); commit on `Rune-Dev`.

## Non-goals
Creating/deleting shop items; diamond-priced items (model is token-only); inventory analytics
per item; editing effectType/effectValue (game-balance config — out of scope for now).
